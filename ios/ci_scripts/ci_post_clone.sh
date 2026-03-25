#!/bin/sh

# ─── Xcode Cloud — Post-Clone Script ────────────────────────────────────────
# Fichier à placer dans : ci_scripts/ci_post_clone.sh
# (à la racine du repo, dans un dossier ci_scripts/)
#
# Résout les deux erreurs :
#   - Generated.xcconfig not found  → flutter pub get
#   - Pods xcfilelist not found     → pod install

set -e  # Arrêter si une commande échoue

echo "▶ Post-clone script démarré"

# ─── 1. Installer Flutter ────────────────────────────────────────────────────

FLUTTER_VERSION="3.35.5"   # ← adapte à ta version Flutter (flutter --version)
FLUTTER_DIR="$HOME/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  echo "▶ Téléchargement de Flutter $FLUTTER_VERSION..."
  curl -L "https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_${FLUTTER_VERSION}-stable.zip" \
    -o flutter.zip
  unzip -q flutter.zip -d "$HOME"
  rm flutter.zip
fi

export PATH="$FLUTTER_DIR/bin:$PATH"
echo "▶ Flutter version : $(flutter --version --machine | grep '"frameworkVersion"' | head -1)"

# ─── 2. Désactiver analytics Flutter (évite les prompts interactifs) ─────────
flutter config --no-analytics

# ─── 3. flutter pub get ──────────────────────────────────────────────────────
echo "▶ flutter pub get..."
cd "$CI_PRIMARY_REPOSITORY_PATH"
flutter pub get

# ─── 4. pod install ──────────────────────────────────────────────────────────
echo "▶ pod install..."
cd "$CI_PRIMARY_REPOSITORY_PATH/ios"

# Mettre à jour le repo CocoaPods si besoin
# pod repo update  # décommenter si tu as des pods privés

pod install --repo-update

echo "✓ Post-clone terminé"