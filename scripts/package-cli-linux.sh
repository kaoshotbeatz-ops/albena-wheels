#!/usr/bin/env bash
# Package the LGPL ffmpeg/ffprobe CLI (Linux x86_64) from <workdir>/prefix, self-contained via RUNPATH $ORIGIN.
# Usage: package-cli-linux.sh <workdir> <outdir>   (needs patchelf; run after build-deps.sh)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; . "$ROOT/scripts/versions.env"
S="$(cd "$1" && pwd)/prefix"; OUT="$(mkdir -p "$2" && cd "$2" && pwd)"
N="albena-ffmpeg-$FFMPEG_VER-linux-x86_64"; T="$(mktemp -d)"; D="$T/$N"; mkdir -p "$D/bin" "$D/lib"
cp -L "$S/bin/ffmpeg" "$S/bin/ffprobe" "$D/bin/"
for l in avcodec avdevice avfilter avformat avutil swresample swscale; do cp -L "$S"/lib/lib$l.so.*.*.* "$D/lib/"; done
(cd "$D/lib"; for f in lib*.so.*.*.*; do b=${f%%.so.*}; m=$(echo "$f" | cut -d. -f3); ln -sf "$f" "$b.so.$m"; done)
patchelf --set-rpath '$ORIGIN/../lib' "$D"/bin/*
for f in "$D"/lib/lib*.so.*.*.*; do patchelf --set-rpath '$ORIGIN' "$f"; done
strip --strip-unneeded "$D"/bin/* "$D"/lib/lib*.so.*.*.*
cp "$ROOT/LICENSES.md" "$ROOT/SOURCE-OFFER.md" "$D/"
tar --owner=0 --group=0 --sort=name -czf "$OUT/$N.tar.gz" -C "$T" "$N"; echo "wrote $OUT/$N.tar.gz"
