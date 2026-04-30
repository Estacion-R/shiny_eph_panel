# Backlog · shiny_eph_panel

Ideas y propuestas en evaluación · sin fecha de ejecución.

## IA en el paquete `{eph}`

> Idea conversada con Pablo el 2026-04-28. Decisión: dejar registrada, sin acción por ahora.

Tres caminos posibles para integrar IA al paquete `{eph}` de R, ordenados por impacto/factibilidad:

### 1) Asistente conversacional sobre la EPH (RAG)

- Función tipo `eph_pregunta("¿qué variable indica si una persona es asalariada informal?")` que responde con la variable, su definición y un ejemplo de código.
- Base de conocimiento: el corpus de `documentacion_eph/` (fichas + diseño de registro).
- Stack natural: `ellmer + Gemini` (mismo del proyecto `tutor_ia_intro_r`).
- **Tradeoff**: bajo riesgo · responde sobre documentación, no calcula indicadores oficiales.

### 2) Codificador automático de texto libre a CNO-2001 / CAES-Mercosur

- LLM con few-shot que clasifica descripciones libres de ocupación / rama de actividad.
- Útil para investigadores con encuestas propias que necesitan codificar al estándar INDEC.
- INDEC ya codifica ~2/3 automáticamente; el 1/3 restante es lo que un LLM podría ayudar a resolver.
- **Tradeoff**: alto impacto pero requiere validación rigurosa contra muestra etiquetada antes de confiar.

### 3) Generador de código survey-aware

- Prompt en lenguaje natural ("tasa de desempleo por sexo en GBA 1T 2025") → script con `srvyr` + ponderadores correctos.
- **Tradeoff**: el más vistoso y el más peligroso. Los LLMs alucinan con `PONDERA` vs `PONDII` y con valores de `CAT_OCUP`. Si se hiciera, sería con plantillas validadas que el LLM rellena, no que escribe libre.

### Tradeoff transversal

Cuanto más cerca esté la IA del cálculo de indicadores oficiales, más riesgo de errores con consecuencias publicadas. La opción 1 mantiene la IA en rol "explicador" y deja el cálculo al humano. Es por donde arrancaría si se decidiera avanzar.
