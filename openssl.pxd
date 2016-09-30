
cdef extern from "openssl/evp.h":
    void OpenSSL_add_all_algorithms()


cdef extern from "openssl/bio.h":
    ctypedef struct BIO:
        pass

    ctypedef struct BIO_METHOD:
        pass

    const BIO_METHOD *BIO_s_mem()
    long BIO_get_mem_data(BIO *, char **)
    BIO *BIO_new(const BIO_METHOD *)
    int BIO_free(BIO *)


cdef extern from "openssl/err.h":
    void ERR_load_crypto_strings()
    void ERR_print_errors(BIO *)
    unsigned long ERR_peek_error()
