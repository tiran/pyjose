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
    echo "openssl-${VERSION} is already installed"
    exit 0
fi

echo "installing openssl-${VERSION}"

mkdir -p $TEMPDIR
cd $TEMPDIR

wget https://www.openssl.org/source/openssl-${VERSION}.tar.gz

tar xzf openssl-${VERSION}.tar.gz

cd openssl-${VERSION}
./config shared --prefix=${PACKAGEHOME}

# one job, I have seen OpenSSL 1.0.2 fail with multiple jobs
make -j1

# run some tests
make -j1 test TESTS="test_rsa test_ecdsa test_ec test_sha test_hmac test_enc"

make install

echo "installed openssl-${VERSION}"
