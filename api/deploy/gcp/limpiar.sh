#!/usr/bin/env bash
# Al terminar el curso: borra el servicio de Cloud Run, el repositorio de
# Artifact Registry, el proveedor/pool de WIF y las cuentas de servicio de cd441,
# para no dejar costos ni accesos abiertos. Pide confirmación.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=api/deploy/gcp/variables.sh
source "${DIR}/variables.sh"
POOL="${WIF_POOL:-github}"

read -r -p "¿Borrar los recursos de cd441 en ${GCP_PROJECT_ID}? (escribe 'si') " respuesta
[[ "${respuesta}" == "si" ]] || { echo "Cancelado."; exit 0; }

gcloud run services delete "${CLOUD_RUN_SERVICE}" --project "${GCP_PROJECT_ID}" --region "${GCP_REGION}" --quiet || true
gcloud artifacts repositories delete "${AR_REPOSITORY}" --project "${GCP_PROJECT_ID}" --location "${GCP_REGION}" --quiet || true
gcloud iam workload-identity-pools delete "${POOL}" --project "${GCP_PROJECT_ID}" --location global --quiet || true
gcloud iam service-accounts delete "${GCP_DEPLOY_SA}" --project "${GCP_PROJECT_ID}" --quiet || true
gcloud iam service-accounts delete "${GCP_RUNTIME_SA}" --project "${GCP_PROJECT_ID}" --quiet || true
echo "Limpieza terminada. Borra también las variables del entorno «cloudrun» en GitHub."
