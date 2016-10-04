from libc.stdlib cimport free
from cpython.version cimport PY_MAJOR_VERSION

cimport jansson
cimport jose

import json


class JoseOperationError(Exception):
    def __init__(self, str op):
        msg = "JOSE operation '{}' failed.".format(op)
        super(JoseOperationError, self).__init__(msg)
        self.op = op


# helper functions
cdef jansson.json_t *obj2jansson(dict obj, str argname) except NULL:
    """Convert Python dict to json_t*

    Returns a new reference.
    """
    cdef jansson.json_t *cjson = NULL

    jsonstr = json.dumps(obj, separators=(',', ':'), allow_nan=False)
    if PY_MAJOR_VERSION >= 3:
        jsonstr = jsonstr.encode('utf-8')

    cjson = jansson.json_loads(jsonstr, 0, NULL)
    if cjson is NULL:
        raise ValueError("Failed to load json", argname, obj)
    return cjson


cdef jansson2obj(jansson.json_t *cjson):
    """Convert json_t* to Python object

    Does not decrement reference count of json_t.
    """
    cdef char *ret = NULL

    ret = jansson.json_dumps(cjson, 0)
    if ret is NULL:
        raise ValueError("Failed to convert")

    try:
        jsons = ret.decode('utf-8')
        return json.loads(jsons)
    finally:
        free(ret)


cdef bytes obj2asciibytes(obj, str argname):
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
        raise TypeError('Expected bytes or text for {}, got {}'.format(
            argname, type(obj)))


cdef ascii2obj(const char* s):
    """Convert char[] to ASCII

    Does not free() s.
    """
    if PY_MAJOR_VERSION < 3:
        return <bytes>s
    else:
        return (<bytes>s).decode('ascii')


# jwk
def jwk_generate(dict jwk not None):
    cdef jansson.json_t *cjwk = NULL

    cjwk = obj2jansson(jwk, 'jwk')
    try:
        if not jose.jose_jwk_generate(cjwk):
            raise JoseOperationError('jwk_generate')

        jwk.clear()
        jwk.update(jansson2obj(cjwk))
    finally:
        jansson.json_decref(cjwk)


def jwk_clean(dict jwk not None):
    cdef jansson.json_t *cjwk = NULL

    cjwk = obj2jansson(jwk, 'jwk')
    try:
        if not jose.jose_jwk_clean(cjwk):
            raise JoseOperationError('jwk_clean')

        jwk.clear()
        jwk.update(jansson2obj(cjwk))
    finally:
        jansson.json_decref(cjwk)


def jwk_allowed(dict jwk not None, req=False, op=None):
    cdef jansson.json_t *cjwk = NULL
    cdef bytes bop

    bop = obj2asciibytes(op, 'op')
    cjwk = obj2jansson(jwk, 'jwk')
    req = bool(req)
    try:
        return True if jose.jose_jwk_allowed(cjwk, req, bop) else False
    finally:
        jansson.json_decref(cjwk)


def jwk_thumbprint(dict jwk not None, hash=u"sha1"):
    cdef jansson.json_t *cjwk = NULL
    cdef char *ret = NULL
    cdef bytes bhash

    bhash = obj2asciibytes(hash, 'hash')
    cjwk = obj2jansson(jwk, 'jwk')
    try:
        ret = jose.jose_jwk_thumbprint(cjwk, bhash)
        if not ret:
            raise JoseOperationError('jwk_thumbprint')

        return ascii2obj(ret)
    finally:
        jansson.json_decref(cjwk)
        free(ret)


def jwk_exchange(dict prv not None, dict pub not None):
    cdef jansson.json_t *cprv = NULL
    cdef jansson.json_t *cpub = NULL
    cdef jansson.json_t *cout = NULL

    try:
        cprv = obj2jansson(prv, 'prv')
        cpub = obj2jansson(pub, 'pub')
        cout = jose.jose_jwk_exchange(cprv, cpub)
        if not cout:
            raise JoseOperationError('jwk_exchange')

        return jansson2obj(cout)
    finally:
        jansson.json_decref(cprv)
        jansson.json_decref(cpub)


def jws_sign(dict jws not None, dict jwk not None, dict sig=None):
    cdef jansson.json_t *cjws = NULL
    cdef jansson.json_t *cjwk = NULL
    cdef jansson.json_t *csig = NULL

    if sig is None:
        sig = {}

    try:
        cjws = obj2jansson(jws, 'jws')
        cjwk = obj2jansson(jwk, 'jwk')
        csig = obj2jansson(sig, 'sig')

        if not jose.jose_jws_sign(cjws, cjwk, csig):
            raise JoseOperationError('jws_sign')

        jws.clear()
        jws.update(jansson2obj(cjws))
    finally:
        jansson.json_decref(cjws)
        jansson.json_decref(cjwk)
        jansson.json_decref(csig)


def jws_verify(dict jws not None, dict jwk not None, dict sig=None):
    cdef jansson.json_t *cjws = NULL
    cdef jansson.json_t *cjwk = NULL
    cdef jansson.json_t *csig = NULL
    cdef char *ret = NULL

    try:
        cjws = obj2jansson(jws, 'jws')
        cjwk = obj2jansson(jwk, 'jwk')
        if sig is not None:
            csig = obj2jansson(sig, 'sig')

        return True if jose.jose_jws_verify(cjws, cjwk, csig) else False
    finally:
        jansson.json_decref(cjws)
        jansson.json_decref(cjwk)
        jansson.json_decref(csig)


def jws_merge_header(dict jws not None):
    cdef jansson.json_t *cjws = NULL
    cdef jansson.json_t *chdr = NULL

    try:
        cjws = obj2jansson(jws, 'jws')
        chdr = jose.jose_jws_merge_header(cjws)
        if not chdr:
            raise JoseOperationError('jws_merge_header')

        return jansson2obj(chdr)
    finally:
        jansson.json_decref(cjws)
        jansson.json_decref(chdr)


def jwe_encrypt(dict jwe not None, dict cek not None, bytes pt not None):
    cdef jansson.json_t *cjwe = NULL
    cdef jansson.json_t *ccek = NULL

    try:
        cjwe = obj2jansson(jwe, 'jwe')
        ccek = obj2jansson(cek, 'cek')

        if not jose.jose_jwe_encrypt(cjwe, ccek, pt, len(pt)):
            raise JoseOperationError('jwe_encrypt')

        jwe.clear()
        jwe.update(jansson2obj(cjwe))
    finally:
        jansson.json_decref(cjwe)
        jansson.json_decref(ccek)


def jwe_wrap(dict jwe not None, dict cek not None, dict jwk not None,
             dict rcp=None):
    cdef jansson.json_t *cjwe = NULL
    cdef jansson.json_t *ccek = NULL
    cdef jansson.json_t *cjwk = NULL
    cdef jansson.json_t *crcp = NULL

    if rcp is None:
        rcp = {}

    try:
        cjwe = obj2jansson(jwe, 'jwe')
        ccek = obj2jansson(cek, 'cek')
        cjwk = obj2jansson(jwk, 'jwk')
        crcp = obj2jansson(rcp, 'rcp')

        if not jose.jose_jwe_wrap(cjwe, ccek, cjwk, crcp):
            raise JoseOperationError('jwe_wrap')

        jwe.clear()
        jwe.update(jansson2obj(cjwe))

        cek.clear()
        cek.update(jansson2obj(ccek))
    finally:
        jansson.json_decref(cjwe)
        jansson.json_decref(ccek)
        jansson.json_decref(cjwk)
        jansson.json_decref(crcp)


def jwe_unwrap(dict jwe not None, dict jwk not None, dict rcp=None):
    cdef jansson.json_t *cjwe = NULL
    cdef jansson.json_t *cjwk = NULL
    cdef jansson.json_t *crcp = NULL
    cdef jansson.json_t *ccek = NULL

    try:
        cjwe = obj2jansson(jwe, 'jwe')
        cjwk = obj2jansson(jwk, 'jwk')

        if rcp is not None:
            crcp = obj2jansson(rcp, 'rcp')

        ccek = jose.jose_jwe_unwrap(cjwe, cjwk, crcp)
        if not ccek:
            raise JoseOperationError('jwe_unwrap')

        return jansson2obj(ccek)
    finally:
        jansson.json_decref(cjwe)
        jansson.json_decref(cjwk)
        jansson.json_decref(crcp)
        jansson.json_decref(ccek)


def jwe_decrypt(dict jwe not None, dict cek not None):
    cdef jansson.json_t *cjwe = NULL
    cdef jansson.json_t *ccek = NULL
    cdef jose.jose_buf_t *pt = NULL

    try:
        cjwe = obj2jansson(jwe, 'jwe')
        ccek = obj2jansson(cek, 'cek')
        pt = jose.jose_jwe_decrypt(cjwe, ccek)
        if not pt:
            raise JoseOperationError('jwe_decrypt')

        return pt.data[:pt.size]
    finally:
        jansson.json_decref(cjwe)
        jansson.json_decref(ccek)
        jose.jose_buf_decref(pt)


def jwe_merge_header(dict jwe not None, dict rcp not None):
    cdef jansson.json_t *cjwe = NULL
    cdef jansson.json_t *crcp = NULL
    cdef jansson.json_t *chdr = NULL
    cdef char *ret = NULL

    try:
        cjew = obj2jansson(jwe, 'jwe')
        crco = obj2jansson(rcp, 'rcp')

        chdr = jose.jose_jwe_merge_header(cjwe, crcp)
        if not chdr:
            raise JoseOperationError('jwe_merge_header')

        return jansson2obj(chdr)
    finally:
        jansson.json_decref(cjwe)
        jansson.json_decref(crcp)
        jansson.json_decref(chdr)


def from_compact(bytes compact not None):
    cdef jansson.json_t *cjose = NULL

    try:
        cjose = jose.jose_from_compact(compact)
        if not cjose:
            raise JoseOperationError('from_compact')

        return jansson2obj(cjose)
    finally:
        jansson.json_decref(cjose)


def to_compact(dict flat not None):
    cdef jansson.json_t *cjose = NULL
    cdef char *ret = NULL

    cjose = obj2jansson(flat, 'flat')
    try:
        ret = jose.jose_to_compact(cjose)
        if not ret:
            raise JoseOperationError('to_compact')

        return <bytes>ret
    finally:
        jansson.json_decref(cjose)
        free(ret)
