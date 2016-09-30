#!/bin/bash
set -e
VERSION=2.69

if [ ! -d $PACKAGEHOME ]; then
    exit 1
fi

TEMPDIR=${PACKAGEHOME}/tmp
DEST=$TEMPDIR/autoconf-${VERSION}.tar.gz

trap "rm -rf $DEST $TEMPDIR/autoconf-${VERSION}" ERR
trap "rm -rf $TEMPDIR/autoconf-${VERSION}" EXIT

if [ -f $DEST ]; then
    echo "autoconf-{VERSION} is already installed"
    exit 0
fi

echo "installing autoconf-{VERSION}"

# copy aclocal macros
mkdir -p ${PACKAGEHOME}/share/aclocal
cp /usr/share/aclocal/* ${PACKAGEHOME}/share/aclocal/

mkdir -p $TEMPDIR
cd $TEMPDIR

wget http://ftp.gnu.org/gnu/autoconf/autoconf-${VERSION}.tar.gz

tar xzvf autoconf-${VERSION}.tar.gz

cd autoconf-${VERSION}
./configure --prefix=${PACKAGEHOME}
make -j1
make install

hash -r

echo "installed autoconf-{VERSION}"
