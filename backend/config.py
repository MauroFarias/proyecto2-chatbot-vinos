"""Configuración central del proyecto: rutas y variables de entorno."""
import os
from pathlib import Path

from dotenv import load_dotenv

RAIZ = Path(__file__).resolve().parent.parent
load_dotenv(RAIZ / ".env")

# Rutas
PROLOG_DIR = RAIZ / "prolog"
CHATBOT_PL = PROLOG_DIR / "chatbot.pl"
BASE_CONOCIMIENTO = PROLOG_DIR / "base_conocimiento.pl"
FRONTEND_DIR = RAIZ / "frontend"

# Prolog
SWIPL = os.getenv("SWIPL_PATH", "swipl")
TIMEOUT_PROLOG = 10  # segundos

# LLM local (Ollama)
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")
MODELO_LLM = os.getenv("MODELO_LLM", "qwen2.5:7b")
CONTEXTO_LLM = 8192   # tokens de contexto: la base completa debe caber
TIMEOUT_LLM = 120     # segundos (un modelo local puede ser lento)

# Validación de entrada
MAX_LARGO_PREGUNTA = 300
