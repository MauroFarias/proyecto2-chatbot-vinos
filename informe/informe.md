---
title: "Proyecto N°2: Diseño de un Agente Inteligente que usa conocimiento"
subtitle: "Sommelier de Chile — Chatbot de vinos y cepas chilenas"
author:
  - "[Integrante 1] · [Integrante 2] · [Integrante 3]"
date: "Fundamentos de Inteligencia Artificial — Ingeniería Civil Informática, Universidad Andrés Bello — 4 de octubre de 2026"
lang: es
---

# 1. Dominio seleccionado

El dominio elegido son los **vinos y cepas de Chile**: las principales variedades de uva que se cultivan en el país, los valles vitivinícolas donde se producen, sus características (color, cuerpo, aromas, origen) y los maridajes recomendados con distintos platos.

Se escogió este dominio por tres razones:

1. **Estructura relacional clara.** El conocimiento se expresa naturalmente como relaciones entre objetos (una cepa *se cultiva en* un valle, un valle *pertenece a* una región, una cepa *marida con* un plato), lo que se ajusta bien a la lógica de primer orden.
2. **Permite inferencia real.** Además de consultar hechos, es posible deducir información que no está escrita explícitamente, como qué cepas se dan en climas fríos o qué cepas comparten dos valles.
3. **Relevancia local y verificabilidad.** Es un tema conocido en Chile, no relacionado con la informática, con información pública fácil de contrastar.

# 2. Modelamiento del conocimiento en lógica de primer orden

## 2.1 Dominio del discurso y constantes

El universo contiene cepas (`carmenere`, `pais`, `sauvignon_blanc`, …), valles (`maipo`, `colchagua`, `itata`, …), regiones (`ohiggins`, `nuble`, …), países de origen (`francia`, `espana`, …), climas, zonas, notas aromáticas y platos.

## 2.2 Predicados

| Predicado | Significado |
|---|---|
| Cepa(c, col) | c es una cepa de color col (tinto o blanco) |
| Origen(c, p) | la cepa c proviene del país p |
| Cuerpo(c, k) | la cepa c tiene cuerpo k (ligero, medio o intenso) |
| Nota(c, n) | la cepa c presenta la nota aromática n |
| Valle(v, z, r, k) | v es un valle de la zona z, región r y clima k |
| Cultiva(v, c) | en el valle v se cultiva la cepa c |
| Marida(c, p) | la cepa c acompaña bien al plato p |
| ClimaFrio(k) | k es un clima frío o fresco |
| TempServicio(col, a, b) | los vinos de color col se sirven entre a y b °C |
| CepaEmblematica(c), CepaPatrimonial(c), CepaMasPlantada(c) | hechos destacados |

La base contiene 14 cepas, 13 valles, 38 hechos `Cultiva`, 40 notas aromáticas y 27 maridajes (cerca de 170 hechos) más 12 reglas.

## 2.3 Reglas (conocimiento inferido)

| Regla en lógica de primer orden | Prolog |
|---|---|
| ∀v ∀k (Valle(v, \_, \_, k) → Clima(v, k)) (análogo para Zona y Region) | `clima(V, K) :- valle(V, _, _, K).` |
| ∀v ∀k (Clima(v, k) ∧ ClimaFrio(k) → ValleFrio(v)) | `valle_frio(V) :- clima(V, K), clima_frio(K).` |
| ∀c (∃v (Cultiva(v, c) ∧ ValleFrio(v)) → CepaClimaFrio(c)) | `cepa_clima_frio(C) :- cultiva(V, C), valle_frio(V).` |
| ∀c ∀r (∃v (Cultiva(v, c) ∧ Region(v, r)) → CepaEnRegion(c, r)) | `cepa_en_region(C, R) :- cultiva(V, C), region(V, R).` |
| ∀v₁ ∀v₂ ∀c (Cultiva(v₁, c) ∧ Cultiva(v₂, c) ∧ v₁ ≠ v₂ → CepaComun(v₁, v₂, c)) | `cepa_comun(V1, V2, C) :- cultiva(V1, C), cultiva(V2, C), V1 \= V2.` |
| ∀p ∀c (Marida(c, p) → Recomendar(p, c)) | `recomendar(Plato, C) :- marida(C, Plato).` |
| ∀c ∀col ∀a ∀b (Cepa(c, col) ∧ TempServicio(col, a, b) → Temperatura(c, a, b)) | `temperatura(C, Min, Max) :- cepa(C, Color), temperatura_servicio(Color, Min, Max).` |
| ∀c (Origen(c, espana) → CepaColonial(c)) | `cepa_colonial(C) :- origen(C, espana).` |
| ∀c (Cepa(c, tinto) → EsTinta(c)) | `es_tinta(C) :- cepa(C, tinto).` |

**Ejemplo de inferencia.** De los hechos Cultiva(casablanca, pinot_noir), Valle(casablanca, aconcagua, valparaiso, costero_fresco) y ClimaFrio(costero_fresco), por *modus ponens* se obtiene ValleFrio(casablanca) y luego CepaClimaFrio(pinot_noir). Prolog realiza esta deducción por resolución SLD con encadenamiento hacia atrás.

# 3. Arquitectura del sistema

```
Navegador
   │  POST /api/preguntar
   ▼
Flask (backend/app.py) ─► chatbot.consultar()
   ├─► prolog_bot.py ─► swipl chatbot.pl ─► base_conocimiento.pl
   └─► llm_bot.py ─► Ollama local (+ base_conocimiento.pl)
```

**Fuente única de conocimiento.** Ambos chatbots usan el archivo `prolog/base_conocimiento.pl`. El chatbot Prolog lo consulta mediante inferencia; el chatbot LLM lo recibe completo en su *prompt* de sistema. Así, un cambio en el conocimiento afecta a ambas versiones sin modificar código, y la comparación entre ellas es justa.

## 3.1 Chatbot Prolog

El procesamiento de una pregunta sigue cuatro pasos:

1. **Tokenización:** se pasa a minúsculas, se quitan tildes y puntuación, y se separa en palabras.
2. **Reconocimiento de entidades:** se buscan cepas, valles, platos y países en la pregunta. Cada entidad se reconoce automáticamente a partir de su átomo (`cabernet_sauvignon` → "cabernet sauvignon") o de un sinónimo (`cabernet`, `francés`). Por eso, una cepa nueva agregada a la base se reconoce sin modificar el chatbot.
3. **Detección de intención:** las cláusulas `intencion/2` se prueban en orden; cada una combina las entidades encontradas con palabras clave (por ejemplo, cepa + "proviene" → origen).
4. **Respuesta:** se consulta la base (hechos y reglas) y se construye una oración en español.

Se resolvió además una ambigüedad propia del dominio: "país" puede ser la cepa País o la palabra nación. Si va precedida de "qué", "cada", "mi", etc., se interpreta como nación.

## 3.2 Chatbot LLM

Se usa el modelo de código abierto **Qwen 2.5 (7B)**, ejecutado localmente con **Ollama** y consultado desde Python mediante su API HTTP, con temperatura 0 para obtener respuestas estables. Se eligió un modelo local porque es gratuito, no requiere conexión a internet ni API key, y los datos no salen del equipo. El contexto se amplió a 8.192 tokens para que la base de conocimiento completa quepa en cada consulta. El *prompt* de sistema define el rol (sommelier virtual), exige responder solo con la base de conocimiento y entrega una frase fija para cuando la información no está disponible, con el fin de reducir alucinaciones. El modelo se puede cambiar en `.env` (por ejemplo, `llama3.2:3b` en equipos con poca memoria).

## 3.3 Interfaz web

Interfaz en HTML, CSS y JavaScript sin frameworks, servida por Flask. Permite elegir el motor (Prolog, LLM o ambos en paralelo), muestra el tiempo de respuesta de cada uno e incluye preguntas de ejemplo. La API valida la entrada (pregunta vacía, largo máximo, motor válido) y los errores de cada motor se informan sin detener al otro.

## 3.4 Buenas prácticas aplicadas

Separación por módulos con una responsabilidad cada uno, configuración centralizada con variables de entorno (el archivo `.env` no se versiona), manejo explícito de errores con excepciones propias, pruebas automáticas con `pytest` y un script reproducible de evaluación (`python -m evaluacion.evaluar`).

# 4. Set de 20 preguntas y respuestas

Las respuestas se obtuvieron ejecutando `python -m evaluacion.evaluar`, que guarda los resultados en `evaluacion/resultados.md`. Las preguntas cubren todos los tipos de consulta e incluyen casos difíciles a propósito: una pregunta fuera de la base (20), una con error ortográfico (19) y una que pide una explicación histórica no registrada (9).

| N° | Pregunta | Respuesta Prolog | Respuesta LLM |
|---|---|---|---|
| 1 | ¿Qué cepas se cultivan en el valle de Colchagua? | En el valle de Colchagua se cultivan: Carménère, Cabernet Sauvignon, Syrah y Malbec. | [COMPLETAR] |
| 2 | ¿En qué valles se produce Carménère? | Carménère se cultiva en los valles de: Aconcagua, Maipo, Cachapoal y Colchagua. | [COMPLETAR] |
| 3 | ¿De dónde proviene la cepa País? | País proviene de España. | [COMPLETAR] |
| 4 | ¿Qué vino me recomiendas para acompañar un ceviche? | Para acompañar ceviche te recomiendo: Sauvignon Blanc. | [COMPLETAR] |
| 5 | ¿Qué notas aromáticas tiene el Sauvignon Blanc? | Las notas aromáticas de Sauvignon Blanc son: cítricos, pasto recién cortado y maracuyá. | [COMPLETAR] |
| 6 | ¿Cómo es el clima del valle de Casablanca? | El valle de Casablanca tiene un clima costero fresco. | [COMPLETAR] |
| 7 | ¿En qué región está el valle del Maipo? | El valle de Maipo está en la Región Metropolitana. | [COMPLETAR] |
| 8 | ¿Se cultiva Pinot Noir en el valle de Leyda? | Sí, Pinot Noir se cultiva en el valle de Leyda. | [COMPLETAR] |
| 9 | ¿Por qué el Carménère se confundió con el Merlot durante años? | Comparación: Carménère es tinto, de cuerpo medio, origen Francia y notas de pimentón rojo, especias y frutos rojos maduros. Merlot es tinto, de cuerpo medio, origen Francia y notas de ciruela, cereza y chocolate. | [COMPLETAR] |
| 10 | ¿Cuál es la cepa emblemática de Chile? | La cepa emblemática de Chile es Carménère. | [COMPLETAR] |
| 11 | ¿Qué cepas comparten el Maipo y Colchagua? | Las cepas que comparten Colchagua y Maipo son: Carménère y Cabernet Sauvignon. | [COMPLETAR] |
| 12 | ¿A qué temperatura se sirve un Syrah? | Syrah se sirve entre 16 y 18 °C. | [COMPLETAR] |
| 13 | ¿Qué valles pertenecen a la zona sur? | Los valles de la zona sur son: Itata, Biobío y Malleco. | [COMPLETAR] |
| 14 | ¿Qué cepas son de origen francés? | Las cepas originarias de Francia son: Cabernet Sauvignon, Carménère, Merlot, Syrah, Pinot Noir, Cinsault, Malbec, Sauvignon Blanc y Chardonnay. | [COMPLETAR] |
| 15 | ¿Qué cepas se dan en valles de clima frío? | Las cepas que se cultivan en valles de clima frío o fresco son: Chardonnay, Cinsault, Gewürztraminer, Moscatel de Alejandría, País, Pinot Noir, Riesling y Sauvignon Blanc. | [COMPLETAR] |
| 16 | ¿Qué vino tinto ligero me recomiendas? | Cepas de vino tinto con cuerpo ligero: Pinot Noir, País y Cinsault. | [COMPLETAR] |
| 17 | ¿Cuál es la diferencia entre un Carménère y un Merlot? | Comparación: Carménère es tinto, de cuerpo medio, origen Francia y notas de pimentón rojo, especias y frutos rojos maduros. Merlot es tinto, de cuerpo medio, origen Francia y notas de ciruela, cereza y chocolate. | [COMPLETAR] |
| 18 | ¿El Cabernet va con sushi? | No tengo registrado que Cabernet Sauvignon marida con sushi. Para ese plato recomiendo: Riesling. | [COMPLETAR] |
| 19 | ¿Qué valles producen carmener? | Conozco estos valles vitivinícolas: Elqui, Limarí, Aconcagua, Casablanca, Leyda, Maipo, Cachapoal, Colchagua, Curicó, Maule, Itata, Biobío y Malleco. | [COMPLETAR] |
| 20 | ¿Qué vino ganó un premio internacional en 2020? | Lo siento, no tengo información sobre eso en mi base de conocimiento. Prueba preguntando por una cepa, un valle o un plato. | [COMPLETAR] |

# 5. Análisis de desempeño

## 5.1 Criterios

Cada respuesta se clasifica como **Correcta** (responde lo preguntado según la base), **Parcial** (información correcta pero incompleta o que no responde exactamente) o **Incorrecta** (no responde lo preguntado o entrega información errónea). En las preguntas fuera de la base, la respuesta correcta es reconocer que no se tiene la información.

## 5.2 Resultados

| N° | Tipo de consulta | Prolog | LLM |
|---|---|---|---|
| 1 | Cepas de un valle | Correcta | [COMPLETAR] |
| 2 | Valles de una cepa | Correcta | [COMPLETAR] |
| 3 | Origen (ambigüedad "País") | Correcta | [COMPLETAR] |
| 4 | Maridaje por plato | Correcta | [COMPLETAR] |
| 5 | Notas aromáticas | Correcta | [COMPLETAR] |
| 6 | Clima de un valle | Correcta | [COMPLETAR] |
| 7 | Región de un valle | Correcta | [COMPLETAR] |
| 8 | Verificación sí/no | Correcta | [COMPLETAR] |
| 9 | Explicación fuera de la base | Incorrecta | [COMPLETAR] |
| 10 | Hecho destacado | Correcta | [COMPLETAR] |
| 11 | Inferencia: cepas en común | Correcta | [COMPLETAR] |
| 12 | Inferencia: temperatura heredada | Correcta | [COMPLETAR] |
| 13 | Valles por zona | Correcta | [COMPLETAR] |
| 14 | Origen con adjetivo ("francés") | Correcta | [COMPLETAR] |
| 15 | Inferencia: cepas de clima frío | Correcta | [COMPLETAR] |
| 16 | Filtro combinado (color + cuerpo) | Correcta | [COMPLETAR] |
| 17 | Comparación de cepas | Parcial | [COMPLETAR] |
| 18 | Maridaje cepa + plato | Correcta | [COMPLETAR] |
| 19 | Error ortográfico | Incorrecta | [COMPLETAR] |
| 20 | Fuera de la base | Correcta | [COMPLETAR] |
| | **Total correctas** | **17 / 20 (85 %)** | **[COMPLETAR]** |

**Tiempo de respuesta.** Prolog responde en torno a 0,05 s por pregunta (medido por el sistema). LLM: [COMPLETAR con el tiempo promedio de `resultados.json`].

## 5.3 Análisis del chatbot Prolog

El chatbot Prolog acierta en todas las preguntas que corresponden a una intención programada, incluidas las que requieren inferencia (11, 12 y 15) y la desambiguación de "País" (3). Sus respuestas son exactas y siempre trazables a hechos de la base.

Sus fallas muestran los límites del enfoque por palabras clave:

- **Pregunta 9:** detecta dos cepas y aplica la intención "comparar", pero la pregunta pedía una explicación histórica que no está en la base. Lo correcto habría sido indicar que no tiene esa información: es un falso positivo de la detección de intención.
- **Pregunta 17:** entrega los atributos de ambas cepas, pero no sintetiza la diferencia (no dice, por ejemplo, que ambas son de cuerpo medio y que difieren en sus aromas).
- **Pregunta 19:** "carmener" no coincide con ningún patrón, por lo que no reconoce la cepa y cae en una intención genérica que lista todos los valles.

## 5.4 Análisis del chatbot LLM

[COMPLETAR tras ejecutar la evaluación. Puntos a revisar en las respuestas: si en la 19 reconoce "carmener" como Carménère; si en la 9 y la 20 declara que no tiene la información o agrega datos externos (alucinación); si en la 15 llega a la misma lista que Prolog al aplicar la regla de clima frío; y si en la 17 sintetiza la diferencia.]

# 6. Fortalezas y debilidades

| | Prolog (lógica de primer orden) | LLM |
|---|---|---|
| **Fortalezas** | Respuestas exactas y explicables (cada una se puede rastrear a hechos y reglas). Comportamiento determinista. Muy rápido y con requisitos mínimos de hardware. Nunca inventa información. Las reglas permiten deducir conocimiento nuevo de forma garantizada. | Entiende lenguaje natural flexible: sinónimos, paráfrasis y errores ortográficos. Puede sintetizar y comparar. Respuestas más naturales. No requiere programar cada tipo de pregunta. Gratuito y sin conexión a internet. |
| **Debilidades** | Comprensión limitada a palabras clave y patrones; cada tipo de pregunta nuevo requiere programar una intención. Sensible a errores ortográficos. Puede elegir una intención equivocada (falso positivo). Respuestas con plantillas rígidas. | Puede alucinar o mezclar conocimiento externo pese a las instrucciones. No es completamente determinista ni explicable. Al ser un modelo local pequeño, es más lento que Prolog, depende del hardware del equipo y comete más errores que un modelo comercial grande. Puede cometer errores al aplicar reglas lógicas largas. |

# 7. Conclusiones

[Revisar y completar con los resultados del LLM.]

La lógica de primer orden resultó adecuada para un dominio relacional como el de los vinos chilenos: con cerca de 170 hechos y 12 reglas, el chatbot Prolog responde correctamente el 85 % del set, incluyendo preguntas que requieren inferencia. Su principal limitación no está en el razonamiento sino en la comprensión del lenguaje natural, que depende de palabras clave.

El enfoque con LLM complementa esa debilidad, ya que interpreta preguntas formuladas con libertad, pero sacrifica garantías: sus respuestas no son verificables paso a paso y pueden contener información que no está en la base. Compartir una única base de conocimiento entre ambas versiones permitió compararlas en igualdad de condiciones y mantener el conocimiento en un solo lugar.

# 8. Propuestas de mejora

1. **Tolerancia a errores ortográficos en Prolog:** comparar las palabras de la pregunta con las entidades usando distancia de edición (Levenshtein), aceptando coincidencias con una o dos letras de diferencia. Resolvería la pregunta 19.
2. **Intención "no sé" más estricta:** exigir palabras clave compatibles antes de aplicar la intención "comparar" y responder que no hay información cuando la pregunta contiene términos como "por qué" o "historia" que la base no cubre. Evitaría el falso positivo de la pregunta 9.
3. **Comparaciones con síntesis:** que la intención de comparar destaque explícitamente los atributos en común y las diferencias.
4. **Arquitectura híbrida:** usar el LLM solo para interpretar la pregunta y traducirla a una consulta Prolog (por ejemplo, `cepa_comun(maipo, colchagua, C)`), y que Prolog calcule la respuesta. Combina la flexibilidad del lenguaje natural con respuestas exactas y explicables.
5. **Memoria de conversación:** guardar el historial para resolver preguntas de seguimiento como "¿y con qué plato va?".
6. **Ampliar la base:** agregar viñas, denominaciones de origen, historia de las cepas (por ejemplo, el redescubrimiento del Carménère) y precios aproximados.
7. **Evaluación automática:** guardar la respuesta esperada de cada pregunta y calcular la precisión de ambos chatbots automáticamente en `evaluar.py`.
