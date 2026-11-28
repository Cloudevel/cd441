# Python 3.12 sobre Debian 12 (bookworm), imagen de devcontainer fijada por versión.
# Dependabot (ecosistema docker) propone las actualizaciones.
FROM mcr.microsoft.com/devcontainers/python:3.3.4-3.12-bookworm

# SDK de Google Cloud (gcloud) desde el repositorio oficial de Google, con la
# clave del repositorio en un keyring dedicado (signed-by) y la versión fijada.
# Sustituye a la feature de terceros dhoeric/features/google-cloud-cli, que no
# recibe mantenimiento y usaba apt-key (obsoleto).
ARG GCLOUD_VERSION=594.0.1-0
RUN curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
        | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
        > /etc/apt/sources.list.d/google-cloud-sdk.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends "google-cloud-cli=${GCLOUD_VERSION}" \
    && rm -rf /var/lib/apt/lists/*

# gitleaks: binario oficial, versión y checksum fijados (no hay paquete apt).
# Checksums: https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_checksums.txt
# Actualizar a mano (Dependabot no cubre este binario).
ARG GITLEAKS_VERSION=8.30.1
RUN set -eu; \
    arch="$(dpkg --print-architecture)"; \
    case "${arch}" in \
      amd64) pkg=linux_x64; sha=551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb ;; \
      arm64) pkg=linux_arm64; sha=e4a487ee7ccd7d3a7f7ec08657610aa3606637dab924210b3aee62570fb4b080 ;; \
      *) echo "Arquitectura no soportada para gitleaks: ${arch}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL -o /tmp/gitleaks.tar.gz \
      "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_${pkg}.tar.gz"; \
    echo "${sha}  /tmp/gitleaks.tar.gz" | sha256sum --check --strict; \
    tar -xzf /tmp/gitleaks.tar.gz -C /tmp gitleaks; \
    install -m 0755 /tmp/gitleaks /usr/local/bin/gitleaks; \
    rm -f /tmp/gitleaks.tar.gz /tmp/gitleaks; \
    gitleaks version

# Kernels de Jupyter (Python y Bash) y herramientas para ejecutar los cuadernos.
COPY requirements.txt /tmp/cd441-requirements.txt
RUN python -m pip install --no-cache-dir -r /tmp/cd441-requirements.txt \
    && python -m bash_kernel.install --sys-prefix \
    && rm /tmp/cd441-requirements.txt
