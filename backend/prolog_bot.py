"""Puente entre Python y el chatbot Prolog.

Ejecuta SWI-Prolog como proceso externo: carga chatbot.pl, llama a main/0
y le envía la pregunta por la entrada estándar. Así no se necesitan
librerías extra y cualquier cambio en los .pl se refleja en la siguiente pregunta.
"""
import subprocess

from backend import config


class ErrorProlog(Exception):
    """Error al ejecutar el chatbot Prolog."""


def preguntar(pregunta: str) -> str:
    """Envía la pregunta al chatbot Prolog y retorna su respuesta."""
    comando = [config.SWIPL, "-q", "-g", "main", "-t", "halt", str(config.CHATBOT_PL)]
    try:
        resultado = subprocess.run(
            comando,
            input=pregunta,
            capture_output=True,
            text=True,
            encoding="utf-8",
            timeout=config.TIMEOUT_PROLOG,
        )
    except FileNotFoundError as error:
        raise ErrorProlog(
            "No se encontró SWI-Prolog. Instálalo o define SWIPL_PATH en el archivo .env."
        ) from error
    except subprocess.TimeoutExpired as error:
        raise ErrorProlog("Prolog tardó demasiado en responder.") from error

    respuesta = resultado.stdout.strip()
    if resultado.returncode != 0 or not respuesta:
        raise ErrorProlog(f"Prolog no pudo responder: {resultado.stderr.strip()}")
    return respuesta
