# tstack

A personal collection of agent skills, mostly vendored from upstream repos and
adapted for Claude Code. There is no build, no package manager, and no test
suite. The deliverables are the `SKILL.md` files under `skills/`.

## Layout

- `skills/<name>/SKILL.md`: one directory per skill, with optional
  `references/`, `scripts/`, or `agents/` alongside.
- `SOURCES.md`: provenance, upstream baselines, local adaptations, and
  skill dependencies. It is the source of truth for what is vendored.
- `README.md`: the user-facing skill list and install instructions.
- `licenses/<owner>-<repo>/LICENSE`: upstream license texts.

## Rules

- **Vendored skills.** Every skill except `tstack-update` comes from an
  upstream listed in `SOURCES.md`. To sync them, use the `tstack-update`
  skill. Never bulk-copy upstream directories over local ones.
- **Keep local adaptations.** Anything recorded under **Local adaptations** in
  `SOURCES.md` is intentional. Don't revert it to match upstream.
- **Claude Code conventions.** When adapting a skill from Cursor or another
  agent:
  - Project-local paths use `.claude/skills/`, not `.cursor/skills/`.
  - Refer to other skills by name ("the `foo` skill") rather than as slash
    commands, and add "if it is installed" when the skill isn't vendored here.
  - Subagent fan-out uses parallel `Agent` tool calls.
- **Frontmatter.** Every `SKILL.md` needs YAML frontmatter with `name`
  (lowercase, digits, hyphens; matches the directory) and `description`.
  Keep `disable-model-invocation: true` where upstream sets it.

## Adding or changing a skill

Do all of these in the same change:

1. Add or edit `skills/<name>/`.
2. `SOURCES.md`: provenance row, source repo and baseline if new, local
   adaptations, dependency notes, and the "Currently vendored / Not yet
   vendored" lists.
3. `README.md`: the skills table, "What changed from upstream", and the
   dependency and not-vendored lists.
4. If the skill comes from an upstream, add its path to the sparse-checkout
   list in `skills/tstack-update/SKILL.md`.

Use the existing upstream baseline commit when the upstream skill hasn't
changed since that commit. Otherwise sync the whole source with
`tstack-update` rather than mixing baselines.

## Checks

There is nothing to build. Before committing:

- Re-read every changed `SKILL.md` end to end.
- Confirm that every skill named in a `SKILL.md` exists under `skills/` or is
  listed as not vendored in `SOURCES.md`.
- For changed scripts, run a syntax check, for example
  `python3 -m py_compile skills/babysit-pr/scripts/pr-wait`.
