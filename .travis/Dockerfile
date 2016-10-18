FROM fedora:24
MAINTAINER Christian Heimes <cheimes@redhat.com>

RUN dnf -y update \
    && dnf install -y dnf-plugins-core \
    && dnf copr enable -y npmccallum/jansson \
    && dnf copr enable -y npmccallum/jose \
    && dnf install -y \
        gcc redhat-rpm-config make pkgconfig \
        findutils tar bzip2 \
        jansson-devel openssl-devel zlib-devel \
        jose libjose-devel libjose-openssl-devel libjose-zlib-devel \
        python-tox python-pip python-setuptools python-virtualenv \
        Cython python-devel \
        python3-tox python3-pip python3-setuptools python3-virtualenv \
        python3-Cython python3-devel \
    && dnf clean all

VOLUME ["/tmp/build"]
WORKDIR "/tmp/build"
