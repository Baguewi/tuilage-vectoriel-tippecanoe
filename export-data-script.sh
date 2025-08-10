#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="/mnt/c/www/tileserver"
DEST_HOST="82.165.248.216"
DEST_USER="root"
DEST_DIR="/var/www/tileserver"
REMOTE_SCRIPT="docker-run.sh"

# Lancer rsync et capturer sa sortie
RSYNC_OUTPUT=$(rsync -avz --update --inplace --partial \
  --include='*.mbtiles' --exclude='*' \
  -e "ssh -o StrictHostKeyChecking=no" \
  "$SRC_DIR/" "$DEST_USER@$DEST_HOST:$DEST_DIR/")

echo "$RSYNC_OUTPUT"

# Vérifier s'il y a eu des fichiers transférés (hors "sending incremental file list")
if echo "$RSYNC_OUTPUT" | grep -q -E -v '^(sending incremental file list|sent [0-9]|total size is)'; then
    echo "📦 Des fichiers ont été mis à jour, exécution de docker-run.sh..."
    ssh -o StrictHostKeyChecking=no "$DEST_USER@$DEST_HOST" \
    "set -e; cd '/root'; bash '$REMOTE_SCRIPT'"
else
    echo "ℹ️ Aucun fichier mis à jour, docker-run.sh non exécuté."
fi

echo "✅ Synchronisation terminée."
