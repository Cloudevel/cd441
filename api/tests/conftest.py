"""Fixtures compartidas: cada prueba usa una aplicación nueva, en memoria."""

import pytest

from app import create_app


@pytest.fixture(autouse=True)
def entorno_limpio(monkeypatch):
    """Las pruebas no dependen del entorno de quien las ejecuta."""
    for variable in ("DATABASE_URL", "APP_VERSION", "SECRET_KEY"):
        monkeypatch.delenv(variable, raising=False)


@pytest.fixture
def app():
    return create_app()


@pytest.fixture
def client(app):
    return app.test_client()
