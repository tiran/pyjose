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

    int JANSSON_MAJOR_VERSION, JANSSON_MINOR_VERSION, JANSSON_MICRO_VERSION

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
