#!/bin/bash
set -e

VERSION=jose_list
# VERSION=4

if [ ! -d $PACKAGEHOME ]; then
    exit 1
fi

TEMPDIR=${PACKAGEHOME}/tmp
if [ "$VERSION" != "master" ]; then
    REMOTE_NAME=v${VERSION}.zip
    DEST=$TEMPDIR/$REMOTE_NAME
    if [ -f $DEST ]; then
        echo "jose-${VERSION} is already installed"
        exit 0
    fi
else
    REMOTE_NAME=master.zip
    DEST=${TEMPDIR}/${REMOTE_NAME}
    rm -f ${DEST}*
fi

REMOTE_NAME=${VERSION}.zip
DEST=${TEMPDIR}/${REMOTE_NAME}

rm -f ${DEST}*

trap "rm -rf $DEST $TEMPDIR/jose-${VERSION}" ERR
trap "rm -rf $TEMPDIR/jose-${VERSION}" EXIT

echo "installing jose-${VERSION}"

mkdir -p $TEMPDIR
cd $TEMPDIR

# wget https://github.com/latchset/jose/archive/${REMOTE_NAME}
wget https://github.com/tiran/jose/archive/${REMOTE_NAME}
unzip -q -o ${REMOTE_NAME}

cd jose-${VERSION}
autoreconf -ifv

./configure --prefix=${PACKAGEHOME}
make

rm -rf $PACKAGEHOME/include/jose
rm -rf $PACKAGEHOME/lib/libjose*

make install

ldd ${PACKAGEHOME}/bin/jose

${PACKAGEHOME}/bin/jose list

make check || (cat test-suite.log; exit 2)


echo "installed jose-${VERSION}"
