"""Pruebas contra PostgreSQL real. Se omiten si no hay TEST_DATABASE_URL.

Para ejecutarlas en local (ver CONTRATO_CODIGO.md):
    TEST_DATABASE_URL=postgresql://... pytest tests/test_postgres.py
"""

import os

import pytest

from app import create_app

URL = os.environ.get("TEST_DATABASE_URL")
pytestmark = pytest.mark.skipif(not URL, reason="sin TEST_DATABASE_URL")


@pytest.fixture
def cliente_pg(monkeypatch):
    import psycopg

    with psycopg.connect(URL) as conexion:
        conexion.execute("DROP TABLE IF EXISTS tareas")
    monkeypatch.setenv("DATABASE_URL", URL)
    return create_app().test_client()


def test_health_con_postgres(cliente_pg):
    cuerpo = cliente_pg.get("/health").get_json()
    assert cuerpo == {"status": "ok", "version": "dev", "almacen": "postgresql"}


def test_crud_con_postgres(cliente_pg):
    creada = cliente_pg.post("/tareas", json={"titulo": "En la base"}).get_json()
    assert creada == {"id": 1, "titulo": "En la base", "hecha": False}
    cambiada = cliente_pg.patch("/tareas/1", json={"hecha": True}).get_json()
    assert cambiada["hecha"] is True
    assert cliente_pg.get("/tareas").get_json() == [cambiada]
    assert cliente_pg.delete("/tareas/1").status_code == 204
    assert cliente_pg.get("/tareas/1").status_code == 404
    assert cliente_pg.patch("/tareas/1", json={"hecha": True}).status_code == 404


def test_inyeccion_sql_se_guarda_como_texto(cliente_pg):
    # Consultas parametrizadas: el texto no se ejecuta como SQL.
    titulo = "x'); DROP TABLE tareas; --"
    creada = cliente_pg.post("/tareas", json={"titulo": titulo}).get_json()
    assert creada["titulo"] == titulo
    assert len(cliente_pg.get("/tareas").get_json()) == 1
