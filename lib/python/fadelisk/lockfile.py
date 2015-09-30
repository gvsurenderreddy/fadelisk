
from __future__ import print_function

import os
import pwd
import grp
import struct
import fcntl
import signal
import time

class LockfileError(Exception): pass
class LockfileOpenError(Exception): pass
class LockfileLockedError(Exception): pass
class LockfileStaleError(Exception): pass
class LockfileEstablishError(Exception): pass
class LockfileReleaseError(Exception): pass
class LockfileKillError(Exception): pass
class LockfileKillTimeoutError(Exception): pass

class Lockfile(object):
    def __init__(self, dir_name, instance_name=None, user='nobody'):
        self.dir_name = dir_name
        if instance_name != None:
            self.instance_name = instance_name
        else:
            self.instance_name = dir_name
        self.user = user

        self.path = os.path.join('/var/run', self.dir_name)
        self.filename = os.path.join(self.path, self.instance_name) + '.pid'

        self.fd = None
        self.lock = None

    def acquire(self):
        if self.fd:
            raise LockfileError("Lockfile %s already open this process" %
                               self.filename)

        pid = self.get_locking_process()
        if pid:
            raise LockfileLockedError(
                'Lock file already locked by PID %s' % pid)

        pwent = pwd.getpwnam(self.user)

        if not os.path.exists(self.path):
            os.mkdir(self.path, 0o775)
        os.chown(self.path, pwent.pw_uid, pwent.pw_gid)

        self.fd = os.open(self.filename, os.O_WRONLY | os.O_CREAT |
                          os.O_TRUNC, 0o664)
        os.fchown(self.fd, pwent.pw_uid, pwent.pw_gid)

        try:
            self.lock = fcntl.lockf(self.fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except:
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
                'Unable to unlock lockfile %s' % self.filename)
        os.close(self.fd)
        os.remove(self.filename)

    def kill_process(self, sig=signal.SIGTERM, wait=True):
        if not os.path.exists(self.filename):
            print('Process is not running')
            return

        pid = self.get_locking_process()

        if not pid:
            try:
                os.remove(self.filename)
            except:
                raise LockfileStaleError("Lockfile: stale lockfile")
            return 0

        # This process is locking the file
        if pid == os.getpid():
            raise LockfileKillError("Lockfile: would terminate this process")

        os.kill(pid, sig)

        if wait:
            for interval in range(100):
                if not os.path.exists(self.filename):
                    return
                time.sleep(.1)
            raise LockfileKillTimeoutError(
                "Timeout while waiting for process to exit")

    def get_locking_process(self):
        if not os.path.exists(self.filename):
            return 0

        pid = None
        with open(self.filename, "r") as lockfile:
            flock_t = struct.pack('hhqqh', fcntl.F_WRLCK, 0, 0, 0, 0)
            lock = fcntl.fcntl(lockfile, fcntl.F_GETLK, flock_t)
            type_, whence, start, len_, pid = struct.unpack('hhqqh', lock)
        return pid

