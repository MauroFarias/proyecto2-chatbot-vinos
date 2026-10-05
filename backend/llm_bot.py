"""Chatbot basado en un LLM local (Ollama) que responde usando la base de conocimiento.

El LLM recibe el archivo base_conocimiento.pl completo como contexto y se le
instruye responder SOLO con esa información. Así ambos chatbots usan el mismo
conocimiento, y un cambio en el archivo afecta a los dos.

Requiere Ollama corriendo localmente (https://ollama.com) con el modelo descargado:
    ollama pull qwen2.5:7b
"""
import requests

from backend import config

INSTRUCCIONES = """Eres un sommelier virtual especializado en vinos y cepas de Chile.

Reglas:
1. Responde en español, en máximo 3 oraciones, de forma clara y amable.
2. Usa ÚNICAMENTE la información de la BASE DE CONOCIMIENTO de abajo. Está escrita
   en Prolog: los comentarios (%) explican el significado de cada predicado y las
   reglas (:-) permiten deducir información nueva.
3. Los átomos están sin tildes (ej: carmenere). Muestra los nombres de forma legible,
   usando nombre/2 cuando exista.
4. Si la respuesta no se puede obtener de la base, responde: "No tengo esa información
   en mi base de conocimiento." No inventes datos ni uses conocimiento externo.

BASE DE CONOCIMIENTO:
"""


class ErrorLLM(Exception):
    """Error al consultar el LLM."""


def cargar_base() -> str:
    """Lee la base de conocimiento en cada pregunta para reflejar cambios al instante."""
    return config.BASE_CONOCIMIENTO.read_text(encoding="utf-8")


def preguntar(pregunta: str) -> str:
    """Envía la pregunta a Ollama junto con la base de conocimiento."""
    cuerpo = {
        "model": config.MODELO_LLM,
        "stream": False,
        "messages": [
            {"role": "system", "content": INSTRUCCIONES + cargar_base()},
            {"role": "user", "content": pregunta},
        ],
        # temperature 0: respuestas estables; num_ctx: espacio para toda la base
        "options": {"temperature": 0, "num_ctx": config.CONTEXTO_LLM},
    }
    try:
        respuesta = requests.post(
            f"{config.OLLAMA_URL}/api/chat", json=cuerpo, timeout=config.TIMEOUT_LLM
        )
    except requests.ConnectionError as error:
        raise ErrorLLM(
            f"No se pudo conectar con Ollama en {config.OLLAMA_URL}. ¿Está abierto Ollama?"
        ) from error
    except requests.Timeout as error:
        raise ErrorLLM("El LLM tardó demasiado en responder.") from error

    if respuesta.status_code == 404:
        raise ErrorLLM(
            f"El modelo '{config.MODELO_LLM}' no está descargado. "
            f"Ejecuta: ollama pull {config.MODELO_LLM}"
        )
    if not respuesta.ok:
        raise ErrorLLM(f"Error de Ollama ({respuesta.status_code}): {respuesta.text[:200]}")

    texto = respuesta.json().get("message", {}).get("content", "").strip()
    if not texto:
        raise ErrorLLM("El LLM no entregó una respuesta.")
    return texto
