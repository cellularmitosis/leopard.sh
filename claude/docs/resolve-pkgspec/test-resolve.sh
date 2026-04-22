#!/bin/bash

# test-resolve.sh: regression tests for 'leopard.sh --resolve'.
# Historical reference: these are the 16 cases used when developing the feature.
#
# Uses LEOPARDSH_MIRROR=file://<repo-root> so the tests run offline against the
# packages.txt / packages.ppc64.txt checked into this repo.
#
# Run from anywhere:
#   $ ./claude/docs/resolve-pkgspec/test-resolve.sh

set -u

cd "$(dirname "$0")/../../.."
repo_root=$(pwd)
export LEOPARDSH_MIRROR="file://$repo_root"

pass=0
fail=0

check() {
    input="$1"
    expected="$2"
    actual=$(./leopard.sh --resolve "$input" 2>/dev/null || echo "(none)")
    if test "$actual" = "$expected" ; then
        printf '  [PASS] %-34s -> %s\n' "$input" "$actual"
        pass=$((pass + 1))
    else
        printf '  [FAIL] %-34s -> %s (expected %s)\n' "$input" "$actual" "$expected"
        fail=$((fail + 1))
    fi
}

echo "Testing leopard.sh --resolve:"

# bare name -> newest slug from packages.txt
check gzip                            gzip-1.11
check libiconv                        libiconv-1.16
check libiconv-bootstrap              libiconv-bootstrap-1.16
check gcc                             gcc-10.3.0
check mpfr                            mpfr-4.1.0
check ca-certificates                 ca-certificates-20230110

# full slug -> passthrough (no network)
check gzip-1.11                       gzip-1.11
check libiconv-bootstrap-1.16.ppc64   libiconv-bootstrap-1.16.ppc64

# bare name with .ppc64 -> newest slug from packages.ppc64.txt
check gzip.ppc64                      gzip-1.11.ppc64
check libiconv.ppc64                  libiconv-1.16.ppc64
check libiconv-bootstrap.ppc64        libiconv-bootstrap-1.16.ppc64
check mpfr.ppc64                      mpfr-4.1.0.ppc64

# full slug with .ppc64 -> passthrough
check gzip-1.11.ppc64                 gzip-1.11.ppc64

# not in packages.ppc64.txt (exists only in packages.txt)
check gcc.ppc64                       "(none)"
check ca-certificates.ppc64           "(none)"

# not in either list
check nosuch.ppc64                    "(none)"

echo
echo "$pass passed, $fail failed."
test "$fail" -eq 0
