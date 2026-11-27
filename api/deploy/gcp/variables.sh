#!/usr/bin/env bash
# Variables comunes de los guiones de GCP del cuaderno 16. Se cargan con `source`.
# Cada estudiante usa SU PROPIO proyecto de GCP. Exporta los valores antes de
# ejecutar un guion (mismos nombres que las variables del entorno `cloudrun`):
#   export GCP_PROJECT_ID=<proyecto> GCP_REGION=<región>
# No se asume ninguna región: elige la más cercana y revisa precios en la
# documentación oficial de Cloud Run.
# shellcheck disable=SC2034  # las variables se usan en los guiones que hacen source

GCP_PROJECT_ID="${GCP_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"
GCP_REGION="${GCP_REGION:?Define GCP_REGION (p. ej. export GCP_REGION=<región>)}"
AR_REPOSITORY="${AR_REPOSITORY:-cd441}"
CLOUD_RUN_SERVICE="${CLOUD_RUN_SERVICE:-cd441-api}"
RUNTIME_SA_NAME="${RUNTIME_SA_NAME:-cd441-runtime}"
DEPLOY_SA_NAME="${DEPLOY_SA_NAME:-cd441-deployer}"

if [[ -z "${GCP_PROJECT_ID}" ]]; then
  echo "ERROR: define GCP_PROJECT_ID o ejecuta 'gcloud config set project <id>'." >&2
  exit 1
fi

GCP_RUNTIME_SA="${RUNTIME_SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"
GCP_DEPLOY_SA="${DEPLOY_SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"
AR_HOST="${GCP_REGION}-docker.pkg.dev"
IMAGEN_BASE="${AR_HOST}/${GCP_PROJECT_ID}/${AR_REPOSITORY}/${CLOUD_RUN_SERVICE}"
