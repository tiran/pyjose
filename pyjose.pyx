# Cython imports
cimport cython
cimport jansson
cimport pyjose
from libc cimport stdio
from libc cimport stdlib
from libc cimport string
from cpython.unicode cimport PyUnicode_AsUTF8String, PyUnicode_DecodeUTF8
from cpython.float cimport PyFloat_AsDouble
from cpython.long cimport PyLong_AsLongLong
from cpython.object cimport Py_EQ, Py_NE
from cpython.version cimport PY_MAJOR_VERSION

# forward declarations
cdef class Jansson(object)

cdef NULL_JANSSON = object()

cdef Jansson newJansson(jansson.json_t *json):
    """Create Jansson instance, steals ref
    """
    if json is NULL:
        raise ValueError("json is NULL")
    cdef Jansson j = Jansson(NULL_JANSSON)
    j.json = json
    return j


# Jansson interface
cdef object _convert_from_json(jansson.json_t *json, size_t depths=0):
    cdef jansson.json_type jt
    cdef size_t len
    cdef size_t i
    cdef jansson.json_t *subjson
    cdef jansson.json_t *value
    cdef const char *key

    if depths >= 50:
        # _convert_json() is a naive recursive function
        # 50 levels is good enough for us
        raise RuntimeError("JSON is too deeply nested")

    jt = jansson.json_typeof(json)

    # Don't worry, Cython turns this into a switch statement
    if jt == jansson.JSON_OBJECT:
        retval = {}
        key = jansson.json_object_iter_key(jansson.json_object_iter(json))
        while 1:
            if key is NULL:
                break
            value = jansson.json_object_iter_value(
                jansson.json_object_key_to_iter(key)
            )
            pykey = PyUnicode_DecodeUTF8(key, string.strlen(key), NULL)
            pyvalue = _convert_from_json(value, depths+1)

            retval[pykey] = pyvalue
            # next key
            key = jansson.json_object_iter_key(
                jansson.json_object_iter_next(
                    json, jansson.json_object_key_to_iter(key)
            ))
        return retval
    elif jt == jansson.JSON_ARRAY:
        retval = []
        len = jansson.json_array_size(json)
        for i from 0 <= i < len:
            subjson = jansson.json_array_get(json, i)
            retval.append(_convert_from_json(subjson, depths+1))
        return retval
    elif jt == jansson.JSON_STRING:
        return PyUnicode_DecodeUTF8(
            jansson.json_string_value(json),
            jansson.json_string_length(json),
            NULL)
    elif jt == jansson.JSON_INTEGER:
        return jansson.json_integer_value(json)
    elif jt == jansson.JSON_REAL:
        return jansson.json_real_value(json)
    elif jt == jansson.JSON_TRUE:
        return True
    elif jt == jansson.JSON_FALSE:
        return False
    elif jt == jansson.JSON_NULL:
        return None
    else:
        raise ValueError(jt)


cdef jansson.json_t *_convert_to_json(object obj, size_t depths=0) except NULL:
    cdef jansson.json_t *subjson
    cdef jansson.json_t *jsonitem

    if depths == 0 and not isinstance(obj, (dict, list, tuple)):
        raise TypeError("'{}' is not an object or array".format(type(obj)))
    if depths >= 50:
        raise RuntimeError("Python data structure is too deeply nested")

    if obj is True:
        return jansson.json_true()
    elif obj is False:
        return jansson.json_false()
    elif obj is None:
        return jansson.json_null()
    elif isinstance(obj, int):
        return jansson.json_integer(PyLong_AsLongLong(obj))
    elif PY_MAJOR_VERSION == 2 and isinstance(obj, long):
        return jansson.json_integer(PyLong_AsLongLong(obj))
    elif isinstance(obj, float):
        return jansson.json_real(PyFloat_AsDouble(obj))
    elif isinstance(obj, unicode):
        return jansson.json_string(PyUnicode_AsUTF8String(obj))
    elif isinstance(obj, (list, tuple)):
        subjson = jansson.json_array()
        if subjson is NULL:
            raise MemoryError("json_array")
        for item in obj:
            jsonitem = _convert_to_json(item, depths+1)
            #if jsonitem is NULL:
            #    raise
            if jansson.json_array_append_new(subjson, jsonitem) == -1:
                raise ValueError("json_array_append", obj, item)
        return subjson
    elif isinstance(obj, dict):
        subjson = jansson.json_object()
        for key, value in obj.items():
            if not isinstance(key, unicode):
                raise TypeError("key '{}' is not text".format(key))
            keyb = PyUnicode_AsUTF8String(key)
            jsonitem = _convert_to_json(value, depths+1)
            if jansson.json_object_set_new(subjson, keyb, jsonitem) == -1:
                raise ValueError("json_object_set", key, value)
        return subjson
    else:
        raise TypeError(type(obj), obj)


@cython.final
cdef class Jansson(object):
    cdef jansson.json_t *json

    def __cinit__(self, object obj):
        if obj is NULL_JANSSON:
            self.json = NULL
        else:
            self.json = _convert_to_json(obj)

    cdef int _check(self) except -1:
        if self.json is NULL:
            raise ValueError("json is NULL")
        return 0

    def __str__(self):
        return self.dumps()

    def __richcmp__(Jansson self, Jansson other, op):
        cdef int eq

        self._check()
        if not isinstance(other, Jansson):
            return NotImplemented
        eq = jansson.json_equal(self.json, other.json)
        if op == Py_EQ:
            return True if eq else False
        elif op == Py_NE:
            return False if eq else True
        else:
            return NotImplemented

    __hash__ = None

    def __dealloc__(self):
        cdef jansson.json_t *json
        if self.json is not NULL:
            json = self.json
            self.json = NULL
            jansson.json_decref(json)

    def deepcopy(self):
        cdef jansson.json_t *json
        self._check()

        json = jansson.json_deep_copy(self.json)
        if json is NULL:
            raise MemoryError()
        return newJansson(json)

    def dumps(self, int flags=0):
        cdef char *dump
        self._check()
        dump = jansson.json_dumps(self.json, flags)
        try:
            return dump.decode('utf-8')
        finally:
            stdlib.free(dump)

    def dump(self):
        self._check()
        return _convert_from_json(self.json)



def demo():
    cdef jansson.json_t *jwk
    cdef Jansson j

    j = Jansson({u'alg': u'A128GCM'})
    pyjose.jose_jwk_generate(j.json)
    return j

# version numbers

JANSSON_VERSION = (
    jansson.JANSSON_MAJOR_VERSION,
    jansson.JANSSON_MINOR_VERSION,
    jansson.JANSSON_MICRO_VERSION
)


JSON_VERSION = None


cdef openssl_version(unsigned long version):
    patch = (version >> 4) & 0xFF
    fix = (version >> 12) & 0xFF
    minor = (version >> 20) & 0xFF
    major = (version >> 28) & 0xFF
    return major, minor, fix, patch


OPENSSL_VERSION = openssl_version(pyjose.SSLeay())
OPENSSL_VERSION_NAME = pyjose.SSLeay_version(pyjose.SSLEAY_VERSION).decode('utf-8')
OPENSSL_API_VERSION = openssl_version(pyjose.OPENSSL_VERSION_NUMBER)


cdef init():
    # init jansson hash randomization seed
    jansson.json_object_seed(0)
    # initialize OpenSSL
    pyjose.ERR_load_crypto_strings()
    pyjose.OpenSSL_add_all_algorithms()
    # try to import _ssl to set up threading locks
    try:
        __import__('_ssl')
    except ImportError:
        pass

init()
