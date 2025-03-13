#! /bin/bash
echo "Start" $(date)
rm -f *.geojson

dbname="sirene"
echo "Import data form Postgres begin" $(date)

etab_sirene="select siren, siret, raison_soc, creation_etab, creation_ent, employeur_etab, 
		effectif_etab, anneeeffectif_etab, employeur_ent, effectif_ent, anneeeffectif_ent, 
		siege, s.adresse, cp, s.commune, compl_adr, code_insee, enseigne, 
		code_naf_etab, code_naf_ent, sigle, categorie, anneecategorie, cat_juridique,
		g.result_score, g.result_type, ST_Point(longitude, latitude, 4326) geom
	from public.sirene s 
		inner join sirene_geocode g 
			on s.siret = g.id
	where cat_juridique <> '1000' and cat_juridique not like '7%' and g.longitude is not null and g.latitude is not null and g.result_score >= 0.5 
	limit 100000"

etab_public="select siren, siret, raison_soc, creation_etab, creation_ent, employeur_etab, 
		effectif_etab, anneeeffectif_etab, employeur_ent, effectif_ent, anneeeffectif_ent, 
		siege, s.adresse, cp, s.commune, compl_adr, code_insee, enseigne, 
		code_naf_etab, code_naf_ent, sigle, categorie, anneecategorie, cat_juridique,
		g.result_score, g.result_type, ST_Point(longitude, latitude, 4326) geom
	from public.sirene s 
		inner join sirene_geocode g 
			on s.siret = g.id
	where cat_juridique <> '1000' and cat_juridique like '7%' and g.longitude is not null and g.latitude is not null and g.result_score >= 0.5 limit 10000"

ent_individuel="select s.*, g.result_score, g.result_type, ST_Point(longitude, latitude, 4326) geom
	from public.sirene s 
		inner join sirene_geocode g 
			on s.siret = g.id
	where cat_juridique = '1000' and g.longitude is not null and g.latitude is not null and g.result_score >= 0.5 limit 10000"

echo "Import sirene" $(date)
ogr2ogr -f "GeoJSON" "sirene.geojson" PG:"host=82.165.248.216 port=5433 dbname=$dbname user=postgres" -sql "$etab_sirene"
echo "Import etab public et assos" $(date)
#ogr2ogr -f "GeoJSON" "etab_public.geojson" PG:"host=82.165.248.216 port=5433 dbname=$dbname user=postgres" -sql "$etab_public"
echo "Import entreprise individuel" $(date)
#ogr2ogr -f "GeoJSON" "ent_individuel.geojson" PG:"host=82.165.248.216 port=5433 dbname=$dbname user=postgres" -sql "$ent_individuel"

echo "Tuile JSON data with tippecanoe begin" $(date)
echo "Tuile data sirene" $(date)
tippecanoe -f -o sirene.mbtiles -Z12 -z16 -r1 --generate-ids --read-parallel --cluster-distance=20 sirene.geojson

echo "Tuile data etab public et assos" $(date)
#tippecanoe -f -o etab_public.mbtiles -Z13 -z16 -pf -pk --generate-ids --read-parallel --cluster-radius=50 --cluster-densest-as-needed --extend-zooms-if-still-dropping etab_public.geojson
echo "Tuile data entreprise individuel" $(date)
#tippecanoe -f -o ent_individuel.mbtiles -Z13 -z16 -pf -pk --generate-ids --read-parallel --cluster-radius=50 --cluster-densest-as-needed --extend-zooms-if-still-dropping ent_individuel.geojson

echo "Tuile data entreprise individuel" $(date)
#tile-join -f -o etablissement.mbtiles -pk sirene.mbtiles etab_public.mbtiles ent_individuel.mbtiles 

echo End $(date)