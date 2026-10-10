#!/usr/bin/env bash
# Build licence-clean FFmpeg (LGPL only) + permissive codec libs into $PREFIX.
# Usage: build-deps.sh <workdir>     (works on manylinux_2_28 x86_64 and macOS arm64)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/scripts/versions.env"
W="${1:?workdir}"; mkdir -p "$W"; W="$(cd "$W" && pwd)"
PREFIX="$W/prefix"; mkdir -p "$PREFIX" "$ROOT/src"
OS="$(uname -s)"; JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN)}"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig" PATH="$PREFIX/bin:$PATH"
export CFLAGS="-O2 -fPIC" CXXFLAGS="-O2 -fPIC"
if [ "$OS" = Darwin ]; then
  export MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-13.0}"
  export CFLAGS="$CFLAGS -mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET" CXXFLAGS="$CXXFLAGS -mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET"
fi

fetch() { # url sha -> echoes path in src/
  local f="$ROOT/src/$(basename "$1")"
  [ -f "$f" ] || curl -fsSL -o "$f" "$1"
  echo "$2  $f" | { shasum -a 256 -c - >&2 2>/dev/null || sha256sum -c - >&2; }
  echo "$f"
}
unpack() { local d="$W/$2"; rm -rf "$d"; mkdir -p "$d"; tar -xf "$1" -C "$d" --strip-components=1; echo "$d"; }
done_flag() { [ -f "$PREFIX/.done-$1" ]; }
mark() { touch "$PREFIX/.done-$1"; }

if ! done_flag openssl; then
  d=$(unpack "$(fetch $OPENSSL_URL $OPENSSL_SHA)" openssl); cd "$d"
  tgt=linux-x86_64; [ "$OS" = Darwin ] && tgt=darwin64-arm64-cc
  ./Configure $tgt no-shared no-tests no-docs no-apps --prefix="$PREFIX" --libdir=lib
  make -j"$JOBS" build_libs && make install_dev; mark openssl
fi
if ! done_flag opus; then
  d=$(unpack "$(fetch $OPUS_URL $OPUS_SHA)" opus); cd "$d"
  ./configure --prefix="$PREFIX" --disable-shared --enable-static --with-pic --disable-doc --disable-extra-programs
  make -j"$JOBS" && make install; mark opus
fi
if ! done_flag vpx; then
  d=$(unpack "$(fetch $VPX_URL $VPX_SHA)" vpx); cd "$d"
  ./configure --prefix="$PREFIX" --disable-shared --enable-static --enable-pic --disable-examples --disable-tools --disable-docs --disable-unit-tests --enable-vp9-highbitdepth --enable-runtime-cpu-detect
  make -j"$JOBS" && make install; mark vpx
fi
if ! done_flag dav1d; then
  d=$(unpack "$(fetch $DAV1D_URL $DAV1D_SHA)" dav1d); cd "$d"
  meson setup build --prefix="$PREFIX" --libdir=lib --default-library=static --buildtype=release -Denable_tools=false -Denable_tests=false -Db_staticpic=true
  ninja -C build install; mark dav1d
fi
if ! done_flag aom; then
  d=$(unpack "$(fetch $AOM_URL $AOM_SHA)" aom); cd "$d"
  cmake -S . -B b -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_INSTALL_LIBDIR=lib \
    -DBUILD_SHARED_LIBS=0 -DCMAKE_POSITION_INDEPENDENT_CODE=1 -DENABLE_TESTS=0 -DENABLE_TOOLS=0 -DENABLE_EXAMPLES=0 -DENABLE_DOCS=0 -DENABLE_TESTDATA=0
  cmake --build b -j"$JOBS" && cmake --install b; mark aom
fi
HW=()
if [ "$OS" = Darwin ]; then
  HW=(--enable-videotoolbox --enable-audiotoolbox)
else
  if ! done_flag nvh; then
    d=$(unpack "$(fetch $NVH_URL $NVH_SHA)" nvh); make -C "$d" install PREFIX="$PREFIX" LIBDIR=lib; mark nvh
  fi
  HW=(--enable-ffnvcodec --enable-nvdec --enable-cuvid --disable-xlib --disable-libxcb --disable-sdl2 --disable-alsa --disable-sndio --disable-vaapi --disable-vdpau --disable-libdrm)
fi
d=$(unpack "$(fetch $FFMPEG_URL $FFMPEG_SHA)" ffmpeg); cd "$d"
# NOTE: no --enable-gpl, no --enable-nonfree, no libx264/x265/fdk-aac/openh264, no libnpp/cuda-nvcc.
# --enable-version3 is required for OpenSSL 3 (Apache-2.0); resulting licence: LGPL v3 or later.
./configure --prefix="$PREFIX" --libdir="$PREFIX/lib" \
  --enable-shared --disable-static --enable-pic --disable-doc --disable-debug \
  --disable-gpl --disable-nonfree --enable-version3 \
  --enable-libopus --enable-libvpx --enable-libdav1d --enable-libaom --enable-openssl \
  "${HW[@]}" \
  --pkg-config-flags=--static \
  --extra-cflags="-I$PREFIX/include" --extra-ldflags="-L$PREFIX/lib" \
  --extra-libs="-lpthread -lm"
make -j"$JOBS" && make install
echo "OK ffmpeg installed in $PREFIX"
