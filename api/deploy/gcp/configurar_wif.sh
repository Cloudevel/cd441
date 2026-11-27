#!/usr/bin/env bash
# Configura Workload Identity Federation (OIDC) para que el workflow
# deploy-cloud-run.yml del repositorio del estudiante actúe como cd441-deployer
# SIN llaves JSON. Idempotente.
#
# Uso: GITHUB_REPO=<propietario>/<repositorio> bash api/deploy/gcp/configurar_wif.sh
#
# Cómo funciona (cuaderno 13 y 16):
#   1. GitHub firma un token OIDC para cada job que lo pide (id-token: write).
#      El token dice, entre otras cosas, de qué repositorio y entorno viene.
#   2. El «proveedor» de este pool confía en el emisor de GitHub, pero con una
#      CONDICIÓN DE ATRIBUTOS: solo acepta tokens de ESTE repositorio y del
#      entorno protegido «cloudrun». Un fork u otro repositorio no pasa.
#   3. Solo esa identidad puede «actuar como» cd441-deployer
#      (roles/iam.workloadIdentityUser), y recibe un token de GCP de corta duración.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=api/deploy/gcp/variables.sh
source "${DIR}/variables.sh"

GITHUB_REPO="${GITHUB_REPO:?Define GITHUB_REPO=<propietario>/<repositorio>}"
[[ "${GITHUB_REPO}" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || { echo "GITHUB_REPO no válido" >&2; exit 1; }
ENTORNO="${GITHUB_ENVIRONMENT:-cloudrun}"
POOL="${WIF_POOL:-github}"
PROVEEDOR="${WIF_PROVIDER_ID:-cd441-actions}"
NUMERO="$(gcloud projects describe "${GCP_PROJECT_ID}" --format 'value(projectNumber)')"

if ! gcloud iam workload-identity-pools describe "${POOL}" \
  --location global --project "${GCP_PROJECT_ID}" >/dev/null 2>&1; then
  gcloud iam workload-identity-pools create "${POOL}" \
    --location global --project "${GCP_PROJECT_ID}" \
    --display-name "GitHub Actions"
fi

if ! gcloud iam workload-identity-pools providers describe "${PROVEEDOR}" \
  --workload-identity-pool "${POOL}" --location global --project "${GCP_PROJECT_ID}" >/dev/null 2>&1; then
  gcloud iam workload-identity-pools providers create-oidc "${PROVEEDOR}" \
    --workload-identity-pool "${POOL}" --location global --project "${GCP_PROJECT_ID}" \
    --display-name "cd441 GitHub Actions" \
    --issuer-uri "https://token.actions.githubusercontent.com" \
    --attribute-mapping "google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.environment=assertion.environment" \
    --attribute-condition "assertion.repository == '${GITHUB_REPO}' && assertion.environment == '${ENTORNO}'"
fi

gcloud iam service-accounts add-iam-policy-binding "${GCP_DEPLOY_SA}" \
  --project "${GCP_PROJECT_ID}" \
  --role roles/iam.workloadIdentityUser \
  --member "principalSet://iam.googleapis.com/projects/${NUMERO}/locations/global/workloadIdentityPools/${POOL}/attribute.repository/${GITHUB_REPO}" \
  --quiet >/dev/null

echo
echo "Variable GCP_WIF_PROVIDER del entorno «${ENTORNO}»:"
echo "  projects/${NUMERO}/locations/global/workloadIdentityPools/${POOL}/providers/${PROVEEDOR}"
