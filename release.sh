#!/bin/bash
set -e

# ── Code signing credentials ──────────────────────────────────────────────────
SIGN_IDENTITY="Developer ID Application: Philippe Pasquier (F552F7HWJ5)"
APPLE_ID="pasquier@sfu.ca"       # replace with Philippe's Apple ID
TEAM_ID="F552F7HWJ5"
APP_PASSWORD="xtzt-bmni-fgag-kxps"
# ─────────────────────────────────────────────────────────────────────────────

VENV_SITE="venv/lib/python3.10/site-packages"

echo "Cleaning up old builds..."
rm -rf dist build

mkdir -p recordings

echo "Running PyInstaller..."
venv/bin/pyinstaller main.py \
  --name Autolume \
  --add-binary "$(which ffmpeg):bin" \
  --add-binary "$(which ffprobe):bin" \
  --add-binary "${VENV_SITE}/ninja/data/bin/ninja:." \
  --add-binary "${VENV_SITE}/torch/lib/libc10.dylib:torch/lib" \
  --add-binary "${VENV_SITE}/torch/lib/libomp.dylib:torch/lib" \
  --add-binary "${VENV_SITE}/torch/lib/libshm.dylib:torch/lib" \
  --add-binary "${VENV_SITE}/torch/lib/libtorch_cpu.dylib:torch/lib" \
  --add-binary "${VENV_SITE}/torch/lib/libtorch.dylib:torch/lib" \
  --add-binary "${VENV_SITE}/torch/lib/libtorch_python.dylib:torch/lib" \
  --add-data "architectures:architectures" \
  --add-data "assets:assets" \
  --add-data "training:training" \
  --add-data "torch_utils:torch_utils" \
  --add-data "recordings:recordings" \
  --add-data "${VENV_SITE}/clip/bpe_simple_vocab_16e6.txt.gz:clip" \
  --add-data "${VENV_SITE}/torch/include:torch/include" \
  --collect-all "glfw" \
  --collect-all "ffmpeg" \
  --collect-all "lpips" \
  --collect-all "setuptools" \
  --hidden-import "backports.tarfile"

echo "Copying assets..."
cp -r assets dist/Autolume/assets

echo "Copying sr_models..."
cp -r sr_models dist/Autolume/sr_models

echo "Creating directories..."
mkdir -p dist/Autolume/models
mkdir -p dist/Autolume/screenshots
mkdir -p dist/Autolume/recordings
mkdir -p dist/Autolume/training-runs

echo "Code signing..."

ENTITLEMENTS="$(pwd)/entitlements.plist"

# Sign all .dylib and .so files
find dist/Autolume/_internal \( -name "*.dylib" -o -name "*.so" \) | while read f; do
  codesign --force --sign "${SIGN_IDENTITY}" --timestamp --options runtime \
    --entitlements "${ENTITLEMENTS}" "$f"
done

# Sign all Mach-O executables (ninja, ffmpeg, ffprobe, torch binaries, etc.)
find dist/Autolume/_internal -type f ! -name "*.dylib" ! -name "*.so" \
  ! -name "*.py" ! -name "*.pyc" ! -name "*.pyz" | while read f; do
  if file "$f" | grep -q "Mach-O"; then
    codesign --force --sign "${SIGN_IDENTITY}" --timestamp --options runtime \
      --entitlements "${ENTITLEMENTS}" "$f"
  fi
done

# Sign Python binary directly (framework structure is incomplete after PyInstaller)
codesign --remove-signature dist/Autolume/_internal/Python.framework/Versions/3.10/Python 2>/dev/null || true
codesign --force --sign "${SIGN_IDENTITY}" --timestamp --options runtime \
  --entitlements "${ENTITLEMENTS}" \
  dist/Autolume/_internal/Python.framework/Versions/3.10/Python

# Sign main executable last
codesign --force --sign "${SIGN_IDENTITY}" --timestamp --options runtime \
  --entitlements "${ENTITLEMENTS}" dist/Autolume/Autolume

echo "Creating DMG..."
hdiutil create -volname "Autolume" -srcfolder dist/Autolume -ov -format UDZO dist/Autolume-mac.dmg

echo "Notarizing (this takes a few minutes)..."
xcrun notarytool submit dist/Autolume-mac.dmg \
  --apple-id "${APPLE_ID}" \
  --team-id "${TEAM_ID}" \
  --password "${APP_PASSWORD}" \
  --wait

echo "Stapling notarization ticket..."
xcrun stapler staple dist/Autolume-mac.dmg

echo "Done! dist/Autolume-mac.dmg is ready to distribute."
