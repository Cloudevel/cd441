#!/usr/bin/env bash
# Verificación de SOLO LECTURA de los prerrequisitos de las pruebas en vivo de cd441
# (docs/PRERREQUISITOS_PRUEBAS_EN_VIVO.md). No crea, modifica ni borra nada: solo
# consulta (gcloud ... describe/list/get-iam-policy, gh api GET, curl GET y, en la
# sección «vm», comandos de lectura por SSH). No imprime valores de secretos: de los
# secretos y variables de GitHub solo lee los NOMBRES.
#
# Uso:
#   bash scripts/verificar_prerrequisitos.sh [gcp|github|ghcr|vm|todo]   (por omisión: todo)
#
# Variables de entrada (todas son identificadores, ninguna es un secreto):
#   gcp     GCP_PROJECT_ID, GCP_REGION, GITHUB_REPO=<propietario>/<repositorio>
#           opcionales: AR_REPOSITORY (cd441), CLOUD_RUN_SERVICE (cd441-api),
#                       RUNTIME_SA_NAME (cd441-runtime), DEPLOY_SA_NAME (cd441-deployer),
#                       WIF_POOL (github), WIF_PROVIDER_ID (cd441-actions)
#   github  GITHUB_REPO; RUNNER_REPO=<propietario>/<repositorio privado> (opcional)
#   ghcr    GITHUB_REPO; opcional IMAGE_TAG (etiqueta que debe existir, p. ej. un SHA)
#   vm      SSH_HOST, SSH_USER, SSH_PORT, SSH_KEY_FILE (ruta de la clave privada),
#           SSH_KNOWN_HOSTS_FILE (ruta del known_hosts verificado);
#           opcional SSH_DEPLOY_DIR (/opt/cd441)
#
# Salida: una línea [OK], [FALLA], [AVISO] o [OMITIDO] por comprobación y un resumen.
# Código de salida: 0 si no hay [FALLA]; 1 si hay alguna.
set -uo pipefail

SECCION="${1:-todo}"
case "${SECCION}" in gcp | github | ghcr | vm | todo) ;; *)
  echo "Uso: $0 [gcp|github|ghcr|vm|todo]" >&2
  exit 2
  ;; esac

N_OK=0 N_FALLA=0 N_AVISO=0 N_OMITIDO=0
ok() { N_OK=$((N_OK + 1)); echo "[OK] $*"; }
falla() { N_FALLA=$((N_FALLA + 1)); echo "[FALLA] $*"; }
aviso() { N_AVISO=$((N_AVISO + 1)); echo "[AVISO] $*"; }
omitido() { N_OMITIDO=$((N_OMITIDO + 1)); echo "[OMITIDO] $*"; }
tiene() { command -v "$1" >/dev/null 2>&1; }
# contiene "texto multilínea" "palabra exacta"
contiene() { grep -qxF -- "$2" <<<"$1"; }
# igual "obtenido" "esperado" "mensaje si coincide" "mensaje si no"
igual() { if [[ "$1" == "$2" ]]; then ok "$3"; else falla "$4"; fi; }

AR_REPOSITORY="${AR_REPOSITORY:-cd441}"
CLOUD_RUN_SERVICE="${CLOUD_RUN_SERVICE:-cd441-api}"
RUNTIME_SA_NAME="${RUNTIME_SA_NAME:-cd441-runtime}"
DEPLOY_SA_NAME="${DEPLOY_SA_NAME:-cd441-deployer}"
WIF_POOL="${WIF_POOL:-github}"
WIF_PROVIDER_ID="${WIF_PROVIDER_ID:-cd441-actions}"
GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"
GCP_REGION="${GCP_REGION:-}"
GITHUB_REPO="${GITHUB_REPO:-}"
RUNNER_REPO="${RUNNER_REPO:-}"

# Nombres exactos que usan los workflows (solo nombres).
VARS_CLOUDRUN=(GCP_PROJECT_ID GCP_REGION AR_REPOSITORY CLOUD_RUN_SERVICE GCP_WIF_PROVIDER GCP_DEPLOY_SA GCP_RUNTIME_SA)
SECRETOS_LINUX=(SSH_HOST SSH_USER SSH_PORT SSH_PRIVATE_KEY SSH_KNOWN_HOSTS)
VARS_LINUX=(SSH_DEPLOY_DIR)
APIS_GCP=(run.googleapis.com artifactregistry.googleapis.com iam.googleapis.com iamcredentials.googleapis.com sts.googleapis.com)
# No las habilita preparar_proyecto.sh, pero los comandos «gcloud projects ...» pueden pedirla.
APIS_PROBABLES=(cloudresourcemanager.googleapis.com)

validar_repo() { [[ "$1" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; }

# ---------------------------------------------------------------- GCP
verificar_gcp() {
  echo "== GCP =="
  if ! tiene gcloud; then
    falla "gcloud no está instalado"
    return
  fi
  if [[ -z "${GCP_PROJECT_ID}" || -z "${GCP_REGION}" ]] || ! validar_repo "${GITHUB_REPO}"; then
    falla "define GCP_PROJECT_ID, GCP_REGION y GITHUB_REPO=<propietario>/<repositorio>"
    return
  fi
  local P="${GCP_PROJECT_ID}" R="${GCP_REGION}"
  local DEPLOY_SA="${DEPLOY_SA_NAME}@${P}.iam.gserviceaccount.com"
  local RUNTIME_SA="${RUNTIME_SA_NAME}@${P}.iam.gserviceaccount.com"
  local salida api rol

  salida="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null)"
  if [[ -n "${salida}" ]]; then ok "hay una cuenta de gcloud activa"; else
    falla "gcloud no tiene una cuenta activa (gcloud auth login)"
    return
  fi

  local numero
  numero="$(gcloud projects describe "${P}" --format='value(projectNumber)' 2>/dev/null)"
  if [[ -n "${numero}" ]]; then ok "el proyecto ${P} existe y es accesible"; else
    falla "no se puede leer el proyecto ${P}"
    return
  fi

  salida="$(gcloud billing projects describe "${P}" --format='value(billingEnabled)' 2>/dev/null)"
  if [[ "${salida}" == "True" ]]; then ok "facturación habilitada"; else falla "el proyecto no tiene facturación habilitada"; fi

  salida="$(gcloud services list --enabled --project "${P}" --format='value(config.name)' 2>/dev/null)"
  for api in "${APIS_GCP[@]}"; do
    if contiene "${salida}" "${api}"; then ok "API habilitada: ${api}"; else falla "API sin habilitar: ${api} (preparar_proyecto.sh la habilita)"; fi
  done

  for api in "${APIS_PROBABLES[@]}"; do
    if contiene "${salida}" "${api}"; then ok "API habilitada: ${api}"; else aviso "API sin habilitar: ${api} (los guiones usan «gcloud projects»; si fallan, habilítala)"; fi
  done

  salida="$(gcloud artifacts repositories describe "${AR_REPOSITORY}" --location "${R}" --project "${P}" --format='value(format)' 2>/dev/null)"
  if [[ "${salida}" == "DOCKER" ]]; then ok "Artifact Registry: repositorio Docker ${AR_REPOSITORY} en ${R}"; else falla "no existe el repositorio Docker ${AR_REPOSITORY} en ${R}"; fi

  local sa
  for sa in "${RUNTIME_SA}" "${DEPLOY_SA}"; do
    salida="$(gcloud iam service-accounts describe "${sa}" --project "${P}" --format='value(email)' 2>/dev/null)"
    if [[ -n "${salida}" ]]; then ok "cuenta de servicio existe: ${sa%%@*}"; else falla "no existe la cuenta de servicio ${sa%%@*}"; fi
  done

  # Roles mínimos de la cuenta de despliegue en el proyecto: solo run.developer.
  salida="$(gcloud projects get-iam-policy "${P}" --flatten='bindings[].members' \
    --filter="bindings.members:serviceAccount:${DEPLOY_SA}" --format='value(bindings.role)' 2>/dev/null)"
  if contiene "${salida}" "roles/run.developer"; then ok "deployer: roles/run.developer en el proyecto"; else falla "deployer sin roles/run.developer"; fi
  while IFS= read -r rol; do
    [[ -z "${rol}" || "${rol}" == "roles/run.developer" ]] && continue
    aviso "deployer tiene un rol de proyecto adicional: ${rol} (el mínimo es solo roles/run.developer)"
  done <<<"${salida}"

  salida="$(gcloud artifacts repositories get-iam-policy "${AR_REPOSITORY}" --location "${R}" --project "${P}" \
    --flatten='bindings[].members' --filter="bindings.members:serviceAccount:${DEPLOY_SA}" --format='value(bindings.role)' 2>/dev/null)"
  if contiene "${salida}" "roles/artifactregistry.writer"; then ok "deployer: roles/artifactregistry.writer solo en el repositorio"; else falla "deployer sin artifactregistry.writer en el repositorio"; fi

  salida="$(gcloud iam service-accounts get-iam-policy "${RUNTIME_SA}" --project "${P}" \
    --flatten='bindings[].members' --filter="bindings.members:serviceAccount:${DEPLOY_SA}" --format='value(bindings.role)' 2>/dev/null)"
  if contiene "${salida}" "roles/iam.serviceAccountUser"; then ok "deployer: roles/iam.serviceAccountUser solo sobre la cuenta de runtime"; else falla "deployer sin serviceAccountUser sobre runtime"; fi

  salida="$(gcloud projects get-iam-policy "${P}" --flatten='bindings[].members' \
    --filter="bindings.members:serviceAccount:${RUNTIME_SA}" --format='value(bindings.role)' 2>/dev/null)"
  if [[ -z "${salida}" ]]; then ok "runtime: sin roles en el proyecto (privilegio mínimo)"; else aviso "runtime tiene roles de proyecto (esperado: ninguno)"; fi

  salida="$(gcloud iam service-accounts keys list --iam-account "${DEPLOY_SA}" --managed-by=user --format='value(name)' --project "${P}" 2>/dev/null)"
  if [[ -z "${salida}" ]]; then ok "deployer: sin llaves JSON creadas por usuarios"; else falla "deployer tiene llaves JSON de usuario: bórralas"; fi

  # Workload Identity Federation
  salida="$(gcloud iam workload-identity-pools describe "${WIF_POOL}" --location global --project "${P}" --format='value(state)' 2>/dev/null)"
  if [[ "${salida}" == "ACTIVE" ]]; then ok "WIF: pool ${WIF_POOL} activo"; else falla "WIF: el pool ${WIF_POOL} no existe o no está activo"; fi

  salida="$(gcloud iam workload-identity-pools providers describe "${WIF_PROVIDER_ID}" --workload-identity-pool "${WIF_POOL}" \
    --location global --project "${P}" --format='value(state)' 2>/dev/null)"
  if [[ "${salida}" == "ACTIVE" ]]; then ok "WIF: proveedor ${WIF_PROVIDER_ID} activo"; else falla "WIF: el proveedor ${WIF_PROVIDER_ID} no existe o no está activo"; fi

  salida="$(gcloud iam workload-identity-pools providers describe "${WIF_PROVIDER_ID}" --workload-identity-pool "${WIF_POOL}" \
    --location global --project "${P}" --format='value(oidc.issuerUri)' 2>/dev/null)"
  if [[ "${salida}" == "https://token.actions.githubusercontent.com" ]]; then ok "WIF: emisor OIDC de GitHub Actions"; else falla "WIF: emisor OIDC distinto del de GitHub Actions"; fi

  salida="$(gcloud iam workload-identity-pools providers describe "${WIF_PROVIDER_ID}" --workload-identity-pool "${WIF_POOL}" \
    --location global --project "${P}" --format='value(attributeCondition)' 2>/dev/null)"
  if [[ "${salida}" == *"assertion.repository == '${GITHUB_REPO}'"* && "${salida}" == *"assertion.environment == 'cloudrun'"* ]]; then
    ok "WIF: la condición de atributos fija el repositorio y el entorno cloudrun"
  else
    falla "WIF: la condición de atributos no restringe a ${GITHUB_REPO} y al entorno cloudrun"
  fi

  salida="$(gcloud iam service-accounts get-iam-policy "${DEPLOY_SA}" --project "${P}" \
    --flatten='bindings[].members' --filter='bindings.role:roles/iam.workloadIdentityUser' --format='value(bindings.members)' 2>/dev/null)"
  if grep -qF -- "projects/${numero}/locations/global/workloadIdentityPools/${WIF_POOL}/attribute.repository/${GITHUB_REPO}" <<<"${salida}"; then
    ok "WIF: solo el repositorio indicado puede actuar como el deployer (workloadIdentityUser)"
  else
    falla "WIF: falta roles/iam.workloadIdentityUser para el repositorio en el deployer"
  fi
  if [[ "$(wc -l <<<"${salida}")" -gt 1 ]]; then aviso "el deployer tiene más de un principal con workloadIdentityUser; revisa que sea intencional"; fi

  # Políticas de organización que rompen el primer despliegue público (solo informativo).
  salida="$(gcloud org-policies describe iam.allowedPolicyMemberDomains --project "${P}" --effective --format='value(spec.rules)' 2>/dev/null)"
  if [[ -n "${salida}" ]]; then
    aviso "«Domain restricted sharing» parece activa: --allow-unauthenticated fallará (ver §6 de docs/ESTADO_Y_PRUEBAS.md)"
  else
    ok "sin «Domain restricted sharing» efectiva (o no consultable con estos permisos)"
  fi
}

# ---------------------------------------------------------------- GitHub
nombres_de() { gh api "$1" --jq "$2" 2>/dev/null; }

verificar_github() {
  echo "== GitHub =="
  if ! tiene gh; then
    falla "gh no está instalado"
    return
  fi
  if ! validar_repo "${GITHUB_REPO}"; then
    falla "define GITHUB_REPO=<propietario>/<repositorio>"
    return
  fi
  local estado
  estado="$(gh auth status 2>&1)"
  if ! gh auth status >/dev/null 2>&1; then
    falla "gh no tiene sesión iniciada (gh auth login)"
    return
  fi
  ok "gh con sesión iniciada"
  if grep -qE "Token scopes:.*'workflow'" <<<"${estado}"; then
    ok "el token de gh incluye el alcance «workflow»"
  else
    aviso "no se puede confirmar el alcance «workflow» (un token de grano fino no lo lista): se comprueba al hacer push"
  fi

  local push vis nombres n
  push="$(nombres_de "repos/${GITHUB_REPO}" '.permissions.push')"
  if [[ "${push}" == "true" ]]; then ok "permiso de escritura en ${GITHUB_REPO}"; else falla "sin permiso de escritura en ${GITHUB_REPO}"; fi
  vis="$(nombres_de "repos/${GITHUB_REPO}" '.visibility')"
  echo "[INFO] visibilidad de ${GITHUB_REPO}: ${vis:-desconocida}"

  # Entorno cloudrun
  if gh api "repos/${GITHUB_REPO}/environments/cloudrun" >/dev/null 2>&1; then
    ok "entorno cloudrun existe"
    n="$(nombres_de "repos/${GITHUB_REPO}/environments/cloudrun" '[.protection_rules[]? | select(.type=="required_reviewers")] | length')"
    if [[ "${n:-0}" -ge 1 ]]; then ok "cloudrun: revisores obligatorios configurados"; else aviso "cloudrun: sin revisores obligatorios"; fi
    nombres="$(nombres_de "repos/${GITHUB_REPO}/environments/cloudrun/variables" '.variables[].name')"
    local v
    for v in "${VARS_CLOUDRUN[@]}"; do
      if contiene "${nombres}" "${v}"; then ok "cloudrun: variable ${v}"; else falla "cloudrun: falta la variable ${v}"; fi
    done
    nombres="$(nombres_de "repos/${GITHUB_REPO}/environments/cloudrun/secrets" '.secrets[].name')"
    if [[ -z "${nombres}" ]]; then ok "cloudrun: sin secretos (OIDC no los necesita)"; else aviso "cloudrun tiene secretos definidos; no hacen falta"; fi
  else
    falla "no existe el entorno cloudrun en ${GITHUB_REPO} (o no hay permiso para leerlo)"
  fi

  # Entorno linux (en el repositorio del runner si se indica; si no, en el mismo)
  local RL="${RUNNER_REPO:-${GITHUB_REPO}}"
  if ! validar_repo "${RL}"; then
    falla "RUNNER_REPO no válido"
    return
  fi
  if [[ -n "${RUNNER_REPO}" ]]; then
    vis="$(nombres_de "repos/${RUNNER_REPO}" '.visibility')"
    if [[ "${vis}" == "private" ]]; then ok "el repositorio del runner es privado"; else falla "el repositorio del runner NO es privado (visibilidad: ${vis:-desconocida})"; fi
  else
    omitido "RUNNER_REPO no definido: se busca el entorno linux en ${GITHUB_REPO}"
  fi
  if gh api "repos/${RL}/environments/linux" >/dev/null 2>&1; then
    ok "entorno linux existe en ${RL}"
    n="$(nombres_de "repos/${RL}/environments/linux" '[.protection_rules[]? | select(.type=="required_reviewers")] | length')"
    if [[ "${n:-0}" -ge 1 ]]; then ok "linux: revisores obligatorios configurados"; else aviso "linux: sin revisores obligatorios (en repos privados exigen GitHub Pro o Team)"; fi
    nombres="$(nombres_de "repos/${RL}/environments/linux/secrets" '.secrets[].name')"
    local s
    for s in "${SECRETOS_LINUX[@]}"; do
      if contiene "${nombres}" "${s}"; then ok "linux: secreto ${s}"; else falla "linux: falta el secreto ${s}"; fi
    done
    nombres="$(nombres_de "repos/${RL}/environments/linux/variables" '.variables[].name')"
    for v in "${VARS_LINUX[@]}"; do
      if contiene "${nombres}" "${v}"; then ok "linux: variable ${v}"; else falla "linux: falta la variable ${v}"; fi
    done
    if contiene "${nombres}" "DEPLOY_RUNNER"; then ok "linux: variable opcional DEPLOY_RUNNER definida"; else omitido "linux: DEPLOY_RUNNER no definida (por omisión: self-hosted)"; fi
  else
    falla "no existe el entorno linux en ${RL} (o no hay permiso para leerlo)"
  fi

  if [[ -n "${RUNNER_REPO}" ]]; then
    nombres="$(nombres_de "repos/${RUNNER_REPO}/actions/runners" '.runners[] | "\(.name) \(.status)"')"
    if [[ -n "${nombres}" ]]; then ok "hay al menos un runner registrado en ${RUNNER_REPO}"; else omitido "sin runner registrado en ${RUNNER_REPO} (con --ephemeral es normal fuera de una ejecución)"; fi
  fi
}

# ---------------------------------------------------------------- GHCR (sin credenciales)
verificar_ghcr() {
  echo "== GHCR (consulta anónima) =="
  if ! tiene curl; then
    falla "curl no está instalado"
    return
  fi
  if ! validar_repo "${GITHUB_REPO}"; then
    falla "define GITHUB_REPO=<propietario>/<repositorio>"
    return
  fi
  local paquete="${GITHUB_REPO,,}/api" codigo token tmp
  tmp="$(mktemp)"
  codigo="$(curl -s -o "${tmp}" -w '%{http_code}' "https://ghcr.io/token?service=ghcr.io&scope=repository:${paquete}:pull")"
  if [[ "${codigo}" != "200" ]]; then
    rm -f "${tmp}"
    falla "GHCR: ${paquete} no es público (el token anónimo respondió ${codigo}); cámbialo a Public en Package settings"
    return
  fi
  token="$(sed -n 's/.*"token":"\([^"]*\)".*/\1/p' "${tmp}")"
  rm -f "${tmp}"
  ok "GHCR: ${paquete} permite descarga anónima"
  if [[ -n "${IMAGE_TAG:-}" ]]; then
    codigo="$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer ${token}" \
      -H 'Accept: application/vnd.oci.image.index.v1+json, application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json' \
      "https://ghcr.io/v2/${paquete}/manifests/${IMAGE_TAG}")"
    if [[ "${codigo}" == "200" ]]; then ok "GHCR: existe la etiqueta ${IMAGE_TAG}"; else falla "GHCR: no existe la etiqueta ${IMAGE_TAG} (HTTP ${codigo})"; fi
  else
    omitido "IMAGE_TAG no definido: no se comprueba ninguna etiqueta"
  fi
}

# ---------------------------------------------------------------- VM Ubuntu 24.04 (solo lectura por SSH)
verificar_vm() {
  echo "== VM Ubuntu 24.04 =="
  local faltan=() v
  for v in SSH_HOST SSH_USER SSH_PORT SSH_KEY_FILE SSH_KNOWN_HOSTS_FILE; do
    [[ -n "${!v:-}" ]] || faltan+=("${v}")
  done
  if [[ "${#faltan[@]}" -gt 0 ]]; then
    falla "define: ${faltan[*]}"
    return
  fi
  if ! tiene ssh; then
    falla "ssh no está instalado"
    return
  fi
  [[ "${SSH_PORT}" =~ ^[0-9]{1,5}$ && "${SSH_HOST}" =~ ^[A-Za-z0-9._:-]+$ && "${SSH_USER}" =~ ^[a-z_][a-z0-9_-]*$ ]] \
    || { falla "SSH_HOST, SSH_USER o SSH_PORT con formato no válido"; return; }
  [[ -f "${SSH_KEY_FILE}" ]] || { falla "no existe SSH_KEY_FILE"; return; }
  [[ -s "${SSH_KNOWN_HOSTS_FILE}" ]] || { falla "SSH_KNOWN_HOSTS_FILE no existe o está vacío"; return; }
  local modo
  modo="$(stat -c '%a' "${SSH_KEY_FILE}")"
  if [[ "${modo}" == "600" || "${modo}" == "400" ]]; then ok "la clave privada tiene permisos ${modo}"; else falla "la clave privada debe tener permisos 600"; fi
  if ssh-keygen -y -P "" -f "${SSH_KEY_FILE}" >/dev/null 2>&1; then ok "la clave privada se lee sin contraseña (como exige el workflow)"; else aviso "la clave privada pide contraseña o no es válida: el workflow no puede usarla"; fi
  if ssh-keygen -lf "${SSH_KEY_FILE}.pub" 2>/dev/null | grep -q 'ED25519'; then ok "la clave pública es Ed25519"; else aviso "no se pudo confirmar que la clave pública sea Ed25519 (se espera ${SSH_KEY_FILE}.pub)"; fi

  local DIR="${SSH_DEPLOY_DIR:-/opt/cd441}" salida
  # Todo lo que se ejecuta en la VM es de lectura. known_hosts fijado: huella desconocida = rechazo.
  salida="$(ssh -o BatchMode=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile="${SSH_KNOWN_HOSTS_FILE}" \
    -o ConnectTimeout=15 -i "${SSH_KEY_FILE}" -p "${SSH_PORT}" "${SSH_USER}@${SSH_HOST}" bash -s -- "${DIR}" 2>&1 <<'REMOTO'
dir="$1"
. /etc/os-release
echo "os=${ID}-${VERSION_ID}"
echo "init=$(ps -p 1 -o comm= | tr -d ' ')"
for u in docker postgresql; do echo "activo_${u}=$(systemctl is-active "${u}" 2>/dev/null || true)"; done
echo "unidad_api=$(systemctl is-enabled cd441-api.service 2>/dev/null || echo ausente)"
echo "docker_cli=$(command -v docker >/dev/null && echo si || echo no)"
echo "compose=$(docker compose version >/dev/null 2>&1 && echo si || echo no)"
echo "dir=$([ -d "${dir}" ] && echo si || echo no)"
echo "env_modo=$(stat -c '%a %U:%G' /etc/cd441/api.env 2>/dev/null || echo ausente)"
echo "grupo_docker=$(id -nG | tr ' ' '\n' | grep -qx docker && echo si || echo no)"
echo "sudo_sin_clave=$(sudo -n true 2>/dev/null && echo si || echo no)"
REMOTO
  )"
  local rc=$?
  if [[ "${rc}" -ne 0 ]]; then
    falla "no se pudo entrar por SSH con la clave y el known_hosts indicados (código ${rc}); revisa host, puerto, usuario y huella"
    return
  fi
  ok "SSH con clave, sin contraseña y con huella fijada"
  local clave valor
  declare -A R=()
  while IFS='=' read -r clave valor; do [[ -n "${clave}" ]] && R["${clave}"]="${valor}"; done <<<"${salida}"
  igual "${R[os]:-}" "ubuntu-24.04" "sistema: Ubuntu 24.04" "el sistema no es Ubuntu 24.04 (${R[os]:-?})"
  igual "${R[init]:-}" "systemd" "systemd es PID 1" "systemd no es PID 1 (no sirve un contenedor)"
  igual "${R[docker_cli]:-}/${R[compose]:-}" "si/si" "Docker y Compose v2 instalados" "falta Docker o Compose v2 (preparar_anfitrion.sh los instala)"
  igual "${R[activo_docker]:-}" "active" "servicio docker activo" "servicio docker inactivo"
  igual "${R[activo_postgresql]:-}" "active" "servicio postgresql activo" "servicio postgresql inactivo"
  igual "${R[unidad_api]:-}" "enabled" "unidad cd441-api.service habilitada" "cd441-api.service no está habilitada"
  igual "${R[dir]:-}" "si" "existe el directorio de despliegue" "no existe el directorio de despliegue ${DIR}"
  if [[ "${R[env_modo]:-}" == 640\ root:* ]]; then ok "/etc/cd441/api.env con modo 640 y propietario root"; else falla "/etc/cd441/api.env ausente o con permisos distintos de 640 root:<grupo>"; fi
  if [[ "${R[grupo_docker]:-}" == "si" ]]; then aviso "el usuario ${SSH_USER} está en el grupo docker (equivale a root; esperado, documentado)"; else falla "el usuario ${SSH_USER} no está en el grupo docker"; fi
  if [[ "${R[sudo_sin_clave]:-}" == "si" ]]; then aviso "el usuario ${SSH_USER} tiene sudo sin contraseña: no debería"; else ok "el usuario ${SSH_USER} no tiene sudo sin contraseña"; fi
}

case "${SECCION}" in
  gcp) verificar_gcp ;;
  github) verificar_github ;;
  ghcr) verificar_ghcr ;;
  vm) verificar_vm ;;
  todo)
    verificar_gcp
    verificar_github
    verificar_ghcr
    verificar_vm
    ;;
esac

echo
echo "Resumen: ${N_OK} ok, ${N_FALLA} fallan, ${N_AVISO} avisos, ${N_OMITIDO} omitidos."
[[ "${N_FALLA}" -eq 0 ]]
