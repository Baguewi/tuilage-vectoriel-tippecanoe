#!/bin/bash
echo "🚀 Début génération tuiles Cimetières" $(date)

# Paramètres PostgreSQL
dbname="osm_france_cemeteries"
host="localhost"
port="5432"
user="postgres"

# Nettoyage ancien dossier + création
rm -rf data && rm -f cemeteries.mbtiles
mkdir -p data
cd data

# Requête SQL : sélection des colonnes utiles avec alias plus clairs
echo "📥 Extraction des données Cimetières depuis PostgreSQL" $(date)
sql_request="
    SELECT
        osm_id AS id,
        geom,
		area_m2 AS surface,
        name AS nom,
        name_fr,
        name_en,
        addr_city AS ville,
        addr_postcode AS code_postal,
        addr_street AS rue,
        addr_housenumber AS numero,
        landuse,
        amenity,
        cemetery_type AS type_cimetiere,
        religion,
        denomination,
        \"operator\" AS operateur,
        operator_type AS type_operateur,
        fee AS payant,
        wheelchair AS acces_pm,
        opening_hours AS horaires,
        website AS site_web,
		contact_website, 
		phone AS telephone, 
		email,
        wikidata,
        wikipedia,
        source
    FROM public.osm_cemeteries
    WHERE geom_webmerc IS NOT NULL
"

# Export GeoJSON
echo "📄 Export GeoJSON depuis la BDD" $(date)
ogr2ogr -f "GeoJSON" "cemeteries.geojson" PG:"host=$host port=$port dbname=$dbname user=$user" -sql "$sql_request"

# Génération des tuiles avec Tippecanoe
echo "🗺️  Génération des tuiles vectorielles avec Tippecanoe" $(date)
tippecanoe \
  --read-parallel \
  --force \
  --no-feature-limit \
  --no-tile-size-limit \
  --maximum-tile-bytes=50000000 \
  --minimum-zoom=3 \
  --maximum-zoom=15 \
  --layer=cemeteries \
  --output cemeteries.mbtiles \
  cemeteries.geojson

# Suppression du fichier GeoJSON
rm cemeteries.geojson

# Déplacement du fichier mbtiles si > 10 Mo
FICHIER="cemeteries.mbtiles"
MIN_SIZE_MB=10
if [ -f "$FICHIER" ]; then
    FILE_SIZE=$(stat -c%s "$FICHIER")
    FILE_SIZE_MB=$((FILE_SIZE / 1024 / 1024))
    if [ "$FILE_SIZE_MB" -ge "$MIN_SIZE_MB" ]; then
        echo "✅ Fichier généré > $MIN_SIZE_MB Mo, déplacement vers /mnt/c/www/tileserver/"
        mv "$FICHIER" /mnt/c/www/tileserver/
    else
        echo "⚠️  Fichier généré trop petit (${FILE_SIZE_MB} Mo), non déplacé."
    fi
fi

# Nettoyage
cd .. && rm -rf data

echo "✅ Fin du script Cimetières" $(date)
