#!/usr/bin/env bash
# Primer despliegue, imperativo, en Cloud Run (cuaderno 16). Lo ejecuta el
# estudiante con SU cuenta (propietaria del proyecto), en Codespaces o Cloud Shell.
#
# Construye la imagen del commit actual, la publica en Artifact Registry y la
# despliega con acceso público (--allow-unauthenticated). Ese permiso de
# cambiar la política IAM del servicio lo tiene la persona, no el workflow:
# por eso el primer despliegue es manual. Los siguientes los hace el workflow.
#
# Uso: bash api/deploy/gcp/desplegar_manual.sh
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAIZ="$(cd "${DIR}/../../.." && pwd)"
# shellcheck source=api/deploy/gcp/variables.sh
source "${DIR}/variables.sh"

SHA="$(git -C "${RAIZ}" rev-parse HEAD)"
IMAGEN="${IMAGEN_BASE}:${SHA}"

gcloud auth configure-docker "${AR_HOST}" --quiet
docker build -t "${IMAGEN}" "${RAIZ}"
docker push "${IMAGEN}"

# Si la organización aplica la política «Domain restricted sharing»,
# --allow-unauthenticated fallará: usa un proyecto personal fuera de ella.
gcloud run deploy "${CLOUD_RUN_SERVICE}" \
  --project "${GCP_PROJECT_ID}" \
  --region "${GCP_REGION}" \
  --image "${IMAGEN}" \
  --service-account "${GCP_RUNTIME_SA}" \
  --set-env-vars "APP_VERSION=${SHA}" \
  --port 8080 \
  --max-instances 1 \
  --allow-unauthenticated

bash "${DIR}/comprobar.sh"
