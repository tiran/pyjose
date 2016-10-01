#!/bin/bash
set -e
VERSION=2.4.6

if [ ! -d $PACKAGEHOME ]; then
    exit 1
fi

TEMPDIR=${PACKAGEHOME}/tmp
DEST=$TEMPDIR/libtool-${VERSION}.tar.gz

trap "rm -rf $DEST $TEMPDIR/libtool-${VERSION}" ERR
trap "rm -rf $TEMPDIR/libtool-${VERSION}" EXIT

if [ -f $DEST ]; then
    echo "libtool-${VERSION} is already installed"
    exit 0
fi

echo "installing libtool-${VERSION}"

mkdir -p $TEMPDIR
cd $TEMPDIR

wget http://ftp.gnu.org/gnu/libtool/libtool-${VERSION}.tar.gz

tar xzf libtool-${VERSION}.tar.gz

cd libtool-${VERSION}
./configure --prefix=${PACKAGEHOME} --silent
make
make install

hash -r

echo "installed libtool-${VERSION}"
