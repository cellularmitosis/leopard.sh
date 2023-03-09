#!/bin/bash

# Compute the MD5 of the audio stream of an MP3 file, ignoring ID3 tags.

# The problem with comparing MP3 files is that a simple change to the ID3 tags
# in one file will cause the two files to have differing MD5 sums.  This script
# avoids that problem by taking the MD5 of only the audio stream, ignoring the
# tags.

# Note that by virtue of using ffmpeg, this script happens to also work for any
# other audio file format supported by ffmpeg (not just MP3's).

set -e

stdoutf=$( mktemp mp3md5.XXXXXX )
stderrf=$( mktemp mp3md5.XXXXXX )

set +e
ffmpeg -i "$1" -c:a copy -f md5 - >$stdoutf 2>$stderrf
ret=$?
set -e

if test $ret -ne 0 ; then
    cat $stderrf
else
    cat $stdoutf | sed 's/MD5=//'
fi

rm -f $stdoutf $stderrf
exit $ret
