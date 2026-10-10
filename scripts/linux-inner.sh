#!/usr/bin/env bash
# Runs inside quay.io/pypa/manylinux_2_28_x86_64 with repo mounted at /io
set -euxo pipefail
PY=/opt/python/cp312-cp312/bin/python
yum install -y nasm perl-IPC-Cmd perl-core >/dev/null
$PY -m pip -q install meson ninja cmake auditwheel patchelf numpy
export PATH=/opt/python/cp312-cp312/bin:$PATH
cd /io
./scripts/build-deps.sh work/linux
./scripts/build-wheels.sh work/linux $PY dist-linux bash -c '
  for w in work/linux/raw/*.whl; do
    LD_LIBRARY_PATH=$PWD/work/linux/prefix/lib auditwheel repair --plat manylinux_2_28_x86_64 -w dist-linux "$w"
  done'
