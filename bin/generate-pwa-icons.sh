#!/bin/bash
# bin/generate-pwa-icons.sh
# Génère les icônes PNG pour la PWA à partir du SVG master
# Utilise ImageMagick (convert) et optrek (cairosvg)

set -e

ICONS_DIR="public/icons"
SVG_SOURCE="$ICONS_DIR/icon.svg"

echo "🎨 Generating PWA icons from $SVG_SOURCE..."

# Vérifier que le fichier SVG existe
if [ ! -f "$SVG_SOURCE" ]; then
  echo "❌ SVG source not found: $SVG_SOURCE"
  exit 1
fi

# Vérifier que ImageMagick ou optrek est disponible
if ! command -v convert &> /dev/null && ! command -v cairosvg &> /dev/null; then
  echo "❌ Either ImageMagick (convert) or cairosvg required"
  echo "   Install: sudo apt-get install imagemagick"
  echo "   Or:      pip install cairosvg"
  exit 1
fi

# Générer les icônes PNG en différentes tailles
SIZES=(192 512)
for size in "${SIZES[@]}"; do
  OUTPUT="$ICONS_DIR/icon-${size}x${size}.png"
  
  if command -v cairosvg &> /dev/null; then
    cairosvg "$SVG_SOURCE" -w "$size" -h "$size" -o "$OUTPUT"
  else
    # Convert (ImageMagick)
    convert -background none -size "${size}x${size}" "$SVG_SOURCE" -trim +repage -resize "${size}x${size}" -gravity center -extent "${size}x${size}" "$OUTPUT"
  fi
  
  echo "✅ Generated $OUTPUT"
done

# Générer les maskable versions (rounded, pour adaptatibe icons)
for size in "${SIZES[@]}"; do
  OUTPUT="$ICONS_DIR/icon-${size}x${size}-maskable.png"
  SOURCE="$ICONS_DIR/icon-${size}x${size}.png"
  
  if [ -f "$SOURCE" ]; then
    if command -v convert &> /dev/null; then
      # Ajouter du padding pour la version maskable
      convert "$SOURCE" \
        -background "rgba(99, 102, 241, 1)" \
        -gravity center \
        -extent "$((size + 40))x$((size + 40))" \
        -resize "${size}x${size}" \
        "$OUTPUT"
      echo "✅ Generated $OUTPUT (maskable)"
    fi
  fi
done

# Générer les screenshots
echo "📸 Generating screenshots..."
SCREENSHOT_WIDTH=540
SCREENSHOT_HEIGHT=720

if command -v cairosvg &> /dev/null; then
  cairosvg "$SVG_SOURCE" -w "$SCREENSHOT_WIDTH" -h "$SCREENSHOT_HEIGHT" -o "$ICONS_DIR/screenshot-540x720.png" 2>/dev/null || true
fi

echo "✨ PWA icons generation complete!"
