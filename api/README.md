# API de ejemplo · cd441 (Cloudevel)

API HTTP mínima en Flask que usan los cuadernos 14–17 del curso
*CI/CD con GitHub Actions*. Guarda «tareas» en memoria o, si se define
`DATABASE_URL`, en PostgreSQL.

| Método | Ruta | Respuesta |
|---|---|---|
| `GET` | `/health` | `{"status": "ok", "version": "<APP_VERSION>", "almacen": "memoria\|postgresql"}`; `503` si la base no responde |
| `GET` | `/tareas` | Lista de tareas |
| `POST` | `/tareas` | Crea `{"titulo": "…", "hecha": false}` → `201` |
| `GET` | `/tareas/<id>` | La tarea o `404` |
| `PATCH` | `/tareas/<id>` | Cambia `titulo` y/o `hecha` |
| `DELETE` | `/tareas/<id>` | `204` o `404` |

Puerto: **8080** (variable `PORT`). Variables documentadas en `.env.example`.

## Desarrollo (Codespaces o equipo propio), desde `api/`

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
cp .env.example .env
ruff check . && ruff format --check .
pytest                                   # en memoria; no necesita base de datos
flask --app wsgi:app run --debug --port 8080
```

Pruebas contra PostgreSQL (opcional): `TEST_DATABASE_URL=postgresql://… pytest`.

## Contenedor, desde la raíz del repositorio

```bash
docker build -t cd441-api .
docker run --rm -p 8080:8080 -e APP_VERSION=local cd441-api
curl -s http://127.0.0.1:8080/health
docker compose -f api/deploy/compose.yaml up -d --build --wait   # igual que en el servidor
```

## Despliegue

| Destino | Workflow | Preparación |
|---|---|---|
| Imagen en GHCR (por SHA) | `.github/workflows/ci.yml` (job `publicar-imagen`, solo en `main`) | Hacer público el paquete `api` |
| Cloud Run | `.github/workflows/deploy-cloud-run.yml` (OIDC, sin llaves) | `api/deploy/gcp/preparar_proyecto.sh`, `configurar_wif.sh`, `desplegar_manual.sh` |
| Ubuntu 24.04 por SSH | `.github/workflows/deploy-linux-ssh.yml` | `api/deploy/preparar_anfitrion.sh` (Docker, PostgreSQL, unidad `cd441-api.service`) |

Ninguna credencial vive en el repositorio: se usan variables y secretos de los
entornos `cloudrun` y `linux` de GitHub, y `/etc/cd441/api.env` en el servidor.
