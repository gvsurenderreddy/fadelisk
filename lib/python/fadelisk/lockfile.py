
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
            raise LockfileError("Lockfile %s already open by this process" %
                               self.filename)
        if self.has_exlock():
            raise LockfileLockedError(
                'Lock file already locked by PID %s' % self.get_pid())

        pwent = pwd.getpwnam(self.user)

        if not os.path.exists(self.path):
            os.mkdir(self.path)
        os.chown(self.path, pwent.pw_uid, pwent.pw_gid)
        os.chmod(self.path, 0o755)

        self.fd = os.open(self.filename, os.O_WRONLY | os.O_CREAT | os.O_TRUNC)
        os.fchown(self.fd, pwent.pw_uid, pwent.pw_gid)
        os.fchmod(self.fd, 0o644)

        try:
            self.lock = fcntl.lockf(self.fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except:
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
        except:
            raise LockfileReleaseError(
                'Unable to unlock lockfile %s' % self.filename)
        os.close(self.fd)
        os.remove(self.filename)

    def kill_process(self, sig=signal.SIGTERM, wait=True):
        pid = self.get_pid()
        if not pid:
            print('Process is not running')
            return

        if not self.has_exlock():
            try:
                os.remove(self.filename)
            except:
                raise LockfileStaleError("Lockfile: stale lockfile")
            return 0

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

    def has_exlock(self):
        if not os.path.exists(self.filename):
            return False

        with open(self.filename) as f:
            try:
                fcntl.lockf(f.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
            except:
                return True
        return False

    def get_pid(self):
        try:
            with open(self.filename, "r") as lockfile:
                return int(lockfile.read())
        except:
            return 0

