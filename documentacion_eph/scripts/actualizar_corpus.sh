#!/usr/bin/env bash
# Refresca el corpus de documentación EPH del INDEC.
# Uso: ./actualizar_corpus.sh
# Requiere: curl, pdftotext (poppler-utils)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PDF_DIR="$ROOT/pdfs"
TXT_DIR="$ROOT/txt"

mkdir -p "$PDF_DIR"/{metodologia,muestra,registros,informalidad,pobreza,ingresos,cuestionarios,clasificadores,calendario}
mkdir -p "$TXT_DIR"

declare -A URLS=(
  # Metodología general
  ["metodologia/metodologia_eph_continua.pdf"]="https://www.indec.gob.ar/ftp/cuadros/sociedad/metodologia_eph_continua.pdf"
  ["metodologia/Gacetilla_EPHContinua.pdf"]="https://www.indec.gob.ar/ftp/cuadros/sociedad/Gacetilla_EPHContinua.pdf"
  ["metodologia/Anex1_EPHContinua_Pruebas.pdf"]="https://www.indec.gob.ar/ftp/cuadros/sociedad/Anex1_EPHContinua_Pruebas.pdf"
  ["metodologia/eph_innovaciones_12_09.pdf"]="https://www.indec.gob.ar/ftp/cuadros/menusuperior/eph/eph_innovaciones_12_09.pdf"
  ["metodologia/EPH_consideraciones_metodologicas_2t20.pdf"]="https://www.indec.gob.ar/ftp/cuadros/menusuperior/eph/EPH_consideraciones_metodologicas_2t20.pdf"
  ["metodologia/listado_metodologias.pdf"]="https://www.indec.gob.ar/ftp/cuadros/menusuperior/listado_metodologias.pdf"

  # Muestra
  ["muestra/eph_muestras_74-03.pdf"]="https://www.indec.gob.ar/ftp/cuadros/sociedad/eph_muestras_74-03.pdf"

  # Registros y bases
  ["registros/EPH_registro_1T2025.pdf"]="https://www.indec.gob.ar/ftp/cuadros/menusuperior/eph/EPH_registro_1T2025.pdf"
  ["registros/EPH_tot_urbano_estructura_bases_2025.pdf"]="https://www.indec.gob.ar/ftp/cuadros/menusuperior/eahu/EPH_tot_urbano_estructura_bases_2025.pdf"

  # Informalidad
  ["informalidad/metodologia_informalidad_laboral_2025.pdf"]="https://www.indec.gob.ar/ftp/cuadros/sociedad/metodologia_informalidad_laboral.pdf"

  # Pobreza
  ["pobreza/EPH_metodologia_22_pobreza.pdf"]="https://www.indec.gob.ar/ftp/cuadros/sociedad/EPH_metodologia_22_pobreza.pdf"

  # Ingresos
  ["ingresos/nota_EPH_ingresos_06_17.pdf"]="https://www.indec.gob.ar/ftp/cuadros/sociedad/nota_EPH_ingresos_06_17.pdf"

  # Cuestionarios
  ["cuestionarios/EPHContinua_CIndividual.pdf"]="https://www.indec.gob.ar/ftp/cuadros/sociedad/EPHContinua_CIndividual.pdf"
  ["cuestionarios/EPH_Hogar.pdf"]="https://redatam.indec.gob.ar/redarg/encuestas/EAHU/EPH_Hogar.pdf"

  # Clasificadores
  ["clasificadores/EPHcontinua_CNO2001_reducido_09.pdf"]="https://www.indec.gob.ar/ftp/cuadros/menusuperior/eph/EPHcontinua_CNO2001_reducido_09.pdf"

  # Calendario
  ["calendario/calendario_1sem2026.pdf"]="https://www.indec.gob.ar/ftp/cuadros/publicaciones/calendario_1sem2026.pdf"
  ["calendario/calendario_2sem2026.pdf"]="https://www.indec.gob.ar/ftp/cuadros/publicaciones/calendario_2sem2026.pdf"
)

echo "Descargando PDFs desde el sitio del INDEC..."
for path in "${!URLS[@]}"; do
  url="${URLS[$path]}"
  out="$PDF_DIR/$path"
  echo "  → $path"
  curl -sLf -A "Mozilla/5.0" "$url" -o "$out" || echo "    !! Falló: $url"
done

echo ""
echo "Extrayendo texto plano para indexación..."
for pdf in "$PDF_DIR"/*/*.pdf; do
  base=$(basename "$pdf" .pdf)
  pdftotext -layout "$pdf" "$TXT_DIR/${base}.txt" 2>/dev/null || true
done

echo ""
echo "Corpus actualizado:"
echo "  $(find "$PDF_DIR" -name '*.pdf' | wc -l) PDFs"
echo "  $(find "$TXT_DIR" -name '*.txt' | wc -l) archivos de texto extraídos"
echo ""
echo "Listo."
