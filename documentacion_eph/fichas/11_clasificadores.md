# 11 · Clasificadores

> Fuente: `pdfs/clasificadores/EPHcontinua_CNO2001_reducido_09.pdf`

## CNO-2001 · Clasificador Nacional de Ocupaciones

Es el sistema oficial argentino para clasificar ocupaciones. Es **único** en su construcción: además de identificar la actividad, codifica **dimensiones analíticas** del puesto.

### Estructura del código (5 dígitos)

```
D1 D2 D3 · D4 · D5
│  │  │    │    │
│  │  │    │    └── Calificación ocupacional
│  │  │    └─────── Tecnología
│  │  └──────────── Jerarquía / carácter ocupacional
│  └─────────────── Carácter de la ocupación
└────────────────── Carácter de la ocupación
```

### Campo de la ocupación (3 primeros dígitos)

Sectores agrupados por afinidad temática:

- 0 - 2: dirección, gestión, administración pública, gestión privada
- 3 - 4: producción industrial, artesanal y de servicios
- 5: comercialización, transporte, comunicaciones
- 6 - 7: servicios sociales básicos (salud, educación)
- 8 - 9: servicios varios y trabajos no calificados

### Carácter ocupacional (4° dígito)

| Código | Significado |
|--------|------------|
| 1 | Producción de bienes |
| 2 | Producción de servicios |
| 3 | Comercialización |
| 4 | Servicios sociales básicos |
| 5 | Otros servicios |

### Calificación ocupacional (5° dígito)

| Código | Significado |
|--------|------------|
| 1 | **Profesional** |
| 2 | **Técnica** |
| 3 | **Operativa** |
| 4 | **No calificada** |

> Esta es la dimensión más utilizada en análisis de mercado laboral. Se asocia con nivel educativo, ingresos, condiciones de trabajo.

### Variables en la base

| Variable | Tipo |
|----------|------|
| `PP04D_COD` | Código CNO-2001 (5 dígitos) |
| `CAT_OCUP` | Categoría ocupacional (1=Patrón · 2=Cuenta propia · 3=Asalariado · 4=TFSR) |

## CAES-MERCOSUR · Clasificador de Actividades para Encuestas Sociodemográficas

Clasifica la **rama de actividad económica** del establecimiento donde trabaja la persona.

### Estructura

Adaptación del **CIIU Rev. 4** (Clasificación Internacional Industrial Uniforme) armonizado para encuestas a hogares en el Mercosur.

### Niveles de agregación habituales

| Nivel | Ejemplo |
|-------|---------|
| Sección (1 dígito · letra) | A · Agricultura, ganadería, silvicultura |
| División (2 dígitos) | 01 · Agricultura |
| Grupo (3 dígitos) | 011 · Cultivos agrícolas no perennes |
| Clase (4 dígitos) | 0111 · Cultivo de cereales |

### Variables en la base

| Variable | Tipo |
|----------|------|
| `PP04B_COD` | Código CAES (4 dígitos) de la actividad del establecimiento |
| `PP04A` | Sector institucional (1=Estatal · 2=Privado · 3=Otro) |

### Cambios históricos

- Antes de 2009: la EPH usó distintas versiones del CAES con desagregaciones que cambiaron en el tiempo (la serie no era homogénea).
- A partir de 2009: INDEC publicó **bases de microdatos retroactivas con criterios homogéneos** desde el 3T 2003. Se aplicaron las desagregaciones más recientes a toda la serie. La codificación automática se mejoró duplicando el repertorio de frases clave (>40.000), llevando la automatización a 2/3 de los registros.

## Otros clasificadores usados

### CIUO (ISCO) · Clasificación Internacional Uniforme de Ocupaciones (OIT)

Para comparaciones internacionales se requiere convertir CNO-2001 a **CIUO-08**. Hay tablas de equivalencia publicadas por OIT y CEPAL.

### Cobertura geográfica

- `REGION` (campo de 2 dígitos) · ver Ficha 04.
- `AGLOMERADO` (campo de 2 dígitos) · ver Ficha 04.

### Educación

- `CH12` · Nivel educativo más alto (jardín · primario · secundario · superior no universitario · universitario · posgrado).
- `CH13` · Lo finalizó (Sí / No).
- `CH14` · Año / curso aprobado.
- `NIVEL_ED` · Variable derivada (recodificación estándar usada por INDEC para tabular).

## Para profundizar

- Ficha 07 · Mercado laboral
- INDEC, *Clasificador Nacional de Ocupaciones (CNO-2001)* · `pdfs/clasificadores/EPHcontinua_CNO2001_reducido_09.pdf`
- INDEC, *Clasificador de Actividades para Encuestas Sociodemográficas (CAES-Mercosur)* · disponible en https://www.indec.gob.ar
