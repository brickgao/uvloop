from libc.signal cimport sighandler_t


cdef extern from "Python.h":
    ctypedef void (*PyOS_sighandler_t)(int)

    PyOS_sighandler_t   PyOS_getsig(int)
    PyOS_sighandler_t   PyOS_setsig(int, PyOS_sighandler_t)


cdef class SignalsStack:
    cdef:
        sighandler_t[MAX_SIG] signals
        bint saved

    cdef save(self)
    cdef restore(self)
