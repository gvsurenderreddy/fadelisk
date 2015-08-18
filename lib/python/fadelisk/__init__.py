
from . import application
from . import constants

def begins():                       # so apps can have "fadelisk.begins()"
    app = application.Application()
    app.run()

