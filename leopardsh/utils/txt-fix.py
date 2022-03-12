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
        if 'pipefail' not in line:
            line = line.replace('set -e -x', 'set -e -x -o pipefail')
        lines2.append(line)
    return lines2

def fix_binpkgs(lines):
    lines2 = []
    for line in lines:
        line = line.replace('$LEOPARDSH_MIRROR/$binpkg', '$LEOPARDSH_MIRROR/binpkgs/$binpkg')
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
        if "$(leopard.sh -j)" not in line \
            and "make install" not in line \
            and "make check" not in line \
            and "make clean" not in line \
            and "make[" not in line \
            and "make:" not in line:
            line = line.replace("make", "make $(leopard.sh -j)")
        lines2.append(line)
    return lines2

def fix_tests(lines):
    lines2 = []
    for line in lines:
        line = line.replace('$LEOPARDSH_MAKE_CHECK', '$LEOPARDSH_RUN_TESTS')
        lines2.append(line)
    return lines2

def fix_binpkg2(lines):
    lines2 = []
    for line in lines:
        line = line.replace('binpkg=$package-$version.$(leopard.sh --os.cpu).tar.gz', 'binpkg=$pkgspec.$(leopard.sh --os.cpu).tar.gz')
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
        if line == 'LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://ssl.pepas.com/leopardsh}':
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
            '        mkdir -p /opt/$pkgspec/share/leopard.sh/$pkgspec',
            '        gzip config.cache',
            '        mv config.cache.gz /opt/$pkgspec/share/leopard.sh/$pkgspec/',
            '    fi'
        ] \
        + lines[start_index+1:]
    return lines2

def fix_terminal_title(lines):
    lines2 = []
    for line in lines:
        if "033" in line and "Installing" in line:
            line = 'echo -n -e "\\033]0;leopard.sh $pkgspec ($(hostname -s))\\007'
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

def fix_arch_check2(lines):
    lines2 = []
    for line in lines:
        line = line.replace('--arch-check $pkgspec', '--arch-check $pkgspec $ppc64')
        lines2.append(line)
    return lines2

def fix_linker_check(lines):
    lines2 = []
    for line in lines:
        if "leopard.sh --arch-check $pkgspec $ppc64" in line:
            lines2.append("    leopard.sh --linker-check $pkgspec")
        lines2.append(line)
    return lines2

def skip_bin_link(lines):
    lines2 = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if line == "if test -e /opt/$pkgspec/bin ; then":
            sys.stderr.write("skip\n")
            i += 3
            continue
        else:
            lines2.append(line)
            i += 1
            continue
    return lines2

def skip_sbin_link(lines):
    lines2 = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if line == "if test -e /opt/$pkgspec/sbin ; then":
            i += 3
            continue
        else:
            lines2.append(line)
            i += 1
            continue
    return lines2

def fix_gzip(lines):
    lines2 = []
    for line in lines:
        if "gzip config.cache" in line:
            line = line.replace("gzip config.cache", "gzip -9 config.cache")
        lines2.append(line)
    return lines2

def fix_configure(lines):
    lines2 = []
    for line in lines:
        if "./configure" in line:
            line = line.replace("./configure", "/usr/bin/time ./configure")
        lines2.append(line)
    return lines2

def fix_make(lines):
    lines2 = []
    for line in lines:
        if "make $(" in line:
            line = line.replace("make $(", "/usr/bin/time make $(")
        lines2.append(line)
    return lines2

def fix_upstream(lines):
    lines2 = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if i < (len(lines) - 1) and "srcmirror=" in line:
            line2 = lines[i+1]
            if "tarball=" in line2:
                line = "upstream=%s/%s" % (line.split("=")[1], line2.split("=")[1])
                lines2.append(line)
                i += 2
                continue

        lines2.append(line)
        i += 1
        continue
    return lines2


def fix_path(lines):
    lines2 = []
    for line in lines:
        if "PATH=" in line and "MPN_PATH" not in line and "tigersh-deps-0.1" not in line and "PKG_CONFIG_PATH" not in line:
            line = 'PATH="/opt/tigersh-deps-0.1/bin:$PATH"'
        lines2.append(line)
    return lines2

def fix_mirror(lines):
    lines2 = []
    for line in lines:
        if "LEOPARDSH_MIRROR=" in line:
            line = "LEOPARDSH_MIRROR=${LEOPARDSH_MIRROR:-https://leopard.sh}"
        lines2.append(line)
    return lines2

def fix_binpkg_section(lines):
    lines2 = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if r'echo -n -e "\033' in line \
        and i+6 < len(lines) \
        and lines[i+1] == "" \
        and "binpkg=$pkgspec" in lines[i+2] \
        and "if curl -sSfI" in lines[i+3] \
        and "cd /opt" in lines[i+4] \
        and "curl -#f" in lines[i+5] \
        and "else" in lines[i+6]:
            lines2.append(line)
            for l in [ \
"", \
"if leopard.sh --install-binpkg $pkgspec ; then", \
"    exit 0", \
"fi", \
"", \
'echo -e "${COLOR_CYAN}Building${COLOR_NONE} $pkgspec from source." >&2', \
"set -x", \
"", \
"if ! test -e /usr/bin/gcc ; then", \
"    leopard.sh xcode-3.1.4", \
"fi", \
"", \
"leopard.sh --unpack-dist $pkgspec" ]:
                lines2.append(l)
            while "cd $package-$" not in lines[i] and "cd ncurses-$version" not in lines[i] and "cd Python-$version" not in lines[i] and "cd sqlite-autoconf-3370200" not in lines[i]:
                i += 1
            continue

        lines2.append(line)
        i += 1
        continue
    return lines2

def fix_config_cache2(lines):
    lines2 = []
    for line in lines:
        if "cat /opt/leopard.sh/share/leopard.sh/config.cache" in line:
            continue
        else:
            lines2.append(line)
    return lines2

def fix_cd(lines):
    lines2 = []
    for line in lines:
        if "cd $package-" in line:
            line = line.replace("cd $package", "cd /tmp/$package")
        lines2.append(line)
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
    # lines = fix_tests(lines)
    # lines = fix_binpkg2(lines)
    # lines = fix_pkgspec(lines)
    # lines = fix_semicolons(lines)
    # lines = fix_prefix(lines)
    # lines = fix_ln(lines)
    # lines = fix_prefix2(lines)
    # lines = fix_config_cache(lines)
    # lines = fix_terminal_title(lines)
    # lines = fix_arch_check(lines)
    # lines = fix_arch_check2(lines)
    # lines = fix_linker_check(lines)

    # lines = skip_bin_link(lines)
    # lines = skip_sbin_link(lines)
    # lines = fix_gzip(lines)
    # lines = fix_configure(lines)
    # lines = fix_make(lines)
    # lines = fix_upstream(lines)
    # lines = fix_path(lines)
    # lines = fix_mirror(lines)
    # lines = fix_binpkg_section(lines)
    # lines = fix_config_cache2(lines)
    lines = fix_cd(lines)

    text = '\n'.join(lines) + '\n'
    sys.stdout.write(text)

    if '--write' in sys.argv:
        fd = open(sys.argv[1], 'w')
        fd.write(text)
        fd.close()
