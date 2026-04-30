# Repositorio de conocimiento sobre la EPH (INDEC)

Corpus curado de documentación oficial sobre la **Encuesta Permanente de Hogares (EPH)** del INDEC. Pensado como referencia para el dashboard `shiny_eph_panel`, los cursos de Estación R que usan EPH y cualquier proyecto que requiera explotar los microdatos de la encuesta.

> Fuente primaria: [INDEC · EPH · Total urbano](https://www.indec.gob.ar/indec/web/Nivel4-Tema-4-31-58)
> Última actualización del corpus: 2026-04-28

---

## Cómo usar este repositorio

```
documentacion_eph/
├── README.md                  ← este archivo (índice)
├── fichas/                    ← fichas temáticas resumidas (Markdown)
├── pdfs/                      ← PDFs originales del INDEC, por tema
│   ├── metodologia/
│   ├── muestra/
│   ├── registros/
│   ├── informalidad/
│   ├── pobreza/
│   ├── ingresos/
│   ├── cuestionarios/
│   ├── clasificadores/
│   └── calendario/
└── txt/                       ← texto extraído de los PDFs (para grep/búsqueda)
```

- Las **fichas** sintetizan los temas clave en español, con las definiciones canónicas y los puntos críticos para el análisis (incluyen referencias al PDF de origen).
- Los **PDFs** son los documentos oficiales del INDEC tal como se descargaron del sitio.
- El **texto extraído** (`txt/`) sirve para hacer `grep` rápido sobre todo el corpus.

---

## Fichas temáticas

| # | Tema | Ficha |
|---|------|-------|
| 01 | Qué es la EPH (objetivos, historia, reformulación 2003) | [`fichas/01_que_es_la_eph.md`](fichas/01_que_es_la_eph.md) |
| 02 | Diseño muestral (estratos, etapas, marco muestral) | [`fichas/02_diseno_muestral.md`](fichas/02_diseno_muestral.md) |
| 03 | Panel y esquema de rotación 2-2-2 | [`fichas/03_panel_y_rotacion.md`](fichas/03_panel_y_rotacion.md) |
| 04 | Aglomerados, regiones y cobertura | [`fichas/04_aglomerados_y_cobertura.md`](fichas/04_aglomerados_y_cobertura.md) |
| 05 | Cuestionarios y estructura de bases | [`fichas/05_cuestionarios_y_variables.md`](fichas/05_cuestionarios_y_variables.md) |
| 06 | Ponderadores y tratamiento de no respuesta | [`fichas/06_ponderadores_y_no_respuesta.md`](fichas/06_ponderadores_y_no_respuesta.md) |
| 07 | Mercado laboral (tasas básicas, condición de actividad) | [`fichas/07_mercado_laboral.md`](fichas/07_mercado_laboral.md) |
| 08 | Informalidad laboral (marco conceptual y operacionalización 2023+) | [`fichas/08_informalidad.md`](fichas/08_informalidad.md) |
| 09 | Pobreza e indigencia (CBA, CBT, líneas) | [`fichas/09_pobreza_e_indigencia.md`](fichas/09_pobreza_e_indigencia.md) |
| 10 | Ingresos y distribución | [`fichas/10_ingresos_y_distribucion.md`](fichas/10_ingresos_y_distribucion.md) |
| 11 | Clasificadores (CNO-2001, CAES-Mercosur) | [`fichas/11_clasificadores.md`](fichas/11_clasificadores.md) |
| 12 | Calendario y difusión | [`fichas/12_calendario_y_difusion.md`](fichas/12_calendario_y_difusion.md) |
| 99 | Glosario de variables y conceptos clave | [`fichas/glosario.md`](fichas/glosario.md) |

---

## Documentos descargados (mapa rápido)

### Metodología general

- `pdfs/metodologia/metodologia_eph_continua.pdf` · La nueva EPH 2003 (documento fundacional · 4.000 líneas).
- `pdfs/metodologia/Gacetilla_EPHContinua.pdf` · Gacetilla de cambios metodológicos 2003.
- `pdfs/metodologia/Anex1_EPHContinua_Pruebas.pdf` · Anexo 1: pruebas metodológicas (PET, PERC).
- `pdfs/metodologia/eph_innovaciones_12_09.pdf` · Innovaciones 12/2009 (calibración, hot-deck).
- `pdfs/metodologia/EPH_consideraciones_metodologicas_2t20.pdf` · Tratamiento del 2T 2020 (pandemia COVID).
- `pdfs/metodologia/listado_metodologias.pdf` · Listado completo de docs metodológicos del INDEC.

### Muestra y panel

- `pdfs/muestra/eph_muestras_74-03.pdf` · Actualización del diseño muestral 1974-2003.

### Registros y bases

- `pdfs/registros/EPH_registro_1T2025.pdf` · Diseño de registros vigente (bases preliminares Hogar y Personas).
- `pdfs/registros/EPH_tot_urbano_estructura_bases_2025.pdf` · Estructura de bases del total urbano.

### Cuestionarios

- `pdfs/cuestionarios/EPHContinua_CIndividual.pdf` · Cuestionario individual.
- `pdfs/cuestionarios/EPH_Hogar.pdf` · Cuestionario hogar.

### Informalidad

- `pdfs/informalidad/metodologia_informalidad_laboral_2025.pdf` · Metodología INDEC N° 43 (abril 2025).

### Pobreza

- `pdfs/pobreza/EPH_metodologia_22_pobreza.pdf` · Metodología INDEC N° 22 (medición de pobreza e indigencia).

### Ingresos

- `pdfs/ingresos/nota_EPH_ingresos_06_17.pdf` · Documento técnico sobre no respuesta de ingresos.

### Clasificadores

- `pdfs/clasificadores/EPHcontinua_CNO2001_reducido_09.pdf` · CNO-2001 reducido.

### Calendario

- `pdfs/calendario/calendario_1sem2026.pdf` · Calendario de difusión 1° semestre 2026.
- `pdfs/calendario/calendario_2sem2026.pdf` · Calendario de difusión 2° semestre 2026.

---

## Enlaces oficiales del INDEC (vivos)

| Recurso | URL |
|---------|-----|
| Página EPH · Total urbano | https://www.indec.gob.ar/indec/web/Nivel4-Tema-4-31-58 |
| Página EPH · Distribución del ingreso | https://www.indec.gob.ar/indec/web/Nivel4-Tema-4-31-60 |
| Bases de datos EPH (descarga) | https://www.indec.gob.ar/indec/web/Institucional-Indec-bases_de_datos_eph_amp |
| Bases EPH tabulado continua | https://www.indec.gob.ar/indec/web/Institucional-Indec-bases_EPH_tabulado_continua |
| Catálogo de metodologías | https://www.indec.gob.ar/indec/web/Institucional-Indec-Metodologias |
| Calendario INDEC | https://www.indec.gob.ar/indec/web/Calendario-Fecha-0 |
| Redatam EPH | https://redatam.indec.gob.ar/redarg/encuestas/EPH/RpIndex.htm |

---

## Cómo se construyó este corpus

1. Se exploró la página oficial de EPH del INDEC y se mapearon enlaces a documentos metodológicos y bases.
2. Se buscaron URLs específicas para los temas críticos (panel, informalidad, pobreza, muestra, registros, ingresos, clasificadores, cuestionarios, calendario).
3. Se descargaron los PDFs oficiales (17 documentos · ~12 MB) con `curl`.
4. Se extrajo texto plano con `pdftotext -layout` (en `txt/`) para indexación y consulta rápida.
5. Se redactaron fichas temáticas en Markdown a partir del contenido oficial, manteniendo la terminología del INDEC.

Para refrescar el corpus, ver `scripts/actualizar_corpus.sh` (a crear cuando se necesite reproducibilidad).
