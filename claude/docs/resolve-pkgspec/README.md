# resolve-pkgspec

Resolve a bare package name (e.g. `gzip`) to a full pkgspec (e.g. `gzip-1.11`)
so users don't have to remember or look up version numbers.

    $ leopard.sh gzip                 # installs gzip-1.11
    $ leopard.sh --resolve gzip       # prints "gzip-1.11" to stdout
    $ leopard.sh --resolve gzip.ppc64 # prints "gzip-1.11.ppc64"

## Behavior

- **Full slug passed in**: returned as-is. Detected via the shell case pattern
  `*-*[0-9]*` after stripping any `.ppc64` suffix. No network I/O.
- **Bare name passed in**: `packages.txt` (or `packages.ppc64.txt` for a
  `.ppc64` arg) is fetched from the mirror, filtered, and the newest match is
  printed. Not cached — follows the same one-shot download convention as
  `--list`.
- **No match**: prints `Error: no package named 'X'.` to stderr and exits 1.

## Matching rule

A pkgspec matches bare name `NAME` iff:

1. The pkgspec starts with `NAME-`.
2. The first hyphen-separated token after `NAME-` contains at least one digit.

The digit-token requirement is what keeps `gcc` from wrongly matching
`gcc-libs-10.3.0`: the first token after `gcc-` there is `libs`, which has no
digit.

Table of cases, derived from the real package list:

| input                  | matched prefix          | rest            | first token    | has digit? |
|------------------------|-------------------------|-----------------|----------------|------------|
| `gcc`                  | `gcc-`                  | `10.3.0`        | `10.3.0`       | yes → keep |
| `gcc`                  | `gcc-`                  | `libs-10.3.0`   | `libs`         | no  → skip |
| `gcc-libs`             | `gcc-libs-`             | `10.3.0`        | `10.3.0`       | yes → keep |
| `libiconv`             | `libiconv-`             | `bootstrap-1.16`| `bootstrap`    | no  → skip |
| `libiconv-bootstrap`   | `libiconv-bootstrap-`   | `1.16`          | `1.16`         | yes → keep |
| `mplayer`              | `mplayer-`              | `osx.app-rev11` | `osx.app`      | no  → skip |

## Version sort ("newest")

When multiple candidates pass the matching rule, we pick the newest via a
classic sort trick: **pad every run of digits to 10 chars** with leading zeros
to build a sort key, then take the lexicographically-largest key.

Example — sorting `1.9` vs `1.10`:

| raw    | key                           |
|--------|-------------------------------|
| `1.9`  | `0000000001.0000000009`       |
| `1.10` | `0000000001.0000000010`       |

`0000000010` > `0000000009`, so `1.10` wins.

This approach handles the full variety of versions seen in the package list:
dotted numeric (`10.3.0`), date stamps (`20230110`), letter prefixes/suffixes
(`rr4`, `fpr32.5`, `0.29.2t`), hyphens inside the version
(`2.1.0-beta3`, `9.5.9-racket-20230127`), and names with digits
(`sdl2`, `x264`, `pcre2`).

## The `.ppc64` suffix

The suffix is treated as a *dimension*, not part of the version. A `.ppc64`
arg resolves exclusively against `packages.ppc64.txt`; a non-`.ppc64` arg
resolves exclusively against `packages.txt`. Within each list the matching and
sort logic is identical.

Stripping `.ppc64` before the full-slug short-circuit is load-bearing: without
it, `libiconv-bootstrap.ppc64` would match `*-*[0-9]*` because `.ppc64`
contains digits, and would be wrongly returned as-is rather than resolved to
`libiconv-bootstrap-1.16.ppc64`.

## Implementation

- `resolve_pkgspec()` function, placed between the `# list:` and `# resolve:`
  blocks in both [leopard.sh](../../../leopard.sh) and
  [tiger.sh](../../../tiger.sh).
- Called from the `install` op (which prints a `Resolved 'X' to 'Y'.` message
  when the arg and result differ) and from the `--resolve` op (which prints
  only the slug, for scripting).
- Filter + newest-pick is a single awk invocation; digit-run padding is done
  via `match`/`substr`/`sprintf("%010d", ...)`.

## Why this approach

- **awk, not sort -V**: BSD `sort` on Tiger/Leopard doesn't support `-V`.
- **No cache**: matches the existing `--list`/`--describe`/`--tag` pattern of
  fetching fresh each time; avoids staleness bugs and keeps the implementation
  conceptually flat.
- **Hardcoded `.ppc64`**: it's the only such suffix, and no others are
  planned. A general suffix mechanism would be overkill.

See [test-resolve.sh](test-resolve.sh) for the regression cases used during
development.
