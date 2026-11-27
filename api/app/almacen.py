"""Almacenes de tareas: en memoria (por defecto) o PostgreSQL (DATABASE_URL)."""

from __future__ import annotations

from typing import Any

Tarea = dict[str, Any]


class AlmacenMemoria:
    """Almacén por proceso. Por eso gunicorn arranca con un solo worker."""

    tipo = "memoria"

    def __init__(self) -> None:
        self._tareas: dict[int, Tarea] = {}
        self._siguiente = 1

    def comprobar(self) -> None:
        return None

    def listar(self) -> list[Tarea]:
        return [dict(t) for t in self._tareas.values()]

    def crear(self, titulo: str, hecha: bool) -> Tarea:
        tarea = {"id": self._siguiente, "titulo": titulo, "hecha": hecha}
        self._tareas[self._siguiente] = tarea
        self._siguiente += 1
        return dict(tarea)

    def obtener(self, ident: int) -> Tarea | None:
        tarea = self._tareas.get(ident)
        return dict(tarea) if tarea else None

    def actualizar(self, ident: int, cambios: dict[str, Any]) -> Tarea | None:
        tarea = self._tareas.get(ident)
        if tarea is None:
            return None
        tarea.update(cambios)
        return dict(tarea)

    def eliminar(self, ident: int) -> bool:
        return self._tareas.pop(ident, None) is not None


class AlmacenPostgres:
    """Almacén en PostgreSQL con una sola tabla, creada si no existe.

    Todas las consultas son parametrizadas (sin concatenar texto del usuario).
    """

    tipo = "postgresql"

    _CREAR_TABLA = """
        CREATE TABLE IF NOT EXISTS tareas (
            id SERIAL PRIMARY KEY,
            titulo TEXT NOT NULL CHECK (length(titulo) > 0),
            hecha BOOLEAN NOT NULL DEFAULT FALSE
        )
    """

    def __init__(self, url: str) -> None:
        self._url = url
        self._tabla_lista = False

    def _conectar(self):
        import psycopg
        from psycopg.rows import dict_row

        conexion = psycopg.connect(self._url, row_factory=dict_row, connect_timeout=3)
        if not self._tabla_lista:
            with conexion.cursor() as cursor:
                cursor.execute(self._CREAR_TABLA)
            conexion.commit()
            self._tabla_lista = True
        return conexion

    def comprobar(self) -> None:
        with self._conectar() as conexion:
            conexion.execute("SELECT 1")

    def listar(self) -> list[Tarea]:
        with self._conectar() as conexion:
            return conexion.execute(
                "SELECT id, titulo, hecha FROM tareas ORDER BY id"
            ).fetchall()

    def crear(self, titulo: str, hecha: bool) -> Tarea:
        with self._conectar() as conexion:
            return conexion.execute(
                "INSERT INTO tareas (titulo, hecha) VALUES (%s, %s) "
                "RETURNING id, titulo, hecha",
                (titulo, hecha),
            ).fetchone()

    def obtener(self, ident: int) -> Tarea | None:
        with self._conectar() as conexion:
            return conexion.execute(
                "SELECT id, titulo, hecha FROM tareas WHERE id = %s", (ident,)
            ).fetchone()

    def actualizar(self, ident: int, cambios: dict[str, Any]) -> Tarea | None:
        actual = self.obtener(ident)
        if actual is None:
            return None
        actual.update(cambios)
        with self._conectar() as conexion:
            return conexion.execute(
                "UPDATE tareas SET titulo = %s, hecha = %s WHERE id = %s "
                "RETURNING id, titulo, hecha",
                (actual["titulo"], actual["hecha"], ident),
            ).fetchone()

    def eliminar(self, ident: int) -> bool:
        with self._conectar() as conexion:
            cursor = conexion.execute("DELETE FROM tareas WHERE id = %s", (ident,))
            return cursor.rowcount > 0


def crear_almacen(database_url: str | None):
    """Elige el almacén según la configuración."""
    if database_url:
        return AlmacenPostgres(database_url)
    return AlmacenMemoria()
