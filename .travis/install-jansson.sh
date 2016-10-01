#!/bin/bash
set -e
VERSION=2.9

if [ ! -d $PACKAGEHOME ]; then
    exit 1
fi

TEMPDIR=${PACKAGEHOME}/tmp
DEST=$TEMPDIR/jansson-${VERSION}.tar.gz

trap "rm -rf $DEST $TEMPDIR/jansson-${VERSION}" ERR
trap "rm -rf $TEMPDIR/jansson-${VERSION}" EXIT

if [ -f $DEST ]; then
    echo "jansson-${VERSION} is already installed"
    exit 0
fi

echo "installing jansson-${VERSION}"

mkdir -p $TEMPDIR
cd $TEMPDIR

wget http://www.digip.org/jansson/releases/jansson-${VERSION}.tar.gz

tar xzf jansson-${VERSION}.tar.gz

cd jansson-${VERSION}
./configure --prefix=${PACKAGEHOME} --silent
make
make install

echo "installed jansson-${VERSION}"
