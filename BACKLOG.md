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

## Armador de panel personalizado

> Idea registrada el 2026-05-17. **Diseño cerrado el 2026-05-18.**
> Documento completo: [`DISENO_ARMADOR_PANEL.md`](DISENO_ARMADOR_PANEL.md).
> Issues: #77 (épico MVP) · #78 (Aglomerado fast-follow).

Nueva tarjeta en el hub que habilita a las personas a armar su propio panel
aplicando cortes al dataset longitudinal ya procesado y descargarlo para sus
propios análisis. **Reemplaza la sección "Datos descargables"** (no duplica).

### Decisiones tomadas

- **No es #29:** comparte la capa de filtros pero el output es descarga, no
  visualización. Son features hermanas.
- **MVP con 4 filtros:** Sexo, Edad, Condición de actividad, Categoría
  ocupacional (los 4 ya en el panel runtime, no requieren tocar ETL).
- **Aglomerado: fast-follow** (issue aparte). El microdato local fue reducido a
  15 cols y no incluye `AGLOMERADO`: sumarlo exige re-bajar los 86 trimestres
  desde INDEC. No bloquea el MVP.
- **Pobreza diferida a v2**, atada al issue #30 (requiere construir el cálculo
  con canastas CBA/CBT).
- **Toggle t0/t1 global** para variables que cambian entre olas.
- **Preview:** conteo de personas/filas + tabla DT de las primeras ~20 filas.
- **Arquitectura:** filtrado server-side con Arrow lazy (no cargar 1.86 M filas
  en RAM; `collect()` solo al descargar).

### Estimación

MVP ~9-13 hs en 5 fases (F1 módulo filtros · F2 preview+descarga · F3
integración hub · F4 tests · F5 deploy). Pre-requisito #12 ya cerrado.
Fast-follow Aglomerado ~3-5 hs + descarga INDEC. v2 Pobreza atada a #30.

## Persistencia de UX con `{cookies}` (shinyworks)

> Idea evaluada el 2026-05-16. Recurso: https://cookies.shinyworks.org/

Paquete R liviano para guardar pares nombre/valor en el browser desde Shiny. Encaja como mejora menor de UX, sin backend extra.

### Casos de uso candidatos

- **Recordar última sección/tab visitada** (más relevante ahora que abrimos varios módulos con el rediseño hub-and-spoke).
- Recordar última selección de filtros (período, aglomerado, variable).
- "Novedades desde tu última visita": guardar timestamp de última sesión y resaltar cambios (nuevo trimestre, features nuevas).
- Suprimir tour/onboarding la segunda vez.

### Tradeoffs

- Si la mayoría de visitas son one-shot, persistir filtros aporta poco. Falta evidencia de retorno de usuarios.
- Alternativa nativa de Shiny: bookmarking con URL state. Más compartible que cookies, pero menos transparente para el usuario.
- GDPR: para uso técnico (preferencias, sin tracking) no exige banner, pero conviene declararlo en la nota legal.
- `shinytest2` headless no soporta cookies. Cuidar que no rompamos tests existentes.

### Recomendación

Prioridad baja. Arrancar por "recordar última sección visitada" como prueba de concepto. Si suma, extender a filtros.

### Issue asociado

GH issue: [#75](https://github.com/Estacion-R/shiny_eph_panel/issues/75) (#76 cerrado como duplicado el 2026-05-16).
