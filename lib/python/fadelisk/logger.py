
import os
import sys
import syslog

class LoggerError(Exception):
    pass

class Logger(object):
    def __init__(self, ident=None, facility=syslog.LOG_DAEMON,
                 logoption=syslog.LOG_NDELAY | syslog.LOG_PID):
        self.ident = ident
        self.facility = facility
        self.logoption = logoption

        if self.ident == None:
            self.ident = os.path.basename(sys.argv[0])
        self.openlog()

    def openlog(self):
        syslog.openlog(self.ident, self.logoption, self.facility)

    def log(self, priority, message):
        syslog.syslog(priority, str(message))

    def error(self, message):
        self.log(syslog.LOG_ERR, message)

    def warning(self, message):
        self.log(syslog.LOG_WARNING, message)

    def info(self, message):
        self.log(syslog.LOG_INFO, message)

    def debug(self, message):
        self.log(syslog.LOG_DEBUG, message)

    def set_level(self, level):
        levels = {
            'error':   syslog.LOG_ERR,
            'warning': syslog.LOG_WARNING,
            'info':    syslog.LOG_INFO,
            'debug':   syslog.LOG_DEBUG,
        }
        try:
            syslog.setlogmask(syslog.LOG_UPTO(levels[level]))
        except KeyError:
            raise LoggerError("Unknown log level while setting threshold")

    def stderr_on(self):
        self.logoption |= syslog.LOG_PERROR
        self.openlog()

    def stderr_off(self):
        self.logoption &= ~syslog.LOG_PERROR
        self.openlog()

