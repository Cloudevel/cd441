# Prerrequisitos de las pruebas en vivo de cd441

Este documento es la **lista exacta de lo que hay que dar o crear** antes de probar en vivo WIF (Workload Identity Federation), Cloud Run, el *runner* autoalojado y el despliegue por SSH. Complementa `docs/ESTADO_Y_PRUEBAS.md` (estado, costos y riesgos) y se comprueba con `scripts/verificar_prerrequisitos.sh`.

Reglas: **solo nombres, nunca valores**; no se improvisan accesos ni se crean cuentas por nuestra cuenta; cada recurso lo crea quien es su propietario. Las pruebas en vivo siguen **sin ejecutarse**.

## 1. Lista de lo que hay que dar o crear

### 1.1 Google Cloud

| # | Qué | Nombre o valor esperado | Quién lo hace |
|---|---|---|---|
| G1 | **ID del proyecto de GCP**, nuevo y dedicado, con **facturación vinculada** | `<GCP_PROJECT_ID>` (6–30 caracteres: minúsculas, dígitos y guiones). Mejor un proyecto personal, **fuera de una organización** con la política «Domain restricted sharing» | José Luis |
| G2 | **Región** | `<GCP_REGION>` (la elige él; ningún guion asume una) | José Luis |
| G3 | **Persona que ejecuta los guiones**, con rol `Owner` en el proyecto (o, como mínimo: `serviceusage.serviceUsageAdmin`, `artifactregistry.admin`, `iam.serviceAccountAdmin`, `iam.workloadIdentityPoolAdmin`, `resourcemanager.projectIamAdmin`, `run.admin`) | Cuenta de José Luis, con `gcloud auth login` en un Codespace o en Cloud Shell | José Luis |
| G4 | **APIs a habilitar** | `run.googleapis.com`, `artifactregistry.googleapis.com`, `iam.googleapis.com`, `iamcredentials.googleapis.com`, `sts.googleapis.com` (las habilita `preparar_proyecto.sh`). Probable además: `cloudresourcemanager.googleapis.com`, que el guion no habilita y que los comandos `gcloud projects …` pueden exigir | `preparar_proyecto.sh` |
| G5 | **Repositorio de Artifact Registry** (Docker) | `cd441` (variable `AR_REPOSITORY`) | `preparar_proyecto.sh` |
| G6 | **Cuenta de servicio de ejecución** | `cd441-runtime@<GCP_PROJECT_ID>.iam.gserviceaccount.com`, **sin roles** | `preparar_proyecto.sh` |
| G7 | **Cuenta de servicio de despliegue** y sus **roles mínimos** | `cd441-deployer@<GCP_PROJECT_ID>.iam.gserviceaccount.com` con: `roles/run.developer` (proyecto); `roles/artifactregistry.writer` (solo el repositorio `cd441`); `roles/iam.serviceAccountUser` (solo sobre `cd441-runtime`); `roles/iam.workloadIdentityUser` (solo para el repositorio de GitHub, G8). **Sin llaves JSON** | `preparar_proyecto.sh` y `configurar_wif.sh` |
| G8 | **Pool de WIF** | `github` (ubicación `global`) | `configurar_wif.sh` |
| G9 | **Proveedor OIDC de WIF** | `cd441-actions`; emisor `https://token.actions.githubusercontent.com`; asignación `google.subject`, `attribute.repository`, `attribute.environment`; **condición de atributos**: `assertion.repository == '<propietario>/<repositorio>' && assertion.environment == 'cloudrun'` | `configurar_wif.sh` (con `GITHUB_REPO=<propietario>/<repositorio>`) |
| G10 | **Servicio de Cloud Run** | `cd441-api` (variable `CLOUD_RUN_SERVICE`); primer despliegue manual y público | `desplegar_manual.sh` |

### 1.2 GitHub

| # | Qué | Nombres exactos | Tipo |
|---|---|---|---|
| H1 | **Repositorio público** de la prueba de Cloud Run | `<propietario>/cd441` (o la copia del estudiante) | — |
| H2 | **Entorno `cloudrun`** en ese repositorio, con **revisores obligatorios** (disponibles en repositorios públicos con cualquier plan) y despliegue limitado a `main` y a las etiquetas `v*` | `cloudrun` | — |
| H3 | **Variables del entorno `cloudrun`** (el entorno **no tiene secretos**) | `GCP_PROJECT_ID`, `GCP_REGION`, `AR_REPOSITORY`, `CLOUD_RUN_SERVICE`, `GCP_WIF_PROVIDER`, `GCP_DEPLOY_SA`, `GCP_RUNTIME_SA` | Variables |
| H4 | **Repositorio privado para el *runner*** (copia importada o desde plantilla; un *fork* de un repositorio público no puede ser privado). Debe contener los workflows, porque `deploy-linux-ssh.yml` rechaza un *runner* propio en un repositorio público | `<propietario>/<repositorio-privado>` | — |
| H5 | **Entorno `linux`** en ese repositorio. Los revisores obligatorios en repositorios privados exigen **GitHub Pro o Team** | `linux` | — |
| H6 | **Secretos del entorno `linux`** | `SSH_HOST`, `SSH_USER`, `SSH_PORT`, `SSH_PRIVATE_KEY`, `SSH_KNOWN_HOSTS` | Secretos |
| H7 | **Variables del entorno `linux`** | `SSH_DEPLOY_DIR` (p. ej. `/opt/cd441`); opcional `DEPLOY_RUNNER` (`self-hosted` por omisión) | Variables |
| H8 | **Paquete de GHCR público** de cada repositorio que despliegue (`ghcr.io/<propietario>/<repositorio>/api`). Se publica con el CI en `main` y hay que cambiarlo a *Public* en *Package settings*. Si debe ser privado, el anfitrión necesita un `docker login ghcr.io` único con un token de solo lectura (`read:packages`) que vive solo en él | `api` | — |
| H9 | **Permiso `workflow` para hacer push.** Lo necesita cualquier push que cambie `.github/workflows/` (la rama de la CI de cuadernos modifica `notebooks.yml`). Con un token clásico, el alcance `workflow`; con uno de grano fino, el permiso *Workflows: Read and write* | — | Credencial de quien hace el push |

### 1.3 Máquina Ubuntu 24.04 y SSH

| # | Qué | Nombres exactos |
|---|---|---|
| V1 | **VM Ubuntu 24.04 completa, con systemd como PID 1** (local o en la nube; no sirve un contenedor ni Codespaces), desechable, con salida a Internet para `apt` y GHCR | `<SSH_HOST>` |
| V2 | **Usuario de despliegue**, que crea `preparar_anfitrion.sh` (sin `sudo`, con acceso al grupo `docker`, que equivale a root) | `deploy` (`<SSH_USER>`) |
| V3 | **Usuario del *runner***, distinto del de despliegue y **sin `sudo`** | `runner` |
| V4 | **Puerto SSH** | `22` (`<SSH_PORT>`) |
| V5 | **Directorio de despliegue** | `/opt/cd441` (`SSH_DEPLOY_DIR`) |
| V6 | **Clave SSH Ed25519 exclusiva de la prueba, sin contraseña**, que genera José Luis en su equipo (como el cuaderno 17: `ssh-keygen -t ed25519 -N ""`). La **pública** se pasa a `preparar_anfitrion.sh`; la **privada** solo va al secreto `SSH_PRIVATE_KEY` | `~/cd441-destino/ssh/deploy` y `.pub` |
| V7 | **`known_hosts` verificado**: `ssh-keyscan -t ed25519 -p <puerto> <host>` y comparar con `ssh-keygen -lf -` contra la huella que imprime `preparar_anfitrion.sh` en el servidor. Nunca `ssh-keyscan` dentro del pipeline | secreto `SSH_KNOWN_HOSTS` |
| V8 | ***Runner* autoalojado** `--ephemeral`, con etiquetas `self-hosted,linux`, registrado con un token de registro de corta vida que no se guarda | en el repositorio de H4 |

## 2. Orden de ejecución

1. **Dar** G1–G3 y H1–H5, V1 y V6 (lo que solo puede hacer José Luis).
2. **Verificar de solo lectura** lo que ya exista: `bash scripts/verificar_prerrequisitos.sh gcp|github|ghcr|vm` (§3). Repetirlo tras cada paso.
3. **Codespace:** pruebas de `docs/ESTADO_Y_PRUEBAS.md` §4.1 (incluidas las 3 pruebas de PostgreSQL).
4. **Push** de la rama con el permiso `workflow` (H9) y comprobar la CI de `main` en verde (job `verificar`, `publicar-imagen` y el workflow «Cuadernos»).
5. **GHCR:** cambiar el paquete a público (H8) y verificar con `scripts/verificar_prerrequisitos.sh ghcr`.
6. **GCP** (lo ejecuta José Luis): `preparar_proyecto.sh` → `configurar_wif.sh` → cargar las 7 variables de H3 → `desplegar_manual.sh` → verificación `gcp` y `github`.
7. **Despliegue desde el workflow:** `deploy-cloud-run.yml` con `workflow_dispatch`, aprobación del entorno. Pruebas negativas de WIF (otra rama, entorno o repositorio no obtiene el token). Acceso con token de identidad (§4).
8. **Anfitrión Linux:** `preparar_anfitrion.sh <clave.pub>` (dos veces) → secretos H6 y variables H7 → verificación `vm` y `github`.
9. ***Runner*** `--ephemeral` en el repositorio privado y `deploy-linux-ssh.yml`.
10. **Ejercicios de systemd de cd101** en la misma VM (`docs/ESTADO_Y_PRUEBAS.md` §9).
11. **Desmontaje:** `limpiar.sh` o borrar el proyecto, destruir la VM, retirar secretos, clave y Codespaces.

## 3. Script de verificación (solo lectura)

`scripts/verificar_prerrequisitos.sh [gcp|github|ghcr|vm|todo]` consulta, sin crear ni modificar nada:

| Sección | Comprueba |
|---|---|
| `gcp` | Cuenta de `gcloud` activa; proyecto accesible; facturación; las 5 APIs (y aviso por `cloudresourcemanager`); repositorio Docker de Artifact Registry; las dos cuentas de servicio; **roles mínimos exactos** (y aviso si el `deployer` tiene alguno de más); `runtime` sin roles; **sin llaves JSON**; pool y proveedor de WIF activos, emisor de GitHub y **condición de atributos** con el repositorio y el entorno `cloudrun`; `workloadIdentityUser` solo para el repositorio; aviso si «Domain restricted sharing» está activa |
| `github` | Sesión de `gh` y alcance `workflow` (si se puede ver); permiso de escritura; entornos `cloudrun` y `linux`; **nombres** de variables y secretos (nunca valores); revisores obligatorios; repositorio del *runner* privado; *runners* registrados |
| `ghcr` | Descarga anónima del paquete `api` (sin credenciales) y, si se define `IMAGE_TAG`, que exista esa etiqueta |
| `vm` | Entra por SSH con la clave y el `known_hosts` fijado (huella desconocida = rechazo) y solo **lee**: Ubuntu 24.04, systemd como PID 1, Docker y Compose, servicios `docker` y `postgresql`, `cd441-api.service`, directorio de despliegue, `/etc/cd441/api.env` con modo 640 `root`, grupo `docker`, ausencia de `sudo` sin contraseña |

Variables de entrada (identificadores, no secretos): `GCP_PROJECT_ID`, `GCP_REGION`, `GITHUB_REPO`, `RUNNER_REPO`, `IMAGE_TAG`, `SSH_HOST`, `SSH_USER`, `SSH_PORT`, `SSH_KEY_FILE` y `SSH_KNOWN_HOSTS_FILE` (rutas). Salida: `[OK]`, `[FALLA]`, `[AVISO]` u `[OMITIDO]` por comprobación y un resumen; código de salida 1 si hay alguna falla.

Estado de la validación del propio script: pasa `shellcheck` y su lógica se probó con sustitutos (*stubs*) de `gcloud`, `gh`, `curl` y `ssh` (camino feliz y fallos inducidos). **Nunca se ha ejecutado contra servicios reales**: las banderas de `gcloud` se comprobaron con `--help` en el *devcontainer*, pero los filtros de IAM y de la API de entornos de GitHub deben confirmarse en la primera ejecución real.

## 4. Decisión pendiente: `/health` cuando Cloud Run es privado

El último paso de `deploy-cloud-run.yml` hace `curl` **sin token** a `/health`. Con el servicio público funciona; con el servicio privado (o con «Domain restricted sharing», que impide dejarlo público) devuelve 403 y el job falla aunque el despliegue haya salido bien.

**Opción A: obtener un token de identidad en el workflow.**
- Un segundo paso con `google-github-actions/auth` (`token_format: id_token`, `id_token_audience: <URL del servicio>`, `service_account: <GCP_DEPLOY_SA>`), después de `gcloud run deploy`, y `curl -H "Authorization: Bearer …"`. Los tokens de identidad duran como máximo 10 minutos.
- Una concesión **única**, hecha por una persona propietaria (el workflow no puede cambiar IAM): `roles/run.invoker` para `cd441-deployer` **solo sobre ese servicio**.
- El servicio puede quedar privado. Coste: un paso más y un rol más que explicar en el cuaderno 16, y modificar un workflow con acciones fijadas por SHA. Pendiente de confirmar en vivo si `roles/iam.workloadIdentityUser` basta para generar el token o si hace falta `roles/iam.serviceAccountOpenIdTokenCreator`.

**Opción B: documentarlo como limitación.**
- No se cambia ningún workflow. Con el servicio privado, el paso de `/health` se omite o se marca `continue-on-error`, y la comprobación se hace a mano con `curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" <URL>/health`.
- Es lo más simple y coincide con el cuaderno 16 (servicio público), pero un despliegue correcto se vería rojo o sin verificar, y no sirve de ejemplo para entornos con «Domain restricted sharing».

**Recomendación: A, en dos tiempos.** Documentar B ahora (cambio de texto, sin tocar workflows y sin riesgo) y **implementar A en la primera prueba en vivo**, cuando WIF ya se haya demostrado con el paso de despliegue: así se confirma el rol necesario sobre un servicio real y el pipeline termina verificando la versión desplegada con el servicio privado, que es la configuración segura por defecto y la única que funciona en organizaciones con «Domain restricted sharing». La decisión final es de José Luis.
