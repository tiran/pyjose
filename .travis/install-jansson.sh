#!/bin/bash
set -ex

VERSION=2.9
URL=http://www.digip.org/jansson/releases/jansson-${VERSION}.tar.gz
TMPDIR=/tmp/jansson

echo "installing jansson-${VERSION}"
rm -rf $TMPDIR
mkdir $TMPDIR
cd $TMPDIR

curl "$URL" | tar -xz --strip-components=1
./configure --silent --prefix=/usr
make
rm -rf /usr/lib/libjansson*
rm -rf /usr/include/jansson*

sudo make install
sudo ldconfig

echo "installed jansson-${VERSION}"
