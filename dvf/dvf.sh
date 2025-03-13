#! /bin/bash
echo "Start tuile DVF data " $(date)

dbname="bati-foncier"

echo "Import data form Postgres begin" $(date)
rm -rf data && rm -f dvf.mbtiles
mkdir data && 

cd data

echo "Import data dvf_info"
dvf_request="select ogc_fid id
				, min_date_mut min_date
				, max_date_mut max_date
				, min_val_fonc
				, max_val_fonc
				, nature
				, cp
				, insee
				, commune
				, dep
				, nb_mut
				, (select json_agg(mut) from dvf_mutation_info_data(mutation) mut) mutations
				, string_to_array(id, ',') parcelles
				, dvf_geometry(id) geom
			from dvf_info_parc"

parc_request="select d.id, ST_MakeValid(c.wkb_geometry) geom
			from dvf_parcelle d
				inner join cadastre c 
					on d.id = c.id"

echo "Import data DVF-DATA" $(date)
ogr2ogr -f "GeoJSON" "dvf-data.geojson" PG:"host=82.165.248.216 port=5433 dbname=$dbname user=postgres" -sql "$dvf_request"

echo "Import data DVF-PARCELLE" $(date)
ogr2ogr -f "GeoJSON" "dvf-cadastre.geojson" PG:"host=82.165.248.216 port=5433 dbname=$dbname user=postgres" -sql "$parc_request"

echo "Tuile JSON data with tippecanoe begin" $(date)
echo "Tuile data DVF-DATA" $(date)
tippecanoe --detect-shared-borders --simplify-only-low-zooms --generate-ids --read-parallel --force --coalesce-densest-as-needed -Z10 -z16 --output dvf-data.mbtiles dvf-data.geojson
rm dvf-data.geojson

echo "Tuile data DVF-PARCELLE" $(date)
tippecanoe --detect-shared-borders --simplify-only-low-zooms --generate-ids --read-parallel --force --coalesce-densest-as-needed -Z10 -z16 --output dvf-cadastre.mbtiles dvf-cadastre.geojson
rm dvf-cadastre.geojson

echo "Tuile data JOIN" $(date)
tile-join '--attribution=Etalab' '--name=dvf' --no-tile-size-limit --force --output dvf.mbtiles dvf-data.mbtiles dvf-cadastre.mbtiles

mv dvf.mbtiles ../.
# cd .. && rm -rf data

echo End $(date)