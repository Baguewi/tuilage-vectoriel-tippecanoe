#!/bin/bash
echo "🚀 Début génération tuiles ICPE" $(date)

# Paramètres PostgreSQL
dbname="icpe_db"
host="localhost"
port="5432"
user="postgres"

# Nettoyage ancien dossier + création
rm -rf data && rm -f icpe.mbtiles
mkdir -p data
cd data

# Requête SQL : sélection des colonnes nécessaires
echo "📥 Extraction des données ICPE depuis PostgreSQL" $(date)
sql_request="
	SELECT 
		ogc_fid id,
		code_aiot,
		nom_ets,
		num_dep,
		adresse,
		cd_insee,
		cd_postal,
		commune,
		code_naf,
		lib_naf,
		num_siret,
		cd_regime,
		lib_regime,
		seveso,
		lib_seveso,
		CAST(bovins AS boolean) AS bovins,
		CAST(porcs AS boolean) AS porcs,
		CAST(volailles AS boolean) AS volailles,
		CAST(carriere AS boolean) AS carriere,
		CAST(eolienne AS boolean) AS eolienne,
		CAST(industrie AS boolean) AS industrie,
		CAST(ied AS boolean) AS ied,
		CAST(priorite_nationale AS boolean) AS priorite_nationale,
		rubriques_autorisation AS autorisation,
		rubriques_enregistrement AS enregistrement,
		rubriques_declaration AS declaration,
		date_modification,
		derniere_inspection,
		url_fiche,
		ST_MakeValid(wkb_geometry) AS geom
	FROM public.installations_classees
	WHERE wkb_geometry IS NOT NULL"

# Export GeoJSON
echo "📄 Export GeoJSON depuis la BDD" $(date)
ogr2ogr -f "GeoJSON" "icpe.geojson" PG:"host=$host port=$port dbname=$dbname user=$user" -sql "$sql_request"

# Génération des tuiles avec Tippecanoe
echo "🗺️  Génération des tuiles vectorielles avec Tippecanoe" $(date)
tippecanoe \
  --read-parallel \
  --force \
  --no-feature-limit \
  --no-tile-size-limit \
  --maximum-tile-bytes=50000000 \
  --minimum-zoom=8 \
  --maximum-zoom=13 \
  --layer=icpe \
  --output icpe.mbtiles \
  icpe.geojson

# Suppression du fichier GeoJSON
rm icpe.geojson

# Déplacement du fichier mbtiles si > 10 Mo
FICHIER="icpe.mbtiles"
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

echo "✅ Fin du script ICPE" $(date)
