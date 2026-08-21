# Post redes — Novedades mayo 2026 (shiny_eph_panel)

> Comunicación combinada de dos features: descarga del panel armado + modo interanual.
> Fecha publicación: 2026-05-04 (o cuando Pablo decida)
> Canales: LinkedIn (versión completa) + Twitter (hilo adaptado)
> Telegram queda para follow-up posterior con tip técnico

---

## LinkedIn (versión completa)

[NOVEDADES 📊] - Actualización app EPH + Panel


La semana pasada compartí la reedición de shiny_eph_panel: una web app pública para analizar el mercado laboral argentino con la técnica de panel (la "película", no solo la "foto") sobre datos de la EPH del INDEC. Si te la perdiste, el link va al final.


Hoy te quería compartir que hay dos cosas nuevas. Las dos van por el mismo camino: hacer más accesible (y más profundo) el análisis del panel de la EPH.


1. Ahora podés bajar el panel longitudinal ya armado


Armar el panel de la EPH no es trivial. Hay que "matchear" a las mismas personas entre trimestres, validar consistencia y entender los cortes de la serie. Hasta ahora la app lo construía por dentro pero no lo exponía.


Desde la nueva sección Datos del sidebar lo podés descargar entero. 1,86 millones de filas, 31 columnas, de 2003 a 2025. En Parquet o CSV comprimido. Va con diccionario de variables y un aviso metodológico que vale la pena leer (consideraciones sobre los datos por parte del INDEC, panel balanceado, cobertura).


Si alguna vez quisiste analizar quién entra y sale del empleo formal en Argentina pero te frenaste en el armado del panel, esto es para vos.


2. Ahora podés comparar interanualmente, no solo entre trimestres consecutivos


La EPH permite seguir a las mismas personas entre trimestres continuos (T → T+1), pero también entre el mismo trimestre de dos años distintos (T1 2024 vs T1 2025). Esa segunda lectura neutraliza la estacionalidad y deja ver cambios estructurales que la comparación trimestral o el corte transversal anual no captan.


Hay un botón abajo a la derecha que ahora te deja alternar entre las dos vistas. Vas a poder hacer la lectura interanual para la Foto, Película y Tasas,


▸ Ejemplo concreto: cuántos asalariados informales del T1 2024 siguen siendo informales un año después.


Lo que pierde la foto trimestral, lo gana la película anual.


👉 Probá la aplicación acá: https://estacionr.shinyapps.io/shiny_eph_panel/


¡Y compartí en comentario si usas o usaste panel y cómo!


#EPH #MercadoLaboral #RStats #DatosPúblicos #estacionR

---

## Twitter / X (hilo de 4 tweets)

**Tweet 1 (hook + intro)**

Dos novedades este mes en shiny_eph_panel, la app pública para analizar el panel de la EPH del INDEC 📊

(Si te perdiste el lanzamiento de la semana pasada, link al final.)

Las dos novedades van por el mismo camino: bajar la barrera y abrir profundidad analítica.

🧵👇

---

**Tweet 2 (novedad 1)**

1/ Ahora podés bajar el panel longitudinal ya armado.

1,86 M de filas · 31 columnas · 2003 a 2025 · Parquet o CSV.

Si alguna vez quisiste hacer análisis de panel con la EPH pero te frenaste al "matchear" personas entre trimestres, esto es para vos.

---

**Tweet 3 (novedad 2)**

2/ Nuevo modo interanual: comparar el mismo trimestre entre dos años (T1 2024 vs T1 2025), no solo entre trimestres continuos.

Neutraliza la estacionalidad y deja ver cambios estructurales que el corte transversal anual no capta.

---

**Tweet 4 (ejemplo + CTA)**

Caso concreto: cuántos asalariados informales del T1 2024 seguían siendo informales un año después.

🔗 https://estacionr.shinyapps.io/shiny_eph_panel/

#EPH #MercadoLaboral #RStats #DatosPúblicos #estacionR

---

## Sugerencias de asset visual

### Para LinkedIn (1 imagen, ratio 1200×627 o cuadrado 1080×1080)

**Opción A · composición de dos capturas (recomendada):**
- Panel izquierdo: sidebar de la app con la sección **Datos** abierta, mostrando los botones de descarga (Parquet / CSV) y el preview del diccionario.
- Panel derecho: el FAB inferior derecho expandido mostrando el toggle **Intertrimestral / Interanual** activo en interanual, con la pestaña Foto detrás (matriz de transición o Sankey visible).
- Marco superior con bandera de color azul Estación R y texto "Novedades · mayo 2026".

**Opción B · una sola captura limpia:**
- La app abierta en pestaña Foto con el modo Interanual activo y el Sankey visible en pantalla completa, con un overlay sutil señalando los dos puntos nuevos (flecha al sidebar Datos, flecha al FAB).

### Para Twitter (1 imagen por tweet con novedad)

- **Tweet 2:** captura del sidebar con la sección **Datos** abierta. Foco en los botones de descarga y los metadatos (1,86 M filas, 31 columnas).
- **Tweet 3:** captura del FAB expandido con el toggle en modo Interanual + la matriz de transición o el Sankey de fondo.
- **Tweet 1 y 4:** sin imagen, o reusar la composición de LinkedIn como cover del hilo en el tweet 1.

### Notas de captura

- Capturar en pantalla 1440×900 mínimo, sin scroll visible.
- Vista por defecto del análisis: condición de actividad (la más legible de las tres).
- Para el Sankey, elegir un par de trimestres con flujos visualmente claros (T1 2024 vs T1 2025 funciona bien).
- Limpiar barra de navegador (modo incógnito o screenshot solo del viewport de la app).

---

## Notas internas

- **Combinación elegida:** las dos features comparten subtexto (expandir lo que se puede hacer con el panel de la EPH). Una baja la barrera de entrada, la otra abre dimensión analítica. Hilo conductor del post.
- **No mencionado a propósito:** versiones (0.6.0, 0.7.0), bugs/hotfixes, detalles internos de `eph::organize_panels()`.
- **Aclaración explícita:** modo interanual solo cubre Foto por ahora. Película y Tasas pendientes (Fases 2/3 issue #44).
- **Follow-up Telegram:** quedó pendiente un tip técnico breve mostrando el patrón de uso del archivo Parquet descargado (lectura en R con `arrow::read_parquet()` y un análisis de transición simple). Programar para 7-10 días después del post de redes.
