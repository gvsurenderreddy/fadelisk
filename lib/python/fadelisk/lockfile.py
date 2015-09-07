
import os
import pwd
import struct
import fcntl
import signal

class LockfileError(Exception): pass
class LockfileOpenError(Exception): pass
class LockfileLockedError(Exception): pass
class LockfileStaleError(Exception): pass
class LockfileEstablishError(Exception): pass
class LockfileReleaseError(Exception): pass
class LockfileKillError(Exception): pass

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
            if self.get_locking_process(self.filename):
                raise LockfileLockedError(
                    'Lock file already locked by PID %s' % pid)
        except:
            pass
        try:
            self.fd = os.open(self.filename, os.O_WRONLY | os.O_CREAT |
                              os.O_TRUNC)
        except Exception:
            raise LockfileOpenError("Could not open lock file %s" %
                                    self.filename)
        try:
            self.lock = fcntl.lockf(self.fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except Exception:
            self.lock = None
            os.close(self.fd)
            self.fd = None
            raise LockfileEstablishError("Could not establish lock %s" %
                                        self.filename)
        os.write(self.fd, "%s\n" % os.getpid())

    def release(self):
        if not self.fd:
            raise LockfileReleaseError(
                "Lockfile not locked by this process: %s" % self.filename)
        try:
            fcntl.lockf(self.fd, fcntl.LOCK_UN)
        except Exception:
            raise LockfileReleaseError(
                "Unable to unlock lockfile %s" % self.filename)
        os.close(self.fd)
        self.remove_lockfile()

    def kill_process(self):
        pid = self.get_locking_process(self.filename)

        # There was no lock on the file
        if not pid:
            self.remove_lockfile()
            raise LockfileStaleError("Lockfile: stale lockfile")

        # This process is locking the file
        if pid == os.getpid():
            raise LockfileKillError(
                "Lockfile: would terminate this process")

        os.kill(pid, signal.SIGTERM)

    def get_locking_process(self, filename):
        pid = None
        try:
            with open(filename, "r") as lockfile:
                flock_t = struct.pack('hhqqh', fcntl.F_WRLCK, 0, 0, 0, 0)
                lock = fcntl.fcntl(lockfile, fcntl.F_GETLK, flock_t)
                type_, whence, start, len_, pid = struct.unpack('hhqqh', lock)
        except IOError:
            raise LockfileOpenError('Lock file %s does not exist' % filename)
        return pid

    def chown_lockfile(self, username):
        pwent = pwd.getpwnam(username)
        os.fchown(self.fd, pwent.pw_uid, pwent.pw_gid)

    def remove_lockfile(self):
        if os.path.exists(self.filename):
            os.remove(self.filename)

