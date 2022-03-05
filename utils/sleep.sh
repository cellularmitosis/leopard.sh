#!/bin/bash

set -e

if test -n "$1" ; then
    # tell another machine to sleep.
    host=$1
    ssh $host osascript -e \'tell application \"Finder\" to sleep\'
else
    # sleep this machine.
    osascript -e 'tell application "Finder" to sleep'
fi
