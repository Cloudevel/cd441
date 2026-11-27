#!/usr/bin/env bash
# Prepara el proyecto de GCP de un estudiante para el cuaderno 16.
# Se ejecuta en Codespaces (con el SDK de Google Cloud) o en Cloud Shell, con una
# cuenta propietaria del proyecto:   bash api/deploy/gcp/preparar_proyecto.sh
# Idempotente.
#
#  - Habilita las API necesarias (Cloud Run, Artifact Registry, IAM, STS).
#  - Crea el repositorio Docker de Artifact Registry.
#  - Crea dos cuentas de servicio con PRIVILEGIO MÍNIMO:
#      cd441-runtime   identidad del contenedor: sin roles (la API no usa GCP)
#      cd441-deployer  identidad del workflow: publicar en ESE repositorio de
#                      imágenes, desplegar en Cloud Run y «actuar como» SOLO
#                      cd441-runtime. No puede cambiar políticas IAM.
#  - NO crea llaves JSON: el workflow usa OIDC (ver configurar_wif.sh).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=api/deploy/gcp/variables.sh
source "${DIR}/variables.sh"

echo "Proyecto: ${GCP_PROJECT_ID} · Región: ${GCP_REGION}"

gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  sts.googleapis.com \
  --project "${GCP_PROJECT_ID}"

if ! gcloud artifacts repositories describe "${AR_REPOSITORY}" \
  --location "${GCP_REGION}" --project "${GCP_PROJECT_ID}" >/dev/null 2>&1; then
  gcloud artifacts repositories create "${AR_REPOSITORY}" \
    --repository-format docker \
    --location "${GCP_REGION}" \
    --description "Imágenes del curso cd441 (Cloudevel)" \
    --project "${GCP_PROJECT_ID}"
fi

crear_sa() {
  local nombre="$1" descripcion="$2"
  if ! gcloud iam service-accounts describe "${nombre}@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
    --project "${GCP_PROJECT_ID}" >/dev/null 2>&1; then
    gcloud iam service-accounts create "${nombre}" \
      --display-name "${descripcion}" --project "${GCP_PROJECT_ID}"
  fi
}
crear_sa "${RUNTIME_SA_NAME}" "cd441: identidad del contenedor en Cloud Run"
crear_sa "${DEPLOY_SA_NAME}" "cd441: despliegue desde GitHub Actions"

# Desplegar revisiones de Cloud Run (sin permiso para cambiar políticas IAM).
gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
  --member "serviceAccount:${GCP_DEPLOY_SA}" \
  --role roles/run.developer \
  --condition None --quiet >/dev/null
# Publicar imágenes solo en este repositorio de Artifact Registry.
gcloud artifacts repositories add-iam-policy-binding "${AR_REPOSITORY}" \
  --location "${GCP_REGION}" --project "${GCP_PROJECT_ID}" \
  --member "serviceAccount:${GCP_DEPLOY_SA}" \
  --role roles/artifactregistry.writer --quiet >/dev/null
# «Actuar como» la cuenta del contenedor, y solo esa.
gcloud iam service-accounts add-iam-policy-binding "${GCP_RUNTIME_SA}" \
  --project "${GCP_PROJECT_ID}" \
  --member "serviceAccount:${GCP_DEPLOY_SA}" \
  --role roles/iam.serviceAccountUser --quiet >/dev/null

cat <<RESUMEN

Listo. Variables del entorno «cloudrun» en GitHub:
  GCP_PROJECT_ID    = ${GCP_PROJECT_ID}
  GCP_REGION        = ${GCP_REGION}
  AR_REPOSITORY     = ${AR_REPOSITORY}
  CLOUD_RUN_SERVICE = ${CLOUD_RUN_SERVICE}
  GCP_RUNTIME_SA    = ${GCP_RUNTIME_SA}
  GCP_DEPLOY_SA     = ${GCP_DEPLOY_SA}
  GCP_WIF_PROVIDER  = (lo imprime configurar_wif.sh)

Siguientes pasos:
  GITHUB_REPO=<propietario>/<repositorio> bash api/deploy/gcp/configurar_wif.sh
  bash api/deploy/gcp/desplegar_manual.sh
RESUMEN
