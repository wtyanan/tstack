# tstack

A personal collection of agent skills I use, modified to fit my workflow.

These are not all my own work. Most are vendored from public repositories and
adapted where noted. Provenance, baselines, and license details live in
[`SOURCES.md`](SOURCES.md).

## Install

```bash
npx skills add wtyanan/tstack
```

Install selected skills for a specific agent:

```bash
npx skills add wtyanan/tstack --skill council --skill full-send -a claude-code
```

List what the repo offers without installing:

```bash
npx skills add wtyanan/tstack --list
```

## Skills

| Skill | What it does |
| --- | --- |
| `babysit-pr` | Watches a PR through CI and review bots, then fixes the real findings. |
| `council` | Gets review from three models on different providers and loops until they agree. |
| `create-verification-skill` | Generates a project-local Claude skill that drives the app like a user and proves behavior. |
| `full-send` | Takes a change to a merged PR with nobody watching. |
| `full-stop` | Same as `full-send`, but stops when the PR is ready for me to merge. |
| `gen-app-store-screenshots` | Builds an App Store screenshot set from the code alone: a Sol-reviewed plan, real captures plus GPT imagery, and a Sol review loop. |
| `maintain-verification-skill` | Audits a project's verification skill against source and the live app, then ships proven fixes. |
| `sol-loop` | Reviews a change with GPT Sol in a loop until both sides agree. |
| `tstack-update` | Syncs the vendored skills from their upstream sources. |
| `unslop` | Cuts AI tells from any writing. |

## What changed from upstream

This repo is a personal fork, not a mirror. Changes are tracked under **Local
adaptations** in [`SOURCES.md`](SOURCES.md). The main ones:

- `create-verification-skill` and `maintain-verification-skill` target Claude
  Code's `.claude/skills/` layout instead of Cursor's.
- `unslop` is provider-neutral and uses standard skill frontmatter.
- `tstack-update` is maintained here rather than vendored.
- `gen-app-store-screenshots` is written here. It adapts ideas from
  [adamlyttleapps/claude-skill-aso-appstore-screenshots](https://github.com/adamlyttleapps/claude-skill-aso-appstore-screenshots)
  and [ParthJadhav/app-store-screenshots](https://github.com/ParthJadhav/app-store-screenshots)
  and replaces their AI-painted and web-editor output with real simulator
  captures, a Swift compositor and a Sol review loop.

## Dependencies

Some skills call other skills by name:

- `full-stop` reads and follows `full-send`.
- `full-send` uses `sol-loop`, `file-pr`, and `babysit-pr`.
- `file-pr`, `babysit-pr`, and `modernize` use `leaving-pr-comments`.
- `create-verification-skill` points at `maintain-verification-skill` for its
  optional maintenance loop.
- `maintain-verification-skill` points at `create-verification-skill` when a
  project has no verification skill yet.

Not vendored here yet: `file-pr`, `leaving-pr-comments`, `modernize`, and
`takeover`. Install those from
their upstream repositories if a workflow needs them.

`gen-app-store-screenshots` needs macOS with Xcode (its compositor is a Swift
script), an iOS Simulator, and T3 Code for the device tools, the Sol reviews and GPT image
generation.

`babysit-pr` also ships a `pr-wait` helper that needs `python3`, and the
PR-focused skills expect an authenticated [GitHub CLI](https://cli.github.com)
(`gh`).

## Updating

If you installed these skills with the Skills CLI:

```bash
npx skills check
npx skills update
```

If you are maintaining this repo, use the `tstack-update` skill. It compares
each vendored skill against the upstream commits recorded in `SOURCES.md` and
integrates changes without dropping the local adaptations.

## License

MIT. See [`LICENSE`](LICENSE). Upstream license texts are in
[`licenses/`](licenses/).
