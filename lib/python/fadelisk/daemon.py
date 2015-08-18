
from __future__ import print_function

import os
import sys
import pwd
import signal

class Daemon(object):
    def __init__(self, working_dir='/', umask=027, full_closure=False,
                 stdin='/dev/null', stdout='/dev/null', stderr=None):
        self.working_dir = working_dir
        self.umask = umask
        self.full_closure = full_closure
        self.stdin = stdin
        self.stdout = stdout
        self.stderr = stderr

    def daemonize(self):
        self.fork_process()
        self.decouple()
        self.fork_process()
        signal.signal(signal.SIGHUP, signal.SIG_IGN)
        self.reopen_std_streams()

    def fork_process(self):
        if os.fork():
            os._exit(0)             # exit parent

    def decouple(self):
        os.chdir(self.working_dir)
        os.setsid()                 # become process group leader
        os.umask(self.umask)

    def chuser(self, username):
        pwent = pwd.getpwnam(username)
        os.setgid(pwent.pw_gid)
        os.setuid(pwent.pw_uid)

    def euser(self):
        os.setuid(os.geteuid())
        os.setgid(os.getegid())

    def reopen_std_streams(self):
        # stdin/stdout on a forked process should have assured
        # desinations instead of a possibly vanishing controlling TTY.
        # Closure is an acceptable solution, but redirection to the
        # null device provides a stable destination and thus ensures
        # that subsequent write operations do not raise exceptions. Note:
        #
        #  * If stdin/stderr remain open/unredirected, SSH sessions
        #    will block when an interactive shell is exited because
        #    SSH is waiting for forthcoming data. The presence of an
        #    open/unredirected stderr does not have this effect.
        #
        #  * Merely redirecting sys.std* is inadequate because copies
        #    of the original FDs are preserved in sys.__std*__ and
        #    remain open unless explicitely closed.
        if self.full_closure:
            try:
                max_fd = os.sysconf("SC_OPEN_MAX")
            except:
                max_fd = 1024
            os.closerange(0, max_fd)

        with open('/dev/null', 'r') as stdin:
            os.dup2(stdin.fileno(), sys.stdin.fileno())
            os.dup2(stdin.fileno(), sys.__stdin__.fileno())

        with open(self.stdout, 'a+') as stdout:
            os.dup2(stdout.fileno(), sys.stdout.fileno())
            os.dup2(stdout.fileno(), sys.__stdout__.fileno())

        if self.stderr:
            with open(self.stderr, 'a+', 0) as stderr:
                os.dup2(stderr.fileno(), sys.stderr.fileno())
                os.dup2(stderr.fileno(), sys.__stderr__.fileno())


