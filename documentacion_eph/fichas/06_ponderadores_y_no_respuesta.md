# 06 · Ponderadores y tratamiento de no respuesta

> Fuente: `pdfs/metodologia/eph_innovaciones_12_09.pdf` · `pdfs/ingresos/nota_EPH_ingresos_06_17.pdf` · `pdfs/metodologia/EPH_consideraciones_metodologicas_2t20.pdf`

## Por qué hay varios ponderadores

La EPH publica **factores de expansión múltiples** porque distintos tipos de variables tienen distintos patrones de no respuesta:

- **Ponderador general** (`PONDERA`): para variables sociodemográficas, laborales, etc.
- **Ponderadores específicos para ingresos**: corrigen la no respuesta diferencial en preguntas sobre ingresos.

## El ponderador general

`PONDERA` se construye combinando:

1. **Ponderación de diseño**: inversa de la probabilidad de selección de cada vivienda.
2. **Corrección por no respuesta total** del hogar (factor `FCNRhr`): se aplica al nivel del estrato.
3. **Ajuste a las proyecciones demográficas**: la base se calibra para que la suma de ponderadores reproduzca la población total proyectada del aglomerado.
4. **Calibración por sexo y tramos de edad** (incorporada en 2009): ajusta las proporciones por sexo y grupo etario para reducir variaciones aleatorias del muestreo trimestre a trimestre.

> Sin el paso 4, una muestra que casualmente capta más niños o adultos mayores produciría tasas de actividad infladas o deprimidas.

## Ponderadores de ingreso (calibrados por no respuesta)

| Ponderador | Variable que pondera | Aplica a |
|------------|----------------------|----------|
| `PONDIIO` | `P21` (ingreso de la ocupación principal) y componentes (`PP06C, PP06D, PP08D1, PP08D4, PP08F1, PP08F2`) | Personas con ocupación principal |
| `PONDII` | `P47T` (ingreso total individual) | Todas las personas |
| `PONDIH` | `ITF` (ingreso total familiar) | Hogares |

Estos ponderadores parten de `PONDERA` y le suman:

- Un **ajuste por no respuesta específica** de la variable (en su aglomerado y estrato).
- Una **calibración a subpoblaciones** para que el ponderador no rompa la estructura demográfica.

> A los **respondentes** se les aumenta el peso. A los **no respondentes**, se les asigna peso cero en ese ponderador específico.

## Estrategia histórica de corrección

| Etapa | Método | Limitación |
|-------|--------|------------|
| 2003-2009 | Solo reponderación con `PONDIIO`, `PONDII`, `PONDIH` | El usuario debía manejar 4 ponderadores · análisis multivariado restringido · inconsistencias entre bases |
| 2009+ | **Imputación hot-deck aleatorio** + ponderadores específicos | Se mantienen los ponderadores pero ahora todas las celdas tienen valor |

### Ejemplo de inconsistencia (pre-2009)

> En la distribución del ingreso del 2T 2006, el cuadro 4 (personas) decía que el ingreso máximo de la ocupación principal era $50.000, pero el cuadro 5 (hogares) decía que el hogar más rico ganaba $34.380. **Esto es imposible** (un hogar no puede ganar menos que la persona que más gana en él). El problema es que el hogar de quien ganaba $50.000 tenía al menos un no respondente, lo que lo eliminaba de la base de hogares con `PONDIH > 0`.

## Hot-deck aleatorio (desde 2009)

Es la técnica que reemplaza la reponderación pura para variables de ingreso:

1. Se identifica un **donante** para cada valor faltante, dentro de una **subpoblación definida por variables auxiliares** (correlacionadas con el ingreso).
2. Se sustituye el valor faltante por el valor válido del donante.
3. El registro queda completo en todas las celdas de ingreso.

Ventajas:

- Se preserva la **distribución** de la variable (a diferencia de la imputación por regresión).
- Permite **análisis multivariado** sin trabajar con sub-bases.
- Elimina las **inconsistencias** entre estimaciones de personas y hogares.

> En las nuevas bases hay un campo que indica **qué celdas fueron imputadas** (para que el usuario pueda hacer análisis de sensibilidad si quiere).

## Tratamiento del 2T 2020 (pandemia)

El relevamiento se hizo telefónico. INDEC introdujo dos ajustes adicionales:

### Ajuste por probabilidad de respuesta (propensity score)

- Se modeló la probabilidad de que un hogar respondiera la encuesta dado un set de covariables (visitas previas, contacto previo, características del hogar).
- El ponderador se ajustó por la inversa del propensity score estimado.

### Ajuste por calibración

- Después del propensity score, se aplicó **calibración** a totales conocidos por sexo y tramos de edad para corregir cualquier sesgo residual.

## Series de no respuesta de ingresos (Argentina)

| Período | Comportamiento |
|---------|---------------|
| 2003 - 2T 2007 | Mejora sostenida en respuesta y calidad |
| 2007-2015 | **Deterioro creciente** de la respuesta + uso de imputación que ocultaba el problema |
| 4T 2016 | 17,8% de no respuesta de ingresos en el total de aglomerados |
| 2016+ | Reversión gradual de la tendencia · controles trimestrales · capacitación |

## Recomendaciones para el usuario

1. Para **tasas de empleo, desempleo, actividad**: usar `PONDERA`.
2. Para **distribución del ingreso, pobreza** y agregados de ingresos: usar el ponderador específico (`PONDIIO`, `PONDII` o `PONDIH`) **o** usar `PONDERA` con valores imputados (a partir de las bases con hot-deck).
3. Verificar siempre la **suma de ponderadores** contra la población proyectada.
4. Para variancia y errores estándar, idealmente usar **diseño muestral complejo** (paquete `survey` en R · `srvyr` para sintaxis tidy).
5. Reportar siempre la **versión de la base** (preliminar vs. definitiva) y el **período**.

## Recursos

- INDEC, *Ponderación de la muestra y tratamiento de valores faltantes en las variables de ingreso en la EPH* (Metodología INDEC N° 15, 2010).
- `pdfs/metodologia/eph_innovaciones_12_09.pdf` · innovaciones de 2009.
- `pdfs/metodologia/EPH_consideraciones_metodologicas_2t20.pdf` · ajustes 2T 2020.

## Para profundizar

- Ficha 03 · Panel y rotación
- Ficha 10 · Ingresos y distribución
