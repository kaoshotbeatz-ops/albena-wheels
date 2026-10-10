#!/usr/bin/env bash
# Build PyAV + OpenCV wheels against the LGPL FFmpeg in <workdir>/prefix.
# Usage: build-wheels.sh <workdir> <python> <outdir> [repair-cmd...]   (run after build-deps.sh)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; . "$ROOT/scripts/versions.env"
W="$(cd "$1" && pwd)"; PY="$2"; OUT="$3"; mkdir -p "$OUT"; OUT="$(cd "$OUT" && pwd)"
PREFIX="$W/prefix"; OS="$(uname -s)"; JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN)}"
fetch() { local f="$ROOT/src/$(basename "$1")"; [ -f "$f" ] || curl -fsSL -o "$f" "$1"; echo "$f"; }
RAW="$W/raw"; rm -rf "$RAW"; mkdir -p "$RAW"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
[ "$OS" = Darwin ] && export MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-13.0}"
[ "$OS" = Linux ] && export LD_LIBRARY_PATH="$PREFIX/lib"
[ "$OS" = Darwin ] && export DYLD_FALLBACK_LIBRARY_PATH="$PREFIX/lib"

# --- PyAV (BSD-3) against our FFmpeg ---
"$PY" -m pip -q install "cython>=3.1,<3.2" setuptools wheel
"$PY" -m pip wheel --no-deps --no-build-isolation --no-binary av -w "$RAW" "$(fetch $AV_URL)"
# --- OpenCV headless (Apache-2.0), FFmpeg/IPP/GStreamer disabled ---
export ENABLE_HEADLESS=1 MAKEFLAGS="-j$JOBS"
export CMAKE_ARGS="-DWITH_FFMPEG=OFF -DWITH_GSTREAMER=OFF -DWITH_IPP=OFF -DWITH_ITT=OFF -DWITH_1394=OFF -DOPENCV_ENABLE_NONFREE=OFF -DCMAKE_BUILD_TYPE=Release -DWITH_AVIF=OFF"
[ "$OS" = Darwin ] && CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_IGNORE_PREFIX_PATH=/opt/homebrew;/usr/local" && export CMAKE_ARGS
"$PY" -m pip wheel --no-deps -w "$RAW" "$(fetch $CV_URL)" -v
shift 3
"$@"   # repair command (auditwheel / delocate) is supplied by the caller
