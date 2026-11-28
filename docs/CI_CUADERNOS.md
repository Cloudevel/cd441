# CI de los cuadernos (`.github/workflows/notebooks.yml`)

El workflow «Cuadernos» ejecuta **todos** los cuadernos `[0-9][0-9]_*.ipynb` de la raíz, incluidos el 16 y el 17, y, **si existe** la carpeta `soluciones/`, también `soluciones/*.ipynb`. Si esa carpeta no está, el *job* termina bien con solo los de la raíz. Lo hace `scripts/ejecutar_cuadernos.py` con *nbclient*, dentro del mismo *devcontainer* que usan los estudiantes (Python 3.12, kernels de Python y Bash, y el binario `gitleaks`).

## Qué no puede hacer la CI

La CI **no tiene credenciales ni servicios externos**: ni proyecto de Google Cloud, ni acceso de escritura a GHCR, ni un anfitrión Ubuntu por SSH, ni un *runner* propio. Por eso las celdas que los necesitan se **omiten de forma explícita**:

- Mecanismo: la etiqueta de celda `skip-execution` (en `metadata.tags` de la celda). El script ya la respetaba para los editores interactivos; no se añadió ningún mecanismo nuevo.
- Las celdas omitidas se **cuentan y se muestran** en el registro de la CI: `[OK] cuaderno.ipynb (… s, N celdas de código ejecutadas, M omitidas con skip-execution)`.
- Todo lo demás se ejecuta de verdad: el kernel arranca, las celdas sin etiqueta corren y un error en cualquiera hace fallar el cuaderno.
- `scripts/cuadernos_omitidos.txt` (que omite cuadernos enteros) está vacío a propósito.

## Celdas omitidas (numeración desde 0, la de *nbformat*)

| Cuaderno | Celda | Comando | Por qué se omite |
|---|---|---|---|
| 16 | 9 | `bash api/deploy/gcp/preparar_proyecto.sh` | Necesita un proyecto de Google Cloud, `gcloud` autenticado y rol de propietario |
| 16 | 11 | `GITHUB_REPO="${GITHUB_REPOSITORY}" bash api/deploy/gcp/configurar_wif.sh` | Crea el pool y el proveedor de Workload Identity Federation en un proyecto real |
| 16 | 15 | `bash api/deploy/gcp/desplegar_manual.sh` | Publica en Artifact Registry y despliega en Cloud Run |
| 16 | 25 | `bash api/deploy/gcp/limpiar.sh` | Borra recursos de un proyecto real (y pide confirmación interactiva) |
| 17 | — | ninguna | La única celda de código (`ssh-keygen` de una clave Ed25519 de práctica, sin contraseña) no necesita servicios externos y **se ejecuta** |

Resultado en el *devcontainer*: cuaderno 16 → 0 celdas de código ejecutadas y 4 omitidas; cuaderno 17 → 1 celda de código ejecutada y 0 omitidas. Sin las etiquetas, el 16 falla en la celda 9 (falta `GCP_REGION`).

## Soluciones (`soluciones/`)

Cuando la carpeta está en el repositorio, la CI recorre también `soluciones/*.ipynb` con el mismo mecanismo (`skip-execution`). Las celdas de esos cuadernos que la CI no puede ejecutar (y el motivo: `requiere-nube`, `requiere-docker`, `requiere-ssh` o `requiere-gitleaks`) las documenta Experto docente en la tabla **«Qué no puede ejecutar la CI»** de `soluciones/README.md`. Esa tabla es la referencia; no se duplica aquí.

## Cómo añadir una celda que necesita un servicio externo

1. Etiquétala con `skip-execution` (en Jupyter: *View → Cell Toolbar → Tags*, o `"metadata": {"tags": ["skip-execution"]}` en el JSON).
2. Añade una fila a la tabla de arriba (cuadernos de la raíz) o, si es una solución, a la de `soluciones/README.md`.
3. Ejecuta localmente: `python scripts/ejecutar_cuadernos.py <cuaderno>.ipynb` dentro del *devcontainer*.

La CI de la API (`ci.yml`) y los despliegues (`deploy-*.yml`) son independientes de este workflow. Las pruebas reales de esos despliegues están descritas en `docs/PRERREQUISITOS_PRUEBAS_EN_VIVO.md` y `docs/ESTADO_Y_PRUEBAS.md`.
