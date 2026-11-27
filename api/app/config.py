"""Configuración leída de variables de entorno (ver api/.env.example)."""

import os
import secrets


class Config:
    """Valores leídos al instanciar la clase, no al importar el módulo.

    - SECRET_KEY: si no se define, se genera una aleatoria por proceso. Así nunca
      queda una clave conocida en producción; defínela en el entorno si necesitas
      que sea estable entre reinicios. No dejes valores reales en el repositorio.
    - APP_VERSION: SHA del commit desplegado (lo inyectan los workflows).
    - DATABASE_URL: opcional. Si existe, las tareas se guardan en PostgreSQL;
      si no, en memoria (desarrollo, pruebas y Cloud Run).
    """

    def __init__(self):
        self.SECRET_KEY = os.environ.get("SECRET_KEY") or secrets.token_hex(32)
        self.APP_VERSION = os.environ.get("APP_VERSION", "dev")
        self.DATABASE_URL = os.environ.get("DATABASE_URL") or None
