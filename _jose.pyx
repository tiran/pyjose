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

def get_supported_algorithms():
    cdef jose.jose_jwe_crypter_t *jwe_crypter
    cdef jose.jose_jwe_wrapper_t *jwe_wrapper
    cdef jose.jose_jwe_zipper_t *jwe_zipper
    cdef jose.jose_jwk_generator_t *jwk_generator
    cdef jose.jose_jwk_hasher_t *jwk_hasher
    cdef jose.jose_jwk_op_t *jwk_op
    cdef jose.jose_jwk_type_t *jwk_type
    cdef jose.jose_jws_signer_t *jws_signer
    cdef char *p
    cdef size_t i

    result = {
       'jwk_types': {},
       'jwk_ops': [],
       'jwk_generators': set(),
       'jwk_hashers': {},
       'jws_signers': set(),
       'jwe_crypters': set(),
       'jwe_wrappers': set(),
       'jwe_zippers': set(),
    }

    jwe_crypter = jose.jose_jwe_crypters()
    while jwe_crypter is not NULL:
        result['jwe_crypters'].add(ascii2obj(jwe_crypter.enc))
        jwe_crypter = jwe_crypter.next

    jwe_wrapper = jose.jose_jwe_wrappers()
    while jwe_wrapper is not NULL:
        result['jwe_wrappers'].add(ascii2obj(jwe_wrapper.alg))
        jwe_wrapper = jwe_wrapper.next

    jwe_zipper = jose.jose_jwe_zippers()
    while jwe_zipper is not NULL:
        result['jwe_zippers'].add(ascii2obj(jwe_zipper.zip))
        jwe_zipper = jwe_zipper.next

    jwk_generator = jose.jose_jwk_generators()
    while jwk_generator is not NULL:
        result['jwk_generators'].add(ascii2obj(jwk_generator.kty))
        jwk_generator = jwk_generator.next

    jwk_hasher = jose.jose_jwk_hashers()
    while jwk_hasher is not NULL:
        name = ascii2obj(jwk_hasher.name)
        result['jwk_hashers'][name] = jwk_hasher.size
        jwk_hasher = jwk_hasher.next

    jwk_op = jose.jose_jwk_ops()
    while jwk_op is not NULL:
        result['jwk_ops'].append(
            (ascii2obj(jwk_op.pub),
             ascii2obj(jwk_op.prv),
             ascii2obj(jwk_op.use))
        )
        jwk_op = jwk_op.next

    jwk_type = jose.jose_jwk_types()
    while jwk_type is not NULL:
        name = ascii2obj(jwk_type.kty)
        reqs = []
        prvs = []

        if jwk_type.req is not NULL:
            for i in range(255):
                p = jwk_type.req[i]
                if p is NULL:
                    break
                reqs.append(ascii2obj(p))

        if jwk_type.prv is not NULL:
            for i in range(255):
                p = jwk_type.prv[i]
                if p is NULL:
                    break
                prvs.append(ascii2obj(p))

        result['jwk_types'][name] = {
            'req': reqs,
            'prv': prvs,
            'sym': True if jwk_type.sym else False
        }

        jwk_type = jwk_type.next

    jws_signer = jose.jose_jws_signers()
    while jws_signer is not NULL:
        result['jws_signers'].add(ascii2obj(jws_signer.alg))
        jws_signer = jws_signer.next

    return result
