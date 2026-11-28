#!/usr/bin/env python3
"""Ejecuta los cuadernos del curso con nbclient y resume el resultado.

Uso:
    python3 scripts/ejecutar_cuadernos.py [--omitir ARCHIVO] [--timeout S] [cuaderno ...]

- Sin cuadernos explícitos, recorre ``[0-9][0-9]_*.ipynb`` de la raíz y, si existe
  la carpeta ``soluciones/``, también ``soluciones/*.ipynb``. Si la carpeta no
  está, el script sigue y no falla.
- ``--omitir`` apunta a un archivo de texto con un cuaderno por línea (los
  comentarios empiezan con ``#``); esos cuadernos no se ejecutan y se cuentan
  como omitidos.
- Cada cuaderno usa el kernel declarado en sus metadatos.
- Las celdas con la etiqueta ``skip-execution`` no se ejecutan (por ejemplo,
  editores interactivos). Las celdas con la etiqueta ``raises-exception``
  pueden terminar en error sin que el cuaderno falle (lo admite nbclient).
- En los cuadernos con kernel de Python, cada línea ``!comando`` se comprueba
  con ``_exit_code``: un comando del sistema que termina con error hace fallar
  la celda (IPython, por sí solo, no lo considera un error).
- Ningún cuaderno se guarda: las salidas solo se usan para el resumen.
- Los cuadernos se ejecutan en una copia temporal del repositorio, para que los
  archivos de práctica que crean no ensucien el árbol de trabajo.
- Por cuaderno se informa cuántas celdas de código se ejecutan y cuántas se
  omiten con ``skip-execution``. Las celdas que necesitan un servicio externo
  (proyecto de Google Cloud, GHCR, un anfitrión por SSH) llevan esa etiqueta;
  véase ``docs/CI_CUADERNOS.md``. Las celdas omitidas de ``soluciones/`` están
  en la tabla «Qué no puede ejecutar la CI» de ``soluciones/README.md``.
"""

from __future__ import annotations

import argparse
import glob
import os
import shutil
import sys
import tempfile
import time

import nbformat
from nbclient import NotebookClient

ETIQUETA_OMITIR = "skip-execution"
COMPROBACION = "if _exit_code != 0: raise RuntimeError(f'El comando terminó con código {_exit_code}')"


def leer_omitidos(ruta: str | None) -> dict[str, str]:
    omitidos: dict[str, str] = {}
    if not ruta:
        return omitidos
    with open(ruta, encoding="utf-8") as f:
        for linea in f:
            linea = linea.strip()
            if not linea or linea.startswith("#"):
                continue
            nombre, _, motivo = linea.partition("#")
            omitidos[nombre.strip()] = motivo.strip()
    return omitidos


def verificar_comandos(celda) -> None:
    """Añade, tras cada línea ``!comando``, una comprobación de su código de salida."""
    if "raises-exception" in celda.get("metadata", {}).get("tags", []):
        return
    nuevas = []
    sangria = None  # sangría del comando ! en curso (puede seguir en varias líneas con \\)
    for linea in celda.source.splitlines():
        nuevas.append(linea)
        if sangria is None and linea.lstrip().startswith("!"):
            sangria = linea[: len(linea) - len(linea.lstrip())]
        if sangria is not None and not linea.rstrip().endswith("\\"):
            nuevas.append(f"{sangria}{COMPROBACION}")
            sangria = None
    celda.source = "\n".join(nuevas)


def ejecutar(ruta: str, timeout: int) -> tuple[bool, str, int, int]:
    nb = nbformat.read(ruta, as_version=4)
    antes = len(nb.cells)
    nb.cells = [c for c in nb.cells if ETIQUETA_OMITIR not in c.get("metadata", {}).get("tags", [])]
    celdas_omitidas = antes - len(nb.cells)
    celdas_codigo = sum(1 for c in nb.cells if c.cell_type == "code")
    kernel = nb.metadata.get("kernelspec", {}).get("name", "python3")
    if nb.metadata.get("kernelspec", {}).get("language", "python") == "python":
        for celda in nb.cells:
            if celda.cell_type == "code":
                verificar_comandos(celda)
    cliente = NotebookClient(
        nb,
        timeout=timeout,
        kernel_name=kernel,
        allow_errors=False,
        resources={"metadata": {"path": os.path.dirname(os.path.abspath(ruta))}},
    )
    try:
        cliente.execute()
    except Exception as exc:  # noqa: BLE001
        return False, f"{type(exc).__name__}: {str(exc)[-800:]}", celdas_omitidas, celdas_codigo
    return True, "", celdas_omitidas, celdas_codigo


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("cuadernos", nargs="*")
    parser.add_argument("--omitir", help="archivo con la lista de cuadernos que no se ejecutan")
    parser.add_argument("--timeout", type=int, default=180, help="segundos máximos por celda")
    args = parser.parse_args()

    raiz = os.getcwd()
    if args.cuadernos:
        cuadernos = [os.path.abspath(c) for c in args.cuadernos]
    else:
        encontrados = sorted(glob.glob("[0-9][0-9]_*.ipynb"))
        if os.path.isdir("soluciones"):
            encontrados.extend(sorted(glob.glob(os.path.join("soluciones", "*.ipynb"))))
        cuadernos = [os.path.abspath(c) for c in encontrados]
    omitidos = leer_omitidos(args.omitir)
    # La copia conserva el nombre del directorio (algunas celdas usan rutas como ../cd101).
    temporal = tempfile.mkdtemp(prefix="cuadernos-")
    copia = os.path.join(temporal, os.path.basename(raiz))
    shutil.copytree(raiz, copia, dirs_exist_ok=True, ignore=shutil.ignore_patterns(".git"))
    pasan, fallan, saltados = [], [], []

    for ruta in cuadernos:
        relativo = os.path.relpath(ruta, raiz)
        nombre = os.path.basename(ruta)
        clave = relativo if relativo in omitidos else nombre
        if clave in omitidos or nombre in omitidos:
            saltados.append(relativo)
            print(f"[OMITIDO] {relativo}: {omitidos.get(clave) or omitidos[nombre]}", flush=True)
            continue
        inicio = time.monotonic()
        ok, error, n_omit, n_codigo = ejecutar(os.path.join(copia, relativo), args.timeout)
        duracion = time.monotonic() - inicio
        extra = f", {n_codigo} celdas de código ejecutadas, {n_omit} omitidas con {ETIQUETA_OMITIR}"
        if ok:
            pasan.append(relativo)
            print(f"[OK] {relativo} ({duracion:.1f} s{extra})", flush=True)
        else:
            fallan.append(relativo)
            print(f"[FALLA] {relativo} ({duracion:.1f} s{extra})\n{error}", flush=True)

    shutil.rmtree(temporal, ignore_errors=True)
    print(f"\nResumen: {len(pasan)} pasan, {len(fallan)} fallan, {len(saltados)} omitidos.")

    def _grupo(rutas: list[str], prefijo: str) -> list[str]:
        if prefijo == "raiz":
            return [r for r in rutas if not r.startswith("soluciones" + os.sep)]
        return [r for r in rutas if r.startswith("soluciones" + os.sep)]

    if any(r.startswith("soluciones" + os.sep) for r in pasan + fallan + saltados) and any(
        not r.startswith("soluciones" + os.sep) for r in pasan + fallan + saltados
    ):
        for etiqueta, prefijo in (("raíz", "raiz"), ("soluciones/", "soluciones")):
            p, f, o = _grupo(pasan, prefijo), _grupo(fallan, prefijo), _grupo(saltados, prefijo)
            print(f"  {etiqueta}: {len(p)} pasan, {len(f)} fallan, {len(o)} omitidos.")

    for nombre in fallan:
        print(f"  - falla: {nombre}")
    return 1 if fallan else 0


if __name__ == "__main__":
    sys.exit(main())
