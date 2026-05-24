
### Libraries de runtime (lo que la app necesita cargado al arrancar).
### Cada library() acá suma RAM al proceso. Removemos todo lo que no
### se usa efectivamente para mantener el footprint bajo el límite del
### plan free de shinyapps.io (~1 GB).

library(dplyr)
library(eph)
library(shiny)
library(highcharter)
library(arrow)
library(glue)
library(bslib)
### bs_theme(brand = "_brand.yml") requiere el paquete brand.yml en runtime.
### Sin este library() explícito, rsconnect no lo detecta y el deploy falla.
library(brand.yml)
library(bsicons)
library(waiter)
library(tidyr)  ### pivot_wider en arma_matriz_transicion()
library(gt)     ### tabla matriz de transición en Foto
library(reactable)  ### backend de gt::opt_interactive() (preview ordenable del Armador, #77)
### eph ya está cargado arriba; eph::organize_labels() etiqueta el dataset del
### Armador. haven (transitivo de eph) provee as_factor() para el etiquetado.

### NOTA: ggplot2, gghighlight (solo en ETL/data_viz.R, script local de
### exploración, no runtime), thematic, ragg quedaron fuera para reducir
### RAM. Si en el futuro se vuelve a usar thematic_shiny() para sincronizar
### el theme de ggplot con bslib, agregar library(thematic) acá y reactivar
### la llamada en app.R.