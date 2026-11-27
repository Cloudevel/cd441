#!/usr/bin/env bash
# Preparación mínima del destino Linux del cuaderno 17: un Ubuntu 24.04 COMPLETO
# (con systemd), propio de cada estudiante. No funciona en Codespaces: allí no
# hay systemd.
#
# Se ejecuta una vez, como root, en el anfitrión:
#   sudo bash api/deploy/preparar_anfitrion.sh <clave_publica_ed25519.pub> [usuario] [directorio]
#   (por defecto: usuario «deploy», directorio «/opt/cd441»)
#
# Qué hace (idempotente: se puede repetir sin romper nada):
#   1. Instala Docker (con Compose v2), PostgreSQL y curl desde los repositorios de Ubuntu.
#   2. Crea el usuario de despliegue, autoriza SOLO su clave ed25519 y crea el directorio.
#   3. Crea en PostgreSQL el rol y la base «cd441» con una contraseña aleatoria,
#      y limita pg_hba.conf a conexiones LOCALES por socket con scram-sha-256.
#   4. Escribe /etc/cd441/api.env (DATABASE_URL y SECRET_KEY), legible solo por
#      root y el usuario de despliegue. Esos secretos no pasan por GitHub.
#   5. Instala y habilita la unidad systemd cd441-api.service.
#   6. Muestra la huella de la clave del servidor para verificar SSH_KNOWN_HOSTS.
set -euo pipefail

CLAVE_PUBLICA="${1:?Uso: $0 <clave_publica_ed25519.pub> [usuario] [directorio]}"
USUARIO="${2:-deploy}"
DIRECTORIO="${3:-/opt/cd441}"
DIR_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ "${EUID}" -eq 0 ]] || { echo "Ejecuta este guion como root (sudo)." >&2; exit 1; }
[[ "${USUARIO}" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || { echo "Usuario no válido." >&2; exit 1; }
[[ "${DIRECTORIO}" =~ ^/[A-Za-z0-9._/-]+$ ]] || { echo "Directorio no válido (ruta absoluta)." >&2; exit 1; }
grep -q '^ssh-ed25519 ' "${CLAVE_PUBLICA}" || { echo "La clave pública debe ser ed25519." >&2; exit 1; }
if ! [[ -d /run/systemd/system ]]; then
  echo "Se necesita systemd (un Ubuntu 24.04 completo, no Codespaces)." >&2; exit 1
fi
if ! grep -q 'VERSION_ID="24.04"' /etc/os-release; then
  echo "Aviso: este guion se probó para Ubuntu 24.04." >&2
fi

echo "== 1. Paquetes"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq docker.io docker-compose-v2 postgresql curl openssl >/dev/null
systemctl enable --now docker postgresql

echo "== 2. Usuario ${USUARIO} y directorio ${DIRECTORIO}"
id "${USUARIO}" >/dev/null 2>&1 || useradd --create-home --shell /bin/bash "${USUARIO}"
# Ojo: el grupo docker equivale a root en el anfitrión. Aceptable en una máquina
# de práctica propia; en producción se usaría Docker sin root o un orquestador.
usermod -aG docker "${USUARIO}"
HOGAR="$(getent passwd "${USUARIO}" | cut -d: -f6)"
install -d -m 700 -o "${USUARIO}" -g "${USUARIO}" "${HOGAR}/.ssh"
touch "${HOGAR}/.ssh/authorized_keys"
grep -qxF "$(cat "${CLAVE_PUBLICA}")" "${HOGAR}/.ssh/authorized_keys" \
  || cat "${CLAVE_PUBLICA}" >> "${HOGAR}/.ssh/authorized_keys"
chown "${USUARIO}:${USUARIO}" "${HOGAR}/.ssh/authorized_keys"
chmod 600 "${HOGAR}/.ssh/authorized_keys"
install -d -m 750 -o "${USUARIO}" -g "${USUARIO}" "${DIRECTORIO}"

echo "== 3. PostgreSQL: rol y base cd441, solo conexiones locales"
ENV_API=/etc/cd441/api.env
if [[ ! -f "${ENV_API}" ]]; then
  # Hexadecimal: va dentro de una URL sin necesidad de escapar caracteres.
  CONTRASENA="$(openssl rand -hex 24)"
  if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='cd441'" | grep -q 1; then
    ACCION=ALTER
  else
    ACCION=CREATE
  fi
  # La contraseña va por la entrada estándar, no como argumento visible en `ps`.
  sudo -u postgres psql -q <<SQL
${ACCION} ROLE cd441 WITH LOGIN PASSWORD '${CONTRASENA}';
SQL
  sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='cd441'" | grep -q 1 \
    || sudo -u postgres createdb --owner cd441 cd441

  install -d -m 750 -o root -g "${USUARIO}" /etc/cd441
  umask 027
  cat > "${ENV_API}" <<ENV
# Generado por preparar_anfitrion.sh. NO copiar a git ni a GitHub.
DATABASE_URL=postgresql://cd441:${CONTRASENA}@/cd441?host=/var/run/postgresql
SECRET_KEY=$(openssl rand -hex 32)
ENV
  chown "root:${USUARIO}" "${ENV_API}"
  chmod 640 "${ENV_API}"
  umask 022
fi

HBA="$(sudo -u postgres psql -tAc 'SHOW hba_file')"
REGLA='local   cd441   cd441   scram-sha-256'
if ! grep -qxF "${REGLA}" "${HBA}"; then
  # La regla va al principio: PostgreSQL usa la primera que coincide.
  sed -i "1i # cd441: solo por socket local, con contraseña (scram-sha-256)\n${REGLA}" "${HBA}"
fi
# listen_addresses se deja en 'localhost' (valor por defecto de Ubuntu): sin TCP externo.
sudo -u postgres psql -tAc 'SHOW listen_addresses'
systemctl reload postgresql

echo "== 4. Unidad systemd cd441-api.service"
sed -e "s|@DEPLOY_DIR@|${DIRECTORIO}|g" -e "s|@DEPLOY_USER@|${USUARIO}|g" \
  "${DIR_SCRIPT}/cd441-api.service" > /etc/systemd/system/cd441-api.service
systemctl daemon-reload
systemctl enable cd441-api.service

echo "== 5. Huella de la clave ed25519 de ESTE servidor"
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
echo "Compárala con: ssh-keyscan -t ed25519 -p <puerto> <host> | ssh-keygen -lf -"
echo "Listo. Configura SSH_DEPLOY_DIR=${DIRECTORIO} y SSH_USER=${USUARIO} en GitHub."
