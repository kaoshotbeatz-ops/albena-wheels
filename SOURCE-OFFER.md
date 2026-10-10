# Written offer of corresponding source (LGPL-3.0 sec. 4/6)

The Albena wheels and the albena-ffmpeg CLI tarballs contain FFmpeg 8.1.3 (LGPL-3.0-or-later) and other libraries listed in `LICENSES.md`.
For at least **three (3) years** from the date you received the binaries, and for as long as we offer spare parts or support for them, we will give any third party, on request, the complete corresponding source for those libraries, including the build scripts and patches (no patches are currently applied). Request: write to omar@dbaomarhuertasllc.com. Charge: no more than the cost of physical distribution (none for download). We also keep this repository (`scripts/`, `patches/`, `LICENSES.md`) with every release.

## Upstream sources (exact, sha256 in `scripts/versions.env`)

* FFmpeg 8.1.3: https://ffmpeg.org/releases/ffmpeg-8.1.3.tar.xz
* PyAV 17.1.0: https://files.pythonhosted.org/packages/5e/e3/477fa20578c284abeda08d91b63ee9abaebc93445d8feeb989d3d444bae1/av-17.1.0.tar.gz
* opencv-python-headless 4.14.0.94: https://files.pythonhosted.org/packages/67/8a/51ff1c6287be0b6cd3070cf095875da4ff7d6eda38507e6ada5608786a78/opencv_python_headless-4.14.0.94.tar.gz
* Opus 1.5.2: https://downloads.xiph.org/releases/opus/opus-1.5.2.tar.gz
* libvpx 1.16.0: https://github.com/webmproject/libvpx/archive/refs/tags/v1.16.0.tar.gz
* dav1d 1.5.3: https://code.videolan.org/videolan/dav1d/-/archive/1.5.3/dav1d-1.5.3.tar.gz
* libaom 3.15.2: https://storage.googleapis.com/aom-releases/libaom-3.15.2.tar.gz
* OpenSSL 3.5.9: https://github.com/openssl/openssl/releases/download/openssl-3.5.9/openssl-3.5.9.tar.gz
* nv-codec-headers n13.0.19.0: https://github.com/FFmpeg/nv-codec-headers/archive/refs/tags/n13.0.19.0.tar.gz

## How to rebuild

`scripts/build-deps.sh` (FFmpeg + codecs, exact `./configure` flags inside), `scripts/build-wheels.sh` (PyAV, OpenCV), `scripts/linux-inner.sh` (manylinux_2_28 container recipe), `scripts/verify.py` (tests). Replace the bundled `libav*` in `av.libs/` (Linux) or `av/.dylibs/` (macOS) with your own build of the same FFmpeg major version to use a modified FFmpeg.
