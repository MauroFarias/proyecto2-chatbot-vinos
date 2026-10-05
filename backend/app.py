"""Servidor web Flask: entrega el frontend y expone la API del chatbot.

Ejecutar desde la raíz del proyecto:  python -m backend.app
"""
from flask import Flask, jsonify, request, send_from_directory

from backend import chatbot, config

app = Flask(__name__, static_folder=str(config.FRONTEND_DIR), static_url_path="")

OPCIONES_MOTOR = {
    "prolog": ["prolog"],
    "llm": ["llm"],
    "ambos": ["prolog", "llm"],
}


@app.get("/")
def inicio():
    return send_from_directory(config.FRONTEND_DIR, "index.html")


@app.post("/api/preguntar")
def preguntar():
    datos = request.get_json(silent=True) or {}
    motor = datos.get("motor", "ambos")

    if motor not in OPCIONES_MOTOR:
        return jsonify(error="Motor inválido. Usa: prolog, llm o ambos."), 400
    try:
        pregunta = chatbot.validar_pregunta(datos.get("pregunta"))
    except ValueError as error:
        return jsonify(error=str(error)), 400

    respuestas = {m: chatbot.consultar(m, pregunta) for m in OPCIONES_MOTOR[motor]}
    return jsonify(pregunta=pregunta, respuestas=respuestas)


if __name__ == "__main__":
    app.run(debug=True, port=5000)
