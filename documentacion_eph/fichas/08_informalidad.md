# 08 · Informalidad laboral

> Fuente: `pdfs/informalidad/metodologia_informalidad_laboral_2025.pdf` (Metodología INDEC N° 43, abril 2025)

## Definición conceptual

> **Informalidad laboral** = conjunto de trabajadores y/o unidades productivas que desarrollan sus actividades **al margen de las normas que las regulan**.

La definición se alinea con la **Resolución I de la 21° CIET** (OIT, 2023a), que reemplaza la Resolución I de la 15° CIET (1993) y las Directrices de la 17° CIET (2003).

## Dos enfoques que se cruzan

### 1) Empleo informal (a nivel del puesto)

- Empleo **asalariado informal**: ausencia de aportes jubilatorios por parte del empleador (variable `PP07H` en la EPH).
- Empleo **independiente informal**: el indicador depende del registro de la unidad económica (no había forma de captarlo antes de 2023).

### 2) Sector informal (a nivel de la unidad económica)

Según OIT 2023, las unidades económicas se clasifican en:

| Sector | Definición |
|--------|-----------|
| **Formal** | Unidades económicas formalmente reconocidas que producen para el mercado, sin fines de lucro reconocidas, o unidades no de mercado. Incluye sector público, empresas formales constituidas o no, ISFL formalmente reconocidas. |
| **Informal** | Unidades económicas que producen bienes o servicios principalmente para el mercado y **no están reconocidas** a tal fin. |
| **Sector hogares** | Unidades económicas que producen para uso propio del hogar o ISFL **no formalmente reconocidas**. |

> La **21° CIET excluye el tamaño** del establecimiento como criterio de informalidad: una microempresa puede estar perfectamente registrada y formal.

## Por qué INDEC actualizó la EPH (4T 2023)

Antes de 2023 la EPH solo permitía medir **directamente** la informalidad asalariada (vía `PP07H`). Para los **independientes** los analistas usaban proxies (calificación, tamaño del establecimiento, ingresos), todas con problemas. La actualización del cuestionario incorpora preguntas directas que permiten:

1. Captar la informalidad de los **trabajadores independientes** (cuenta propia y patrones).
2. Identificar segmentos de informalidad entre **asalariados** y **TFSR** según la unidad económica.
3. Producir un indicador único de informalidad para el **conjunto de los ocupados**.

Esto cumple con el objetivo **8.3.1 de los ODS** ("aumento sustancial de la proporción de empleo en el sector formal").

## Operacionalización 2023+

### Para trabajadores independientes (cuenta propia y patrones)

Se busca la **situación de registro de la unidad económica**. Variables clave:

1. ¿La empresa/negocio está **registrada en AFIP**? (Sí / No / Ns)
2. ¿Tiene **contabilidad completa**? (variable de rescate cuando no hay info de registro)
3. ¿Le hacen / hace **factura** por el trabajo? (rescate adicional)

Algoritmo simplificado:

```
SI sociedad_constituida = Sí → Sector formal
SINO SI registro_unidad_economica = Sí → Sector formal
SINO SI contabilidad_completa = Sí → Sector formal
SINO → Sector informal (o Sector ignorado si toda la info falta)
```

### Para asalariados

Se distingue por sector institucional:

| Sector institucional | Sector resultante |
|----------------------|-------------------|
| Estatal | Formal (con o sin aporte determina formalidad del puesto) |
| Privado constituido en sociedad | Formal |
| Privado no constituido + registro Sí | Formal |
| Privado no constituido + registro No / Ns | Informal |
| ISFL reconocida | Formal |
| ISFL no reconocida o producción para el hogar | Sector hogares |

> Las preguntas adicionales se aplican solo a privados no constituidos en sociedad y a ISFL para definir si la unidad económica es formal.

### Trabajadores familiares sin remuneración (TFSR)

Se aplica el mismo esquema que para asalariados privados (parte del privado), con la diferencia de que no hay aporte jubilatorio porque no hay remuneración.

## Cuatro umbrales de medición

A partir de 2023+ la EPH puede producir:

1. **Empleo informal asalariado** (basado en `PP07H` · serie histórica desde 2003).
2. **Empleo informal independiente** (nuevo · desde 4T 2023).
3. **Empleo en el sector informal** (nuevo · clasificación de la unidad económica).
4. **Empleo informal total** (suma de 1 + 2 + asalariados informales por sector hogares).

## Antecedente: módulo de informalidad 2005 (GBA)

INDEC, junto con el Ministerio de Trabajo, OIT, Banco Mundial y la Secretaría de PyMEs, aplicó un **módulo de informalidad** sobre la EPH del 4T 2005 en GBA. La metodología 2025 retoma muchas preguntas de ese módulo, ajustadas a:

- Cambios en el mercado laboral.
- Nuevo marco normativo del trabajo registrado en Argentina.
- Pruebas cualitativas (2021) y cuantitativas (2022) realizadas para validar el rediseño.

## Heterogeneidad de la informalidad

El documento de INDEC enfatiza que la informalidad **no se reduce a microempresas familiares**. Coexisten:

- Trabajadores **independientes informales** de baja calificación (vendedores ambulantes, changarines, etc.).
- Independientes **profesionales** informales (consultores que no facturan).
- Asalariados **"en negro"** en empresas formales (cumplimiento parcial).
- **Plataformas digitales** (categorización ambigua, en estudio).

Para abordar esta heterogeneidad la EPH brinda variables auxiliares:

- **Calificación ocupacional** (CNO-2001 · 5° dígito).
- **Rama** (CAES-Mercosur).
- **Tamaño del establecimiento**.
- **Ingresos** y **antigüedad** en el puesto.
- Tipo de **modalidad contractual** (asalariados).

## Implicancias para el análisis

1. **Series largas (pre-2023)**: solo se puede analizar informalidad **asalariada** (`PP07H = 2`).
2. **Desde 4T 2023**: se puede medir informalidad para todo el universo de ocupados.
3. Comparaciones internacionales con países de la región: usar las definiciones armonizadas con OIT/CEPAL.
4. Los datos del 1T y 2T pueden tener mayor estacionalidad en sectores como construcción y turismo.

## Para profundizar

- Ficha 07 · Mercado laboral
- Ficha 11 · Clasificadores
- INDEC, *Diseño conceptual y metodológico para la medición de la informalidad laboral con datos de la EPH* (Metodología N° 43, 2025) · `pdfs/informalidad/metodologia_informalidad_laboral_2025.pdf`
