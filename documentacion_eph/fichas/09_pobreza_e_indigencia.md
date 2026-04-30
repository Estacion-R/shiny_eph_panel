# 09 · Pobreza e indigencia

> Fuente: `pdfs/pobreza/EPH_metodologia_22_pobreza.pdf` (Metodología INDEC N° 22, diciembre 2016)

## Método de medición indirecto · "líneas"

INDEC mide pobreza e indigencia por el **método de líneas** (también llamado "método indirecto"). Compara el ingreso del hogar contra el costo de canastas de bienes y servicios.

| Concepto | Pregunta que responde |
|----------|----------------------|
| **Línea de Indigencia (LI)** | ¿El hogar tiene ingresos suficientes para cubrir una canasta alimentaria que satisfaga un umbral mínimo de necesidades energéticas y proteicas? |
| **Línea de Pobreza (LP)** | ¿El hogar tiene ingresos suficientes para cubrir, además de alimentos, otros consumos básicos no alimentarios (vestimenta, transporte, educación, salud, etc.)? |

> Ingresos del hogar = **ITF (Ingreso Total Familiar)**, captado por la EPH.
> Canastas valorizadas con los precios del **IPC**.

## Canasta Básica Alimentaria (CBA)

- **Definición**: conjunto de alimentos que satisfacen requerimientos nutricionales mínimos, con estructura que refleja el patrón de consumo de la **población de referencia** (hogares cuyos consumos en alimentos cubren las necesidades alimentarias).
- **Construcción**:
  1. Determinar requerimiento energético y nutrientes por grupo etario.
  2. Determinar estructura de consumo de la población de referencia (a partir de la **ENGHo**).
  3. Seleccionar productos y cantidades.
  4. Hacer ajustes nutricionales para optimizar el criterio normativo.
  5. Valorizar monetariamente con el IPC.
- **Versión 1988-2016**: 50 productos, 2.700 kcal para el adulto equivalente, basada en la encuesta de gastos 1985/86 GBA.
- **Versión 2016+**: actualizada con la **ENGHo 2004/05**, más productos, canastas regionales propias para cada región (no solo GBA).

## Canasta Básica Total (CBT)

CBT = CBA × ICE

donde **ICE = inversa del Coeficiente de Engel**:

```
Coeficiente de Engel = Gasto Alimentario / Gasto Total
```

(observado en la población de referencia, en la ENGHo).

> El CdE se actualiza en cada período por el **cambio en el precio relativo** de los alimentos respecto del resto de bienes y servicios.

## Adulto equivalente

Como las necesidades nutricionales difieren por edad y sexo, se construye una **unidad de referencia** (varón adulto de 30-59 años, actividad moderada). Cada miembro del hogar se traduce en una cantidad de adultos equivalentes según su edad y sexo. La línea para el hogar se multiplica por la suma de adultos equivalentes.

### Tabla de equivalencias (resumen)

- Niño/a 1 año: ~0,33 ad. eq.
- Niño/a 4 años: ~0,55 ad. eq.
- Mujer 30 años (mod. activa): ~0,75 ad. eq.
- Varón 30 años (mod. activa): 1,00 ad. eq. (referencia)
- Varón 65 años: ~0,77 ad. eq.

> La tabla completa figura en el anexo del documento de pobreza.

## Clasificación del hogar

Para cada hogar:

```
LI_hogar = CBA_per_capita × Σ(adultos_equivalentes del hogar)
LP_hogar = CBT_per_capita × Σ(adultos_equivalentes del hogar)
```

| Estado | Condición |
|--------|-----------|
| **Indigente** | ITF < LI |
| **Pobre no indigente** | LI ≤ ITF < LP |
| **Pobre** (incluye los anteriores) | ITF < LP |
| **No pobre** | ITF ≥ LP |

La caracterización de cada hogar se traslada a **cada una de las personas** que lo integran.

## Avances 2016 (reanudación)

Cuando se reanudó la difusión de pobreza en 2016, INDEC introdujo cambios pendientes desde 2007:

1. **Actualización con ENGHo 2004/05**: nuevas estructuras de consumo.
2. **Tabla de equivalencias** revisada · incorporación del concepto de "densidad nutricional".
3. **Canastas regionales propias** (en lugar de extrapolar la del GBA con coeficientes de Paridad del Poder de Compra).

## Líneas de pobreza regionales

Desde 2016 se calculan **6 líneas regionales**:

- GBA · Pampeana · Cuyo · NOA · NEA · Patagonia

Cada una tiene su propia composición de CBA (por hábitos alimentarios) y su propio Coeficiente de Engel.

## Frecuencia de difusión

- **Pobreza e indigencia (EPH 31 aglomerados)**: semestral · publicada el último jueves de marzo (2° semestre del año previo) y de septiembre (1° semestre del año en curso).
- **CBA y CBT (Gran Buenos Aires)**: **mensual** · publicada con el IPC.
- **Pobreza Total Urbano**: anual (3T).

## Avances en estudio

INDEC sigue trabajando en:

- **Canastas más diferenciadas** (propietarios vs. inquilinos · hogares con niños · adultos mayores · economía de escala intra-hogar).
- **Pobreza multidimensional** (otra perspectiva, no reemplaza al método de líneas).

## Implicancias para el análisis

1. Los **ingresos** que se comparan contra la línea son los del **mes de referencia** (mes anterior a la entrevista).
2. Para construir la línea hay que conocer la composición del hogar (edad y sexo de cada miembro).
3. La pobreza se calcula sobre la base de hogares con **respuesta de ingresos** (ITF no faltante o imputado).
4. Para un trimestre dado, hay que aplicar la **CBA y CBT promedio** del trimestre, no el valor mensual.
5. La incidencia de pobreza es sensible a la imputación de ingresos: revisar siempre el porcentaje de hogares con `IDIMPP = 1` (imputado).

## Para profundizar

- Ficha 06 · Ponderadores y no respuesta
- Ficha 10 · Ingresos y distribución
- INDEC, *La medición de la pobreza y la indigencia en la Argentina* (Metodología INDEC N° 22) · `pdfs/pobreza/EPH_metodologia_22_pobreza.pdf`
