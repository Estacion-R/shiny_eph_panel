
### Libraries
library(dplyr)
library(ggplot2)
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
library(gghighlight)
library(waiter)
library(thematic)
library(ragg)
library(tidyr)  ### pivot_wider en arma_matriz_transicion()
library(gt)     ### tabla matriz de transición en Foto