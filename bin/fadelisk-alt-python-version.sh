#!/bin/sh

INTERPRETER="python2.6"
SCRIPT="fadelisk.real"

if ! echo $SCRIPT | egrep -q '^/'
then
    # Script does not have an absolute path. Try to find it in $PATH.
    if which $SCRIPT >/dev/null
    then
	SCRIPT=$(which $SCRIPT)
    else
	echo "Script $SCRIPT could not be found in path"
	exit 1
    fi
else
    # Otherwise, make sure it exists.
    if ! [ -e $SCRIPT ]
    then
	echo "Script $SCRIPT does not exist"
	exit 1
    fi
fi

exec $INTERPRETER $SCRIPT $@

