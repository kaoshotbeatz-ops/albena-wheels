# albena-wheels
LGPL-only FFmpeg 8.1.3 + PyAV 17.1.0 + OpenCV 4.14.0.94 (headless, no FFmpeg inside) wheels for Albena Hub.
Targets: linux x86_64 manylinux_2_28 (cp312, av is abi3 cp311+) and macOS arm64 (macOS 26+).
Build: `scripts/linux-inner.sh` in `quay.io/pypa/manylinux_2_28_x86_64` (rsync repo, `docker run -v $PWD:/io ...`); macOS: `scripts/build-deps.sh work/mac` then `scripts/build-wheels.sh` + `delocate-wheel` (see SOURCE-OFFER.md). Test: `python -I scripts/verify.py [rtsp-url]` in a throwaway venv.
Install ONLY with `pip install --no-index --find-links dist av==17.1.0 opencv-python-headless==4.14.0.94` (PyPI has same/newer names; ours carry no local-version tag).
Hardware decode: Linux `HWAccel("cuda")` (NVDEC) or `h264_cuvid`; macOS `HWAccel("videotoolbox")`; fall back to go2rtc/camera JPEG snapshots when no hw decoder. Albena's cv2 use is imdecode/imencode/resize/etc. only (no VideoCapture); RTSP uses the `ffmpeg` subprocess (camera_registry.py) so it needs an LGPL `ffmpeg` binary (built in `work/*/prefix/bin`, not yet packaged).
Updating: bump `scripts/versions.env` (+sha256), rerun; ~1h Linux, ~40 min macOS. PyAV major must match FFmpeg major (libavcodec 62 = FFmpeg 8.x); Cython pinned <3.2 for PyAV 17.1.
