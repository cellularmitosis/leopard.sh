# How it all works

Durable, accumulating reference for `leopard.sh` / `tiger.sh` internals.
Topic-specific findings live under `claude/topics/`; this file is for
knowledge that persists across investigations.

Edit in place as understanding grows. If a section gets unwieldy, split
it into its own file under `claude/reference/`.

---

## Distribution model

The system is **dev / qa / prod** with `rsync` as the deployment
mechanism:

| Role | Host | Path |
|---|---|---|
| dev  | uranium    | `~/github/cellularmitosis/leopard.sh/` (the git checkout) |
| qa   | mini10v    | `/var/www/html/` (symlink → `/mnt/sda3/html/`) |
| prod | leopard.sh | `/var/www/html/` |

Both qa and prod serve their `/var/www/html/` over HTTP — that's what
the user-facing `leopard.sh` / `tiger.sh` CLIs fetch from. There are
git checkouts in `/var/www/html/` on both mirrors, but they're inert
artifacts and not part of how the mirror gets populated; **no git
activity is performed on the mirrors.**

### Deploy scripts

Live in `~/junk/catfarm/` (a private repo, not part of this one):

- `deploy-to-mini10v.sh` — `rsync -av --delete` uranium → mini10v
- `deploy-to-leopard.sh` — `rsync -av --delete --exclude .wwdc/`
  uranium → leopard.sh

**Both use `--delete`.** Anything on the destination not present on
uranium at deploy time gets pruned. The mirror is a faithful copy of
uranium's working tree at the moment of the last deploy.

### Workflow direction (current vs. intended)

The current catfarm scripts above push directly `uranium → mini10v`
and `uranium → leopard.sh`. That requires uranium to host all
artifacts (binpkgs, dist tarballs) for the rsync to copy out — which
runs into 20+ GB of disk pressure as the project grows.

The intended evolution: build hosts (the various PowerPC machines)
push directly to **mini10v** for binpkgs/dist; **mini10v → leopard.sh**
becomes the promotion step; **uranium** is reduced to source-only
(install scripts, `packages.txt`, tags). Separates the small
source-flow from the large artifact-flow.

If catfarm scripts haven't been updated to reflect this yet, treat the
description above as the target shape, not the literal current
implementation.

### Per-port lifecycle

For a port (the `port` topic category — the bulk of project work):

1. Get the upstream source compiling.
2. Build binpkgs for all supported platforms — G3, G4, G4e, G5/32,
   G5/64 × Tiger, Leopard. See [README.md](../../README.md) for the
   support matrix and which `gcc -mcpu=` / optimization flags apply
   per platform.
3. Land the binpkgs on **mini10v** (qa).
4. QA against mini10v.
5. Promote to **leopard.sh** (prod).
6. Commit + push the install scripts / `packages.txt` updates from
   uranium to GitHub.

## What git tracks (and what it doesn't)

Git tracks **source-only**: install scripts under
`{leopard,tiger}sh/scripts/`, package lists (`packages.txt`,
`packages.ppc64.txt`), tags under `{leopard,tiger}sh/tags/`, templates,
utility scripts, etc.

Binary artifacts and derived files are excluded by `.gitignore`:

    binpkgs/*.*       (built binary packages)
    dist/*.*          (curated source tarballs)
    dist/orig/*.*     (upstream-original source tarballs)
    dist/fonts/*.*
    linux/*           (with a few specific exceptions)
    **/*.md5          (per-file md5 sidecars)
    **/md5s.manifest  (concatenated manifests)
    **/md5s.manifest.gz

So the git checkout stays small (source only); the *artifact* side of
the filesystem is populated separately and lives on the mirrors.

**One special case**: `binpkgs/tigersh-deps-0.1.tiger.g3.tar.gz` — the
bootstrap tarball — is referenced by the Makefile's `md5` target but
is *not* in git either. It has to be present on the filesystem for
`make` to work. Lives on the mirrors as part of their artifact set.

## Package lists

The two CLIs treat four flat text files as the canonical list of
available packages:

- `leopardsh/packages.txt`        — Leopard, 32-bit (the default)
- `leopardsh/packages.ppc64.txt`  — Leopard, ppc64
- `tigersh/packages.txt`          — Tiger, 32-bit (the default)
- `tigersh/packages.ppc64.txt`    — Tiger, ppc64

Format: one pkgspec per line, sorted (e.g. `gzip-1.11`,
`adium.app-1.4.5`). The pkgspec is `<name>-<version>`, optionally with a
`.ppc64` dimension suffix in `packages.ppc64.txt`. See
[../topics/001-feature-resolve-pkgspec/README.md](../topics/001-feature-resolve-pkgspec/README.md)
for the matching/resolution rules used by the CLI to map a bare name
(`gzip`) to a full pkgspec (`gzip-1.11`).

These files are what the CLI fetches when you run `--list`, `--describe`,
`--tag`, or `--resolve`. They define what is *officially shipped*.

## Manifests (md5 sums)

To track file-level integrity (and to enable drift detection), every
file shipped by the mirror has an `.md5` sidecar, and every directory
that ships files has a per-directory `md5s.manifest`. The per-directory
manifests are then concatenated into a single top-level
`md5s.manifest` for the whole mirror.

### Per-directory `md5s.manifest`

Generated by [utils/generate-md5s.sh](../../utils/generate-md5s.sh)
when run inside a directory. Behavior:

1. For every non-`.md5` file in the dir, generate `<file>.md5` if it's
   missing or older than the file (`mtime` comparison via `stat`).
2. Concatenate all `*.md5` files into a per-directory `md5s.manifest`,
   one `<basename> <md5>` line per file.
3. Also produces `md5s.manifest.gz` for cheap download.

Per-directory manifests live in (at minimum):

    binpkgs/                         # built binary packages
    dist/                            # source tarballs (curated)
    dist/orig/                       # source tarballs (upstream-original)
    leopardsh/scripts/               # per-package install scripts
    leopardsh/scripts/wip/           # work-in-progress install scripts
    leopardsh/config.cache/          # cached ./configure outputs
    tigersh/scripts/
    tigersh/scripts/wip/
    tigersh/config.cache/

### Top-level `md5s.manifest`

Generated by [utils/generate-manifest.sh](../../utils/generate-manifest.sh).
Concatenates a **fixed subset** of the per-directory manifests, with each
line prefixed by the directory path:

    binpkgs/, dist/, dist/orig/,
    leopardsh/scripts/, tigersh/scripts/,
    leopardsh/config.cache/, tigersh/config.cache/

**Notable exclusion:** `*/scripts/wip/` is *not* included in the
top-level manifest, even though those dirs have their own per-directory
manifests. Those files exist on the mirror but aren't tracked in the
canonical top-level checksum list — a potential drift blind spot.

### Orchestration

The whole md5/manifest dance is driven by `make md5s` from the top-level
[Makefile](../../Makefile):

    md5s: binpkgs-md5s dist-md5s leopardsh-md5s tigersh-md5s md5
        utils/generate-manifest.sh

The dependent targets (`binpkgs-md5s` etc.) descend into each shipping
dir and run `make` there, which in turn calls `generate-md5s.sh`. The
trailing `md5` target produces the human-readable top-level `md5` text
file (md5s of the two CLI scripts and the bootstrap tarball).

### Caveat: manifest staleness

`md5s.manifest` only reflects what was on the filesystem the last time
`make md5s` was run. If files get added or replaced afterward without
re-running, the filesystem drifts ahead of the manifest. Anyone using
the manifest to detect drift (between hosts, or for integrity checks)
should check `mtime` on the manifest first to know how stale it is —
otherwise the manifest-diff will undercount real divergence.

### Caveat: empty-md5 entries

When a per-file `.md5` sidecar is zero bytes (e.g. a prior
`generate-md5s.sh` run failed mid-write, or `md5 -q` produced no
output), `generate-md5s.sh` concatenates it into the per-directory
manifest unchanged. The result is a line like:

    install-foo-1.0.sh ␣

— filename, space, then nothing before the newline. Code that parses
manifests and expects `<file> <md5>` will silently get an empty md5
and may produce false drift signals. Worth fixing in
`generate-md5s.sh` (skip the file if its `.md5` is empty, or
regenerate before emitting).

### Caveat: Makefiles call BSD `md5 -q` directly (no Linux fallback)

[generate-md5s.sh](../../utils/generate-md5s.sh) has a Darwin-vs-Linux
switch (`md5 -q` on Darwin, `md5sum | awk` on Linux), **but the
per-directory `Makefile`s and the top-level `Makefile`'s `md5` target
invoke `md5 -q` directly.** That works on macOS but fails on Linux,
where `md5` doesn't exist by default — relevant any time `make md5s`
is run on the qa or prod hosts.

**Current workaround**: a hand-installed `~/bin/md5` shim on each
Linux host (mini10v and leopard.sh) wraps `md5sum`:

    #!/bin/bash
    set -e
    # implement bsd 'md5 -q' behavior
    # used by leopard.sh
    md5sum "${@: -1}" | awk '{print $1}'

This relies on `~/bin` being on `PATH` for the user that runs `make`
on each host. The shim is **not** part of any provisioning script —
it lives only in those two specific user homes.

**Proper fix**: gate the Makefile invocations on `uname -s` the same
way `generate-md5s.sh` does. Until that lands, don't assume `make
md5s` works out-of-the-box on a fresh Linux host.

## Mirror filesystem layout

Both mirrors serve a directory tree from `/var/www/html/` over HTTP.
Confirmed paths from the qa side (mini10v):

    /md5s.manifest                              # top-level
    /binpkgs/md5s.manifest
    /dist/md5s.manifest
    /dist/orig/md5s.manifest
    /leopardsh/scripts/md5s.manifest
    /leopardsh/scripts/wip/md5s.manifest
    /leopardsh/config.cache/md5s.manifest
    /tigersh/scripts/md5s.manifest
    /tigersh/scripts/wip/md5s.manifest
    /tigersh/config.cache/md5s.manifest

The `packages.txt` files live alongside, under `leopardsh/` and
`tigersh/`. Binpkgs and dist tarballs are at the root of their
respective dirs (`binpkgs/<pkgspec>.<arch>.<os>.tar.gz`,
`dist/<package>-<version>.tar.gz`).

## Conventions

### `.ppc64.sh` install scripts are symlinks

For any package that has a ppc64 build, there's exactly one install
script — `install-<name>-<version>.sh` — and
`install-<name>-<version>.ppc64.sh` is a **symlink** to it. The script
detects which name it was invoked as via `$0` and sets the `ppc64`
variable accordingly:

    if test -n "$(echo -n $0 | grep '\.ppc64\.sh$')" ; then
        ppc64=".ppc64"
    fi
    pkgspec=$package-$version$ppc64

So one script body handles both targets; the symlink just selects the
build flavor. This is a hard convention — when adding a new
ppc64-capable port, both the `.sh` file and the `.ppc64.sh` symlink
must exist. The [utils/new-src-pkg.sh](../../utils/new-src-pkg.sh)
helper sets this up automatically.
