#!/usr/bin/env bash
set -euo pipefail

host="localhost"
port="5432"
dbname="admin-express"
user="postgres"

OUT_DIR="./data"
MBTILES_FILE="admin-express.mbtiles"

# Export final (si taille OK)
DEST_DIR="/mnt/c/www/tileserver"
MIN_SIZE_MB=10   # ← seuil mini en Mo avant déplacement

mkdir -p "$OUT_DIR"
rm -f "$OUT_DIR"/*.geojson
rm -f "$MBTILES_FILE"

# 1) Lister les tables géométriques
mapfile -t GEO_TABLES < <(
  psql -h "$host" -p "$port" -U "$user" -d "$dbname" -At \
    -c "SELECT f_table_schema, f_table_name, f_geometry_column FROM geometry_columns ORDER BY 1,2;"
)

if [[ ${#GEO_TABLES[@]} -eq 0 ]]; then
  echo "Aucune table géométrique trouvée dans $dbname."
  exit 1
fi

# 2) Export PostGIS -> GeoJSON (sans préfixe 'public_')
for row in "${GEO_TABLES[@]}"; do
  IFS='|' read -r schema table geom <<< "$row"

  if [[ "$schema" == "public" ]]; then
    layer="$table"
  else
    layer="${schema}_${table}"
  fi

  out_file="$OUT_DIR/${layer}.geojson"
  echo "→ Export ${schema}.${table} -> $out_file"

  ogr2ogr -f "GeoJSON" "$out_file" \
    "PG:host=$host port=$port dbname=$dbname user=$user" \
    "$schema.$table" \
    -t_srs EPSG:4326 \
    -sql "SELECT * FROM \"$schema\".\"$table\" WHERE NOT ST_IsEmpty(\"$geom\")" \
    -skipfailures
done

# 3) Générer le MBTiles unique
echo "→ Génération de $MBTILES_FILE"
tippecanoe -zg -f -o "$MBTILES_FILE" \
  -pf -pk --coalesce-densest-as-needed --extend-zooms-if-still-dropping \
  "$OUT_DIR"/*.geojson

echo "✅ Fichier MBTiles généré : $MBTILES_FILE"

# 4) Vérifier la taille et déplacer si OK
if [[ -f "$MBTILES_FILE" ]]; then
  FILE_SIZE_BYTES=$(stat -c%s "$MBTILES_FILE")            # Linux
  FILE_SIZE_MB=$(( FILE_SIZE_BYTES / 1024 / 1024 ))

  echo "ℹ️  Taille de $MBTILES_FILE : ${FILE_SIZE_MB} Mo"
  if (( FILE_SIZE_MB >= MIN_SIZE_MB )); then
    mkdir -p "$DEST_DIR"
    echo "📦 Déplacement vers $DEST_DIR ..."
    mv "$MBTILES_FILE" "$DEST_DIR/"
    echo "✅ Déplacé : $DEST_DIR/$MBTILES_FILE"
  else
    echo "⚠️  Taille inférieure à ${MIN_SIZE_MB} Mo : fichier conservé localement."
  fi
else
  echo "❌ MBTiles introuvable après génération."
  exit 1
fi
