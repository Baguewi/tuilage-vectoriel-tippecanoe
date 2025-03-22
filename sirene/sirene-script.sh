#! /bin/bash
echo "Start" $(date)
rm -f *.geojson
rm -rf *.mbtiles

dbname="sirene"
host="localhost"
port="5432"
user="postgres"
echo "Import data form Postgres begin" $(date)

etab_sirene="select siren, siret, raison_soc, creation_etab, creation_ent, employeur_etab, 
		effectif_etab, anneeeffectif_etab, employeur_ent, effectif_ent, anneeeffectif_ent, 
		siege, s.adresse, cp, s.commune, compl_adr, code_insee, enseigne, 
		code_naf_etab, code_naf_ent, sigle, categorie, anneecategorie, cat_juridique,
		g.result_score, g.result_type, ST_Point(longitude, latitude, 4326) geom
	from public.sirene s 
		inner join sirene_geocode g 
			on s.siret = g.id
	where cat_juridique <> '1000' and cat_juridique not like '7%' and g.longitude is not null and g.latitude is not null and g.result_score >= 0.5"

etab_public="select siren, siret, raison_soc, creation_etab, creation_ent, employeur_etab, 
		effectif_etab, anneeeffectif_etab, employeur_ent, effectif_ent, anneeeffectif_ent, 
		siege, s.adresse, cp, s.commune, compl_adr, code_insee, enseigne, 
		code_naf_etab, code_naf_ent, sigle, categorie, anneecategorie, cat_juridique,
		g.result_score, g.result_type, ST_Point(longitude, latitude, 4326) geom
	from public.sirene s 
		inner join sirene_geocode g 
			on s.siret = g.id
	where cat_juridique <> '1000' and cat_juridique like '7%' and g.longitude is not null and g.latitude is not null and g.result_score >= 0.5"

ent_individuel="select s.*, g.result_score, g.result_type, ST_Point(longitude, latitude, 4326) geom
	from public.sirene s 
		inner join sirene_geocode g 
			on s.siret = g.id
	where cat_juridique = '1000' and g.longitude is not null and g.latitude is not null and g.result_score >= 0.5"

echo "Import sirene" $(date)
ogr2ogr -f "GeoJSON" "sirene.geojson" PG:"host=$host port=$port dbname=$dbname user=$user" -sql "$etab_sirene"
echo "Import etab public et assos" $(date)
ogr2ogr -f "GeoJSON" "etab_public.geojson" PG:"host=$host port=$port dbname=$dbname user=$user" -sql "$etab_public"
echo "Import entreprise individuel" $(date)
ogr2ogr -f "GeoJSON" "ent_individuel.geojson" PG:"host=$host port=$port dbname=$dbname user=$user" -sql "$ent_individuel"

echo "Tuile JSON data with tippecanoe begin" $(date)
echo "Tuile data sirene" $(date)
tippecanoe -f -o sirene.mbtiles -Z13 -z16 -pf -pk --generate-ids --read-parallel --cluster-densest-as-needed --extend-zooms-if-still-dropping sirene.geojson
tippecanoe -f -o cluster_sirene.mbtiles -Z12 -z16 -r1 --generate-ids --read-parallel --cluster-distance=20 sirene.geojson

echo "Tuile data etab public et assos" $(date)
tippecanoe -f -o etab_public.mbtiles -Z13 -z16 -pf -pk --generate-ids --read-parallel --cluster-densest-as-needed --extend-zooms-if-still-dropping etab_public.geojson
#tippecanoe -f -o cluster_etab_public.mbtiles -Z12 -z16 -r1 --generate-ids --read-parallel --cluster-distance=20 etab_public.geojson

echo "Tuile data entreprise individuel" $(date)
tippecanoe -f -o ent_individuel.mbtiles -Z13 -z16 -pf -pk --generate-ids --read-parallel --cluster-densest-as-needed --extend-zooms-if-still-dropping ent_individuel.geojson
#tippecanoe -f -o cluster_ent_individuel.mbtiles -Z12 -z16 -r1 --generate-ids --read-parallel --cluster-distance=20 ent_individuel.geojson

echo "Tuile data entreprise" $(date)
tile-join '--attribution=Timbi dev (Mody Yaya DIALLO)' -f -o etablissement.mbtiles -pk sirene.mbtiles etab_public.mbtiles ent_individuel.mbtiles cluster_sirene.mbtiles

sirene="sirene.mbtiles"
MIN_SIZE_MB=10

if [ -f "$sirene" ]; then
    FILE_SIZE=$(stat -c%s "$sirene")
    FILE_SIZE_MB=$((FILE_SIZE / 1024 / 1024))
    if [ "$FILE_SIZE_MB" -ge "$MIN_SIZE_MB" ]; then
        mv sirene.mbtiles /mnt/c/www/tileserver/
    fi
fi

etab_public="etab_public.mbtiles"
if [ -f "$etab_public" ]; then
    FILE_SIZE=$(stat -c%s "$etab_public")
    FILE_SIZE_MB=$((FILE_SIZE / 1024 / 1024))
    if [ "$FILE_SIZE_MB" -ge "$MIN_SIZE_MB" ]; then
        mv etab_public.mbtiles /mnt/c/www/tileserver/
    fi
fi

ent_individuel="ent_individuel.mbtiles"
if [ -f "$ent_individuel" ]; then
    FILE_SIZE=$(stat -c%s "$ent_individuel")
    FILE_SIZE_MB=$((FILE_SIZE / 1024 / 1024))
    if [ "$FILE_SIZE_MB" -ge "$MIN_SIZE_MB" ]; then
        mv ent_individuel.mbtiles /mnt/c/www/tileserver/
    fi
fi

etablissement="etablissement.mbtiles"
if [ -f "$etablissement" ]; then
    FILE_SIZE=$(stat -c%s "$etablissement")
    FILE_SIZE_MB=$((FILE_SIZE / 1024 / 1024))
    if [ "$FILE_SIZE_MB" -ge "$MIN_SIZE_MB" ]; then
        mv etablissement.mbtiles /mnt/c/www/tileserver/
    fi
fi

rm -rf *.mbtiles

echo End $(date)