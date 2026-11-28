"""Utilidades compartidas por los cuadernos de soluciones de cd441 (Cloudevel).

Ninguna función de este módulo usa credenciales ni accede a la red. Sirven para
ensayar en local lo que después hace GitHub Actions: leer un *workflow*,
sustituir expresiones ``${{ ... }}`` y ejecutar sus pasos ``run`` con ``bash``.
"""

from __future__ import annotations

import os
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

import yaml

EXPRESION = re.compile(r"\$\{\{\s*([A-Za-z_]+)\.([A-Za-z0-9_]+)\s*\}\}")
USES_FIJADO = re.compile(r"^[^@\s]+@[0-9a-f]{40}$")
IGNORAR = shutil.ignore_patterns(
    ".git", ".venv", "__pycache__", ".pytest_cache", ".ruff_cache", ".coverage", "coverage.xml", "actions-runner"
)


def raiz_repositorio(inicio: Path | None = None) -> Path:
    """Devuelve el directorio raíz del repositorio (el que contiene ``api/wsgi.py``)."""
    inicio = (inicio or Path.cwd()).resolve()
    for candidato in [inicio, *inicio.parents]:
        if (candidato / "api" / "wsgi.py").exists():
            return candidato
    raise FileNotFoundError("No se encontró la raíz del repositorio (api/wsgi.py).")


def copiar_repositorio(raiz: Path, destino: Path) -> Path:
    """Copia el repositorio (sin historial ni cachés) para trabajar sin ensuciarlo."""
    copia = destino / raiz.name
    shutil.copytree(raiz, copia, ignore=IGNORAR)
    return copia


def directorio_temporal() -> Path:
    return Path(tempfile.mkdtemp(prefix="cd441-sol-"))


def cargar_workflow(origen: str | Path) -> dict:
    """Lee un *workflow* desde una ruta o desde un texto YAML.

    PyYAML sigue YAML 1.1, donde ``on`` es un booleano: la clave ``on`` queda
    guardada como ``True``. Esta función la devuelve como ``"on"``.
    """
    texto = Path(origen).read_text(encoding="utf-8") if isinstance(origen, Path) else origen
    datos = yaml.safe_load(texto)
    if True in datos:
        datos["on"] = datos.pop(True)
    return datos


def sustituir_expresiones(texto: str, contextos: dict[str, dict[str, str]]) -> str:
    """Sustituye ``${{ contexto.nombre }}``; un valor inexistente da cadena vacía."""

    def _valor(coincidencia: re.Match) -> str:
        contexto, nombre = coincidencia.groups()
        return str(contextos.get(contexto, {}).get(nombre, ""))

    resto = EXPRESION.sub(_valor, texto)
    if "${{" in resto:
        raise ValueError("Expresión no admitida por la simulación: " + resto)
    return resto


def simular_job(
    workflow: dict,
    job: str,
    contextos: dict[str, dict[str, str]],
    directorio: Path,
    secretos: tuple[str, ...] = (),
) -> list[tuple[str, str, int]]:
    """Ejecuta con ``bash`` los pasos ``run`` de un *job* y enmascara los secretos.

    Devuelve una lista de ``(nombre del paso, salida, código de salida)``. Los pasos
    con ``uses`` no se ejecutan. Es un ensayo: no sustituye a un *runner* real.
    """
    definicion = workflow["jobs"][job]
    entorno_base = {"PATH": os.environ["PATH"], "HOME": str(directorio), "LC_ALL": "C.UTF-8"}
    entorno_base.update(
        {k: sustituir_expresiones(str(v), contextos) for k, v in {**workflow.get("env", {}), **definicion.get("env", {})}.items()}
    )
    resultados = []
    for numero, paso in enumerate(definicion["steps"], start=1):
        nombre = paso.get("name") or paso.get("uses") or f"Paso {numero}"
        if "run" not in paso:
            resultados.append((nombre, "(acción omitida en la simulación)", 0))
            continue
        entorno = dict(entorno_base)
        entorno.update({k: sustituir_expresiones(str(v), contextos) for k, v in paso.get("env", {}).items()})
        guion = sustituir_expresiones(paso["run"], contextos)
        proceso = subprocess.run(
            ["bash", "--noprofile", "--norc", "-eo", "pipefail", "-c", guion],
            cwd=directorio,
            env=entorno,
            capture_output=True,
            text=True,
            check=False,
        )
        salida = proceso.stdout + proceso.stderr
        for secreto in secretos:
            salida = salida.replace(secreto, "***")
        resultados.append((nombre, salida.rstrip("\n"), proceso.returncode))
    return resultados


def mostrar_resultados(resultados: list[tuple[str, str, int]]) -> None:
    for nombre, salida, codigo in resultados:
        print(f"▶ {nombre} (código de salida {codigo})")
        for linea in salida.splitlines():
            print(f"    {linea}")


def pasos(workflow: dict, job: str) -> list[dict]:
    return workflow["jobs"][job]["steps"]


def acciones_usadas(workflow: dict) -> list[tuple[str, str]]:
    """Lista ``(job, uses)`` de todas las acciones externas del *workflow*."""
    encontradas = []
    for nombre, job in workflow.get("jobs", {}).items():
        for paso in job.get("steps", []):
            uses = paso.get("uses")
            if uses and not uses.startswith(("./", "docker://")):
                encontradas.append((nombre, uses))
    return encontradas


def acciones_sin_fijar(workflow: dict) -> list[str]:
    return [uses for _, uses in acciones_usadas(workflow) if not USES_FIJADO.match(uses)]


def ejecutar(comando: list[str], directorio: Path, entorno: dict[str, str] | None = None, comprobar: bool = True):
    """Ejecuta un comando y devuelve el ``CompletedProcess`` con salida de texto."""
    return subprocess.run(
        comando,
        cwd=directorio,
        env=entorno,
        capture_output=True,
        text=True,
        check=comprobar,
    )


def crear_entorno_api(directorio_api: Path, destino: Path) -> Path:
    """Crea un entorno virtual e instala ``requirements-dev.txt`` (requiere acceso a PyPI).

    Reproduce el paso «Instalar dependencias» del job ``verificar`` de ``ci.yml``.
    Devuelve la ruta del intérprete de Python del entorno.
    """
    entorno = destino / "venv-api"
    ejecutar(["python3", "-m", "venv", str(entorno)], destino)
    python = entorno / "bin" / "python"
    ejecutar(
        [str(python), "-m", "pip", "install", "--quiet", "--disable-pip-version-check",
         "-r", str(directorio_api / "requirements-dev.txt")],
        destino,
    )
    return python


def ejecutar_paso_run(
    ruta_workflow: Path, job: str, nombre_paso: str, entorno: dict[str, str]
) -> dict[str, object]:
    """Ejecuta con ``bash`` el guion ``run`` de un paso de un *workflow* real.

    Sirve para probar, sin nube, los pasos que solo validan datos. Los archivos
    ``GITHUB_OUTPUT``, ``GITHUB_ENV`` y ``GITHUB_STEP_SUMMARY`` se crean en una
    carpeta temporal. Devuelve el código de salida, las salidas del paso
    (``salidas``) y lo que imprimió (``texto``).
    """
    workflow = cargar_workflow(ruta_workflow)
    paso = next(p for p in workflow["jobs"][job]["steps"] if p.get("name") == nombre_paso)
    carpeta = directorio_temporal()
    archivos = {nombre: carpeta / nombre.lower() for nombre in ("GITHUB_OUTPUT", "GITHUB_ENV", "GITHUB_STEP_SUMMARY")}
    for archivo in archivos.values():
        archivo.touch()
    completo = {"PATH": os.environ["PATH"], **{k: str(v) for k, v in archivos.items()}, **entorno}
    proceso = subprocess.run(
        ["bash", "--noprofile", "--norc", "-eo", "pipefail", "-c", paso["run"]],
        env=completo,
        capture_output=True,
        text=True,
        check=False,
    )
    salidas = dict(
        linea.split("=", 1) for linea in archivos["GITHUB_OUTPUT"].read_text().splitlines() if "=" in linea
    )
    return {"codigo": proceso.returncode, "salidas": salidas, "texto": (proceso.stdout + proceso.stderr).strip()}
