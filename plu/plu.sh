#!/bin/bash
set -euo pipefail

echo "🚀 Démarrage génération tuiles PLU — $(date)"

# === Configuration ===
DBNAME="bati-foncier"
HOST="localhost"
PORT="5432"
USER="postgres"
OUTPUT_DIR="data"
OUTPUT_GEOJSON="${OUTPUT_DIR}/plu-zone-urba.geojson"
OUTPUT_MBTILES="plu-zone-urba.mbtiles"
TILESERVER_DIR="/mnt/c/www/tileserver"
SQL_FILE="plu_request.sql"
MIN_SIZE_MB=10

# === Nettoyage et préparation du dossier ===
echo "🧹 Nettoyage des fichiers précédents"
rm -rf "$OUTPUT_DIR" "$OUTPUT_MBTILES"
mkdir -p "$OUTPUT_DIR"

# === Requête SQL dans un fichier externe (plus lisible et maintenable) ===
cat > "$SQL_FILE" <<'EOF'
SELECT
  ogc_fid AS id,
  libelle,
  REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(libelong,
    'Ã©', 'é'), 'Ã¨', 'è'), 'Ã¯', 'ï'), 'Ã´', 'ô'), 'Ã§', 'ç'), 'Ãª', 'ê'),
    'Ã¹', 'ù'), 'Ã¦', 'æ'), 'â¬', '€'), 'Ã«', 'ë'), 'Ã¼', 'ü'), 'Ã¢', 'â'),
    'Â©', '©'), 'Ã', 'à') AS libelong,
  typezone,
  datvalid,
  wkb_geometry AS geom
FROM plu_zone_urba
EOF

# === Export GeoJSON ===
echo "📤 Export des données depuis PostgreSQL — $(date)"
ogr2ogr -f "GeoJSON" "$OUTPUT_GEOJSON" PG:"host=$HOST port=$PORT dbname=$DBNAME user=$USER" -sql "@$SQL_FILE"

# === Tuilage avec Tippecanoe ===
echo "🗺️ Génération des tuiles vectorielles — $(date)"
tippecanoe --detect-shared-borders --simplify-only-low-zooms --generate-ids --read-parallel --force --coalesce-densest-as-needed -Z10 -z16 --output "$OUTPUT_MBTILES" "$OUTPUT_GEOJSON"

# === Vérification de la taille du fichier avant copie ===
echo "📦 Vérification taille fichier MBTiles"
if [ -f "$OUTPUT_MBTILES" ]; then
  FILE_SIZE_BYTES=$(stat -c%s "$OUTPUT_MBTILES" 2>/dev/null || stat -f%z "$OUTPUT_MBTILES")
  FILE_SIZE_MB=$((FILE_SIZE_BYTES / 1024 / 1024))
  echo "📏 Taille : ${FILE_SIZE_MB} MB"

  if [ "$FILE_SIZE_MB" -ge "$MIN_SIZE_MB" ]; then
    echo "✅ Fichier valide, déplacement vers $TILESERVER_DIR"
    mv "$OUTPUT_MBTILES" "$TILESERVER_DIR/"
  else
    echo "❌ Fichier trop petit, abandon du déplacement."
  fi
else
  echo "❌ Fichier MBTiles non généré."
fi

# === Nettoyage final ===
echo "🧼 Nettoyage temporaire"
rm -rf "$OUTPUT_DIR" "$SQL_FILE"

echo "✅ Fin du script — $(date)"
