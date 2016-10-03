#!/bin/bash
set -ex
VERSION=2.9

echo "installing jansson-${VERSION}"
cd /tmp
curl http://www.digip.org/jansson/releases/jansson-${VERSION}.tar.gz | tar -xz
cd jansson-${VERSION}
./configure --silent
make
sudo make install
echo "installed jansson-${VERSION}"
