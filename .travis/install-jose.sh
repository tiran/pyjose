#!/bin/bash
set -ex

VERSION=5
URL=https://github.com/latchset/jose/releases/download/v${VERSION}/jose-${VERSION}.tar.bz2
TMPDIR=/tmp/jose

echo "installing jose-${VERSION}"
rm -rf $TMPDIR
mkdir $TMPDIR
cd $TMPDIR

curl -L "$URL" | tar -xj --strip-components=1

if [ ! -f configure ]; then autoreconf -ifv; fi
./configure --prefix=/usr
make V=1
if ! make check; then cat ./test-suite.log ; exit 1; fi
cmd/jose sup

sudo make install

echo "installed jose-${VERSION}"
