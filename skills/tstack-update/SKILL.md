---
name: tstack-update
description: Use when the user says "tstack update" or asks to sync, refresh, or pull the latest upstream versions of the skills vendored in this repo.
---

# tstack-update

Update the skills vendored in this repo from their upstream sources.

Do this manually: read the upstream source, compare it against the local
version, and integrate the useful changes. Do not run a bulk sync script or
replace whole skill directories blindly. Local customizations are intentional
and must survive an update.

`SOURCES.md` is the source of truth. It lists every vendored skill, its
upstream repository, the path in that repository, the commit each source was
last synced from, and any deliberate local adaptations.

## When to use

- The user says "tstack update".
- The user asks to pull upstream changes into the skills in `skills/`.
- A skill's upstream moved and the user wants the new version.

Do not use this to install unrelated skills. Add those from their own upstream
first and record them in `SOURCES.md`.

## Steps

### 1. Read the sources

Open `SOURCES.md` and build the work list:

- skill name and local path (`skills/<name>/`)
- upstream repository URL
- upstream path (for example `skills/council`)
- license
- the current baseline commit for that skill's source

Only update skills listed there. If the user asks for a skill that is not
listed, stop and ask whether to add it and its source first.

### 2. Prepare the working tree

```bash
git status --short
```

Commit or stash unrelated work first. An update should be easy to review and
easy to roll back. If the user wants a PR, create a branch.

### 3. Fetch upstream without editing it

Use one throwaway sparse checkout per distinct upstream repository. Group the
skills by source so each repository is cloned once:

```bash
# t3dotgg/tstack
rm -rf /tmp/tstack-upstream
git clone --quiet --filter=blob:none --sparse \
  https://github.com/t3dotgg/tstack.git /tmp/tstack-upstream
git -C /tmp/tstack-upstream sparse-checkout set \
  skills/babysit-pr skills/council skills/full-send skills/full-stop skills/sol-loop
git -C /tmp/tstack-upstream log -1 --format='%H %s'

# cursor/plugins
rm -rf /tmp/cursor-plugins-upstream
git clone --quiet --filter=blob:none --sparse \
  https://github.com/cursor/plugins.git /tmp/cursor-plugins-upstream
git -C /tmp/cursor-plugins-upstream sparse-checkout set \
  pstack/skills/create-verification-skill pstack/skills/unslop
git -C /tmp/cursor-plugins-upstream log -1 --format='%H %s'
```

The checkout is read-only reference material. Never edit files there. For a
single-file skill, fetching the raw upstream file is enough:

```bash
curl -fsSL https://raw.githubusercontent.com/t3dotgg/tstack/main/skills/council/SKILL.md \
  -o /tmp/council-SKILL.md
```

Note the upstream commit you fetched for each source. That becomes the new
baseline for that source.

### 4. Compare each skill

List the upstream files and diff them one at a time:

```bash
find /tmp/tstack-upstream/skills/council -type f
diff -ru skills/council /tmp/tstack-upstream/skills/council
```

A whole-directory diff is for orientation. Make decisions per file.

Use the baseline commit for the skill's source to tell local edits apart from
upstream drift:

```bash
# Example: council from t3dotgg/tstack
BASELINE=<baseline commit for t3dotgg/tstack from SOURCES.md>
git -C /tmp/tstack-upstream show \
  "$BASELINE:skills/council/SKILL.md" > /tmp/council-base.md
git merge-file -p --diff3 \
  skills/council/SKILL.md /tmp/council-base.md \
  /tmp/tstack-upstream/skills/council/SKILL.md
```

Never compare a skill against another source's baseline. Repeat with the
baseline and checkout that belong to the skill's own source.

`git merge-file` prints the merged result without touching either input. Use it
to understand overlapping edits. If you write the result out, resolve every
conflict marker before moving on.

If no baseline is recorded for a skill, use local history to identify
intentional changes:

```bash
git log --oneline -- skills/council
git log -p -- skills/council
```

If the history does not make the intent clear, stop and ask the user. Do not
guess and overwrite a local customization.

Classify each difference:

- **Upstream-only change** — apply it.
- **Local-only change** — keep it.
- **Both changed the same lines** — merge by hand. Keep the behavior the user
  wants, not whichever side happens to be newer.
- **New upstream file** — add it unless it collides with a local file.
- **Upstream file deleted** — remove it only if the local copy was not
  customized. Otherwise keep it and report it.
- **Locally deleted file** — respect the deletion unless the upstream change
  makes the file necessary again; ask if unsure.

### 5. Integrate

Make the smallest edits that bring in the upstream behavior. Preserve:

- local wording and repo-specific references
- local model names, commands, and paths
- files the upstream repository does not have
- every adaptation recorded under **Local adaptations** in `SOURCES.md`

Do not copy editor cruft, generated files, secrets, or unrelated examples.
If an upstream change depends on a skill that is not vendored here, report the
missing dependency instead of silently adding it.

### 6. Verify

- Re-read every changed `SKILL.md` end to end.
- Confirm any skill it references still exists under `skills/`.
- Diff the final local tree against upstream and confirm every remaining
  difference is intentional.
- Run checks for changed scripts. For example:

  ```bash
  python3 -m py_compile skills/babysit-pr/scripts/pr-wait
  ```

- Confirm the skills still have valid frontmatter with a `name` and
  `description`.

### 7. Update `SOURCES.md`

- Change that source's baseline commit to the upstream commit you integrated.
- Update upstream paths if a skill moved.
- Add or remove dependency notes if references changed.
- Add or update **Local adaptations** when an update requires a deliberate
  divergence from upstream.
- Keep the source list limited to repositories with skills in this repo.

### 8. Report and commit

Summarize per skill:

- updated, kept local changes, skipped, or conflicted
- the old and new baseline commits
- anything the user still needs to decide

Commit only the intended skill files and `SOURCES.md` together.

## Adding a new vendored skill

1. Put the skill in `skills/<name>/`.
2. Add a row to the provenance table in `SOURCES.md`.
3. Add the repository to the source table if needed.
4. Record the source's baseline commit and any local adaptations.
5. Add dependency notes when the skill calls other skills.

## Rules

- Never blind-copy or bulk-replace upstream directories.
- Never update a skill that is not listed in `SOURCES.md`.
- Never add a source just because it exists; only sources with skills in this
  repo belong in `SOURCES.md`.
- Never edit `tstack-update` from upstream. It is maintained here.
- If upstream is unavailable, report it and continue with the other skills. Do
  not substitute a different source.
- Keep scope limited. An update is not permission to refactor the skill.
