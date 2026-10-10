#!/usr/bin/env bash
# Package the LGPL ffmpeg/ffprobe CLI (macOS arm64) from <workdir>/prefix, relocatable via @rpath. Optional product.
# Usage: package-cli-macos.sh <workdir> <outdir>
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; . "$ROOT/scripts/versions.env"
PFX="$(cd "$1" && pwd)/prefix"; OUT="$(mkdir -p "$2" && cd "$2" && pwd)"
N="albena-ffmpeg-$FFMPEG_VER-macos-arm64"; T="$(mktemp -d)"; D="$T/$N"; mkdir -p "$D/bin" "$D/lib"
cp "$PFX/bin/ffmpeg" "$PFX/bin/ffprobe" "$D/bin/"
cd "$D/lib"
for l in avcodec avdevice avfilter avformat avutil swresample swscale; do cp "$PFX"/lib/lib$l.*.*.*.dylib .; done
for f in lib*.*.*.*.dylib; do b=${f%%.*}; m=$(echo "$f" | cut -d. -f2); ln -sf "$f" "$b.$m.dylib"
  install_name_tool -id "@rpath/$b.$m.dylib" "$f"
  for g in $(otool -L "$f" | awk '{print $1}' | grep "^$PFX/lib"); do install_name_tool -change "$g" "@rpath/$(basename "$g")" "$f"; done
  install_name_tool -add_rpath @loader_path "$f"; done
cd ../bin
for b in ffmpeg ffprobe; do for g in $(otool -L $b | awk '{print $1}' | grep "^$PFX/lib"); do install_name_tool -change "$g" "@rpath/$(basename "$g")" $b; done
  install_name_tool -add_rpath @loader_path/../lib $b; done
cd ..; codesign --force -s - lib/lib*.*.*.*.dylib bin/*
cp "$ROOT/LICENSES.md" "$ROOT/SOURCE-OFFER.md" .
tar --uid 0 --gid 0 -czf "$OUT/$N.tar.gz" -C "$T" "$N"; echo "wrote $OUT/$N.tar.gz"
