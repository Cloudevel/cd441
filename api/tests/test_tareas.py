"""Pruebas del CRUD de tareas (almacén en memoria)."""


def test_listar_vacio(client):
    respuesta = client.get("/tareas")
    assert respuesta.status_code == 200
    assert respuesta.get_json() == []


def test_crear_tarea(client):
    respuesta = client.post("/tareas", json={"titulo": "Escribir pruebas"})
    assert respuesta.status_code == 201
    cuerpo = respuesta.get_json()
    assert cuerpo["id"] == 1
    assert cuerpo["titulo"] == "Escribir pruebas"
    assert cuerpo["hecha"] is False


def test_crear_con_hecha_true(client):
    cuerpo = client.post(
        "/tareas", json={"titulo": "Ya hecha", "hecha": True}
    ).get_json()
    assert cuerpo["hecha"] is True


def test_crear_sin_titulo(client):
    respuesta = client.post("/tareas", json={})
    assert respuesta.status_code == 400
    assert "titulo" in respuesta.get_json()["error"]


def test_crear_titulo_vacio(client):
    respuesta = client.post("/tareas", json={"titulo": "   "})
    assert respuesta.status_code == 400


def test_crear_titulo_no_cadena(client):
    respuesta = client.post("/tareas", json={"titulo": 42})
    assert respuesta.status_code == 400


def test_crear_hecha_no_booleano(client):
    respuesta = client.post("/tareas", json={"titulo": "X", "hecha": "si"})
    assert respuesta.status_code == 400
    assert "hecha" in respuesta.get_json()["error"]


def test_crear_sin_cuerpo_json(client):
    respuesta = client.post("/tareas", data="no-es-json", content_type="text/plain")
    assert respuesta.status_code == 400


def test_ids_secuenciales(client):
    primera = client.post("/tareas", json={"titulo": "Uno"}).get_json()
    segunda = client.post("/tareas", json={"titulo": "Dos"}).get_json()
    assert primera["id"] == 1
    assert segunda["id"] == 2


def test_obtener_tarea(client):
    creada = client.post("/tareas", json={"titulo": "Leer"}).get_json()
    respuesta = client.get(f"/tareas/{creada['id']}")
    assert respuesta.status_code == 200
    assert respuesta.get_json()["titulo"] == "Leer"


def test_obtener_inexistente(client):
    respuesta = client.get("/tareas/99")
    assert respuesta.status_code == 404
    assert "no encontrada" in respuesta.get_json()["error"]


def test_listar_despues_de_crear(client):
    client.post("/tareas", json={"titulo": "A"})
    client.post("/tareas", json={"titulo": "B"})
    listado = client.get("/tareas").get_json()
    assert len(listado) == 2
    assert {item["titulo"] for item in listado} == {"A", "B"}


def test_actualizar_titulo(client):
    creada = client.post("/tareas", json={"titulo": "Viejo"}).get_json()
    respuesta = client.patch(f"/tareas/{creada['id']}", json={"titulo": "Nuevo"})
    assert respuesta.status_code == 200
    assert respuesta.get_json()["titulo"] == "Nuevo"
    assert respuesta.get_json()["hecha"] is False


def test_actualizar_hecha(client):
    creada = client.post("/tareas", json={"titulo": "Pendiente"}).get_json()
    cuerpo = client.patch(f"/tareas/{creada['id']}", json={"hecha": True}).get_json()
    assert cuerpo["hecha"] is True
    assert cuerpo["titulo"] == "Pendiente"


def test_actualizar_inexistente(client):
    respuesta = client.patch("/tareas/99", json={"hecha": True})
    assert respuesta.status_code == 404


def test_actualizar_titulo_invalido(client):
    creada = client.post("/tareas", json={"titulo": "Ok"}).get_json()
    respuesta = client.patch(f"/tareas/{creada['id']}", json={"titulo": ""})
    assert respuesta.status_code == 400


def test_actualizar_hecha_invalida(client):
    creada = client.post("/tareas", json={"titulo": "Ok"}).get_json()
    respuesta = client.patch(f"/tareas/{creada['id']}", json={"hecha": 1})
    assert respuesta.status_code == 400


def test_eliminar_tarea(client):
    creada = client.post("/tareas", json={"titulo": "Borrar"}).get_json()
    respuesta = client.delete(f"/tareas/{creada['id']}")
    assert respuesta.status_code == 204
    assert client.get(f"/tareas/{creada['id']}").status_code == 404
    assert client.get("/tareas").get_json() == []


def test_eliminar_inexistente(client):
    respuesta = client.delete("/tareas/99")
    assert respuesta.status_code == 404
