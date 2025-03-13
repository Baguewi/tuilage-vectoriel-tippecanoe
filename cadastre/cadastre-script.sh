#! /bin/bash
echo "Start tuile cadastre data " $(date)

dbname="bati-foncier"

echo "Import data form Postgres begin" $(date)
rm -rf data && rm -f cadastre.mbtiles
mkdir data && cd data

parcelles="select *
	from public.cadastre;
"
ogr2ogr -f "GeoJSON" "parcelles.geojson" PG:"host=82.165.248.216 port=5433 dbname=$dbname user=postgres" -sql "$parcelles"

echo "Tuile JSON data with tippecanoe begin" $(date)
echo "Tuile data cadastre" $(date)

tippecanoe --detect-shared-borders --simplify-only-low-zooms --generate-ids --read-parallel --force --coalesce-densest-as-needed -Z13 -z16 --output cadastre.mbtiles parcelles.geojson

mv cadastre.mbtiles ../.
cd .. && rm -rf data

echo End $(date)