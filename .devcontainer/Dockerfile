# Python 3.12 sobre Debian 12 (bookworm), imagen de devcontainer fijada por versión.
# Dependabot (ecosistema docker) propone las actualizaciones.
FROM mcr.microsoft.com/devcontainers/python:3.15-bookworm

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

# Kernels de Jupyter (Python y Bash) y herramientas para ejecutar los cuadernos.
COPY requirements.txt /tmp/cd441-requirements.txt
RUN python -m pip install --no-cache-dir -r /tmp/cd441-requirements.txt \
    && python -m bash_kernel.install --sys-prefix \
    && rm /tmp/cd441-requirements.txt
