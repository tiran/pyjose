from libc cimport stdio

cdef extern from "jansson.h":
    ctypedef struct json_t:
        pass

    ctypedef struct json_auto_t:
        pass

    ctypedef struct json_error_t:
        int line
        int column
        int position
        char *source
        char *text

    ctypedef long long json_int_t

    int JANSSON_MAJOR_VERSION, JANSSON_MINOR_VERSION, JANSSON_MICRO_VERSION

    ctypedef enum json_type:
        JSON_OBJECT,
        JSON_ARRAY,
        JSON_STRING,
        JSON_INTEGER,
        JSON_REAL,
        JSON_TRUE,
        JSON_FALSE,
        JSON_NULL

    json_type json_typeof(json_t *json)

    # ref count
    json_t *json_incref(json_t *json)
    void json_decref(json_t *json)

    # new objects
    json_t *json_object()
    json_t *json_array()
    json_t *json_string(const char *value)
    #json_t *json_stringn(const char *value, size_t len)
    json_t *json_integer(json_int_t value)
    json_t *json_real(double value)
    json_t *json_true()
    json_t *json_false()
    json_t *json_null()

    # object get / iter
    size_t json_object_size(const json_t *object)
    json_t *json_object_get(const json_t *object, const char *key)
    int json_object_set_new(json_t *object, const char *key, json_t *value)
    void *json_object_iter(json_t *object)
    void *json_object_key_to_iter(const char *key)
    void *json_object_iter_next(json_t *object, void *iter)
    const char *json_object_iter_key(void *iter)
    json_t *json_object_iter_value(void *iter)

    # array get
    size_t json_array_size(const json_t *array)
    json_t *json_array_get(const json_t *array, size_t index)
    int json_array_append_new(json_t *array, json_t *value)

    # convert
    const char *json_string_value(const json_t *string)
    size_t json_string_length(const json_t *string)
    json_int_t json_integer_value(const json_t *integer)
    double json_real_value(const json_t *real)
    #double json_number_value(const json_t *json)

    # pack and unpack
    json_t *json_pack(const char *fmt, ...)
    json_t *json_pack_ex(json_error_t *error, size_t flags, const char *fmt, ...)

    int json_unpack(json_t *root, const char *fmt, ...)
    int json_unpack_ex(json_t *root, json_error_t *error, size_t flags, const char *fmt, ...)

    json_t *json_loads(const char *input, size_t flags, json_error_t *error)
    json_t *json_loadb(const char *buffer, size_t buflen, size_t flags, json_error_t *error)
    json_t *json_load_file(const char *path, size_t flags, json_error_t *error)

    char *json_dumps(const json_t *json, size_t flags)
    int json_dumpf(const json_t *json, stdio.FILE *output, size_t flags)
    int json_dump_file(const json_t *json, const char *path, size_t flags)

    # misc
    void json_object_seed(size_t seed)
    int json_equal(json_t *value1, json_t *value2)
    json_t *json_deep_copy(const json_t *value)
