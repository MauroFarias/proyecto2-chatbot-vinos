"""Punto único para consultar cualquiera de los dos chatbots.

Lo usan tanto el servidor web (app.py) como el script de evaluación.
"""
import time

from backend import config, llm_bot, prolog_bot

MOTORES = {
    "prolog": prolog_bot.preguntar,
    "llm": llm_bot.preguntar,
}


def validar_pregunta(pregunta) -> str:
    """Limpia la pregunta y lanza ValueError si no es válida."""
    pregunta = str(pregunta or "").strip()
    if not pregunta:
        raise ValueError("La pregunta está vacía.")
    if len(pregunta) > config.MAX_LARGO_PREGUNTA:
        raise ValueError(f"La pregunta supera los {config.MAX_LARGO_PREGUNTA} caracteres.")
    return pregunta


def consultar(motor: str, pregunta: str) -> dict:
    """Consulta un motor y retorna {ok, texto, segundos}. No propaga errores del motor."""
    inicio = time.perf_counter()
    try:
        texto = MOTORES[motor](pregunta)
        ok = True
    except (prolog_bot.ErrorProlog, llm_bot.ErrorLLM) as error:
        texto = str(error)
        ok = False
    segundos = round(time.perf_counter() - inicio, 2)
    return {"ok": ok, "texto": texto, "segundos": segundos}
