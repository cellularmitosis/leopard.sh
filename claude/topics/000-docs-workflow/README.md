# 000 — Workflow rationale

This topic documents the **why** behind the conventions in
[CLAUDE.md](../../../CLAUDE.md). CLAUDE.md is the prescriptive rules;
this is where we record the reasoning, the alternatives we considered,
and the trade-offs we accepted — so future-us (and future-Claude) can
revisit a rule on purpose rather than by accident.

If you find yourself wanting to violate a rule in CLAUDE.md, read the
relevant section here first. If the reasoning no longer applies, update
both files.

## Origin

Established in collaboration between Jason and Claude on 2026-04-25,
during a session to revamp this long-neglected project. The full
back-and-forth that produced these decisions is in the git history of
this directory and CLAUDE.md.

## The `000` meta slot

Topics numbered `000-*` are reserved for documentation *about the
workflow itself* — meta-topics that aren't a feature, port,
investigation, etc. Today there's just this one. New regular work
starts at `001` and counts up; `000-*` is a small carve-out, not a
parallel sequence.

## Decisions

### `claude/topics/<NNN-category-slug>/`

**Considered:** flat `claude/notes/`, per-category top-level dirs
(`claude/ports/`, `claude/features/`, ...), or sticking with the older
`claude/docs/<feature>/` shape that was already in the tree.

**Chose because:** one directory per topic gives every investigation
its own scratch space (logs, captured HTML, shell scripts, command
output) without polluting the repo root. A single flat `topics/`
directory keeps cross-cutting work findable; per-category top-level
dirs would have fragmented the namespace and made global numbering
awkward.

The legacy `claude/docs/resolve-pkgspec/` was migrated into this scheme
as `001-feature-resolve-pkgspec/` and `claude/docs/` was removed.

### Numbered globally, zero-padded to 3 digits

**Considered:** per-category counters (`port-001`, `port-002`,
`feature-001`), date-prefixed slugs (`2026-04-25-foo`), or no number
at all.

**Chose because:** a single global counter gives every topic a stable
short handle ("topic 042") that's category-agnostic — useful when a
topic doesn't fit cleanly in one category, or when referring to it in
chat without typing the full slug. 3 digits buys us 999 topics, which
is plenty for a personal project; if we ever blow past that, renaming
would be straightforward (it's a leading prefix, easily globbed).

Zero-padding makes `ls` sort correctly and makes the numbers
visually-aligned in directory listings.

### Fixed category vocabulary, embedded in the slug

**Considered:** open-ended categories, tags in YAML frontmatter inside
the README, or no category at all.

**Chose because:** putting the category in the directory name means
`ls claude/topics/` is self-documenting — you can see at a glance what
kind of work each topic represents, and `ls *-port-*` filters by
category for free. Frontmatter would have required reading every
README to get the same info.

A fixed vocabulary (vs. open-ended) prevents the inevitable drift
where "investigation" / "research" / "analysis" become near-synonymous
near-duplicates over time.

The current vocabulary lives in CLAUDE.md. Add new categories there
when a genuinely new kind of work shows up — don't smuggle ad-hoc
ones into individual slugs.

### `port` rather than `package` / `recipe` / `formula`

**Considered:** `package` (matches the artifact), `recipe` (Yocto /
Bitbake), `formula` (Homebrew), `build` (too generic).

**Chose because:** `port` is the established term in the BSD/pkgsrc
world that the PowerPC/Tiger/Leopard era was steeped in (FreeBSD
ports, NetBSD pkgsrc) — it's the right cultural register. It also
captures the *work* (make upstream source compile and run on our
targets, including patching, flag-tweaking, and the build matrix)
rather than the *output*. `recipe` and `formula` carry distracting
toolchain associations.

`port` will be by far the most common category — the core workflow of
this project is "get a new piece of software compiling on PowerPC"
— so the short word matters. It'll appear in hundreds of directory
names.

### Port slugs include the version

`003-port-zlib-1.2.13`, not `003-port-zlib`.

**Chose because:** different versions of the same upstream are
effectively different ports. They have different patches, different
build breakage, sometimes different supported platforms. Conflating
them in one topic dir would mix unrelated debugging sessions and
make the "log of what I did to get this version compiling" useless
as a future reference.

If we ever need a topic that's about a *package* in the abstract (not
a specific version), it'd be a `feature` or `docs` topic, not a `port`.

### Categories frozen at creation time

**Considered:** allowing rename-on-pivot when a topic's nature changes
(e.g. an `investigation` that turns into an implementation).

**Chose because:** the directory name is a stable handle. Renaming
breaks any link or cross-reference into the topic, loses `git mv`
rename detection if other files reference the old name, and creates
ambiguity in the git history. The cost of a slightly-misnamed topic
is small; the cost of a broken handle is paid every time someone
follows an old link.

When a topic pivots, note the pivot in its README ("started as an
investigation, became a feature on YYYY-MM-DD") rather than renaming.

### `claude/reference/` (parallel to `claude/topics/`)

**Considered:** stuffing living "how it all works" docs into a
`docs`-category topic, or into the `000` meta slot.

**Chose because:** topics are bounded units of work — they have a
beginning, a goal, and a "done" state. Reference docs aren't bounded;
they grow forever as understanding accumulates. Forcing them into the
topic shape would either bloat one giant `docs` topic or fragment
related knowledge across many short-lived ones.

The split:
- *findings from a specific investigation* → topic
- *durable knowledge that outlives the investigation* → reference

Started with a single `how-it-works.md` to avoid pre-fragmenting; will
split into more files when one becomes unwieldy.

### CLAUDE.md vs 000-docs-workflow split

**Why both:** CLAUDE.md is loaded into context every session. It
should be tight, prescriptive, and skimmable — the rules, not the
arguments for them. This document is loaded only when someone
specifically reaches for it. So discursive reasoning and rejected
alternatives go here; rules go in CLAUDE.md.

Practical rule: if a sentence reads like an argument ("we chose X
because Y, and considered Z"), it belongs here. If it reads like an
instruction ("name topics `NNN-category-slug`"), it belongs in
CLAUDE.md.
