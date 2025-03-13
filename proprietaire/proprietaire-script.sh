#! /bin/bash
echo "Start tuile batiment_proprietaire data " $(date)

dbname="bati-foncier"

echo "Import data form Postgres begin" $(date)
rm -rf data && rm -f bati-proprietaire.mbtiles
mkdir data && cd data

bat_proprietaire="select *
	from public.batiment_proprietaire bp
"
ogr2ogr -f "GeoJSON" "bati-proprietaire.geojson" PG:"port=5433 dbname=$dbname user=postgres" -sql "$bat_proprietaire"

echo "Tuile JSON data with tippecanoe begin" $(date)
echo "Tuile data Batiment - Proprietairene" $(date)
tippecanoe --detect-shared-borders --simplify-only-low-zooms --generate-ids --read-parallel --force --coalesce-densest-as-needed -Z13 -z16 --output bati-proprietaire.mbtiles bati-proprietaire.geojson

mv bati-proprietaire.mbtiles ../.
cd .. && rm -rf data

echo End $(date)