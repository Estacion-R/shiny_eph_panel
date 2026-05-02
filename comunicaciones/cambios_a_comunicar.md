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

---

## Publicados

(vacío por ahora)
