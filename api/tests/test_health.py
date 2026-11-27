"""Pruebas del endpoint de salud y de la configuración por entorno."""

from app import create_app
from app.config import Config


def test_health_ok(client):
    respuesta = client.get("/health")
    assert respuesta.status_code == 200
    cuerpo = respuesta.get_json()
    assert cuerpo["status"] == "ok"
    assert cuerpo["version"] == "dev"
    assert cuerpo["almacen"] == "memoria"


def test_health_version_desde_entorno(monkeypatch):
    monkeypatch.setenv("APP_VERSION", "abc123")
    cuerpo = create_app().test_client().get("/health").get_json()
    assert cuerpo["version"] == "abc123"


def test_secret_key_aleatoria_si_no_se_define():
    # Sin SECRET_KEY no hay clave conocida: cada instancia genera una distinta.
    primera = create_app().config["SECRET_KEY"]
    segunda = create_app().config["SECRET_KEY"]
    assert len(primera) >= 64
    assert primera != segunda


def test_secret_key_desde_entorno(monkeypatch):
    monkeypatch.setenv("SECRET_KEY", "clave-de-prueba")
    assert create_app().config["SECRET_KEY"] == "clave-de-prueba"


def test_instancias_no_comparten_almacen():
    primera = create_app().test_client()
    segunda = create_app().test_client()
    primera.post("/tareas", json={"titulo": "solo en la primera"})
    assert primera.get("/tareas").get_json() != []
    assert segunda.get("/tareas").get_json() == []


def test_create_app_acepta_la_clase_config():
    aplicacion = create_app(Config)
    assert aplicacion.config["APP_VERSION"] == "dev"


def test_health_503_si_la_base_no_responde(monkeypatch):
    # Puerto 9 (discard): no hay PostgreSQL; la salud debe fallar con 503.
    monkeypatch.setenv("DATABASE_URL", "postgresql://u:p@127.0.0.1:9/db")
    respuesta = create_app().test_client().get("/health")
    assert respuesta.status_code == 503
    assert respuesta.get_json()["status"] == "error"
    assert respuesta.get_json()["almacen"] == "postgresql"
