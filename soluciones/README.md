# Soluciones de los ejercicios · cd441 (Cloudevel)

Cuadernos de solución de las actividades del curso *Integración y entrega continua con GitHub Actions*. Cada cuaderno reproduce el enunciado de cada ejercicio, explica con una celda «La siguiente celda…» lo que hace cada celda de código y termina con una comprobación.

## Cómo se ejecutan

Los cuadernos usan el *kernel* de *Python* del *devcontainer* del curso (*Python* 3.12). Se abren desde la carpeta `soluciones/` y localizan solos la raíz del repositorio. El módulo `utilidades.py` (en esta misma carpeta) contiene las funciones comunes: leer un *workflow*, sustituir expresiones `${{ … }}`, ensayar sus pasos `run` con `bash` y ejecutar los pasos de validación reales de los *workflows*.

Hay tres tipos de celdas:

| Tipo | Etiquetas | Qué necesita | Con `ejecutar_cuadernos.py` |
|---|---|---|---|
| Comprobación local | ninguna | Python, `bash`; algunas necesitan acceso a PyPI | se ejecuta |
| Práctica en la nube | `skip-execution` y `requiere-nube` | cuenta de GitHub con `gh`, o un proyecto de nube | se omite |
| Práctica con Docker, SSH o herramientas externas | `skip-execution` y `requiere-docker`, `requiere-ssh` o `requiere-gitleaks` | un demonio de Docker, un Ubuntu 24.04 completo o el binario `gitleaks` | se omite |

La etiqueta `skip-execution` es la que ya usa `scripts/ejecutar_cuadernos.py`; la segunda etiqueta solo indica el motivo. Detrás de cada celda omitida hay una celda de texto con la **salida esperada**.

Para ejecutar solo las comprobaciones locales desde la raíz del repositorio:

```bash
python scripts/ejecutar_cuadernos.py soluciones/*.ipynb
```

`scripts/ejecutar_cuadernos.py` y el *workflow* `notebooks.yml` recorren solo los cuadernos de la raíz; esta carpeta no forma parte de la CI actual.

## Reglas de las soluciones

* Ningún valor real: los identificadores de proyecto, las direcciones y los usuarios se leen de variables de entorno. Los ejemplos usan marcadores (`proyecto-ejemplo-123`, `ejemplo-norte1`, `192.0.2.10`).
* Ninguna llave se escribe en un archivo del repositorio. Las claves de la práctica se crean en `$HOME/cd441-destino/`.
* Sin imágenes, salvo el logotipo de *Cloudevel* de la portada (con su enlace). No hay texto dentro de imágenes.
* Las celdas con etiqueta nunca se ejecutan en la CI. Cualquier celda nueva que use GCP, SSH o GHCR debe llevar `skip-execution`.

## Índice

| Solución | Cuaderno original | Enunciados | Ejercicios | Celdas omitidas por la CI |
|---|---|---|---|---|
| [`02_solucion_actividad_hello_world.ipynb`](02_solucion_actividad_hello_world.ipynb) | `02_actividad_hello_world.ipynb` | Actividad explícita | 4 | 4 |
| [`06_solucion_variables_y_secretos.ipynb`](06_solucion_variables_y_secretos.ipynb) | `06_expresiones_y_variables.ipynb` | Actividad explícita (apartado «Actividad» y ejemplo de secretos) | 3 | 2 |
| [`07_solucion_actividad_expresiones.ipynb`](07_solucion_actividad_expresiones.ipynb) | `07_actividad_expresiones.ipynb` | Actividad explícita | 3 | 2 |
| [`10_solucion_runner_autoalojado.ipynb`](10_solucion_runner_autoalojado.ipynb) | `10_runner_en_entorno_local.ipynb` | Actividad explícita | 6 | 8 |
| [`11_solucion_artefactos.ipynb`](11_solucion_artefactos.ipynb) | `11_artefactos.ipynb` | Sin enunciado: ejercicios derivados del texto | 3 | 1 |
| [`12_solucion_entornos.ipynb`](12_solucion_entornos.ipynb) | `12_entornos.ipynb` | Sin enunciado: ejercicios derivados del texto | 3 | 2 |
| [`13_solucion_seguridad.ipynb`](13_solucion_seguridad.ipynb) | `13_seguridad.ipynb` | Una actividad explícita (gitleaks) y verificaciones derivadas | 5 | 1 |
| [`14_solucion_pipeline_ci.ipynb`](14_solucion_pipeline_ci.ipynb) | `14_pipeline_ci_de_una_api.ipynb` | Actividad explícita (5 pasos) | 5 | 4 |
| [`15_solucion_imagenes_y_registro.ipynb`](15_solucion_imagenes_y_registro.ipynb) | `15_imagenes_de_contenedor_y_registro.ipynb` | Actividad explícita (3 pasos) | 3 | 2 |
| [`16_solucion_cloud_run.ipynb`](16_solucion_cloud_run.ipynb) | `16_despliegue_en_cloud_run.ipynb` | Actividad explícita (4 pasos) | 5 | 6 |
| [`17_solucion_linux_ssh.ipynb`](17_solucion_linux_ssh.ipynb) | `17_despliegue_en_linux_por_ssh.ipynb` | Actividad explícita (5 pasos) | 6 | 10 |

Los cuadernos 01, 03, 04, 05, 08 y 09 son teóricos o muestran código de demostración y **no tienen ejercicios**, por lo que no tienen solución. Véase «Propuestas» más abajo.

## Ejercicios por cuaderno

### 02_solucion_actividad_hello_world.ipynb

* Ejercicio 1. Crear un repositorio en GitHub
* Ejercicio 2. Crear un workflow simple
* Ejercicio 3. Esperar la primera ejecución y lanzar una manual
* Ejercicio 4. Explorar el proceso de un workflow

### 06_solucion_variables_y_secretos.ipynb

* Ejercicio 1. Definir una variable de repositorio
* Ejercicio 2. Definir un secreto de repositorio
* Ejercicio 3. Resumir los contextos y su sintaxis (complemento)

### 07_solucion_actividad_expresiones.ipynb

* Ejercicio 1. Crear el workflow `expresiones.yml`
* Ejercicio 2. Guardar el archivo y ejecutar el workflow
* Ejercicio 3. Observación de seguridad (complemento)

### 10_solucion_runner_autoalojado.ipynb

* Ejercicio 1. Preparar el repositorio de la práctica como privado (requisito de seguridad)
* Ejercicio 2. Descargar la aplicación del runner
* Ejercicio 3. Verificar la integridad del paquete
* Ejercicio 4. Registrar y poner en marcha el runner
* Ejercicio 5. Ejecutar un workflow en el runner propio
* Ejercicio 6. Dar de baja el runner (limpieza)

### 11_solucion_artefactos.ipynb

* Ejercicio 1. Reproducir en local el informe de cobertura
* Ejercicio 2. Comprobar la retención del artefacto
* Ejercicio 3. Localizar y descargar el artefacto

### 12_solucion_entornos.ipynb

* Ejercicio 1. Diseñar la configuración de los entornos `cloudrun` y `linux`
* Ejercicio 2. Comprobar que los workflows referencian los entornos
* Ejercicio 3. Listar las variables y los secretos de cada entorno

### 13_solucion_seguridad.ipynb

* Ejercicio 1. Buscar secretos en el árbol de trabajo y en el historial
* Ejercicio 2. Comprobar que las acciones están fijadas por SHA
* Ejercicio 3. Comprobar los permisos mínimos
* Ejercicio 4. Comprobar que el checkout no conserva el token
* Ejercicio 5. Comprobar las defensas contra la inyección de comandos y la actualización automática

### 14_solucion_pipeline_ci.ipynb

* Ejercicio 1. Comprobar los archivos del pipeline
* Ejercicio 2. Disparar el workflow CI con un push o un pull request
* Ejercicio 3. Confirmar el job verificar y el artefacto
* Ejercicio 4. Provocar un fallo a propósito
* Ejercicio 5. Localizar el job publicar-imagen

### 15_solucion_imagenes_y_registro.ipynb

* Ejercicio 1. Construir la imagen y comprobar GET /health
* Ejercicio 2. Revisar la construcción y la publicación en una ejecución de CI
* Ejercicio 3. Reconocer instrucciones del Dockerfile

### 16_solucion_cloud_run.ipynb

* Ejercicio 1. Preparar el proyecto, configurar WIF y cargar las variables del entorno cloudrun
* Ejercicio 2. Primer despliegue manual y comprobación de GET /health
* Ejercicio 3. Desplegar con el workflow y comprobar la imagen y la versión
* Ejercicio 4. Reconocer en el workflow el paso de WIF, la promoción y la ausencia de acceso público
* Ejercicio 5. Limpiar los recursos (complemento)

### 17_solucion_linux_ssh.ipynb

* Ejercicio 1. Preparar el destino y el runner (o usar un runner hospedado)
* Ejercicio 2. Verificar la huella del servidor y cargar los secretos del entorno linux
* Ejercicio 3. Desplegar con el workflow y comprobar GET /health
* Ejercicio 4. Comprobar la idempotencia y la persistencia de los datos
* Ejercicio 5. Localizar la guarda, el known_hosts y el borrado de la clave
* Ejercicio 6. Dar de baja el destino y retirar los secretos (complemento)

Los ejercicios cuyo título termina en «(complemento)», y los de verificación de los cuadernos 11, 12 y 13, **no figuran como enunciado** en el cuaderno original: se derivan de afirmaciones de su texto o cierran un riesgo (limpieza, seguridad). Se identifican así a propósito.

## Qué no puede ejecutar la CI

| Cuaderno de solución | Celda (índice desde 0) | Etiquetas | Motivo |
|---|---|---|---|
| `02_solucion_actividad_hello_world.ipynb` | 8 | `skip-execution`, `requiere-nube` | gh repo create en GitHub |
| `02_solucion_actividad_hello_world.ipynb` | 19 | `skip-execution`, `requiere-nube` | git push a GitHub |
| `02_solucion_actividad_hello_world.ipynb` | 26 | `skip-execution`, `requiere-nube` | gh workflow run y gh run watch contra GitHub Actions |
| `02_solucion_actividad_hello_world.ipynb` | 33 | `skip-execution`, `requiere-nube` | gh run view contra GitHub Actions |
| `06_solucion_variables_y_secretos.ipynb` | 12 | `skip-execution`, `requiere-nube` | gh variable set contra GitHub |
| `06_solucion_variables_y_secretos.ipynb` | 17 | `skip-execution`, `requiere-nube` | gh secret set contra GitHub |
| `07_solucion_actividad_expresiones.ipynb` | 17 | `skip-execution`, `requiere-nube` | git push y gh workflow run contra GitHub |
| `07_solucion_actividad_expresiones.ipynb` | 19 | `skip-execution`, `requiere-nube` | gh run watch y gh run view contra GitHub |
| `10_solucion_runner_autoalojado.ipynb` | 7 | `skip-execution`, `requiere-nube` | gh repo edit contra GitHub |
| `10_solucion_runner_autoalojado.ipynb` | 14 | `skip-execution`, `requiere-nube` | descarga desde github.com/actions/runner |
| `10_solucion_runner_autoalojado.ipynb` | 21 | `skip-execution`, `requiere-nube` | usa el paquete descargado de github.com |
| `10_solucion_runner_autoalojado.ipynb` | 25 | `skip-execution`, `requiere-nube` | gh api contra GitHub (token de registro) |
| `10_solucion_runner_autoalojado.ipynb` | 27 | `skip-execution`, `requiere-nube` | config.sh registra el runner en github.com |
| `10_solucion_runner_autoalojado.ipynb` | 30 | `skip-execution`, `requiere-nube` | run.sh se conecta a github.com |
| `10_solucion_runner_autoalojado.ipynb` | 36 | `skip-execution`, `requiere-nube` | git push y gh workflow run contra GitHub |
| `10_solucion_runner_autoalojado.ipynb` | 40 | `skip-execution`, `requiere-nube` | remove-token y gh api contra GitHub |
| `11_solucion_artefactos.ipynb` | 17 | `skip-execution`, `requiere-nube` | gh api y gh run download contra GitHub |
| `12_solucion_entornos.ipynb` | 13 | `skip-execution`, `requiere-nube` | gh api contra GitHub (entornos) |
| `12_solucion_entornos.ipynb` | 22 | `skip-execution`, `requiere-nube` | gh variable set contra GitHub (entorno cloudrun) |
| `13_solucion_seguridad.ipynb` | 15 | `skip-execution`, `requiere-gitleaks` | requiere el binario gitleaks, que no está en el devcontainer |
| `14_solucion_pipeline_ci.ipynb` | 12 | `skip-execution`, `requiere-nube` | git push y gh pr create contra GitHub |
| `14_solucion_pipeline_ci.ipynb` | 21 | `skip-execution`, `requiere-nube` | gh run view y gh api contra GitHub |
| `14_solucion_pipeline_ci.ipynb` | 30 | `skip-execution`, `requiere-nube` | git push y gh run watch contra GitHub |
| `14_solucion_pipeline_ci.ipynb` | 36 | `skip-execution`, `requiere-nube` | gh run view contra GitHub |
| `15_solucion_imagenes_y_registro.ipynb` | 7 | `skip-execution`, `requiere-docker` | docker build/run (demonio de Docker) |
| `15_solucion_imagenes_y_registro.ipynb` | 18 | `skip-execution`, `requiere-nube` | consulta de paquetes de GHCR con gh api |
| `16_solucion_cloud_run.ipynb` | 14 | `skip-execution`, `requiere-nube` | gcloud: preparar_proyecto.sh y configurar_wif.sh (GCP) |
| `16_solucion_cloud_run.ipynb` | 17 | `skip-execution`, `requiere-nube` | gh variable set contra GitHub (entorno cloudrun) |
| `16_solucion_cloud_run.ipynb` | 21 | `skip-execution`, `requiere-nube` | gcloud/docker: desplegar_manual.sh (GCP y Artifact Registry) |
| `16_solucion_cloud_run.ipynb` | 24 | `skip-execution`, `requiere-nube` | gcloud run services describe y curl a Cloud Run |
| `16_solucion_cloud_run.ipynb` | 31 | `skip-execution`, `requiere-nube` | gh workflow run, gcloud y curl contra GitHub, GCP y GHCR |
| `16_solucion_cloud_run.ipynb` | 38 | `skip-execution`, `requiere-nube` | gcloud: limpiar.sh (GCP) y gh variable delete |
| `17_solucion_linux_ssh.ipynb` | 9 | `skip-execution`, `requiere-ssh` | ssh-keygen escribe en $HOME (clave real de la práctica) |
| `17_solucion_linux_ssh.ipynb` | 12 | `skip-execution`, `requiere-ssh` | scp y ssh contra el anfitrión Ubuntu |
| `17_solucion_linux_ssh.ipynb` | 15 | `skip-execution`, `requiere-ssh` | ssh contra el anfitrión y registro del runner en GitHub |
| `17_solucion_linux_ssh.ipynb` | 18 | `skip-execution`, `requiere-ssh` | gh variable set contra GitHub (entorno linux, destino SSH) |
| `17_solucion_linux_ssh.ipynb` | 26 | `skip-execution`, `requiere-ssh` | ssh-keyscan contra el anfitrión |
| `17_solucion_linux_ssh.ipynb` | 29 | `skip-execution`, `requiere-ssh` | gh secret set contra GitHub con la clave privada de la práctica |
| `17_solucion_linux_ssh.ipynb` | 35 | `skip-execution`, `requiere-ssh` | gh workflow run y despliegue por SSH (GHCR y anfitrión) |
| `17_solucion_linux_ssh.ipynb` | 42 | `skip-execution`, `requiere-ssh` | gh workflow run y ssh contra el anfitrión |
| `17_solucion_linux_ssh.ipynb` | 45 | `skip-execution`, `requiere-ssh` | ssh y systemctl en el anfitrión Ubuntu |
| `17_solucion_linux_ssh.ipynb` | 52 | `skip-execution`, `requiere-ssh` | gh secret delete y ssh contra el anfitrión |

Estas filas están pensadas para unirse a la tabla de `docs/CI_CUADERNOS.md` de la rama `ci/cuadernos-16-17-2711`, que no existe en esta rama.

Las comprobaciones locales de los cuadernos 11, 14 y 15 instalan las dependencias de la *API* con `pip` y necesitan acceso a *PyPI*. El cuaderno 17 usa `ssh-keygen` (sin red) para ensayar la verificación de la huella; no se omite.

## Propuestas sobre los enunciados

Los cuadernos originales no se modificaron. Estas son las faltas detectadas y la corrección que se propone en cada uno:

| Cuaderno | Problema | Propuesta |
|---|---|---|
| 02 | El enunciado «Explorar el proceso del workflow» no pide ningún resultado concreto; todo el contenido está en capturas de pantalla. | Añadir una lista de comprobación en texto: nombre del *job*, pasos esperados y estado final. |
| 02 y 10 | El 02 recomienda un repositorio **público**; el 10 exige un repositorio **privado** para el *runner*. | Recomendar repositorio privado en el 02. |
| 06 | La sintaxis `$<contexto>.<nombre>` no existe tal cual. El apartado «Ejemplo» de secretos mezcla pasos y valores sin enunciar el resultado esperado. | Sustituir por `$NOMBRE` (*shell*) y `${{ contexto.NOMBRE }}` (expresión). Añadir el resultado esperado. |
| 07 | No indica el nombre del archivo que se crea (solo aparece en una captura y en el registro). | Indicar `expresiones.yml`. Corregir «Selccionar», «Eejcutar». |
| 10 | La celda del *hash* solo contiene comentarios; no verifica nada. El *token* y el *hash* se pasan «copiando» sin indicar variables. | Sustituir por `echo "${RUNNER_SHA256}  <archivo>" \| sha256sum --check`. Añadir la baja del *runner* al final. |
| 11 | No hay enunciado. | Añadir una actividad: descargar `cobertura-pytest` y comprobar el porcentaje de cobertura. |
| 12 | No hay enunciado. | Añadir una actividad: crear `cloudrun` y `linux` con la política de ramas `main`. |
| 13 | «Como actividad, se puede buscar secretos…» termina en dos puntos, con la explicación en la celda siguiente. `gitleaks` no está en el *devcontainer*. | Unir el enunciado y las órdenes. Añadir `gitleaks` al `Dockerfile` del *devcontainer* o indicar cómo instalarlo. |
| 14 | El paso 4 («alterar una prueba») no dice cuál. | Indicar la prueba y el cambio, por ejemplo el de la solución. |
| 15 | Los pasos 2 y 3 no dicen cómo se «señala» la respuesta. | Pedir el número de línea de cada instrucción. |
| 16 | El paso 1 no da los valores de las siete variables, y el paso 3 no explica cómo verificar la imagen de la revisión. | Añadir una tabla de variables y el comando `gcloud run services describe`. |
| 17 | El paso 4 no dice qué datos crear para comprobar la persistencia. | Indicar `POST /tareas` y `GET /tareas`, como en la solución. |

**Cuadernos sin ejercicios.** Se proponen estos, no incluidos:

* 04 (*YAML*): serializar un diccionario propio con `yaml.dump()` y comprobar que `yaml.safe_load()` devuelve un objeto igual.
* 05 (elementos de un *workflow*): completar un *workflow* con `on`, `jobs`, `runs-on` y `steps` a partir de una descripción.
* 09 (*CI/CD*): clasificar tres estrategias de despliegue (reemplazo, azul-verde, canario).

---

Material de **Cloudevel**. [cloudevel.com](https://cloudevel.com)
