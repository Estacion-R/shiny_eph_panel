# pruebas/

Sandbox de prototipos exploratorios para `shiny_eph_panel`.

Acá van scripts standalone que **prueban una idea antes de meterla en la app productiva**: visualizaciones nuevas, transformaciones de datos, helpers, etc. No son tests automáticos (testthat) ni forman parte del bundle de despliegue (`pruebas/` está excluida en `.rscignore`).

## Convenciones

- Una carpeta por prototipo, con un nombre descriptivo (ej: `calidad_panel_pct/`).
- Cada prototipo es autocontenido: scripts numerados (`01_*.R`, `02_*.R`) que se corren en orden desde la raíz del proyecto.
- Outputs intermedios y artefactos generados (CSV, HTML, PNG) van en `output/` adentro de cada prototipo y se ignoran en git.
- Cuando un prototipo madura y se incorpora a la app, se mueve la carpeta a `_archivado/` o se borra y se referencia el commit/PR donde se integró.

## Prototipos vigentes

| Carpeta | Issue | Descripción |
|---|---|---|
| `calidad_panel_pct/` | [#36](https://github.com/Estacion-R/shiny_eph_panel/issues/36) | % de personas-panel encontradas vs total de la muestra, viz de barras 100% stacked |
