# calidad_panel_pct/

Prototipo de la viz pedida en [#36](https://github.com/Estacion-R/shiny_eph_panel/issues/36): histórico del **% de personas-panel encontradas** respecto al total de la muestra del trimestre base.

> **Cambio de forma respecto al issue original:** se descartó el "stack al 100%" y se pasó a barras simples con el eje Y acotado a 50%. Razón: por el esquema 2-2-2, el máximo conceptual es 50% (las otras dos rotaciones de la muestra t0 no van a estar en t1 por diseño, no por atrición). Mostrar el complemento como segunda serie sugería que era atrición, lo cual confunde.

## Cómo correrlo

Desde la raíz del proyecto (`shiny_eph_panel/`):

```r
source("pruebas/calidad_panel_pct/01_compute_pct.R")
source("pruebas/calidad_panel_pct/02_viz_stack100.R")
```

`01_compute_pct.R` itera sobre todos los pares trimestrales consecutivos disponibles en `df_eph_full`, arma el panel con `armo_base_panel()` y calcula:

- `n_t0` / `pondera_t0`: filas y población expandida del trimestre base
- `n_panel` / `pondera_panel`: filas y población expandida que matchearon en t1
- `pct_encontrado_*`: cocientes en %

Output: `output/pct_encontrado_historico.csv`.

`02_viz_stack100.R` lee ese CSV y genera dos versiones de la viz (highcharter HTML + ggplot PNG) en `output/`.

## A confirmar antes de integrar en la app

- **Denominador**: hoy uso el total del t0 (filtrado a `ESTADO != 0`, que es el universo válido de la EPH). ¿Conviene también ofrecer la versión sobre el total bruto (incluye no respondentes)?
- **Ventana de pareo**: por ahora solo t→t+1 (consecutivos). Cuando esté el toggle de dúos interanuales (FAB del navbar), agregar t→t+4.
- **Métrica ponderada vs sin ponderar**: para una "tasa de pareo" del operativo, el `nrow` cuenta más; para una lectura sustantiva (cuánto de la población expandida sigue), `PONDERA` cuenta más. La viz actual usa la métrica de filas; el CSV deja las dos.
