#!/usr/bin/env python3

import sys
import re

def skip_optmirroreq(lines):
    lines2 = []
    for line in lines:
        if line.startswith('optmirror='):
            continue
        lines2.append(line)
    return lines2

def fix_url(lines):
    lines2 = []
    for line in lines:
        if line.endswith('/leopard}'):
            line = line[:-1] + 'sh}'
        lines2.append(line)
    return lines2

def fix_optmirror(lines):
    lines2 = []
    for line in lines:
        line = line.replace('$optmirror', '$LEOPARDSH_MIRROR')
        lines2.append(line)
    return lines2

def fix_binpkg(lines):
    lines2 = []
    for line in lines:
        line = line.replace('optpkg', 'binpkg')
        lines2.append(line)
    return lines2

def fix_set_e(lines):
    lines2 = []
    for line in lines:
        line = line.replace('set -e -x', 'set -e -x -o pipefail')
        lines2.append(line)
    return lines2

def fix_binpkgs(lines):
    lines2 = []
    for line in lines:
        line = line.replace('$TIGERSH_MIRROR/$binpkg', '$TIGERSH_MIRROR/binpkgs/$binpkg')
        lines2.append(line)
    return lines2

def fix_cache_configure(lines):
    lines2 = []
    for line in lines:
        if "./configure -C" not in line:
            line = line.replace('./configure', './configure -C')
        lines2.append(line)
    return lines2

def fix_make(lines):
    lines2 = []
    for line in lines:
        if "$(tiger.sh -j)" not in line \
            and "make install" not in line \
            and "make check" not in line \
            and "make clean" not in line \
            and "make[" not in line \
            and "make:" not in line:
            line = line.replace("make", "make $(tiger.sh -j)")
        lines2.append(line)
    return lines2

def fix_tests(lines):
    lines2 = []
    for line in lines:
        line = line.replace('$TIGERSH_MAKE_CHECK', '$TIGERSH_RUN_TESTS')
        lines2.append(line)
    return lines2

def fix_binpkg2(lines):
    lines2 = []
    for line in lines:
        line = line.replace('binpkg=$package-$version.$(tiger.sh --os.cpu).tar.gz', 'binpkg=$pkgspec.$(tiger.sh --os.cpu).tar.gz')
        lines2.append(line)
    return lines2

def fix_pkgspec(lines):
    has_pkgspec = False
    for line in lines:
        if 'pkgspec=$package-$version$ppc64' in line:
            has_pkgspec = True
            break
    if has_pkgspec:
        return lines
    start_index = None
    for (i, line) in enumerate(lines):
        if line == 'TIGERSH_MIRROR=${TIGERSH_MIRROR:-https://ssl.pepas.com/tigersh}':
            start_index = i
    if start_index is None:
        raise Exception("lolwut?")
    lines2 = lines[:start_index+1] \
        + [
            '',
            '''if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then''',
            '    ppc64=".ppc64"',
            'fi',
            '',
            'pkgspec=$package-$version$ppc64'
        ] \
        + lines[start_index+1:]
    return lines2

def fix_semicolons(lines):
    lines2 = []
    for line in lines:
        if 'Installing' not in line and re.search('[^ ];', line):
            line = line.replace(';', ' ;')
        lines2.append(line)
    return lines2

def fix_prefix(lines):
    lines2 = []
    for line in lines:
        line = line.replace('--prefix=/opt/$package-$version', '--prefix=/opt/$pkgspec')
        lines2.append(line)
    return lines2

def fix_ln(lines):
    lines2 = []
    for line in lines:
        if line == 'ln -sf /opt/$package-$version/bin/* /usr/local/bin/':
            lines += [
                'if test -e /opt/$pkgspec/bin ; then',
                '    ln -sf /opt/$pkgspec/bin/* /usr/local/bin/',
                'fi',
                '',
                'if test -e /opt/$pkgspec/sbin ; then',
                '    ln -sf /opt/$pkgspec/sbin/* /usr/local/sbin/',
                'fi',
            ]
        else:
            lines2.append(line)
    return lines2

def fix_prefix2(lines):
    lines2 = []
    for line in lines:
        line = line.replace('/opt/$package-$version', '/opt/$pkgspec')
        lines2.append(line)
    return lines2

def fix_config_cache(lines):
    has_config_cache = False
    for line in lines:
        if 'test -e config.cache' in line:
            has_config_cache = True
            break
    if has_config_cache:
        return lines
    start_index = None
    for (i, line) in enumerate(lines):
        if 'make install' in line:
            start_index = i
    if start_index is None:
        return lines
    lines2 = lines[:start_index+1] \
        + [
            '',
            '    if test -e config.cache ; then',
            '        mkdir -p /opt/$pkgspec/share/tiger.sh/$pkgspec',
            '        gzip config.cache',
            '        mv config.cache.gz /opt/$pkgspec/share/tiger.sh/$pkgspec/',
            '    fi'
        ] \
        + lines[start_index+1:]
    return lines2

def fix_terminal_title(lines):
    lines2 = []
    for line in lines:
        if "033" in line and "Installing" in line:
            line = 'echo -n -e "\\033]0;tiger.sh $pkgspec ($(hostname -s))\\007'
        lines2.append(line)
    return lines2

def fix_arch_check(lines):
    lines2 = []
    for i, line in enumerate(lines):
        lines2.append(line)
        if line == "    make install":
            if "--arch-check" not in lines[i+2]:
                lines2.append("")
                lines2.append("    tiger.sh --arch-check $pkgspec")
    return lines2


if __name__ == "__main__":
    fd = open(sys.argv[1])
    lines = fd.read().splitlines()
    fd.close()

    # lines = skip_optmirroreq(lines)
    # lines = fix_url(lines)
    # lines = fix_optmirror(lines)
    # lines = fix_binpkg(lines)
    # lines = fix_set_e(lines)
    # lines = fix_binpkgs(lines)
    #lines = fix_make(lines)
    #lines = fix_tests(lines)
    # lines = fix_binpkg2(lines)
    # lines = fix_pkgspec(lines)
    # lines = fix_semicolons(lines)
    # lines = fix_prefix(lines)
    # lines = fix_ln(lines)
    # lines = fix_prefix2(lines)
    # lines = fix_config_cache(lines)
    # lines = fix_terminal_title(lines)
    lines = fix_arch_check(lines)

    text = '\n'.join(lines) + '\n'
    sys.stdout.write(text)

    if '--write' in sys.argv:
        fd = open(sys.argv[1], 'w')
        fd.write(text)
        fd.close()
