# Sommelier de Chile — Chatbot de vinos y cepas chilenas

Proyecto N°2 · Fundamentos de Inteligencia Artificial · Ingeniería Civil Informática (UNAB)

Chatbot que responde preguntas sobre vinos y cepas de Chile, implementado de dos formas
que comparten **la misma base de conocimiento**:

1. **Prolog** (lógica de primer orden): reconoce entidades y palabras clave en la pregunta e infiere la respuesta con hechos y reglas.
2. **LLM** (modelo local con Ollama, vía Python): recibe la base de conocimiento como contexto y responde en lenguaje natural restringido a ella.

Ambos se usan desde una interfaz web simple, que además permite comparar sus respuestas lado a lado.

## Estructura

```
proyecto2-chatbot-vinos/
├── prolog/
│   ├── base_conocimiento.pl   # Hechos y reglas (única fuente de conocimiento)
│   └── chatbot.pl             # Chatbot Prolog: tokeniza, detecta intención y responde
├── backend/
│   ├── config.py              # Rutas y variables de entorno
│   ├── prolog_bot.py          # Ejecuta el chatbot Prolog desde Python (subprocess)
│   ├── llm_bot.py             # Chatbot LLM (Ollama, modelo local)
│   ├── chatbot.py             # Punto único para consultar cualquier motor
│   └── app.py                 # Servidor web Flask + API REST
├── frontend/                  # Interfaz web (HTML, CSS, JS sin frameworks)
├── evaluacion/
│   ├── preguntas.txt          # Set de 20 preguntas del informe
│   └── evaluar.py             # Ejecuta las preguntas en ambos chatbots
├── tests/test_chatbot.py      # Pruebas automáticas (pytest)
└── informe/                   # Informe de desempeño (.md y .docx)
```

## Instalación

1. Instalar **SWI-Prolog** (https://www.swi-prolog.org/download/stable) y verificar con `swipl --version`.
   En Windows, si `swipl` no queda en el PATH, definir `SWIPL_PATH` en `.env`.
2. Crear entorno virtual e instalar dependencias:
   ```bash
   python -m venv .venv
   source .venv/bin/activate        # Windows: .venv\Scripts\activate
   pip install -r requirements.txt
   ```
3. Instalar **Ollama** (https://ollama.com/download), abrirlo y descargar el modelo:
   ```bash
   ollama pull qwen2.5:7b
   ```
   Es gratis y corre local, sin API key. Requiere unos 5 GB de disco y 8 GB de RAM.
   En equipos con menos memoria se puede usar `llama3.2:3b` (más liviano, menos preciso)
   cambiando `MODELO_LLM` en `.env` (copiar `.env.example` como `.env`).

## Ejecución

Todos los comandos se ejecutan desde la raíz del proyecto.

| Qué | Comando |
|---|---|
| Interfaz web | `python -m backend.app` y abrir http://127.0.0.1:5000 |
| Chatbot Prolog en consola | `cd prolog` → `swipl chatbot.pl` → `?- iniciar.` |
| Consultas Prolog directas | `swipl prolog/base_conocimiento.pl` → `?- cepa_clima_frio(C).` |
| Pruebas | `pytest` |
| Evaluación (20 preguntas) | `python -m evaluacion.evaluar` |
| Copiar respuestas del LLM al informe | `python -m evaluacion.rellenar_informe` (después de la evaluación) |

## API

`POST /api/preguntar` con `{"pregunta": "...", "motor": "prolog" | "llm" | "ambos"}`

Respuesta: `{"pregunta": "...", "respuestas": {"prolog": {"ok": true, "texto": "...", "segundos": 0.05}}}`

## Cómo modificar el conocimiento (útil para la interrogación)

Todo el conocimiento está en `prolog/base_conocimiento.pl`. **No hay que reiniciar nada**:
ambos chatbots leen el archivo en cada pregunta.

**Agregar una cepa nueva** (ej. Tempranillo):
```prolog
cepa(tempranillo, tinto).
origen(tempranillo, espana).
cuerpo(tempranillo, medio).
nota(tempranillo, cereza).
cultiva(maule, tempranillo).
marida(tempranillo, cordero).
```
El chatbot Prolog la reconoce automáticamente (las entidades se detectan a partir del nombre del átomo).
`nombre/2` es opcional; solo sirve para mostrar tildes o mayúsculas.

**Agregar un valle**: `valle(itata_costa, sur, nuble, costero_fresco).` y sus hechos `cultiva/2`.

**Agregar una regla**: por ejemplo, cepas recomendadas para un valle frío:
```prolog
apta_para_frio(C) :- cepa_clima_frio(C), cuerpo(C, ligero).
```
Para que el chatbot Prolog la use en lenguaje natural, se agrega una cláusula `intencion/2` en `chatbot.pl`
con las palabras clave que la activan (el LLM la usa sin cambios de código).

**Agregar un sinónimo** (ej. que "carmenere" escrito "carmener" funcione): en `chatbot.pl`,
`sinonimo([carmener], carmenere).`

## Arquitectura

```
Navegador ──POST /api/preguntar──► Flask (app.py) ──► chatbot.consultar()
                                                      ├─► prolog_bot ──stdin──► swipl chatbot.pl ─► base_conocimiento.pl
                                                      └─► llm_bot ──HTTP──► Ollama local (+ base_conocimiento.pl como contexto)
```
