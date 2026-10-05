"""Ejecuta el set de preguntas en ambos chatbots y guarda los resultados.

Uso (desde la raíz del proyecto):
    python -m evaluacion.evaluar                 # ambos motores
    python -m evaluacion.evaluar --motores prolog

Genera evaluacion/resultados.md (tabla para el informe) y resultados.json.
"""
import argparse
import json
from pathlib import Path

from backend import chatbot

CARPETA = Path(__file__).resolve().parent
ARCHIVO_PREGUNTAS = CARPETA / "preguntas.txt"


def cargar_preguntas() -> list[str]:
    lineas = ARCHIVO_PREGUNTAS.read_text(encoding="utf-8").splitlines()
    return [l.strip() for l in lineas if l.strip()]


def evaluar(motores: list[str]) -> list[dict]:
    resultados = []
    for numero, pregunta in enumerate(cargar_preguntas(), start=1):
        fila = {"n": numero, "pregunta": pregunta}
        for motor in motores:
            fila[motor] = chatbot.consultar(motor, pregunta)
        resultados.append(fila)
        print(f"[{numero}] {pregunta} -> listo")
    return resultados


def a_markdown(resultados: list[dict], motores: list[str]) -> str:
    encabezado = "| N° | Pregunta | " + " | ".join(m.upper() for m in motores) + " |"
    separador = "|---|---|" + "---|" * len(motores)
    filas = [encabezado, separador]
    for r in resultados:
        celdas = [r[m]["texto"].replace("\n", " ").replace("|", "/") for m in motores]
        filas.append(f"| {r['n']} | {r['pregunta']} | " + " | ".join(celdas) + " |")
    return "\n".join(filas) + "\n"


def main():
    parser = argparse.ArgumentParser(description="Evalúa los chatbots con el set de preguntas.")
    parser.add_argument("--motores", nargs="+", choices=list(chatbot.MOTORES),
                        default=list(chatbot.MOTORES))
    args = parser.parse_args()

    resultados = evaluar(args.motores)
    (CARPETA / "resultados.json").write_text(
        json.dumps(resultados, ensure_ascii=False, indent=2), encoding="utf-8")
    (CARPETA / "resultados.md").write_text(a_markdown(resultados, args.motores), encoding="utf-8")
    print("Resultados guardados en evaluacion/resultados.md y evaluacion/resultados.json")


if __name__ == "__main__":
    main()
