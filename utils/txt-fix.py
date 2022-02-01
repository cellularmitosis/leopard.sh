#!/usr/bin/env python3

import sys

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
        line = line.replace('$LEOPARDSH_MIRROR/$binpkg', '$LEOPARDSH_MIRROR/binpkgs/$binpkg')
        lines2.append(line)
    return lines2

fd = open(sys.argv[1])
lines = fd.read().splitlines()
fd.close()

# lines = skip_optmirroreq(lines)
# lines = fix_url(lines)
# lines = fix_optmirror(lines)
# lines = fix_binpkg(lines)
#lines = fix_set_e(lines)
lines = fix_binpkgs(lines)

text = '\n'.join(lines) + '\n'
sys.stdout.write(text)

if '--write' in sys.argv:
    fd = open(sys.argv[1], 'w')
    fd.write(text)
    fd.close()
