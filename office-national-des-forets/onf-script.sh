#!/bin/bash
echo "🚀 Démarrage de la génération des tuiles office-national-des-forets" $(date)

# 🔧 Paramètres de connexion PostgreSQL
dbname="office-national-des-forets"
host="localhost"
port="5432"
user="postgres"

# 🧹 Nettoyage et préparation du dossier
rm -rf data && rm -f office-national-des-forets.mbtiles
mkdir -p data
cd data

# 📤 Fonction générique d'export GeoJSON

function export_geojson {
    local fichier=$1
    local requete_sql=$2
    echo "📤 Export de ${fichier}.geojson" $(date)
    rm -f "${fichier}.geojson"
    ogr2ogr -f "GeoJSON" "${fichier}.geojson" \
        PG:"host=$host port=$port dbname=$dbname user=$user" \
        -sql "$requete_sql" \
        -t_srs EPSG:4326 \
        -lco RFC7946=YES \
        -lco COORDINATE_PRECISION=6 \
        -dim XY \
        -skipfailures
}

# 📦 Fonction générique de génération des tuiles vectorielles
function generate_tiles {
    local fichier=$1
    local nom_couche=$2
    echo "🧱 Génération des tuiles pour ${fichier}.geojson" $(date)
    tippecanoe --layer="$nom_couche" --detect-shared-borders --simplify-only-low-zooms --generate-ids --read-parallel --force -Z10 -z16 --output "${fichier}.mbtiles" "${fichier}.geojson"
    rm "${fichier}.geojson"
}

# 📌 Export des données par couche
export_geojson "aires_territoriales" "SELECT ccod_ag, llib_ag, wkb_geometry FROM public.ate_fr"
export_geojson "communes_rtm" "SELECT id, nom_com, nom_com_m, insee_com, statut, population, insee_arr, nom_dep, insee_dep, nom_reg, insee_reg, code_epci, shape_leng, shape_area, wkb_geometry FROM public.communes_rtm"
export_geojson "dispositifs_ddrtm" "SELECT code, nom, typeobjet, dept, sites, rattachem, devalide, geom_id, surf_dd, fid_1, code_1, nom_1, typeobje_1, dept_1, sites_1, rattache_1, devalide_1, geom_id_1, surf_dd_1, iidtn_frt, iidtn_prf, llib_frt, shape_leng, shape_area, wkb_geometry FROM public.ddrtm"
export_geojson "forets_publiques" "SELECT iidtn_frt, llib_frt, cdom_frt, cinse_dep, wkb_geometry FROM public.for_publ_fr"
export_geojson "parcs_publics" "SELECT iidtn_frt, llib_frt, ccod_prf, wkb_geometry FROM public.parc_publ_fr"
export_geojson "points_reperes_sensibles" "SELECT iidtn_prs, cinse_dep, loff_prs, cdfci_prs, ccod_cmat, ccod_ctps, llib_prs, lobs_prs, qlat_prs, qlon_prs, qdis_prs, llib_com, cinse_com, wkb_geometry FROM public.prs_fr"
export_geojson "risques_biologiques" "SELECT ccod_rb, ccod_reg, ccod_strb, ccod_trb, llib_rb, qsret_rb, id_spn, ccod_srb, yarr_rb, yarm_rb, yaccnpn_rb, yamcnpn_rb, ymaj_rb, ccod_mdpr, ccod_mdsr, qsfsig_rbg, qprm_rbg, wkb_geometry FROM public.rb_fr"

# 🧱 Génération des fichiers .mbtiles
generate_tiles "aires_territoriales" "ate_fr"
generate_tiles "communes_rtm" "communes_rtm"
generate_tiles "dispositifs_ddrtm" "ddrtm"
generate_tiles "forets_publiques" "for_publ_fr"
generate_tiles "parcs_publics" "parc_publ_fr"
generate_tiles "points_reperes_sensibles" "prs_fr"
generate_tiles "risques_biologiques" "rb_fr"

# 🧩 Fusion des tuiles avec attribution
echo "📦 Fusion des tuiles .mbtiles avec tile-join" $(date)
tile-join --name=office-national-des-forets --attribution="Timbi Dev (Mody Yaya DIALLO)" --no-tile-size-limit --force --output office-national-des-forets.mbtiles *.mbtiles

# 📁 Déplacement si le fichier est assez gros
FICHIER="office-national-des-forets.mbtiles"
MIN_SIZE_MB=10
if [ -f "$FICHIER" ]; then
    FILE_SIZE=$(stat -c%s "$FICHIER")
    FILE_SIZE_MB=$((FILE_SIZE / 1024 / 1024))
    if [ "$FILE_SIZE_MB" -ge "$MIN_SIZE_MB" ]; then
        echo "✅ Taille OK, déplacement vers /mnt/c/www/tileserver/"
        mv office-national-des-forets.mbtiles /mnt/c/www/tileserver/
    else
        echo "⚠️ Fichier trop petit ($FILE_SIZE_MB Mo), non déplacé."
    fi
fi

# 🧹 Nettoyage
cd .. && rm -rf data

echo "✅ Script terminé avec succès" $(date)
