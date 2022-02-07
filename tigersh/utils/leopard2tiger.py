#!/usr/bin/env python3

import sys

def fix_leopard2tiger(lines):
    lines2 = []
    for line in lines:
        line = line.replace('leopard', 'tiger')
        line = line.replace('Leopard', 'Tiger')
        line = line.replace('LEOPARD', 'TIGER')
        line = line.replace(' -o pipefail', '')
        line = line.replace('which -s', 'type -a')
        lines2.append(line)
    return lines2

fd = open(sys.argv[1])
lines = fd.read().splitlines()
fd.close()

lines = fix_leopard2tiger(lines)

text = '\n'.join(lines) + '\n'
sys.stdout.write(text)

if '--write' in sys.argv:
    fd = open(sys.argv[1], 'w')
    fd.write(text)
    fd.close()
