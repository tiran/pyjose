#!/bin/bash
set -e
VERSION=1.0.2j

if [ ! -d $PACKAGEHOME ]; then
    exit 1
fi

TEMPDIR=${PACKAGEHOME}/tmp
DEST=$TEMPDIR/openssl-${VERSION}.tar.gz

trap "rm -rf $DEST $TEMPDIR/openssl-${VERSION}" ERR
trap "rm -rf $TEMPDIR/openssl-${VERSION}" EXIT

if [ -f $DEST ]; then
    echo "openssl-{VERSION} is already installed"
    exit 0
fi

echo "installing openssl-{VERSION}"

mkdir -p $TEMPDIR
cd $TEMPDIR

wget https://www.openssl.org/source/openssl-${VERSION}.tar.gz

tar xzvf openssl-${VERSION}.tar.gz

cd openssl-${VERSION}
./config shared --prefix=${PACKAGEHOME}
make -j1
make install

echo "installed openssl-{VERSION}"
