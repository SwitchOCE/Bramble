//! Thread CPU time, the clock every seat is measured on.
#![allow(unsafe_code)]

/// CPU time this thread has used, in ns (`CLOCK_THREAD_CPUTIME_ID`).
pub fn thread_cpu_ns() -> i64 {
    let mut ts = libc::timespec { tv_sec: 0, tv_nsec: 0 };
    // SAFETY: clock_gettime writes one timespec through a valid pointer.
    let rc = unsafe { libc::clock_gettime(libc::CLOCK_THREAD_CPUTIME_ID, &mut ts) };
    assert_eq!(rc, 0, "clock_gettime(CLOCK_THREAD_CPUTIME_ID) failed");
    ts.tv_sec * 1_000_000_000 + ts.tv_nsec
}

/// The CPU clock id of the calling thread, so a watchdog thread can read it.
pub fn this_thread_clock() -> libc::clockid_t {
    let mut id: libc::clockid_t = 0;
    // SAFETY: pthread_self is always valid for the calling thread; id is a valid out pointer.
    let rc = unsafe { libc::pthread_getcpuclockid(libc::pthread_self(), &mut id) };
    assert_eq!(rc, 0, "pthread_getcpuclockid failed");
    id
}

/// CPU time of the thread whose clock id is `id`, in ns, or None if it can't be read.
pub fn clock_ns(id: libc::clockid_t) -> Option<i64> {
    let mut ts = libc::timespec { tv_sec: 0, tv_nsec: 0 };
    // SAFETY: clock_gettime writes one timespec through a valid pointer.
    let rc = unsafe { libc::clock_gettime(id, &mut ts) };
    (rc == 0).then_some(ts.tv_sec * 1_000_000_000 + ts.tv_nsec)
}
