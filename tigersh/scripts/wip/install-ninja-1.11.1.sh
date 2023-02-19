#!/opt/tigersh-deps-0.1/bin/bash
# based on templates/build-from-source.sh v6

# Install ninja on OS X Tiger / PowerPC.

package=ninja
version=1.11.1
upstream=https://github.com/ninja-build/$package/archive/refs/tags/v$version.tar.gz
description="A small build system similar to make"

set -e -o pipefail
PATH="/opt/tigersh-deps-0.1/bin:$PATH"
TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://leopard.sh}

if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
    ppc64=".ppc64"
fi

pkgspec=$package-$version$ppc64

for dep in \
    macports-legacy-support-20221029$ppc64
do
    if ! test -e /opt/$dep ; then
        tiger.sh $dep
    fi
    CPPFLAGS="-I/opt/$dep/include $CPPFLAGS"
    LDFLAGS="-L/opt/$dep/lib $LDFLAGS"
    PATH="/opt/$dep/bin:$PATH"
done
LIBS="-lMacportsLegacySupport"

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

if tiger.sh --install-binpkg $pkgspec ; then
    exit 0
fi

echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2
set -x

if ! test -e /usr/bin/gcc ; then
    tiger.sh xcode-2.5
fi

if ! test -e /opt/python-3.11.2 ; then
    tiger.sh python-3.11.2
    PATH="/opt/python-3.11.2/bin:$PATH"
fi

echo -n -e "\033]0;tiger.sh $pkgspec ($(tiger.sh --cpu))\007"

tiger.sh --unpack-dist $pkgspec
cd /tmp/$package-$version

sed -i '' -e 's|#!/usr/bin/env python|#!/usr/bin/env python3|' configure.py
sed -i '' -e 's|#include <spawn.h>|#include <sys/spawn.h>|' src/subprocess-posix.cc

# Fails on Tiger due to missing posix spawn stuff:
#   c++ -MMD -MT build/subprocess-posix.o -MF build/subprocess-posix.o.d -g -Wall -Wextra -Wno-deprecated -Wno-missing-field-initializers -Wno-unused-parameter -fno-rtti -fno-exceptions -fvisibility=hidden -pipe '-DNINJA_PYTHON="python3"' -O2 -DNDEBUG -DNINJA_HAVE_BROWSE -I. -I/opt/macports-legacy-support-20221029/include/LegacySupport -c ./src/subprocess-posix.cc -o build/subprocess-posix.o
#   ./src/subprocess-posix.cc: In member function 'bool Subprocess::Start(SubprocessSet*, const std::string&)':
#   ./src/subprocess-posix.cc:64: error: 'posix_spawn_file_actions_t' was not declared in this scope
#   ./src/subprocess-posix.cc:64: error: expected `;' before 'action'
#   ./src/subprocess-posix.cc:65: error: 'action' was not declared in this scope
#   ./src/subprocess-posix.cc:65: error: 'posix_spawn_file_actions_init' was not declared in this scope
#   ./src/subprocess-posix.cc:69: error: 'posix_spawn_file_actions_addclose' was not declared in this scope
#   ./src/subprocess-posix.cc:73: error: 'posix_spawnattr_t' was not declared in this scope
#   ./src/subprocess-posix.cc:73: error: expected `;' before 'attr'
#   ./src/subprocess-posix.cc:74: error: 'attr' was not declared in this scope
#   ./src/subprocess-posix.cc:74: error: 'posix_spawnattr_init' was not declared in this scope
#   ./src/subprocess-posix.cc:80: error: 'POSIX_SPAWN_SETSIGMASK' was not declared in this scope
#   ./src/subprocess-posix.cc:81: error: 'posix_spawnattr_setsigmask' was not declared in this scope
#   ./src/subprocess-posix.cc:90: error: 'POSIX_SPAWN_SETPGROUP' was not declared in this scope
#   ./src/subprocess-posix.cc:95: error: 'posix_spawn_file_actions_addopen' was not declared in this scope
#   ./src/subprocess-posix.cc:100: error: 'posix_spawn_file_actions_adddup2' was not declared in this scope
#   ./src/subprocess-posix.cc:116: error: 'posix_spawnattr_setflags' was not declared in this scope
#   ./src/subprocess-posix.cc:122: error: 'posix_spawn' was not declared in this scope
#   ./src/subprocess-posix.cc:126: error: 'posix_spawnattr_destroy' was not declared in this scope
#   ./src/subprocess-posix.cc:129: error: 'posix_spawn_file_actions_destroy' was not declared in this scope

CFLAGS="-I/opt/macports-legacy-support-20221029$ppc64/include/LegacySupport" \
LIBS="-lMacportsLegacySupport" \
./configure.py --verbose --bootstrap

mkdir -p /opt/$pkgspec/bin
cp ninja /opt/$pkgspec/bin/
rsync -av doc misc /opt/$pkgspec/

tiger.sh --linker-check $pkgspec
tiger.sh --arch-check $pkgspec $ppc64

if test -e config.cache ; then
    mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec
    gzip -9 config.cache
    mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/
fi
