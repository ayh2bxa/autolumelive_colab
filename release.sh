#!/bin/bash
set -e

echo "Cleaning up old builds..."
rm -rf dist build

VENV_SITE="venv/lib/python3.10/site-packages"

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

echo "Packaging for distribution..."
cd dist
zip -r Autolume-mac.zip Autolume/
cd ..

echo "Done! dist/Autolume-mac.zip is ready to distribute."
