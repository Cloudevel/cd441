# Nota para la persona instructora · cd441, tramo práctico (cuadernos 14–17)

Requisitos que deben estar listos **antes** de la clase y nombres exactos de
variables y secretos que usan los workflows de `main`. Ningún valor real va en
el repositorio: todo se carga en *Settings → Environments* de GitHub. El
estado técnico interno, las pruebas pendientes y cómo retomar están en
`docs/ESTADO_Y_PRUEBAS.md`.

## 1. Repositorio en GitHub

- Cada estudiante trabaja en su propio repositorio (copia o *fork* de este).
- *Settings → Actions → General → Workflow permissions*: «Read repository
  contents» (los workflows piden más permisos por su cuenta, solo donde hace falta).
- Entornos a crear en *Settings → Environments*: `cloudrun` y `linux`.
  Se recomienda limitar `cloudrun` y `linux` a la rama `main` y, si se quiere mostrar
  aprobaciones, añadir *required reviewers*.
- Paquete en GHCR: el job `publicar-imagen` de `ci.yml` publica
  `ghcr.io/<propietario>/<repositorio>/api:<sha>` solo en *push* a `main`.
  Tras la primera ejecución, cambiar la visibilidad del paquete `api` a
  **pública** (*Packages → api → Package settings*) para que el anfitrión
  Linux pueda hacer `docker pull` sin credenciales. Si debe ser privado, en el
  anfitrión se hace una sola vez `docker login ghcr.io` con un token de solo
  lectura (`read:packages`) que vive únicamente en el anfitrión, nunca en el
  repositorio.

## 2. Proyecto de GCP (cuaderno 16)

- Un proyecto con **facturación habilitada** (por estudiante o compartido;
  ver decisiones abiertas). Cloud Run y Artifact Registry tienen nivel
  gratuito, pero los precios y límites cambian: consúltalos en la
  documentación oficial para la región elegida. Los guiones no asumen una
  región: hay que exportar `GCP_REGION` (la de la tabla es solo un ejemplo).
- Desde Cloud Shell o un Codespace, con rol de propietario del proyecto:

  ```bash
  export GCP_PROJECT_ID=<id-del-proyecto> GCP_REGION=<región>
  bash api/deploy/gcp/preparar_proyecto.sh                      # API, Artifact Registry, cuentas de servicio
  GITHUB_REPO=<propietario>/<repo> bash api/deploy/gcp/configurar_wif.sh   # OIDC/WIF, sin llaves
  bash api/deploy/gcp/desplegar_manual.sh                       # primer despliegue, servicio público
  ```

- **No se crean llaves JSON** de cuentas de servicio. El workflow obtiene un
  token de corta duración por OIDC (Workload Identity Federation). En cd441 solo
  se menciona el mecanismo; su práctica completa es de cursos posteriores.
- El primer despliegue manual deja el servicio con invocación pública
  (`--allow-unauthenticated`). El workflow no tiene permiso para cambiar la
  política IAM del servicio (privilegio mínimo). Si la organización aplica la
  política «Domain restricted sharing», el acceso público fallará: usar un
  proyecto fuera de esa organización.
- Al terminar el curso: `bash api/deploy/gcp/limpiar.sh`.

Cuentas de servicio que crean los guiones:

| Cuenta | Uso | Roles |
|---|---|---|
| `cd441-runtime@<proyecto>.iam.gserviceaccount.com` | Identidad del contenedor | Ninguno (la API no usa servicios de GCP) |
| `cd441-deployer@<proyecto>.iam.gserviceaccount.com` | Identidad del workflow | `roles/run.developer` (proyecto), `roles/artifactregistry.writer` (solo el repositorio `cd441`), `roles/iam.serviceAccountUser` (solo sobre `cd441-runtime`), `roles/iam.workloadIdentityUser` (solo para el repositorio de GitHub indicado) |

**Variables del entorno `cloudrun`** (no hay secretos):

| Variable | Ejemplo |
|---|---|
| `GCP_PROJECT_ID` | `mi-proyecto-cd441` |
| `GCP_REGION` | `us-central1` |
| `AR_REPOSITORY` | `cd441` |
| `CLOUD_RUN_SERVICE` | `cd441-api` |
| `GCP_RUNTIME_SA` | `cd441-runtime@mi-proyecto-cd441.iam.gserviceaccount.com` |
| `GCP_DEPLOY_SA` | `cd441-deployer@mi-proyecto-cd441.iam.gserviceaccount.com` |
| `GCP_WIF_PROVIDER` | `projects/123456789/locations/global/workloadIdentityPools/github/providers/cd441-actions` |

Cloud SQL, Secret Manager y Compute Engine solo se mencionan en el mapa de
servicios; no tienen laboratorio en cd441.

## 3. Anfitrión Linux (cuaderno 17)

- Una máquina Ubuntu 24.04 completa (con systemd; no sirve un Codespace)
  accesible por SSH desde Internet (los *runners* hospedados de GitHub salen
  por IP variables). El guion de preparación instala Docker Engine, el
  plugin Compose y PostgreSQL.
- La API queda en `127.0.0.1:8080` en el anfitrión; la comprobación del
  workflow se hace desde el propio anfitrión.
- Preparación (una vez):

  ```bash
  # En tu equipo: clave SOLO para despliegue, sin passphrase
  ssh-keygen -t ed25519 -N '' -C despliegue-cd441 -f despliegue_ed25519
  # En el anfitrión, como root (usuario «deploy» y directorio «/opt/cd441» por omisión):
  sudo bash api/deploy/preparar_anfitrion.sh despliegue_ed25519.pub
  # En tu equipo: known_hosts y verificación de la huella
  ssh-keyscan -t ed25519 -p <puerto> <host> > known_hosts_cd441
  ssh-keygen -lf known_hosts_cd441   # debe coincidir con la que imprimió el guion
  ```

- Ojo: el usuario `deploy` pertenece al grupo `docker` (equivale a root en el
  anfitrión). Aceptable en una máquina de práctica; no en producción.
- El guion crea en el anfitrión el rol y la base PostgreSQL `cd441`, y escribe
  `DATABASE_URL` y `SECRET_KEY` solo en `/etc/cd441/api.env` (legible por root
  y por el usuario de despliegue). Esos secretos no pasan por GitHub.

**Secretos del entorno `linux`:**

| Secreto | Contenido |
|---|---|
| `SSH_HOST` | Anfitrión (`203.0.113.10` o `aula.example.org`) |
| `SSH_USER` | Usuario de despliegue (`deploy`) |
| `SSH_PORT` | Puerto SSH (opcional; 22 si no está) |
| `SSH_PRIVATE_KEY` | Contenido de `despliegue_ed25519` (clave privada) |
| `SSH_KNOWN_HOSTS` | Contenido de `known_hosts_cd441`, ya verificado |

**Variables del entorno `linux`:**

| Variable | Ejemplo | Obligatoria |
|---|---|---|
| `SSH_DEPLOY_DIR` | `/opt/cd441` | Sí |
| `DEPLOY_RUNNER` | `self-hosted` (por omisión) o `ubuntu-latest` | No |

Si el entorno `linux` no tiene los secretos ni `SSH_DEPLOY_DIR`, el workflow
omite el despliegue en lugar de fallar.

## 4. Orden sugerido de ejecución en clase

1. `ci.yml` (automático en *push*/PR; en *push* a `main` también publica la imagen en GHCR); hacer público el paquete.
2. `deploy-cloud-run.yml` (manual, *Run workflow*).
3. `deploy-linux-ssh.yml` (manual; usa la imagen de GHCR del mismo SHA).

## 5. Mantenimiento

Las *actions* están fijadas por SHA completo con la versión en un comentario, y
la imagen base de Python por *digest*. Dependabot (`.github/dependabot.yml`)
abre PR mensuales para actualizarlas. Revisa versiones antes de cada edición
del curso. La lista de comprobación al retomar está en
`docs/ESTADO_Y_PRUEBAS.md`.

## 6. Decisiones abiertas (valores tomados provisionalmente)

- Proyecto de GCP por estudiante o uno compartido de la persona instructora
  (con WIF por repositorio, cada repositorio de estudiante necesita su propia
  ejecución de `api/deploy/gcp/configurar_wif.sh`).
- Anfitrión Linux por estudiante o uno compartido (con uno compartido, cada
  estudiante necesita su propio directorio o usuario; el material recomienda
  una VM propia por estudiante).
- Cómo se cubre PostgreSQL en el cuaderno 17: la infraestructura del destino
  Linux ya lo incluye, pero el alcance en el cuaderno hay que revisarlo al
  retomar (véase `docs/ESTADO_Y_PRUEBAS.md`).
