// Lógica del frontend: envía la pregunta al backend y muestra las respuestas.
const chat = document.getElementById("chat");
const campo = document.getElementById("pregunta");
const boton = document.getElementById("enviar");

const ETIQUETAS = { prolog: "Prolog (lógica de primer orden)", llm: "LLM (Ollama)" };

function motorSeleccionado() {
  return document.querySelector('input[name="motor"]:checked').value;
}

function agregar(elemento) {
  chat.querySelector(".vacio")?.remove();
  chat.appendChild(elemento);
  elemento.scrollIntoView({ behavior: "smooth", block: "end" });
}

function crearBurbuja(clase, texto) {
  const div = document.createElement("div");
  div.className = clase;
  div.textContent = texto;
  return div;
}

function crearRespuesta(motor, resultado) {
  const div = document.createElement("div");
  div.className = `msg-bot ${motor}` + (resultado.ok ? "" : " error");
  const titulo = document.createElement("p");
  titulo.className = "motor";
  titulo.textContent = `${ETIQUETAS[motor]} · ${resultado.segundos} s`;
  const cuerpo = document.createElement("p");
  cuerpo.textContent = resultado.texto;
  div.append(titulo, cuerpo);
  return div;
}

async function enviar(texto) {
  const pregunta = texto.trim();
  if (!pregunta) return;

  agregar(crearBurbuja("msg-usuario", pregunta));
  campo.value = "";
  boton.disabled = true;
  boton.textContent = "Pensando…";

  try {
    const res = await fetch("/api/preguntar", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ pregunta, motor: motorSeleccionado() }),
    });
    const datos = await res.json();
    if (!res.ok) throw new Error(datos.error || "Error del servidor.");

    const contenedor = document.createElement("div");
    const motores = ["prolog", "llm"].filter((m) => m in datos.respuestas);
    contenedor.className = "respuestas" + (motores.length > 1 ? " doble" : "");
    motores.forEach((m) => contenedor.appendChild(crearRespuesta(m, datos.respuestas[m])));
    agregar(contenedor);
  } catch (error) {
    agregar(crearBurbuja("msg-bot error", `No se pudo obtener respuesta: ${error.message}`));
  } finally {
    boton.disabled = false;
    boton.textContent = "Preguntar";
    campo.focus();
  }
}

boton.addEventListener("click", () => enviar(campo.value));
campo.addEventListener("keydown", (e) => { if (e.key === "Enter") enviar(campo.value); });
document.getElementById("ejemplos").addEventListener("click", (e) => {
  if (e.target.tagName === "BUTTON") enviar(e.target.textContent);
});
