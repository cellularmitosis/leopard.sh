#!/bin/bash

echo "Current system:"
cat /System/Library/Frameworks/OpenGL.framework/Headers/*.h | grep define | grep VERSION | sort
echo

for sdk in MacOSX10.3.9.sdk MacOSX10.4u.sdk MacOSX10.5.sdk ; do
    echo "$sdk:"
    cat /Developer/SDKs/$sdk/System/Library/Frameworks/OpenGL.framework/Headers/*.h \
    | grep define \
    | grep VERSION \
    | sort
    echo
done
