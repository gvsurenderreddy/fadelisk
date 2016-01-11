
from __future__ import print_function

import os
import pwd
import grp
import struct
import fcntl
import signal
import time

class LockfileEstablishError(Exception): pass
class LockfileKillError(Exception): pass
class LockfileKillTimeoutError(Exception): pass
class LockfileLockedError(Exception): pass
class LockfileProcessNotRunningError(Exception): pass

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
            return
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
            return

        fcntl.lockf(self.fd, fcntl.LOCK_UN)
        os.close(self.fd)
        os.remove(self.filename)

    def kill_process(self, sig=signal.SIGTERM, wait=True):
        if not os.path.exists(self.filename):
            raise LockfileProcessNotRunningError("Process is not running")

        if not self.has_exlock():
            os.remove(self.filename)
            return

        pid = self.get_pid()
        if pid == os.getpid():
            raise LockfileKillError("Lockfile: would terminate this process")
        os.kill(pid, sig)

        if not wait:
            return
        for i in range(1,13):
            if not os.path.exists(self.filename):
                return
            time.sleep(2**i/1000.)
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
        with open(self.filename, "r") as lockfile:
            return int(lockfile.read())

