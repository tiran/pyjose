#!/bin/bash
set -ex
VERSION=plugin_load
URL=https://github.com/tiran/jose/archive/${VERSION}.tar.gz
TMPDIR=/tmp/jose

echo "installing jose-${VERSION}"
rm -rf $TMPDIR
mkdir $TMPDIR
cd $TMPDIR
curl -L "$URL" | tar -xz --strip-components=1

if [ ! -f configure ]; then autoreconf -ifv; fi
./configure --prefix=/usr
make V=1
if ! make check; then cat ./test-suite.log ; exit 1; fi
cmd/jose sup
sudo make install

echo "installed jose-${VERSION}"
