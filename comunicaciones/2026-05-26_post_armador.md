# Post redes · Armador de panel personalizado (#77 + #78)

> Novedad del 2026-05-26: Armador de panel personalizado en producción.
> Issues: #77 (MVP 4 filtros) + #78 (Aglomerado fast-follow).
> Canales: LinkedIn (versión completa) + Twitter/X (hilo) + Telegram (ángulo educativo).
> Estado: PUBLICADO por Pablo el 2026-05-26 (LinkedIn, Twitter y Telegram).
> Copy final aprobado con OKA, asset visual capturado por Pablo al publicar.

---

## Decisión editorial

Post focalizado en el Armador. El hub-and-spoke no se combina aquí: el
rediseño de navegación merece su propio post (drafts ya listos en
`comunicaciones/assets/2026-05-14_hub-and-spoke/posts.md`). En este
post va una referencia contextual al hub ("la nueva pantalla de inicio")
pero no como segundo tema, sino como escenario donde vive la nueva
funcionalidad. El follow-up del hub-and-spoke se programa para los dias
siguientes.

---

## LinkedIn (versión completa)

[NOVEDAD] 📊 Armá tu propio panel de la EPH y descargalo · shiny_eph_panel

En Estación R seguimos trabajando para hacer el análisis de panel de la EPH
más accesible. Hoy sumamos a la app pública una sección nueva: el Armador de
panel personalizado.

Hasta ahora, quien quería trabajar con el panel longitudinal de la EPH
tenía dos opciones: armar el dataset desde cero (parear personas entre
trimestres, validar consistencia, lidiar con los cortes de la serie) o
bajar el panel completo que ofrecía la app (1,86 M de filas, sin filtros).

Hoy sumamos una tercera: armá el panel aplicando los cortes que necesitás
y descargalo listo para usar. 🎯

Así funciona:

1. Entrás a la nueva tarjeta "Armá tu panel" en la pantalla de inicio.
2. Elegís los filtros que necesitás: sexo, edad, condición de actividad,
   categoría ocupacional y aglomerado.
3. Para las variables que cambian entre trimestres (condición de actividad,
   categoría ocupacional) podés elegir si el filtro aplica al estado inicial
   del dúo (t0) o al final (t1). Un solo toggle controla los dos.
4. Antes de descargar, un preview te muestra cuántas personas y cuántas
   filas va a tener tu panel, más una tabla con las primeras filas.
5. Descargás en Parquet o CSV.

Ejemplo concreto: si querés estudiar cuántas mujeres jóvenes desocupadas
al inicio del dúo (t0) pasan a estar ocupadas un trimestre después, filtrás
sexo = Mujer, edad (rango joven), condición de actividad = "Desocupado",
toggle en t0, y descargás. El dataset que llega ya tiene el pareo entre
trimestres resuelto: la transición está ahí para analizar.

Arranca con los filtros más demandados (el aglomerado se sumó en la misma
semana), y va a crecer: filtro por pobreza/indigencia está en el roadmap
cuando el cálculo de líneas esté listo.

La app sigue siendo pública y gratuita.

Mercado de trabajo argentino, panel longitudinal de la EPH, 2003 a 2025.

Intertrimestral e interanual.

Ahora también filtrable.

👉 Probala acá: https://estacionr.shinyapps.io/shiny_eph_panel/

Si la usás o la vas a usar, contanos en comentarios qué análisis tenés en
mente. 💬 Siempre nos ayuda a priorizar lo que viene.

#EPH #MercadoLaboral #RStats #DatosPúblicos #estacionR #Shiny

---

## Twitter / X (hilo de 5 tweets)

**Tweet 1 (hook)**

Sumamos el Armador de panel a shiny_eph_panel, la app pública para analizar
el mercado laboral argentino con datos de la EPH del INDEC.

Ahora podés armar tu propio subconjunto del panel longitudinal y descargarlo
listo para usar.

hilo abajo

*Screenshot sugerido: vista del Armador con filtros aplicados y preview
visible (pendiente captura, ver sección de assets).*

---

**Tweet 2 (el problema que resuelve)**

Hasta hoy había dos opciones para trabajar con el panel de la EPH:

- Armarlo desde cero (parear personas entre trimestres, validar
  consistencia, lidiar con los cortes).
- Bajar el dataset completo: 1,86 M de filas, sin filtros.

Ahora hay una tercera.

---

**Tweet 3 (cómo funciona)**

Filtros del MVP: sexo, edad, condición de actividad, categoría
ocupacional, aglomerado.

Un toggle global elige si los filtros de variables que cambian entre
trimestres se aplican al estado inicial (t0) o al final (t1) del dúo.

Preview antes de descargar: N personas / N filas + tabla.
Descarga en Parquet o CSV.

---

**Tweet 4 (ejemplo concreto)**

Ejemplo: mujeres jóvenes desocupadas en t0.

¿Cuántas pasan a estar ocupadas un trimestre después?

Filtrás sexo = Mujer, edad (rango joven), condición de actividad =
"Desocupado", toggle en t0.

Descargás. El pareo ya está resuelto. La transición, lista para analizar.

---

**Tweet 5 (CTA)**

La app es pública y gratuita.

Panel longitudinal EPH 2003 a 2025. Intertrimestral e interanual. Ahora
también filtrable.

https://estacionr.shinyapps.io/shiny_eph_panel/

#EPH #MercadoLaboral #RStats #DatosPúblicos #estacionR

---

## Telegram (ángulo educativo / alumnos Estación R)

Novedad en la app pública de análisis del mercado laboral:
https://estacionr.shinyapps.io/shiny_eph_panel/

Sumamos hoy el Armador de panel. La idea es sencilla: aplicás filtros al
panel longitudinal de la EPH que ya está armado (sexo, edad, condición de
actividad, categoría ocupacional, aglomerado) y descargás solo el
subconjunto que necesitás. En Parquet o CSV, listo para leer con R.

Lo útil para quienes trabajan con R: el archivo que se lleva ya tiene el
pareo entre trimestres resuelto. Si trabajaron alguna vez con
`eph::organize_panels()` saben que ese paso tiene su complejidad. El
Armador lo deja resuelto.

Un detalle que vale la pena conocer: para las variables que cambian entre
trimestres (condición de actividad, categoría ocupacional) hay un toggle
que elige si el filtro aplica al estado inicial del dúo (t0) o al final
(t1). Antes de descargar, un preview muestra cuántas personas tiene el
subconjunto y las primeras filas.

Si están cursando o cursaron con nosotros y tienen algún análisis de panel
en mente, esta herramienta puede ahorrarles bastante trabajo de preparación
de datos.

---

## Asset visual necesario (pendiente)

El post del Armador requiere capturas nuevas. No existe ningún screenshot
de la sección todavia. Pendiente antes de publicar:

**Captura 1 (prioritaria, LinkedIn y tweet principal)**
- Sección Armador con al menos dos filtros aplicados (sugerencia: condición
  de actividad = Ocupado, aglomerado = GBA).
- Toggle t0/t1 visible y activo.
- Preview visible: indicador "N personas / N filas" + tabla de las primeras
  filas.
- Ratio sugerido: 1200×627 (LinkedIn) o 1080×1080.

**Captura 2 (Twitter tweet 3)**
- Panel de filtros del Armador, mostrando los cinco selectores (sexo, edad,
  condición de actividad, categoría ocupacional, aglomerado) y el toggle
  global t0/t1. Foco en la UI de filtros más que en el preview.

**GIF opcional (reemplaza captura 1 si se puede producir)**
- Flujo: elegir filtros → preview actualiza → clic en Descargar. Seis a
  ocho segundos, sin scroll visible.
- Si se hace el GIF, usarlo en LinkedIn y tweet 1 en lugar de screenshot.

Resolución mínima de capturas: 1440×900, modo incógnito (sin barra de
navegador), app en su estado por defecto al cargar la sección.

---

## Notas internas

- **No mencionado a propósito:** número de versión (v0.9.1), detalles del
  re-bootstrap del microdato INDEC, nombres internos de archivos, commit
  3a7d8e2 (cierre técnico sin cara pública).
- **Hub-and-spoke:** se nombra como "pantalla de inicio" o "tarjeta" sin
  convertirlo en segundo tema. El follow-up del rediseño de navegación
  queda para post separado usando los drafts de
  `comunicaciones/assets/2026-05-14_hub-and-spoke/posts.md`.
- **Aglomerado (#78):** se integra como parte natural del Armador (los
  cinco filtros), sin anunciarlo como novedad separada. El usuario ve cinco
  filtros, no un "fast-follow".
- **Revisión integral (commit 3a7d8e2):** no se menciona. Es cierre técnico.
- **Ejemplo de uso:** el caso "mujeres jóvenes desocupadas en t0 → ocupadas
  en t1" muestra el valor longitudinal del panel (la película, no la foto).
  Combina varios filtros (sexo, edad, condición de actividad) y plantea una
  transición concreta. Confirmado por Pablo 2026-05-26.
- **Telegram vs Newsletter:** el copy de Telegram tiene ángulo educativo
  explícito (mención a `eph::organize_panels()`), pensado para alumnos y
  ex-alumnos. Si hay newsletter esta semana, se puede adaptar este copy.
