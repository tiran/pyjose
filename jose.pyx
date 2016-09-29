from libc.stdlib cimport free
from cpython.version cimport PY_MAJOR_VERSION

cimport jansson
cimport jose

import json


# helper functions
cdef jansson.json_t *dumps(dict obj) except NULL:
    """Convert Python dict to json_t*

    Returns a new reference.
    """
    cdef jansson.json_t *js = NULL

    jsons = json.dumps(obj, separators=(',', ':'), allow_nan=False)
    if PY_MAJOR_VERSION >= 3:
        jsons = jsons.encode('utf-8')

    js = jansson.json_loads(jsons, 0, NULL)
    if js is NULL:
        raise ValueError("Failed to load json", obj)
    return js


cdef loads(jansson.json_t *js):
    """Convert json_t* to Python object

    Does not decrement reference count of json_t.
    """
    cdef char *ret = NULL

    ret = jansson.json_dumps(js, 0)
    if ret is NULL:
        raise ValueError("Failed to convert")

    try:
        jsons = ret.decode('utf-8')
        return json.loads(jsons)
    finally:
        free(ret)


cdef bytes _to_asciibytes(obj):
    """Convert str, unicode, bytes to ascii bytes

    None is returned as None. Cython converts <bytes>None to NULL.
    """
    if obj is None:
        return None
    elif type(obj) is bytes:
        return <bytes>obj
    elif PY_MAJOR_VERSION < 3 and isinstance(obj, unicode):
        return <bytes>obj.encode('ascii')
    elif PY_MAJOR_VERSION >= 3 and isinstance(obj, str):
        return <bytes>obj.encode('ascii')
    else:
        raise TypeError(type(obj))

cdef _ascii_fromchar(const char* s):
    """Convert char[] to ASCII

    Does not free() s.
    """
    if PY_MAJOR_VERSION < 3:
        return <bytes>s
    else:
        return (<bytes>s).decode('ascii')


# jwk
def jwk_generate(jwk):
    cdef jansson.json_t *cjwk = NULL

    cjwk = dumps(jwk)
    try:
        assert jose.jose_jwk_generate(cjwk)

        jwk.clear()
        jwk.update(loads(cjwk))
    finally:
        jansson.json_decref(cjwk)


def jwk_clean(jwk):
    cdef jansson.json_t *cjwk = NULL

    cjwk = dumps(jwk)
    try:
        assert jose.jose_jwk_clean(cjwk)

        jwk.clear()
        jwk.update(loads(cjwk))
    finally:
        jansson.json_decref(cjwk)


def jwk_allowed(jwk, bool req=False, use=None, op=None):
    cdef jansson.json_t *cjwk = NULL
    cdef bytes buse, bop

    buse = _to_asciibytes(use)
    bop = _to_asciibytes(op)
    cjwk = dumps(jwk)
    try:
        return True if jose.jose_jwk_allowed(cjwk, req, buse, bop) else False
    finally:
        jansson.json_decref(cjwk)


def jwk_thumbprint(jwk, hash=u"sha1"):
    cdef jansson.json_t *cjwk = NULL
    cdef char *ret
    cdef bytes bhash

    bhash = _to_asciibytes(hash)
    cjwk = dumps(jwk)
    try:
        ret = jose.jose_jwk_thumbprint(cjwk, bhash)
        assert ret

        return _ascii_fromchar(ret)
    finally:
        jansson.json_decref(cjwk)
        free(ret)


def jwk_exchange(prv, pub):
    cdef jansson.json_t *cprv = NULL
    cdef jansson.json_t *cpub = NULL
    cdef jansson.json_t *cout = NULL
    cdef char *ret = NULL

    assert isinstance(prv, dict)
    assert isinstance(pub, dict)

    try:
        cprv = jansson.json_loads(json.dumps(prv).encode(u"UTF-8"), 0, NULL)
        assert cprv

        cpub = jansson.json_loads(json.dumps(pub).encode(u"UTF-8"), 0, NULL)
        assert cpub

        cout = jose.jose_jwk_exchange(cprv, cpub)
        assert cout

        ret = jansson.json_dumps(cout, 0)
        assert ret

        return json.loads(ret)
    finally:
        jansson.json_decref(cprv)
        jansson.json_decref(cpub)
        free(ret)


def jws_sign(jws, jwk, sig={}):
    cdef jansson.json_t *cjws = NULL
    cdef jansson.json_t *cjwk = NULL
    cdef jansson.json_t *csig = NULL
    cdef char *ret = NULL

    assert isinstance(jws, dict)
    assert isinstance(jwk, dict)
    assert isinstance(sig, dict)

    try:
        cjws = jansson.json_loads(json.dumps(jws).encode(u"UTF-8"), 0, NULL)
        assert cjws

        cjwk = jansson.json_loads(json.dumps(jwk).encode(u"UTF-8"), 0, NULL)
        assert cjwk

        csig = jansson.json_loads(json.dumps(sig).encode(u"UTF-8"), 0, NULL)
        assert csig

        assert jose.jose_jws_sign(cjws, cjwk, csig)

        ret = jansson.json_dumps(cjws, 0)
        assert ret

        jws.clear()
        jws.update(json.loads(ret))
    finally:
        jansson.json_decref(cjws)
        jansson.json_decref(cjwk)
        jansson.json_decref(csig)
        free(ret)


def jws_verify(jws, jwk, sig=None):
    cdef jansson.json_t *cjws = NULL
    cdef jansson.json_t *cjwk = NULL
    cdef jansson.json_t *csig = NULL
    cdef char *ret = NULL

    assert isinstance(jws, dict)
    assert isinstance(jwk, dict)
    assert isinstance(sig, dict) or sig is None

    try:
        cjws = jansson.json_loads(json.dumps(jws).encode(u"UTF-8"), 0, NULL)
        assert cjws

        cjwk = jansson.json_loads(json.dumps(jwk).encode(u"UTF-8"), 0, NULL)
        assert cjwk

        if sig is not None:
            csig = jansson.json_loads(json.dumps(sig).encode(u"UTF-8"), 0, NULL)
            assert csig

        return True if jose.jose_jws_verify(cjws, cjwk, csig) else False
    finally:
        jansson.json_decref(cjws)
        jansson.json_decref(cjwk)
        jansson.json_decref(csig)


def jws_merge_header(jws):
    cdef jansson.json_t *cjws = NULL
    cdef jansson.json_t *chdr = NULL
    cdef char *ret = NULL

    assert isinstance(jws, dict)

    try:
        cjws = jansson.json_loads(json.dumps(jws).encode(u"UTF-8"), 0, NULL)
        assert cjws

        chdr = jose.jose_jws_merge_header(cjws)
        assert chdr

        ret = jansson.json_dumps(chdr, 0)
        assert ret

        return json.loads(ret)
    finally:
        jansson.json_decref(cjws)
        jansson.json_decref(chdr)
        free(ret)


def jwe_encrypt(jwe, cek, pt):
    cdef jansson.json_t *cjwe = NULL
    cdef jansson.json_t *ccek = NULL
    cdef char *ret = NULL

    assert isinstance(jwe, dict)
    assert isinstance(cek, dict)
    assert isinstance(pt, bytes)

    try:
        cjwe = jansson.json_loads(json.dumps(jwe).encode(u"UTF-8"), 0, NULL)
        assert cjwe

        ccek = jansson.json_loads(json.dumps(cek).encode(u"UTF-8"), 0, NULL)
        assert cjwe

        assert jose.jose_jwe_encrypt(cjwe, ccek, pt, len(pt))

        ret = jansson.json_dumps(cjwe, 0)
        assert ret

        jwe.clear()
        jwe.update(json.loads(ret))
    finally:
        jansson.json_decref(cjwe)
        jansson.json_decref(ccek)
        free(ret)


def jwe_wrap(jwe, cek, jwk, rcp={}):
    cdef jansson.json_t *cjwe = NULL
    cdef jansson.json_t *ccek = NULL
    cdef jansson.json_t *cjwk = NULL
    cdef jansson.json_t *crcp = NULL
    cdef char *ret = NULL

    assert isinstance(jwe, dict)
    assert isinstance(cek, dict)
    assert isinstance(jwk, dict)
    assert isinstance(rcp, dict)

    try:
        cjwe = jansson.json_loads(json.dumps(jwe).encode(u"UTF-8"), 0, NULL)
        assert cjwe

        ccek = jansson.json_loads(json.dumps(cek).encode(u"UTF-8"), 0, NULL)
        assert cjwe

        cjwk = jansson.json_loads(json.dumps(jwk).encode(u"UTF-8"), 0, NULL)
        assert cjwk

        crcp = jansson.json_loads(json.dumps(rcp).encode(u"UTF-8"), 0, NULL)
        assert crcp

        assert jose.jose_jwe_wrap(cjwe, ccek, cjwk, crcp)

        ret = jansson.json_dumps(cjwe, 0)
        assert ret

        jwe.clear()
        jwe.update(json.loads(ret))

        free(ret)
        ret = NULL

        ret = jansson.json_dumps(ccek, 0)
        assert ret

        cek.clear()
        cek.update(json.loads(ret))
    finally:
        jansson.json_decref(cjwe)
        jansson.json_decref(ccek)
        jansson.json_decref(cjwk)
        jansson.json_decref(crcp)
        free(ret)


def jwe_unwrap(jwe, jwk, rcp=None):
    cdef jansson.json_t *cjwe = NULL
    cdef jansson.json_t *cjwk = NULL
    cdef jansson.json_t *crcp = NULL
    cdef jansson.json_t *ccek = NULL
    cdef char *ret = NULL

    assert isinstance(jwe, dict)
    assert isinstance(jwk, dict)
    assert isinstance(rcp, dict) or rcp is None

    try:
        cjwe = jansson.json_loads(json.dumps(jwe).encode(u"UTF-8"), 0, NULL)
        assert cjwe

        cjwk = jansson.json_loads(json.dumps(jwk).encode(u"UTF-8"), 0, NULL)
        assert cjwk

        if rcp is not None:
            crcp = jansson.json_loads(json.dumps(rcp).encode(u"UTF-8"), 0, NULL)
            assert crcp

        ccek = jose.jose_jwe_unwrap(cjwe, cjwk, crcp)
        assert ccek

        ret = jansson.json_dumps(ccek, 0)
        assert ret

        return json.loads(ret)
    finally:
        jansson.json_decref(cjwe)
        jansson.json_decref(cjwk)
        jansson.json_decref(crcp)
        jansson.json_decref(ccek)
        free(ret)


def jwe_decrypt(jwe, cek):
    cdef jansson.json_t *cjwe = NULL
    cdef jansson.json_t *ccek = NULL
    cdef jose.jose_buf_t *pt = NULL

    assert isinstance(jwe, dict)
    assert isinstance(cek, dict)

    try:
        cjwe = jansson.json_loads(json.dumps(jwe).encode(u"UTF-8"), 0, NULL)
        assert cjwe

        ccek = jansson.json_loads(json.dumps(cek).encode(u"UTF-8"), 0, NULL)
        assert ccek

        pt = jose.jose_jwe_decrypt(cjwe, ccek)
        assert pt

        return pt.data[:pt.size]
    finally:
        jansson.json_decref(cjwe)
        jansson.json_decref(ccek)
        jose.jose_buf_decref(pt)


def jwe_merge_header(jwe, rcp):
    cdef jansson.json_t *cjwe = NULL
    cdef jansson.json_t *crcp = NULL
    cdef jansson.json_t *chdr = NULL
    cdef char *ret = NULL

    assert isinstance(jwe, dict)
    assert isinstance(rcp, dict)

    try:
        cjwe = jansson.json_loads(json.dumps(jwe).encode(u"UTF-8"), 0, NULL)
        assert cjwe

        crcp = jansson.json_loads(json.dumps(rcp).encode(u"UTF-8"), 0, NULL)
        assert cjwe

        chdr = jose.jose_jwe_merge_header(cjwe, crcp)
        assert chdr

        ret = jansson.json_dumps(chdr, 0)
        assert ret

        return json.loads(ret)
    finally:
        jansson.json_decref(cjwe)
        jansson.json_decref(crcp)
        jansson.json_decref(chdr)
        free(ret)


def from_compact(compact):
    cdef jansson.json_t *cjose = NULL
    cdef char *ret = NULL

    assert isinstance(compact, str)

    try:
        cjose = jose.jose_from_compact(compact)
        assert cjose

        ret = jansson.json_dumps(cjose, 0)
        assert ret

        return json.loads(ret)
    finally:
        jansson.json_decref(cjose)
        free(ret)


def to_compact(flat):
    cdef jansson.json_t *cjose = NULL
    cdef char *ret = NULL

    assert isinstance(flat, dict)

    try:
        cjose = jansson.json_loads(json.dumps(flat).encode(u"UTF-8"), 0, NULL)
        assert cjose

        ret = jose.jose_to_compact(cjose)
        assert ret

        return <bytes> ret
    finally:
        jansson.json_decref(cjose)
        free(ret)


cdef init():
    # init jansson hash randomization seed
    jansson.json_object_seed(0)

    # initialize OpenSSL
    jose.OpenSSL_add_all_algorithms()

    # try to import _ssl to set up threading locks
    try:
        __import__('_ssl')
    except ImportError:
        pass

init()
