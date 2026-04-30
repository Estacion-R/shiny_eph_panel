# 10 · Ingresos y distribución

> Fuente: `pdfs/registros/EPH_registro_1T2025.pdf` · `pdfs/ingresos/nota_EPH_ingresos_06_17.pdf` · `pdfs/metodologia/eph_innovaciones_12_09.pdf`

## Período de referencia

Los ingresos relevados por la EPH son aquellos **efectivamente percibidos en el mes anterior a la entrevista**. Esta es una práctica habitual en encuestas de empleo continuas, pero tiene implicancias:

- Ingresos **no mensuales** (aguinaldo, ingresos profesionales independientes, ingresos agropecuarios estacionales) entran tal cual fueron percibidos en ese mes y **distorsionan** las distribuciones mensuales.
- Ejemplo: el aguinaldo provoca **sobreestimación del Gini** en T1 y T3 y subestimación en T2 y T4.
- INDEC trabaja en la consolidación de "ingreso personal disponible" (suavizado) para incorporar a las bases semestrales.

## Tipos de ingreso

### A nivel persona

| Variable | Significado |
|----------|------------|
| `P21` | Ingreso de la **ocupación principal** (monto en pesos) |
| `PP06C, PP06D, PP08D1, PP08D4, PP08F1, PP08F2` | Componentes de `P21` |
| `P47T` | **Ingreso total individual** = ingreso laboral (todas las ocupaciones) + ingresos no laborales personales |
| `T_VI` | Total de ingresos no laborales individuales |

### Ingresos no laborales (V1 a V21)

Captados en el cuestionario individual (lo que recibió cada persona) y en el cuestionario de hogar (lo que recibió el hogar como agregado):

- Jubilación o pensión.
- Indemnización por despido.
- Seguro de desempleo.
- Becas.
- Aguinaldos y SAC.
- Ayuda en dinero de personas no convivientes.
- Ingresos por alquileres y rentas.
- Ingresos por intereses, plazo fijo, dividendos.
- Subsidios y planes sociales del Estado (AUH, AAFF, etc.).
- Otros ingresos no detallados.

### A nivel hogar

| Variable | Significado |
|----------|------------|
| `ITF` | **Ingreso Total Familiar** = Σ `P47T` de los miembros del hogar |
| `IPCF` | **Ingreso Per Cápita Familiar** = ITF / cantidad de miembros |

> El IPCF es el indicador estándar para análisis de distribución, pobreza y comparaciones entre hogares de distinto tamaño.

## Escalas decílicas

INDEC publica varias escalas decílicas (se ordena la población o los hogares por nivel de ingreso y se divide en 10 grupos iguales):

| Escala | Sobre qué ingreso | Universo |
|--------|-------------------|----------|
| `DECCFR` | IPCF | Por región (cada región sus 10 deciles) |
| `DECINDR` | Ingreso individual `P47T` | Por región |
| `DECIFR` | ITF | Por región |
| `DECOCUR` | Ingreso de la ocupación principal `P21` | Solo ocupados, por región |
| `DECCFR_T`, `DECIFR_T`, `DECINDR_T`, `DECOCUR_T` | Versiones a nivel total nacional (no regional) | |

> Para análisis regionales se usan las decílicas regionales. Para comparaciones entre regiones, las nacionales (`_T`).

### Construcción de las decílicas

1. Se ordena a la población (o los hogares) por nivel de ingreso ascendente.
2. Se acumula el ponderador (`PONDIH`, `PONDII`, etc. según corresponda).
3. Se divide en 10 grupos con igual cantidad acumulada de ponderador.
4. Cada registro recibe el código del decil al que pertenece (1 = más pobres · 10 = más ricos).

## Indicadores de distribución del ingreso

### Coeficiente de Gini

Sobre IPCF, ingreso laboral, etc. Mide concentración en escala 0 (igualdad perfecta) a 1 (concentración total).

### Brecha de ingresos (decil 10 / decil 1)

Cociente del ingreso medio del decil más alto contra el del más bajo.

### Participación del ingreso por deciles

Distribución de los ingresos totales entre los 10 deciles (suma 100%).

### Curva de Lorenz

Representación gráfica de la concentración acumulada.

## Difusión

INDEC publica trimestralmente el informe técnico **"Evolución de la distribución del ingreso (EPH)"**, con:

- Distribución de los ingresos individuales (PEA, ocupados).
- Distribución de los ingresos de los hogares (ITF e IPCF).
- Indicadores resumen (Gini, brechas).
- Comparación con el mismo trimestre del año anterior.

## Recomendaciones para el análisis

1. **Elegir el ingreso correcto** según la pregunta: laboral (`P21`) · individual (`P47T`) · familiar (`ITF`) · per cápita (`IPCF`).
2. **Filtrar negativos y ceros** según corresponda. `P47T` puede ser 0 (sin ingresos) o negativo (no esperado, revisar).
3. Para distribución y pobreza, usar el **ponderador específico** o la base con **hot-deck imputado** + `PONDERA`.
4. **Comparaciones intertemporales**: deflactar por IPC (preferir series base reciente).
5. **Comparaciones entre aglomerados / regiones**: considerar paridad de poder de compra regional (las canastas regionales del INDEC son una proxy razonable).
6. **Outliers**: identificar y decidir tratamiento (winsorizar, top-coding, exclusión).

## Distorsiones conocidas

- **Estacionalidad por aguinaldo** (T1 y T3 inflados, T2 y T4 deprimidos en empleo formal).
- **No respuesta diferencial** (deciles altos sub-respondentes en ingresos).
- **Truncamiento por percepción**: ingresos muy altos pueden no estar bien captados.
- **Ingresos en especie** (vivienda gratuita, almuerzo en el trabajo) no se monetizan en la EPH.

## Para profundizar

- Ficha 06 · Ponderadores y no respuesta
- Ficha 09 · Pobreza e indigencia
- INDEC, *Evolución de la distribución del ingreso (EPH)* · publicación trimestral.
