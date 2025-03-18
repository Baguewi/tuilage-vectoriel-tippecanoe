#! /bin/bash
echo "Start tuile plu data " $(date)

dbname="bati-foncier"
host="localhost"
port="5432"
user="postgres"

echo "Import data form Postgres begin" $(date)
rm -rf data && rm -f plu-zone-urba.mbtiles
mkdir data && cd data

plu_request="select ogc_fid id, 
		libelle,
		replace(
			replace(
				replace(
					replace(
						replace(
							replace(
								replace(
									replace(
										replace(
											replace(
												replace(
													replace(
														replace(
															replace(libelong, 'Ã©', 'é') 
														,'Ã¨', 'è')
													,'Ã¯', 'ï')
												,'Ã´', 'ô')
											,'Ã§', 'ç')
										,'Ãª', 'ê')
									,'Ã¹', 'ù')
								,'Ã¦', 'æ')
							,'â¬', '€')
						,'Ã«', 'ë')
					,'Ã¼', 'ü')
				,'Ã¢', 'â')
			,'Â©', '©')
		,'Ã', 'à') libelong,
		typezone, datvalid, wkb_geometry geom
	from plu_zone_urba
"
ogr2ogr -f "GeoJSON" "plu-zone-urba.geojson" PG:"host=$host port=$port dbname=$dbname user=$user" -sql "$plu_request"

echo "Tuile JSON data with tippecanoe begin" $(date)
echo "Tuile data PLU zone-urba" $(date)
tippecanoe --detect-shared-borders --simplify-only-low-zooms --generate-ids --read-parallel --force --coalesce-densest-as-needed -Z10 -z16 --output plu-zone-urba.mbtiles plu-zone-urba.geojson

mv plu-zone-urba.mbtiles ../.
cd .. && rm -rf data

echo End $(date)