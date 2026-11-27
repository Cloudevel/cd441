# syntax=docker/dockerfile:1
# Imagen de la API de cd441 (Cloudevel). Se construye desde la RAÍZ del repositorio:
#   docker build -t cd441-api .
#
# Buenas prácticas que muestra este archivo:
#  1. Base con versión fija Y digest (no `latest`): la misma entrada da la misma
#     imagen. Dependabot (.github/dependabot.yml) propone actualizar el digest.
#  2. Dependencias antes que el código: aprovecha la caché de capas.
#  3. Solo se copia lo necesario para ejecutar (ni pruebas, ni .env, ni deploy/).
#  4. El código pertenece a root y el proceso corre con un usuario sin privilegios:
#     la aplicación no puede modificarse a sí misma.
FROM python:3.15-slim-trixie@sha256:63bb298d2b7b88f176f51b5189f54ce6535c997682ea70885d2132f5d473a8a5

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PORT=8080

WORKDIR /app

# Usuario sin privilegios con UID fijo (el mismo en Docker, Compose y Cloud Run).
RUN groupadd --system --gid 10001 appuser \
    && useradd --system --uid 10001 --gid appuser --no-create-home --shell /usr/sbin/nologin appuser

COPY api/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY api/app/ /app/app/
COPY api/wsgi.py /app/wsgi.py

# Numérico (10001 = appuser) para que plataformas como Kubernetes verifiquen
# que no es root sin consultar /etc/passwd.
USER 10001:10001

EXPOSE 8080

# Útil en Compose o en un servidor Linux. Cloud Run ignora esta instrucción
# y hace su propia comprobación de arranque.
HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
    CMD ["python", "-c", "import os, urllib.request; urllib.request.urlopen('http://127.0.0.1:%s/health' % os.environ.get('PORT', '8080'), timeout=4)"]

# gunicorn en primer plano, un solo worker (el almacén en memoria es por proceso).
# Cloud Run inyecta PORT. --timeout acotado: una petición colgada no vive para siempre.
CMD ["sh", "-c", "exec gunicorn --bind 0.0.0.0:${PORT} --workers 1 --threads 4 --timeout 30 --access-logfile - wsgi:app"]
