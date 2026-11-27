"""Fábrica de la API de demostración del curso cd441 (Cloudevel)."""

from flask import Flask

from .almacen import crear_almacen
from .config import Config
from .routes import bp


def create_app(config_object=None):
    """Crea y configura una instancia de la aplicación Flask."""
    app = Flask(__name__)
    if config_object is None:
        config_object = Config()
    elif isinstance(config_object, type):
        config_object = config_object()
    app.config.from_object(config_object)
    app.extensions["almacen"] = crear_almacen(app.config.get("DATABASE_URL"))
    app.register_blueprint(bp)
    return app
