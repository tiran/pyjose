#!/bin/bash
set -e
VERSION=4

if [ ! -d $PACKAGEHOME ]; then
    exit 1
fi

TEMPDIR=${PACKAGEHOME}/tmp
DEST=$TEMPDIR/v${VERSION}.zip

# trap "rm -rf $DEST $TEMPDIR/v${VERSION}" ERR
# trap "rm -rf $TEMPDIR/v${VERSION}" EXIT

if [ -f $DEST ]; then
    echo "jose-{VERSION} is already installed"
    exit 0
fi

echo "installing jose-{VERSION}"

mkdir -p $TEMPDIR
cd $TEMPDIR
wget https://github.com/latchset/jose/archive/v${VERSION}.zip
unzip -o v${VERSION}.zip

cd jose-${VERSION}
autoreconf -ifv

./configure --disable-silent-rules --prefix=${PACKAGEHOME}
make
make install

echo "installed jose-{VERSION}"
