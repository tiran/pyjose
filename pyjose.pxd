from libc.stdint cimport uint8_t, uint64_t
cimport jansson


cdef extern from "stdbool.h":
    ctypedef signed char bool


cdef extern from "openssl/crypto.h":
    void ERR_load_crypto_strings()
    unsigned long SSLeay()
    const char* SSLeay_version(int type)
    unsigned long OPENSSL_VERSION_NUMBER
    int SSLEAY_VERSION

cdef extern from "openssl/evp.h":
    void OpenSSL_add_all_algorithms()


cdef extern from "openssl/err.h":
    void ERR_load_crypto_strings()


cdef extern from "jose/buf.h":
    ctypedef struct jose_buf_t:
        size_t size
        uint8_t *data

    jose_buf_t *jose_buf(size_t size, uint64_t flags)
    jose_buf_t *jose_buf_incref(jose_buf_t *buf)
    void jose_buf_decref(jose_buf_t *buf)


cdef extern from "jose/jwe.h":
    jansson.json_t *jose_jwe_from_compact(const char *jwe)
    char *jose_jwe_to_compact(const jansson.json_t *jwe)
    bool jose_jwe_encrypt(jansson.json_t *jwe, const jansson.json_t *cek, const uint8_t pt[], size_t ptl)
    bool jose_jwe_wrap(jansson.json_t *jwe, jansson.json_t *cek, const jansson.json_t *jwk, jansson.json_t *rcp)
    jansson.json_t *jose_jwe_unwrap(const jansson.json_t *jwe, const jansson.json_t *rcp, const jansson.json_t *jwk)
    jose_buf_t *jose_jwe_decrypt(const jansson.json_t *jwe, const jansson.json_t *cek)
    jansson.json_t *jose_jwe_merge_header(const jansson.json_t *jwe, const jansson.json_t *rcp)


cdef extern from "jose/jwk.h":
    bool jose_jwk_generate(jansson.json_t *jwk)
    bool jose_jwk_clean(jansson.json_t *jwk)
    bool jose_jwk_allowed(const jansson.json_t *jwk, bool req, const char *use, const char *op)
    char *jose_jwk_thumbprint(const jansson.json_t *jwk, const char *hash)
    jansson.json_t *jose_jwk_exchange(const jansson.json_t *prv, const jansson.json_t *pub)


cdef extern from "jose/jws.h":
    jansson.json_t *jose_jws_from_compact(const char *jws)
    char *jose_jws_to_compact(const jansson.json_t *jws)
    bool jose_jws_sign(jansson.json_t *jws, const jansson.json_t *jwk, jansson.json_t *sig)
    bool jose_jws_verify(const jansson.json_t *jws, const jansson.json_t *jwk)
    jansson.json_t *jose_jws_merge_header(const jansson.json_t *sig)
