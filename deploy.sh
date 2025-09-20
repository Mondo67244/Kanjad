#!/bin/bash

# Script de déploiement optimisé pour Kanjad avec pré-compression Gzip

set -e

echo "🚀 Début du déploiement optimisé Kanjad"

# Variables
BUILD_DIR="build/web"
DEPLOY_DIR="/var/www/kanjad"
SERVER_USER="kanjad"
SERVER_HOST="kanjad.cm"
SSH_PORT="22"

# Étape 1: Nettoyage du build Flutter précédent
echo "🧹 Nettoyage build précédent..."
rm -rf "$BUILD_DIR"

# Étape 2: Build optimisé
echo "🔨 Build Flutter Web optimisé..."
flutter build web --release \
  --dart-define=FLUTTER_WEB_USE_SKIA=true \
  --pwa-strategy=offline-first
#  --wasm  # si nécessaire

# Étape 3: Optimisation des images (parallélisée)
if command -v convert >/dev/null 2>&1; then
    echo "🖼️ Optimisation des images..."
    find "$BUILD_DIR/assets" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) \
        -print0 | xargs -0 -P 4 convert -strip -quality 85 -resize 1920x1080\>
fi

# Étape 4: Pré-compression Gzip
if command -v gzip >/dev/null 2>&1; then
    echo "🗜️ Compression Gzip des fichiers statiques..."
    find "$BUILD_DIR" -type f \( -name "*.js" -o -name "*.css" -o -name "*.html" -o -name "*.json" -o -name "*.wasm" \) \
        -exec gzip -k -9 {} \;
fi

# Étape 5: Analyse des tailles de fichiers
echo "📊 Analyse des tailles de fichiers après optimisation:"
du -sh "$BUILD_DIR"/*
ls -lh "$BUILD_DIR/main.dart.js"

# Étape 6: Déploiement
echo "📤 Déploiement vers $SERVER_USER@$SERVER_HOST:$SSH_PORT..."

if ssh -p "$SSH_PORT" -o ConnectTimeout=10 "$SERVER_USER@$SERVER_HOST" "echo 'Connexion SSH OK'" 2>/dev/null; then
echo " Suppression de tous les fichiers de kanjad"
    # Supprimer complètement tous les fichiers/dossiers existants sur le serveur
    ssh -p "$SSH_PORT" "$SERVER_USER@$SERVER_HOST" "rm -rf $DEPLOY_DIR/*"
echo " Transfert du nouveau build"
    # Transfert du nouveau build
    rsync -avz --no-owner --no-group -e "ssh -p $SSH_PORT" "$BUILD_DIR/" "$SERVER_USER@$SERVER_HOST:$DEPLOY_DIR/"

    echo "✅ Déploiement réussi"

else
    echo "❌ Connexion SSH échouée"
    echo "👉 Essayez: scp -P $SSH_PORT -r $BUILD_DIR/* $SERVER_USER@$SERVER_HOST:$DEPLOY_DIR/"
    exit 1
fi

# Étape 7: Fin
echo "✅ Déploiement terminé!"
echo "📈 Optimisations appliquées:"
echo "  • Images optimisées"
echo "  • Compression Gzip générée"
echo "  • Cache HTTP optimisé via Caddy"
echo "  • Flutter Web Skia activé"
echo "🌐 Site disponible sur: https://$SERVER_HOST"
echo "📋 Logs Caddy: journalctl -fu caddy"
echo "🎉 Déploiement terminé avec succès!"
