# 07 · Mercado laboral · Tasas básicas y condición de actividad

> Fuente: `pdfs/metodologia/metodologia_eph_continua.pdf`

## Tasas básicas oficiales

Definiciones canónicas del INDEC (sobre la población total del aglomerado, no sobre la PEA salvo donde se aclara):

| Tasa | Definición | Numerador | Denominador |
|------|-----------|-----------|-------------|
| **Tasa de actividad** | % entre la PEA y la población total | Población económicamente activa (ocupados + desocupados) | Población total |
| **Tasa de empleo** | % entre la población ocupada y la población total | Ocupados | Población total |
| **Tasa de desocupación** | % entre la población desocupada y la PEA | Desocupados | PEA |
| **Tasa de subocupación horaria** | % entre la población subocupada y la PEA | Subocupados (trabajan menos de 35 hs/sem y desean trabajar más) | PEA |

Adicionalmente:

- **Subocupación demandante**: subocupados que buscan activamente otro empleo.
- **Subocupación no demandante**: subocupados que no buscan otro empleo.
- **Sobreocupados**: ocupados con más de 45 horas semanales.
- **Ocupados plenos**: entre 35 y 45 horas semanales.

## Condición de actividad

Se determina con la batería de preguntas filtro 1a-1g del cuestionario individual (semana de referencia).

### Ocupados

Personas que en la semana de referencia:

- Trabajaron **al menos una hora** en forma remunerada, **o**
- Trabajaron habitualmente **15 horas o más sin pago**, **o**
- No trabajaron en la semana **pero mantienen el empleo** (vacaciones, licencia, suspensión con pago, etc.).

> El criterio de **una hora trabajada** preserva comparabilidad internacional y permite captar ocupaciones informales o de baja intensidad. Se pueden excluir luego para análisis específicos.

Cambios desde la reformulación:

- Se incorporan trabajadores sin pago que hayan trabajado menos de 15 horas semanales.
- Se incluyen suspendidos con pago (independiente del tiempo de suspensión).
- Se mejoran los criterios para captar quien "no trabajó pero tiene empleo".

### Desocupados

Personas que en la semana de referencia:

- **No tienen ocupación**.
- **Buscan activamente trabajo** (ventana de 4 semanas, no solo 1).
- Están **disponibles para trabajar**.

Incluye:

- Quienes interrumpieron momentáneamente la búsqueda.
- Suspendidos sin pago de más de 1 mes que buscaron activamente.

> La reformulación amplió la captación de **formas no visualizadas** de búsqueda (consultar amigos, poner carteles, anotarse en bolsas de trabajo).

### Inactivos

Quienes no trabajan ni buscan trabajo. Se distingue:

| Tipo | Definición |
|------|-----------|
| **Inactivo marginal** | No busca activamente por desaliento, **pero está disponible** para trabajar (forma oculta de desempleo). |
| **Inactivo típico** | No trabaja, no busca, no está disponible. Subcategorías: jubilado/pensionado, ama de casa, estudiante, rentista, menor que no trabaja, otro. |

## Categorías ocupacionales (`CAT_OCUP`)

| Código | Categoría | Definición |
|--------|-----------|-----------|
| 1 | **Patrón** | Trabaja por cuenta propia · ocupa al menos una persona asalariada. |
| 2 | **Cuenta propia** | Trabaja en su propia ocupación · sin dependientes. |
| 3 | **Asalariado** | Trabaja en relación de dependencia. |
| 4 | **TFSR** (trabajador familiar sin remuneración) | Trabaja en un emprendimiento de un familiar sin recibir pago. |

## Calificación ocupacional

Quinto dígito del código CNO-2001:

| Código | Calificación |
|--------|-------------|
| 1 | Profesional |
| 2 | Técnica |
| 3 | Operativa |
| 4 | No calificada |

## Variables clave de mercado laboral en la base

| Variable | Significado |
|----------|-------------|
| `ESTADO` | 1=Ocupado · 2=Desocupado · 3=Inactivo · 4=Menor de 10 |
| `CAT_OCUP` | Categoría ocupacional |
| `CAT_INAC` | Tipo de inactivo |
| `INTENSI` | Intensidad horaria (1=Subocupado demandante · 2=Subocupado no demandante · 3=Ocupado pleno · 4=Sobreocupado · 9=Ns/Nr) |
| `PP3E_TOT` | Horas semanales en ocupación principal |
| `PP3F_TOT` | Horas semanales en otras ocupaciones |
| `PP04A` | Sector institucional (1=Estatal · 2=Privado · 3=Otro) |
| `PP04B_COD` | Rama de actividad (CAES-Mercosur) |
| `PP04D_COD` | Ocupación (CNO-2001) |
| `PP04C` | Tamaño del establecimiento |
| `PP07H` | Aporte jubilatorio (asalariados) · indicador clave de informalidad |

## Notas para el cálculo de tasas

1. Las tasas oficiales se publican **trimestralmente** para los 31 aglomerados, las 6 regiones y el total.
2. Para reproducirlas hay que usar el **ponderador correcto** (`PONDERA`) y filtrar por aglomerado/región.
3. Los **menores de 10 años** se excluyen del cálculo de actividad/empleo (no se les aplica el cuestionario individual).
4. Para **tasas anuales**, se promedian los 4 trimestres ponderados; o se usa la base de Total Urbano del 3T.

## Para profundizar

- Ficha 08 · Informalidad
- Ficha 11 · Clasificadores (CNO-2001, CAES-Mercosur)
- Ficha 99 · Glosario
