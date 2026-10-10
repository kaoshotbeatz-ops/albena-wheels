# Licences of the Albena wheels

Not legal advice. Have counsel review before shipping.

## What is in the wheels

| Component | Version | Licence | How linked |
|---|---|---|---|
| FFmpeg (libavcodec/format/util/filter/device, swscale, swresample) | 8.1.3 | **LGPL-3.0-or-later** (built with `--disable-gpl --disable-nonfree --enable-version3`) | shared libraries bundled in the wheel; user can replace them |
| PyAV (`av`) | 17.1.0 | BSD-3-Clause | Python extension linking the shared FFmpeg libs |
| OpenCV headless (`cv2`) | 4.14.0.94 (opencv-python-headless) | Apache-2.0 (wheel packaging MIT) | **FFmpeg, IPP, GStreamer, non-free all OFF**; no FFmpeg inside |
| Opus (libopus) | 1.5.2 | BSD-3-Clause | static inside libavcodec |
| libvpx (VP8/VP9) | 1.16.0 | BSD-3-Clause + WebM patent grant | static inside libavcodec |
| dav1d (AV1 decode) | 1.5.3 | BSD-2-Clause | static inside libavcodec |
| libaom (AV1 enc/dec) | 3.15.2 | BSD-2-Clause + AOM patent licence 1.0 | static inside libavcodec |
| OpenSSL (https, rtsps, srtp-in-ffmpeg) | 3.5.9 | Apache-2.0 | static inside libavformat; this is why FFmpeg is built `--enable-version3` (LGPL **v3**, not v2.1) |
| nv-codec-headers (ffnvcodec) | n13.0.19.0 | MIT | headers only; FFmpeg `dlopen`s `libnvcuvid`/`libcuda` from the NVIDIA driver at runtime. No NVIDIA code is shipped. (Linux only) |
| Apple VideoToolbox / AudioToolbox | OS frameworks | system | not redistributed (macOS only) |
| OpenCV bundled third-party (libjpeg-turbo, libpng, libtiff, libwebp, OpenJPEG, OpenEXR, zlib, protobuf, carotene) | see `cv2/LICENSE-3RD-PARTY.txt` in the wheel | permissive (BSD/IJG/zlib/libpng) | static |

Never used: `--enable-gpl`, `--enable-nonfree`, libx264, libx265, xvid, fdk-aac, libnpp, cuda-nvcc, OpenH264, Intel IPP, OpenCV non-free/xfeatures2d.

## H.264 / HEVC (patents)

* **No software H.264/HEVC *encoder*** is shipped (no libx264/x265/OpenH264).
* H.264/HEVC **decoding** is intended to be performed by the platform's hardware decoder: NVIDIA NVDEC (`h264_cuvid`/`hevc_cuvid` or the `cuda` hwaccel; Linux, Blackwell target) or Apple VideoToolbox (macOS). Patent licensing for that hardware path is the responsibility of the OS/driver vendor (NVIDIA/Apple), not of this wheel. That is our understanding; it is not legal advice.
* FFmpeg's *native* `h264` and `hevc` decoders are still compiled in. They are LGPL **source** but implement patented codecs. They cannot be removed without losing hwaccel: FFmpeg's `videotoolbox`/`nvdec` hwaccels hook into the native decoder's bitstream parser (`-hwaccel` needs `h264`/`hevc`). The standalone `*_cuvid` decoders do not need them, so an Albena-only build can later use `--disable-decoder=h264,hevc` and name `h264_cuvid` explicitly (see README). Software decode fallback = native decoder; a vendor shipping this must decide on H.264/HEVC patent pool licensing (e.g. Via LA/Access Advance) for that fallback or disable it at runtime.
* AV1 (dav1d/libaom), VP8/VP9 (libvpx), Opus carry royalty-free patent grants from their authors.
* AAC/MP3 are FFmpeg's native LGPL implementations (AAC decode+encode, MP3 decode; MP3 encode not included). Mp3/AAC patents have expired (MP3) or are in a licensing pool (AAC) -- same caveat as above.
* aiortc hard-codes `libx264` for H.264 *encode*; with these wheels aiortc H.264 send is unavailable (VP8/VP9/AV1/Opus work). Browsers negotiate VP8 fallback.

## LGPL-3 obligations we meet

1. FFmpeg is dynamically linked (separate `.so`/`.dylib` in the wheel; replaceable). Applications using them keep their own licence.
2. Corresponding source (exact tarballs + our scripts) -- see `SOURCE-OFFER.md`.
3. Ship this file and `THIRD_PARTY` licence texts with the product; show LGPL notice in About/EULA; do not forbid reverse engineering for debugging modifications of the LGPL parts.
4. Anti-tivoization (LGPLv3 sec. 4/GPLv3 sec. 6) applies to "User Products": do not lock the Hub so the user cannot run a modified FFmpeg library.
