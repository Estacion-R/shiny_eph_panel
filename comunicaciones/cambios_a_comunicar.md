# Cambios a comunicar en redes

> Registro de cambios y mejoras del dashboard que ameritan post / contenido en
> redes sociales (Twitter, LinkedIn, Instagram, Telegram). Cada entrada queda
> "pendiente" hasta que se publique. Para redacción usar los lineamientos de
> `.claude/estilo-escritura-pablo.md` y delegar al agente `estacion-r-social-media`
> cuando corresponda.

## Formato de cada entrada

```
### [fecha-implementación] · Título corto
- **Estado:** pendiente | publicado (link)
- **Qué cambió:** descripción técnica corta.
- **Valor para el usuario:** por qué le importa al investigador / docente / alumno.
- **Ángulo de copy:** 1-2 ideas de gancho narrativo.
- **Asset visual:** screenshot, GIF, link a la pestaña relevante.
- **Audiencia prioritaria:** Twitter (ciencias sociales argentinas), LinkedIn
  (analistas de datos sector público), Telegram (alumnos Estación R).
- **Issue / commit:** referencia.
```

---

## Pendientes

### 2026-05-02 · Nueva sección "Datos" para descargar el panel longitudinal

- **Estado:** pendiente
- **Qué cambió:** se agregó una sección **Datos** en el sidebar del dashboard
  donde cualquiera puede bajar el panel longitudinal completo de la EPH ya
  armado, en Parquet o CSV (gzip). Suma también un diccionario de variables
  descargable y aviso metodológico (intervención INDEC, panel balanceado,
  inconsistencias, cobertura).
- **Valor para el usuario:** el panel longitudinal de la EPH no es trivial de
  armar (hay que parear personas entre trimestres con `eph::organize_panels()`
  y validar consistencia). Hasta ahora la app lo construía internamente pero
  no lo exponía. Ahora cualquier investigador, docente o alumno puede usarlo
  como insumo en sus análisis sin reproducir la lógica de pareo.
- **Ángulo de copy:**
  1. *"Si alguna vez quisiste analizar quién entra y sale del empleo formal en
     Argentina pero te frenaste al armar el panel, esto es para vos."*
  2. *"Sumamos descarga del panel longitudinal de la EPH. 1.86 M filas, 31
     columnas, 2003 a 2025."*
  3. Educativo: explicar qué es el esquema 2-2-2 y por qué hay que parear
     personas para análisis longitudinal (con link al dashboard).
- **Asset visual:** screenshot de la sección Datos (las 2 tarjetas con dropdown
  + botón). Capturado durante implementación, pendiente de versión definitiva.
- **Audiencia prioritaria:** Twitter (ciencias sociales argentinas, mercado de
  trabajo, analistas), LinkedIn (sector público, consultores). Para Telegram
  Estación R va más adelante con un tip vinculado.
- **Issue / commit:** issue #35.

### 2026-05-03 · Toggle "Tipo de dúo": análisis interanual (T año X vs T año X+1)

- **Estado:** pendiente
- **Qué cambió:** el FAB abajo a la derecha del dashboard ahora permite
  alternar entre análisis **intertrimestral** (T → T+1, default) y
  **interanual** (T año X → T año X+1, mismo trimestre). En modo
  interanual la **Foto** (matriz de transición + tasas + Sankey) se
  recalcula sobre el panel anual armado con `eph::organize_panels(window
  = "anual")`. Los selectores de año y dúo se adaptan automáticamente.
  Película y Tasas todavía muestran datos intertrim con un aviso visible
  (Fase 2/3 pendiente).
- **Valor para el usuario:** la EPH como panel permite seguir a las
  mismas personas entre años consecutivos (gracias al esquema 2-2-2), no
  solo entre trimestres adyacentes. Comparar T1-2024 con T1-2025
  **neutraliza la estacionalidad** y hace visibles cambios estructurales
  que el corte transversal anual no captura. Hasta ahora la app solo
  habilitaba el corte intertrim; ahora cubre la dimensión interanual,
  que es la lectura más usada en publicaciones académicas y reportes
  oficiales (cuando comparan trimestre con trimestre del año anterior).
- **Ángulo de copy:**
  1. *"Lo que pierde la foto trimestral, lo gana la película anual.
     Sumamos al dashboard EPH la opción de comparar el mismo trimestre
     entre años consecutivos sobre las mismas personas."*
  2. Educativo: estacionalidad vs cambio estructural, cómo el panel 2-2-2
     habilita ambos cortes, ejemplo concreto con tasa de informalidad.
  3. Casos de uso: *"si querés saber cuántos asalariados informales del
     T1-2024 siguen siendo informales en el T1-2025, esta es la vista".*
- **Asset visual:** screenshot del toggle abierto + Foto en modo
  interanual. Pendiente versión final con copy del trimestre seleccionado.
- **Audiencia prioritaria:** Twitter + LinkedIn (analistas datos,
  ciencias sociales, sector público). Telegram Estación R con un tip
  específico de cómo se construye el panel anual con `{eph}`.
- **Issue / commit:** issue #44 (Fase 1, Foto). Fase 2 + 3 pendientes.

### 2026-05-03 · Toggle "Tipo de dúo" se extiende a Película y Tasas

- **Estado:** pendiente
- **Qué cambió:** las pestañas **Película** (línea histórica) y
  **Tasas** (Persistencia / Salida / Entrada) ahora respetan el toggle
  Tipo de dúo. En modo Interanual muestran las series anuales reales,
  ya no el cartel "no soportado". Los selectores de trimestre se
  adaptan: `T1 / T2 / T3 / T4` en lugar de `1-2 / 2-3 / 3-4 / 4-1`.
  Cierra el feature end-to-end (queda Fase 3 con Calidad + descarga).
- **Valor para el usuario:** ahora el dashboard permite responder
  preguntas como "¿la tasa de informalidad del T1 entre 2003 y 2025
  cambió estructuralmente?" sin que el ruido estacional ensucie la
  serie. Es la lectura que todo informe oficial de mercado de trabajo
  hace al comparar trimestre con trimestre del año anterior, pero
  ahora sobre el panel longitudinal (mismas personas, no muestras
  independientes).
- **Ángulo de copy:**
  1. Continuación del post anterior: *"Lo prometido es deuda. Ahora
     el toggle Interanual actúa sobre toda la app: Foto, Película y
     Tasas."*
  2. Comparativo visual: GIF del mismo análisis (informalidad
     asalariada, por ejemplo) intertrim vs interanual, mostrando cómo
     desaparece la estacionalidad en la versión anual.
  3. Técnico-educativo: hilo corto sobre cómo se construye un panel
     anual con `eph::organize_panels(window = "anual")`, qué tipo de
     atrición tiene y por qué tiene mayor n por dúo de lo que parece.
- **Asset visual:** GIF o video corto del toggle aplicado en
  Película. Idealmente con la serie de tasa de Persistencia de
  Ocupados como ejemplo (es la métrica más simple y demostrativa).
- **Audiencia prioritaria:** misma que el post anterior (Twitter +
  LinkedIn). Considerar publicar como "follow-up" del primer post,
  no como pieza nueva.
- **Issue / commit:** issue #46 (Fase 2). v0.8.0.

---

## Publicados

(vacío por ahora)
