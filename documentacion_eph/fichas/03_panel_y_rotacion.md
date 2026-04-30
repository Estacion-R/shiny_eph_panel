# 03 · Panel y esquema de rotación 2-2-2

> Fuente: `pdfs/metodologia/EPH_consideraciones_metodologicas_2t20.pdf` · `pdfs/metodologia/metodologia_eph_continua.pdf` · `pdfs/registros/EPH_registro_1T2025.pdf`

## Por qué la EPH es una encuesta de panel

Como toda investigación permanente, la EPH usa un sistema de **renovación de unidades a encuestar** (panel de respondentes). Esto permite:

- Estimar **eficientemente los cambios** entre dos mediciones consecutivas (varianza menor que entre muestras independientes).
- Evitar el aumento de **rechazos** que produciría encuestar siempre los mismos hogares.
- Hacer estudios de **dinámica laboral** (transiciones entre estados, persistencia de la pobreza, movilidad ocupacional).

## Esquema 2-2-2 (vigente desde 2003)

> Una vivienda seleccionada se encuesta en **4 trimestres**, no consecutivos, según el patrón:

```
T1  T2  T3  T4  T5  T6  T7  T8
[X] [X] [-] [-] [X] [X] (sale)
```

- Ingresa a la muestra y se encuesta **2 trimestres consecutivos**.
- Sale **2 trimestres consecutivos**.
- Vuelve a ser encuestada **2 trimestres consecutivos**.
- Después de las 4 mediciones, se reemplaza por otra vivienda de la misma área.

> Esto significa que una vivienda relevada por primera vez en la **semana 2 del 3T** será encuestada otra vez en la **semana 2 del 3T del año siguiente** (al cabo de 5 trimestres totales desde su ingreso).

## Grupos de rotación

- En cada aglomerado la muestra se divide en **4 grupos de rotación (paneles)**.
- Cada grupo es una submuestra de tamaño aproximadamente igual a un cuarto del total.
- Los 4 grupos están **equilibrados a lo largo del trimestre** (cada uno cubre 13 semanas del año).
- En cada trimestre conviven 4 grupos en distinta fase del esquema 2-2-2.

## Solapamiento entre trimestres

Trimestre a trimestre, **el 50% de las viviendas** se mantienen (las que están en su segunda visita consecutiva o volviendo después del descanso). El otro 50% rota.

> Esta es una propiedad útil para estimar cambios trimestrales con menor varianza, pero también introduce **autocorrelación** que hay que considerar en análisis longitudinales.

## Comparación entre trimestres del mismo año

| Comparación | % de viviendas en común (esperado) |
|-------------|-----------------------------------|
| T → T+1 | ~50% |
| T → T+2 | 0% (las que estaban descansan) |
| T → T+3 | ~50% (mismo grupo, segunda fase) |
| T → T+4 (mismo trim. año siguiente) | ~50% |

## Identificación del panel en las bases

En la base de microdatos cada registro tiene:

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `CODUSU` | char(29) | Código de **vivienda**. Se mantiene a lo largo de los 4 trimestres en que la vivienda participa. **Es la llave para el seguimiento longitudinal.** |
| `NRO_HOGAR` | num(1) | Distingue hogares dentro de una misma vivienda. |
| `COMPONENTE` | num | Distingue personas dentro de un hogar. |
| `ANO4` + `TRIMESTRE` | | Fecha del trimestre relevado. |

> Para hacer **análisis de panel** hay que aparear registros usando la combinación `CODUSU + NRO_HOGAR + COMPONENTE` entre trimestres.

## Cuántos paneles seguir

Para construir un panel completo de una vivienda, hay que disponer de las bases de los **4 trimestres** en que esa vivienda participó. Como el patrón es 2-2-2, los trimestres relevantes son:

- t (primera visita)
- t+1 (segunda visita)
- t+4 (tercera visita)
- t+5 (cuarta visita)

> No siempre las cuatro visitas se logran (no respuesta, mudanzas, hogares que dejan de existir). El usuario debe decidir si trabaja con paneles balanceados o no balanceados.

## Adaptaciones del relevamiento

### 2T 2020 (pandemia COVID)

- Se mantuvo el **esquema 2-2-2** y los cuestionarios.
- Se cambió el modo de relevamiento de presencial a **telefónico**.
- Para el grupo nuevo (sin contacto previo) hubo que recolectar teléfonos por buscadores online, guías, autoridad local.
- Se aplicaron ajustes especiales por **probabilidad de respuesta (propensity score)** y **calibración** para corregir los sesgos.
- De 26.940 viviendas seleccionadas, se logró información de contacto en 21.950 y respondieron 11.841.

## Implicancias para el análisis

1. **Para estimaciones puntuales** (un trimestre): usar `PONDERA` o sus variantes ajustadas por no respuesta.
2. **Para cambios entre trimestres**: aprovechar el solapamiento, pero usar correctamente la varianza que tiene en cuenta el panel.
3. **Para análisis longitudinales** (panel rotativo):
   - Aparear con `CODUSU + NRO_HOGAR + COMPONENTE`.
   - Verificar consistencia entre trimestres (edad +1 año, sexo invariable, etc.).
   - Considerar la **erosión del panel** (no respuesta acumulada).

## Para profundizar

- Ficha 02 · Diseño muestral
- Ficha 05 · Cuestionarios y estructura de bases
- Ficha 06 · Ponderadores y no respuesta
