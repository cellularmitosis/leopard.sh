# 001 — Local mirror drift

## Goal

Determine whether the public package mirror at <http://leopard.sh> and the
LAN-local QA mirror on host `mini10v` have drifted out of sync, and if so,
characterize the drift (which side is ahead, by what, and why).

## Background

`mini10v` is a local mirror used to QA built packages before promoting them
to the public site. The expected workflow is:

1. Build a package.
2. Publish it to `mini10v`.
3. QA against `mini10v`.
4. Promote to <http://leopard.sh>.

This project has been neglected for a while, so the two sides may be out of
sync in either direction (mini10v ahead = un-promoted QA; leopard.sh ahead =
something published without going through QA, or mini10v rebuilt/cleared).

## Plan

TBD — to be filled in once we agree on an approach. Likely shape:

1. Enumerate the package list from each side.
2. Diff the lists (presence + per-package file set + checksums/timestamps).
3. Categorize differences and decide on remediation.

## Status

Not yet started.

## Files in this topic

- `README.md` — this file.
