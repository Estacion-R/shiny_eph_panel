# Posts redes · Rediseño hub-and-spoke

> Drafts producidos por `estacion-r-social-media` el 2026-05-16. Revisar antes de
> publicar (ver "Notas de revisión" al final).

Screenshots disponibles en este mismo folder:

- `01-hub-desktop.png` — Hub completo en desktop (1440×900).
- `02-analisis-panel-foto.png` — Análisis de panel · Condición de actividad con
  sidebar interno, badge `Intertrimestral`, filtros NLQ, value boxes, Sankey y
  matriz de transición.
- `03-toggle-modo-popover.png` — Detalle del toggle "Tipo de dúo" con popover
  "¿Qué es?" abierto (útil para destacar el cambio del FAB).
- `04-metadata.png` — Vista Metadata con sidebar interno (Glosario, Definiciones,
  Doc INDEC, Paquete eph).
- `05-datos.png` — Vista Datos con 3 tarjetas de descarga.
- `06-hub-mobile.png` — Hub responsive en mobile (390×844, iPhone 13).

---

## Twitter/X · Hilo de 4 tweets

**Tweet 1 (hook)**

> Hace un par de semanas les contaba de las dos novedades de shiny_eph_panel:
> descarga del panel armado y modo interanual. Hoy va una tercera.
>
> Rediseñamos toda la navegación. Pantalla de inicio con 4 tarjetas que
> organizan la app por lo que querés hacer, no por cómo están estructurados los
> datos.
>
> hilo abajo 🧵

*Screenshot: `01-hub-desktop.png`*

**Tweet 2 (el cambio y por qué importa)**

> 2/ El problema del sidebar viejo: mezclaba análisis de panel, descargas y
> metadata en una sola lista. Si no sabías de antemano qué hacía cada sección,
> la curva de entrada era alta.
>
> Ahora hay un Hub con 4 accesos claros. Entrás a uno, y aparece un sidebar
> interno solo con lo de esa sección.

*Screenshot: `02-analisis-panel-foto.png`*

**Tweet 3 (detalle técnico)**

> 3/ Dos cosas que no eran visibles antes y ahora sí:
>
> - Un indicador arriba del contenido que muestra siempre si el modo activo es
>   Intertrimestral o Interanual (resuelve la desconexión del botón flotante
>   que había).
> - Cada vista queda en la URL: `?v=panel&s=cond_act`. Podés compartir o
>   bookmarkear una vista específica.

*Screenshot: `03-toggle-modo-popover.png`*

**Tweet 4 (CTA)**

> 4/ La app sigue siendo pública y gratuita.
>
> Mercado de trabajo argentino · panel longitudinal EPH · 2003 a 2025.
>
> https://estacionr.shinyapps.io/shiny_eph_panel/
>
> #EPH #MercadoLaboral #RStats #DatosPúblicos #estacionR

---

## LinkedIn

> [NOVEDADES 📊] · Rediseño de navegación · shiny_eph_panel
>
> Hace un par de semanas les compartimos dos novedades de shiny_eph_panel: la
> descarga del panel longitudinal ya armado y el modo de análisis interanual.
> Hoy va una tercera y va por un camino distinto.
>
> shiny_eph_panel estrena pantalla de inicio.
>
> El cambio puede parecer cosmético, pero responde a algo concreto: el sidebar
> viejo listaba secciones ordenadas por la lógica interna del dato (panel,
> transversal, metadata, datos). No por lo que el investigador o analista
> quiere hacer cuando entra.
>
> Reordenamos el dashboard pensando en cómo se usa, no en cómo está organizado
> el dato.
>
> Ahora la pantalla de entrada tiene 4 tarjetas grandes:
>
> ▸ Análisis de panel (los 3 ejes + calidad de la muestra)
> ▸ Análisis transversal (próximamente)
> ▸ Metadata (glosario, definiciones, links)
> ▸ Datos (descargas del panel longitudinal)
>
> Al entrar a cualquiera de ellas aparece un sidebar interno con las
> sub-secciones. Los filtros globales quedan a la vista sin perderlos con el
> scroll.
>
> Dos cosas que antes no estaban y ahora sí:
>
> El toggle que alterna entre modo Intertrimestral e Interanual dejó de ser un
> botón flotante sin contexto. Ahora hay un indicador arriba del contenido que
> muestra siempre el modo activo. Era una de las fricciones más frecuentes:
> usabas el toggle pero no quedaba claro si el output ya había reflejado el
> cambio.
>
> Las URLs reflejan la vista activa (`?v=panel&s=cond_act`). Podés compartir o
> bookmarkear directamente una sección específica de la app.
>
> La app sigue siendo pública y gratuita. Mercado de trabajo argentino, panel
> longitudinal de la EPH, 2003 a 2025.
>
> 👉 Probala acá: https://estacionr.shinyapps.io/shiny_eph_panel/
>
> Y si la usás, contanos en comentarios qué análisis estás haciendo con ella.
>
> #EPH #MercadoLaboral #RStats #Shiny #DatosPúblicos #estacionR

*Screenshot principal: `01-hub-desktop.png` (formato 1200×627 o 1080×1080).*
*Opcional segunda imagen: `02-analisis-panel-foto.png` recortada al sidebar
interno + badge contextual.*

---

## Telegram · Canal Estación R

> Otra novedad en shiny_eph_panel, después de las dos del mes pasado
> (descarga del panel armado y modo interanual).
>
> La navegación cambió bastante: ahora cuando entrás hay una pantalla con 4
> tarjetas grandes en lugar del sidebar lateral de antes. Cada tarjeta lleva a
> una sección (análisis de panel, metadata, descargas), y dentro aparece un
> menú lateral solo con lo de esa sección.
>
> Dos cosas útiles para quienes la usan:
>
> - El toggle Intertrimestral / Interanual ahora tiene un indicador visible
>   arriba del contenido. Ya no queda duda de en qué modo está la app cuando
>   mirás los gráficos.
> - Las URLs ahora reflejan la vista activa. Si encontrás un análisis que te
>   interesa compartir o volver a ver, guardás el link y llega directo ahí.
>
> La app sigue siendo pública: https://estacionr.shinyapps.io/shiny_eph_panel/

*Screenshot sugerido (opcional): `01-hub-desktop.png` o `06-hub-mobile.png`
según foque desktop o mobile.*

---

## Notas de revisión

Drafts ajustados con las dos correcciones de Pablo (2026-05-16):

- **Continuidad narrativa** agregada al inicio de los 3 posts referenciando los
  cambios publicados en el post combinado del 2026-05-04 (sección Datos +
  modo interanual).
- **"badge"** traducido a **"indicador"** en los 3 posts.

Pendiente antes de publicar:

- Recortar las screenshots si LinkedIn pide ratio específico (sugerencia: 1200×627
  o 1080×1080). Para Twitter el ratio 16:9 o 1:1 funciona; las capturas full-page
  pueden necesitar crop.
- Considerar acompañar el post de Telegram con una versión vertical de
  `06-hub-mobile.png` (ya está en orientación correcta).
- Si querés versión "antes/después" con el sidebar viejo: requeriría desplegar
  temporalmente una versión legacy, no la tengo capturada. Avisame y la armo
  desde branch master pre-refactor.
