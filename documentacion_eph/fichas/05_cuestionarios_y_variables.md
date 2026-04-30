# 05 · Cuestionarios y estructura de bases

> Fuente: `pdfs/registros/EPH_registro_1T2025.pdf` · `pdfs/cuestionarios/EPH_Hogar.pdf` · `pdfs/cuestionarios/EPHContinua_CIndividual.pdf`

## Tres cuestionarios

| Cuestionario | A quién | Cuándo |
|--------------|---------|--------|
| **Vivienda** | Relevador (por observación) | Solo en la primera visita a la vivienda |
| **Hogar** (Form. 002/10) | Un informante por hogar | En cada visita |
| **Individual** (Form. 001/03) | Cada persona de **10 años o más** | En cada visita |

## Bases de microdatos

INDEC publica trimestralmente dos archivos:

| Archivo | Contiene | Identificador |
|---------|----------|---------------|
| `usu_hogar.txt` | Características de la vivienda + variables del hogar | `CODUSU` + `NRO_HOGAR` |
| `usu_individual.txt` | Variables individuales (cuestionario individual + parte del de hogar) | `CODUSU` + `NRO_HOGAR` + `COMPONENTE` |

> Los formatos también se publican en SPSS (`.sav`) y Stata (`.dta`) con etiquetas (innovación introducida en 2009).

## Identificadores clave

| Variable | Tipo | Descripción |
|----------|------|-------------|
| `CODUSU` | char(29) | **Código de vivienda**. Permite seguimiento longitudinal entre trimestres. |
| `NRO_HOGAR` | num(1) | Hogar dentro de la vivienda (en general 1, salvo casos con servicio doméstico cama adentro o múltiples hogares). |
| `COMPONENTE` | num | Persona dentro del hogar. |
| `ANO4` | num(4) | Año de relevamiento. |
| `TRIMESTRE` | num(1) | 1, 2, 3 o 4. |
| `REGION` | num(2) | Región estadística. |
| `AGLOMERADO` | num(2) | Aglomerado urbano. |
| `REALIZADA` | num(1) | 1=Sí · 2=No (hogar no respuesta). |

## Bloques temáticos del cuestionario de hogar

1. **Identificación** (CODUSU, NRO_HOGAR, REALIZADA, ANO4, TRIMESTRE, REGION, MAS_500, AGLOMERADO, PONDERA).
2. **Características de la vivienda** (IV1 a IV12 · tipo, ambientes, materiales, agua, baño).
3. **Características habitacionales del hogar** (II1 a II9 · ambientes de uso exclusivo, cocina, agua, combustible, régimen de tenencia).
4. **Estrategias del hogar** (V1 a V22 · ingresos no laborales del hogar: jubilaciones, transferencias, alquileres, ayudas).
5. **Resumen del hogar** (cantidad de miembros, menores, ocupados, etc.).
6. **Ingreso total familiar** (ITF, IPCF) + decílicas.
7. **Organización del hogar** (división de tareas domésticas, presencia de discapacidad).

## Bloques temáticos del cuestionario individual

1. **Características de los miembros del hogar** (CH1 a CH16 · sexo, edad, parentesco, situación conyugal, lugar de nacimiento, migración, cobertura médica, alfabetización, asistencia a establecimiento).
2. **Condición de actividad** (preguntas filtro 1a-1g · determinan si la persona es ocupada, desocupada o inactiva).
3. **Para ocupados que trabajaron en la semana de referencia** (PP01 a PP04 · características de la ocupación principal).
4. **Para todos los ocupados**:
   - Categoría ocupacional (PP04A · patrón, cuenta propia, asalariado, TFSR).
   - Tamaño del establecimiento.
   - Calificación.
   - Rama (CAES-MERCOSUR).
   - Ocupación (CNO-2001).
5. **Independientes** (PP05 a PP09 · uso de instalaciones, capital, registro de la unidad económica · NUEVAS variables 2023+).
6. **Asalariados** (PP07A a PP07J · descuento jubilatorio, modalidad contractual, antigüedad, beneficios).
7. **Ingresos de la ocupación principal** (P21 · monto, PP06 · forma de pago).
8. **Otras ocupaciones** y **ingresos no laborales** (V1 a V21).
9. **Ingreso total individual** (P47T) e **ingreso total familiar** (ITF).

## Variables clave de ingresos

| Variable | Significado |
|----------|-------------|
| `P21` | Ingreso de la ocupación principal |
| `PP06C, PP06D, PP08D1, PP08D4, PP08F1, PP08F2` | Componentes del ingreso de la ocupación principal |
| `P47T` | Ingreso total individual (suma de laboral + no laboral) |
| `T_VI` | Total ingresos no laborales |
| `ITF` | Ingreso total familiar (suma de P47T de los miembros del hogar) |
| `IPCF` | Ingreso per cápita familiar (ITF / cantidad de miembros) |
| `DECCFR`, `DECIFR`, etc. | Escalas decílicas (decílicas regionales y nacionales) |

## Variables clave de mercado laboral

| Variable | Significado |
|----------|-------------|
| `ESTADO` | Condición de actividad (1=Ocupado · 2=Desocupado · 3=Inactivo · 4=Menor de 10) |
| `CAT_OCUP` | Categoría ocupacional (1=Patrón · 2=Cuenta propia · 3=Asalariado · 4=Trabajador familiar sin remuneración) |
| `CAT_INAC` | Tipo de inactivo (jubilado, ama de casa, estudiante, etc.) |
| `INTENSI` | Intensidad horaria (subocupado, ocupado pleno, sobreocupado) |
| `PP3E_TOT` | Horas semanales en la ocupación principal |
| `PP3F_TOT` | Horas semanales en otras ocupaciones |
| `PP04D_COD` | Código CNO-2001 de la ocupación |
| `PP04B_COD` | Código CAES-MERCOSUR de la rama |

## Variables nuevas de informalidad (desde 4T 2023)

| Variable | Pregunta | Aplica a |
|----------|----------|----------|
| `PP04F` (nueva) | ¿La empresa/negocio... está registrada en AFIP? | Independientes |
| `PP04G` (nueva) | ¿Lleva contabilidad completa? | Independientes |
| `PP04H` (nueva) | ¿Le hacen factura por el trabajo? | Independientes |
| Variables relacionadas | Sector institucional + emisión de facturas + contador | Asalariados |

## Recomendaciones para el uso

1. **Trabajar siempre con los ponderadores** (no estimar con datos crudos).
2. Usar **`PONDERA`** para variables generales.
3. Usar **`PONDII` / `PONDIIO` / `PONDIH`** para variables de ingreso (corrigen no respuesta de ingresos).
4. Para análisis multivariado con ingresos, las bases más nuevas usan **hot-deck imputado**, lo que permite usar `PONDERA` también para ingresos.
5. Documentar siempre el **período exacto** (trimestre + año) y la **versión de la base** que se usó (las bases preliminares pueden actualizarse).

## Para profundizar

- Ficha 06 · Ponderadores y no respuesta
- Ficha 07 · Mercado laboral
- Ficha 10 · Ingresos y distribución
- Ficha 99 · Glosario
