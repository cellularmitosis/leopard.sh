#!/bin/bash

set -e

if test -e /System/Library/LaunchAgents/com.apple.Spotlight.plist
|| test -e /System/Library/LaunchDaemons/com.apple.metadata.mds.plist ; then
    read -p "Disable Spotlight? [Y/n]: " answer
    while true ; do
        if test "$answer" = "y" -o "$answer" = "Y" -o "$answer" = "" ; then
            for f in /System/Library/LaunchAgents/com.apple.Spotlight.plist /System/Library/LaunchDaemons/com.apple.metadata.mds.plist ; do
                if test -e $f ; then
                    mv $f $f.disabled
                fi
            done
        elif test "$answer" = "n" -o "$answer" = "N" ; then
            break
        else
            read -p "Please type 'y', 'n' or hit ENTER (same as 'y') " answer
        fi
    done
fi

read -p "Enable QuartzGL? [Y/n]: " answer
while true ; do
    if test "$answer" = "y" -o "$answer" = "Y" -o "$answer" = "" ; then
        sudo defaults write /Library/Preferences/com.apple.windowserver QuartzGLEnabled -boolean YES
    elif test "$answer" = "n" -o "$answer" = "N" ; then
        break
    else
        read -p "Please type 'y', 'n' or hit ENTER (same as 'y') " answer
    fi
done

read -p "Disable BeamSync (NOT for CRT's!)? [Y/n]: " answer
while true ; do
    if test "$answer" = "y" -o "$answer" = "Y" -o "$answer" = "" ; then
        sudo defaults write /Library/Preferences/com.apple.windowserver Compositor -dict deferredUpdates 0
    elif test "$answer" = "n" -o "$answer" = "N" ; then
        break
    else
        read -p "Please type 'y', 'n' or hit ENTER (same as 'y') " answer
    fi
done
