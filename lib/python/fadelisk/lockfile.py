from __future__ import print_function

import os
import sys
import pwd
import struct
import fcntl
import signal

class LockfileError(Exception): pass

class Lockfile(object):
    def __init__(self, filename):
        self.filename = filename
        self.fd = None
        self.lock = None

        if not self.filename.endswith(".pid"):              # extension
            self.filename = self.filename + ".pid"
        if not self.filename.startswith('/'):               # full path
            self.filename = '/var/lock/' + self.filename

        if not self.filename.startswith('/var/lock'):       # restrict path
            raise LockfileError("Lockfile path restricted: %s" %
                                self.filename)

    def acquire(self):
        if self.fd:
            raise LockfileError("Lockfile %s already open this process" %
                               self.filename)
        try:
            self.fd = os.open(self.filename,
                              os.O_WRONLY | os.O_CREAT | os.O_TRUNC)
        except Exception:
            print("Could not open lock file %s" % self.filename,
                  file=sys.stderr)
            raise

        try:
            self.lock = fcntl.lockf(self.fd, fcntl.LOCK_EX|fcntl.LOCK_NB)
        except Exception:
            self.lock = None
            os.close(self.fd)
            self.fd = None
            print("Could not establish lock %s" % self.filename,
                  file=sys.stderr)
            sys.exit(1)

        os.write(self.fd, "%s\n" % os.getpid())

    def chown_lockfile(self, username):
        pwent = pwd.getpwnam(username)
        os.fchown(self.fd, pwent.pw_uid, pwent.pw_gid)

    def remove_lockfile(self):
        try:
            os.remove(self.filename)
        except:
            pass

    def release(self):
        if not self.fd:
            raise LockfileError("Lockfile not locked by this process: %s" %
                               self.filename)
        try:
            fcntl.lockf(self.fd, fcntl.LOCK_UN)
        except Exception:
            print("Unable to unlock lockfile %s" % self.filename,
                  file=sys.stderr)
            raise

        os.close(self.fd)
        self.remove_lockfile()

    def kill_process(self):
        with open(self.filename, "r") as lockfile:

            #-- Get locking process
            flock_t = struct.pack('hhqqh', fcntl.F_WRLCK, 0, 0, 0, 0)
            lock = fcntl.fcntl(lockfile, fcntl.F_GETLK, flock_t)
            type_, whence, start, len_, pid = struct.unpack('hhqqh', lock)

            if not pid:
                self.remove_lockfile()
                raise LockfileError("Lockfile: stale lockfile")

            if pid == os.getpid():
                raise RuntimeError("Lockfile: would terminate own process")

            os.kill(pid, signal.SIGTERM)
            sys.exit(0)

