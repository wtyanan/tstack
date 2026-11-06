# Sources

Upstream repositories for the skills vendored in `skills/`.

Only list a source here when at least one of its skills is actually in this
repo. Sources we have not taken anything from do not belong in this file.
`tstack-update` reads this file to decide what to compare against.

## Skill provenance

| Skill | Upstream source | Upstream path | License |
| --- | --- | --- | --- |
| `babysit-pr` | [t3dotgg/tstack](https://github.com/t3dotgg/tstack) | `skills/babysit-pr` | MIT |
| `council` | [t3dotgg/tstack](https://github.com/t3dotgg/tstack) | `skills/council` | MIT |
| `create-verification-skill` | [cursor/plugins](https://github.com/cursor/plugins) | `pstack/skills/create-verification-skill` | MIT |
| `full-send` | [t3dotgg/tstack](https://github.com/t3dotgg/tstack) | `skills/full-send` | MIT |
| `full-stop` | [t3dotgg/tstack](https://github.com/t3dotgg/tstack) | `skills/full-stop` | MIT |
| `sol-loop` | [t3dotgg/tstack](https://github.com/t3dotgg/tstack) | `skills/sol-loop` | MIT |
| `unslop` | [cursor/plugins](https://github.com/cursor/plugins) | `pstack/skills/unslop` | MIT |

`tstack-update` is maintained locally in this repo. It has no upstream entry.

## Source repositories

| Source | URL | License |
| --- | --- | --- |
| `t3dotgg/tstack` | https://github.com/t3dotgg/tstack | MIT |
| `cursor/plugins` | https://github.com/cursor/plugins | MIT |

## Current baselines

Each source is synced independently. Use the matching commit as the base for
three-way comparisons when updating that source's skills.

| Source | Baseline commit |
| --- | --- |
| `t3dotgg/tstack` | `1085050f3baed1ac724caa4a8166145fb2ac88af` |
| `cursor/plugins` | `2776ddd2355d6d6c8747d3964600f28daf62f049` |

After a successful sync, replace that source's commit with the upstream commit
you integrated.

## Local adaptations

Keep these when syncing from upstream:

- `create-verification-skill` is adapted for Claude Code: generated project
  skills live at `.claude/skills/verify-<app>/`, and its maintenance-loop
  section names the `maintain-verification-skill` skill instead of a slash
  command.
- `unslop` is provider-neutral: its frontmatter contains only `name` and
  `description`, with no agent-specific fields.

## Skill dependencies

Some skills reference others by name:

- `full-stop` reads and follows `full-send`.
- `full-send` uses `sol-loop`, `file-pr`, and `babysit-pr`.
- `file-pr`, `babysit-pr`, and `modernize` use `leaving-pr-comments`.
- `create-verification-skill` points at `maintain-verification-skill` for the
  optional maintenance loop.

Currently vendored: `babysit-pr`, `council`, `create-verification-skill`,
`full-send`, `full-stop`, `sol-loop`, `tstack-update`, `unslop`.
Not yet vendored: `file-pr`, `leaving-pr-comments`,
`maintain-verification-skill`, `modernize`, `takeover`.

## Adding a source

1. Add the skill under `skills/<name>/`.
2. Add a row to **Skill provenance** with the source, upstream path, and
   license.
3. Add the repository to **Source repositories** if it is not already listed.
4. Record that source's baseline commit and any local adaptations.
5. Update the dependency notes when relevant.

## Attribution

This repo is MIT licensed; see `LICENSE`. Both upstreams are MIT licensed too.
Their license texts live in:

- `licenses/t3dotgg-tstack/LICENSE`
- `licenses/cursor-plugins/LICENSE`

Keep the upstream repository link in the provenance table when copying or
modifying a skill. If another source requires its license text to travel with
the files, add it under `licenses/<owner>-<repo>/`.
