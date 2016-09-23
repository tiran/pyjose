cimport pyjose
cimport jansson
from libc cimport stdio

cdef jansson.json_t *jwk

jwk = jansson.json_pack("{s:s}", "alg", "A128GCM")
pyjose.jose_jwk_generate(jwk)
jansson.json_dumpf(jwk, stdio.stderr, 0)

# version numbers
cdef openssl_version(unsigned long version):
    patch = (version >> 4) & 0xFF
    fix = (version >> 12) & 0xFF
    minor = (version >> 20) & 0xFF
    major = (version >> 28) & 0xFF
    return major, minor, fix, patch

_OPENSSL_VERSION = openssl_version(pyjose.SSLeay())
_OPENSSL_VERSION_NAME = pyjose.SSLeay_version(pyjose.SSLEAY_VERSION).decode('utf-8')
_OPENSSL_API_VERSION = openssl_version(pyjose.OPENSSL_VERSION_NUMBER)

_JANSSON_VERSION = (
    jansson.JANSSON_MAJOR_VERSION,
    jansson.JANSSON_MINOR_VERSION,
    jansson.JANSSON_MICRO_VERSION
)

_LIBJSON_VERSION = None
