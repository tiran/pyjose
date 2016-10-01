#!/bin/bash
set -e
VERSION=1.15

if [ ! -d $PACKAGEHOME ]; then
    exit 1
fi

TEMPDIR=${PACKAGEHOME}/tmp
DEST=$TEMPDIR/automake-${VERSION}.tar.gz

trap "rm -rf $DEST $TEMPDIR/automake-${VERSION}" ERR
trap "rm -rf $TEMPDIR/automake-${VERSION}" EXIT

if [ -f $DEST ]; then
    echo "automake-${VERSION} is already installed"
    exit 0
fi

echo "installing automake-${VERSION}"

mkdir -p $TEMPDIR
cd $TEMPDIR

wget http://ftp.gnu.org/gnu/automake/automake-${VERSION}.tar.gz

tar xzf automake-${VERSION}.tar.gz

cd automake-${VERSION}
./configure --prefix=${PACKAGEHOME}  --silent
make
make install

hash -r

echo "installed automake-${VERSION}"
