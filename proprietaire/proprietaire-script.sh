#! /bin/bash
echo "Start tuile batiment_proprietaire data " $(date)

dbname="bati"
host="localhost"
port="5432"
user="postgres"

echo "Import data form Postgres begin" $(date)
rm -rf data && rm -f bati-proprietaire.mbtiles
mkdir data && cd data

bat_proprietaire="select *
	from public.batiment_proprietaire bp
"
ogr2ogr -f "GeoJSON" "bati-proprietaire.geojson" PG:"port=$port dbname=$dbname user=$user" -sql "$bat_proprietaire"

echo "Tuile JSON data with tippecanoe begin" $(date)
echo "Tuile data Batiment - Proprietairene" $(date)
tippecanoe --detect-shared-borders --simplify-only-low-zooms --generate-ids --read-parallel --force --coalesce-densest-as-needed -Z13 -z16 --output bati-proprietaire.mbtiles bati-proprietaire.geojson

FICHIER="bati-proprietaire.mbtiles"
MIN_SIZE_MB=1000

if [ -f "$FICHIER" ]; then
    FILE_SIZE=$(stat -c%s "$FICHIER")
    FILE_SIZE_MB=$((FILE_SIZE / 1024 / 1024))
    if [ "$FILE_SIZE_MB" -ge "$MIN_SIZE_MB" ]; then
        mv bati-proprietaire.mbtiles /mnt/c/www/tileserver/
    fi
fi

rm -rf *.mbtiles
rm -rf *.geojson

echo End $(date)