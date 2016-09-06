from libc.signal cimport SIG_DFL, SIG_IGN, SIG_ERR, sighandler_t, signal, SIGINT


cdef class SignalsStack:
    def __cinit__(self):
        self.saved = 0
        for i in range(MAX_SIG):
            self.signals[i] = NULL

    cdef save(self):
        cdef sighandler_t handler

        for i in range(MAX_SIG):
            handler = <sighandler_t>(PyOS_getsig(i))
            if handler != SIG_ERR:
                self.signals[i] = handler

        self.saved = 1

    cdef restore(self):
        cdef:
            sighandler_t sig

        if not self.saved:
            raise RuntimeError("SignalsStack.save() wasn't called")

        for i in range(MAX_SIG):
            if self.signals[i] == NULL:
                continue

            if PyOS_setsig(i, self.signals[i]) == SIG_ERR:
                raise convert_error(-errno.errno)


cdef void __signal_handler_sigint(int sig) nogil:
    cdef sighandler_t handle

    # We can run this method without GIL because there is no
    # Python code here -- all '.' and '[]' operators work on
    # C structs/pointers.

    if sig != SIGINT or __main_loop__ is None:
        return

    if __main_loop__._executing_py_code and not __main_loop__._custom_sigint:
        PyErr_SetInterrupt()  # void
        return

    if __main_loop__.uv_signals is not None:
        handle = __main_loop__.uv_signals.signals[sig]
        if handle is not NULL:
            handle(sig)  # void


cdef __signal_set_sigint():
    if PyOS_setsig(SIGINT, __signal_handler_sigint) == SIG_ERR:
        raise convert_error(-errno.errno)
