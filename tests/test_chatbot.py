"""Pruebas automáticas. Ejecutar desde la raíz:  pytest

Las pruebas del chatbot Prolog no requieren Ollama.
"""
import pytest

from backend import chatbot, config, prolog_bot

CASOS_PROLOG = [
    ("¿En qué valles se produce Carménère?", "Maipo"),
    ("¿De dónde proviene la cepa País?", "España"),
    ("¿Qué vino va con un ceviche?", "Sauvignon Blanc"),
    ("¿Se cultiva Pinot Noir en Leyda?", "Sí"),
    ("¿Se cultiva Carignan en Casablanca?", "No"),
    ("¿Qué cepas comparten Maipo y Colchagua?", "Cabernet Sauvignon"),
    ("¿A qué temperatura se sirve un Syrah?", "16 y 18"),
    ("QUE VALLES SON DEL SUR???", "Itata"),          # mayúsculas y puntuación
    ("¿De qué país viene el Merlot?", "Francia"),    # "país" como nación
]


@pytest.mark.parametrize("pregunta, esperado", CASOS_PROLOG)
def test_prolog_responde_correctamente(pregunta, esperado):
    assert esperado in prolog_bot.preguntar(pregunta)


def test_prolog_fuera_de_dominio():
    assert "no tengo información" in prolog_bot.preguntar("¿Quién ganó el mundial 2010?")


@pytest.mark.parametrize("pregunta", ["", "   ", "a" * (config.MAX_LARGO_PREGUNTA + 1)])
def test_validacion_rechaza_preguntas_invalidas(pregunta):
    with pytest.raises(ValueError):
        chatbot.validar_pregunta(pregunta)


def test_llm_sin_ollama_entrega_error_controlado(monkeypatch):
    monkeypatch.setattr(config, "OLLAMA_URL", "http://127.0.0.1:9")  # puerto sin servicio
    resultado = chatbot.consultar("llm", "¿Qué es el Carménère?")
    assert resultado["ok"] is False
    assert "Ollama" in resultado["texto"]
