"""Rutas de la API: salud y un CRUD sencillo de tareas."""

from flask import Blueprint, current_app, jsonify, request

bp = Blueprint("api", __name__)


def _almacen():
    return current_app.extensions["almacen"]


@bp.get("/health")
def health():
    """Comprobación de salud para Cloud Run, Compose y los workflows.

    Si hay base de datos configurada y no responde, devuelve 503.
    """
    almacen = _almacen()
    cuerpo = {
        "status": "ok",
        "version": current_app.config.get("APP_VERSION", "dev"),
        "almacen": almacen.tipo,
    }
    try:
        almacen.comprobar()
    except Exception:  # cualquier fallo de la base = servicio no saludable
        current_app.logger.exception("La base de datos no responde")
        cuerpo["status"] = "error"
        return jsonify(cuerpo), 503
    return jsonify(cuerpo)


@bp.get("/tareas")
def listar_tareas():
    return jsonify(_almacen().listar())


@bp.post("/tareas")
def crear_tarea():
    datos = request.get_json(silent=True) or {}
    titulo = datos.get("titulo")
    if not isinstance(titulo, str) or not titulo.strip():
        return jsonify(error="titulo es obligatorio"), 400

    hecha = datos.get("hecha", False)
    if not isinstance(hecha, bool):
        return jsonify(error="hecha debe ser booleano"), 400

    return jsonify(_almacen().crear(titulo.strip(), hecha)), 201


@bp.get("/tareas/<int:ident>")
def obtener_tarea(ident):
    tarea = _almacen().obtener(ident)
    if tarea is None:
        return jsonify(error="tarea no encontrada"), 404
    return jsonify(tarea)


@bp.patch("/tareas/<int:ident>")
def actualizar_tarea(ident):
    datos = request.get_json(silent=True) or {}
    cambios = {}
    if "titulo" in datos:
        titulo = datos["titulo"]
        if not isinstance(titulo, str) or not titulo.strip():
            return jsonify(error="titulo es obligatorio"), 400
        cambios["titulo"] = titulo.strip()
    if "hecha" in datos:
        hecha = datos["hecha"]
        if not isinstance(hecha, bool):
            return jsonify(error="hecha debe ser booleano"), 400
        cambios["hecha"] = hecha

    tarea = _almacen().actualizar(ident, cambios)
    if tarea is None:
        return jsonify(error="tarea no encontrada"), 404
    return jsonify(tarea)


@bp.delete("/tareas/<int:ident>")
def eliminar_tarea(ident):
    if not _almacen().eliminar(ident):
        return jsonify(error="tarea no encontrada"), 404
    return ("", 204)
