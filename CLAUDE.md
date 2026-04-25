# leopard.sh / tiger.sh — Claude collaboration notes

This is a retrocomputing package manager for PowerPC Macs running OS X Leopard
(10.5) and Tiger (10.4). The user-facing CLIs are `leopard.sh` and `tiger.sh`
(rather than `apt`). Binary packages are served from <http://leopard.sh>.

See [README.md](README.md) for end-user docs.

## Working conventions

All Claude-assisted work is organized under `claude/`.

The reasoning behind the rules below — alternatives considered, trade-offs
accepted, why the categories are what they are — lives in
[claude/topics/000-docs-workflow/](claude/topics/000-docs-workflow/README.md).
If you're tempted to violate a rule here, read that first.

### `claude/topics/<NNN-category-slug>/`

Every topic, project, investigation, or task gets its own directory under
`claude/topics/`, named `NNN-category-slug` where:

- `NNN` is a zero-padded 3-digit sequence number,
- `category` is one of the fixed values listed below,
- `slug` is a short kebab-case name.

Examples:

    claude/topics/001-feature-resolve-pkgspec/
    claude/topics/002-investigation-local-mirror-drift/
    claude/topics/003-port-zlib-1.2.13/

### Categories

Pick from this fixed vocabulary. Expand the list (here in CLAUDE.md) if a
genuinely new category comes up — don't invent ad-hoc ones.

- `port` — getting a piece of upstream software to compile, build for all
  supported platforms (G3/G4/G5, Tiger/Leopard), QA on `mini10v`, and ship
  to <http://leopard.sh>. By far the most common category. Slug includes
  the version: `port-zlib-1.2.13`, since each version is effectively its
  own port (different patches, different breakage).
- `feature` — building or changing user-facing functionality of
  `leopard.sh` / `tiger.sh` themselves.
- `investigation` — figuring out what's true (drift checks, perf hunts,
  "why is X broken").
- `bugfix` — known defect, scoped fix.
- `refactor` — internal cleanup, no behavior change.
- `docs` — documentation-only work.
- `ops` — infra, releases, mirror management, CI.

The category is **frozen at creation time**. If a topic pivots (e.g. an
investigation leads to an implementation), note the pivot in the topic's
README rather than renaming the directory — renames break links and lose
`git mv` rename detection.

### Numbering

- Use the next unused 3-digit number. Don't reorder or renumber after the
  fact — these are stable handles.
- Numbering is global across the project, not per-category.
- `000-*` is reserved for meta-topics about the workflow itself (today,
  just `000-docs-workflow`). Regular work starts at `001`.

### Topic contents

Inside each topic directory, store anything related to that topic:

- `README.md` — the canonical entry point (goal, current status, links to
  the other files)
- plans, status reports, logs, post-mortems, gotchas, research notes
- ancillary files: shell scripts, captured `.html` from web searches,
  verbose command output, screenshots, etc.

Pick file names that read well in `ls`. Prefer many small focused files over
one mega-doc.
