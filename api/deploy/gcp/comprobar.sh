#!/usr/bin/env bash
# Estado del servicio de Cloud Run y comprobación de GET /health.
# Uso: bash api/deploy/gcp/comprobar.sh
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=api/deploy/gcp/variables.sh
source "${DIR}/variables.sh"

URL="$(gcloud run services describe "${CLOUD_RUN_SERVICE}" \
  --project "${GCP_PROJECT_ID}" --region "${GCP_REGION}" --format 'value(status.url)')"
echo "Servicio: ${CLOUD_RUN_SERVICE} · URL: ${URL}"

echo "Revisiones recientes:"
gcloud run revisions list --service "${CLOUD_RUN_SERVICE}" \
  --project "${GCP_PROJECT_ID}" --region "${GCP_REGION}" --limit 5

echo "Imágenes en Artifact Registry:"
gcloud artifacts docker images list "${IMAGEN_BASE}" --include-tags --limit 5

curl -fsS --retry 5 --retry-all-errors --retry-delay 3 "${URL}/health"
echo
