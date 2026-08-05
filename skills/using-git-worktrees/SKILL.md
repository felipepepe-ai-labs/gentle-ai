---
name: using-git-worktrees
description: "Set up an isolated workspace before implementation work. Trigger: starting feature work that needs isolation, applying SDD/RDD tasks, running background agents."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

Load this skill before starting implementation work that should not touch the current checkout directly — a background job, a feature that risks conflicting with in-progress work, or any time isolation is explicitly requested.

**Core principle:** Detect existing isolation first. Then use native tools. Then fall back to git. Never fight the harness.

## Critical Rules

| Rule | Requirement |
|------|-------------|
| Detect before creating | Check `git rev-parse --git-dir` vs `--git-common-dir` before doing anything — you may already be in a worktree. |
| Native tools first | If `EnterWorktree` (or an equivalent native worktree tool/flag) is available, use it. Only fall back to manual `git worktree` when no native tool exists. |
| Whatever creates it, removes it | A worktree created via `EnterWorktree` is removed via `ExitWorktree` (or the matching native cleanup) — never mix native creation with manual `git worktree remove`, and vice versa. |
| Verify before delete | Never remove a worktree without confirming `git status --porcelain` and `git log @{u}..` are both empty. Unsaved or unpushed work blocks removal until the user says otherwise. |
| Single project-local location | Manual (git-fallback) worktrees live at `<repo>/.worktrees/<branch>`, and that path must be gitignored before creation. |

## Step 0: Detect Existing Isolation

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**Submodule guard** — `GIT_DIR != GIT_COMMON` is also true inside a submodule. Rule that out first:

```bash
# If this returns a path, you're in a submodule, not a worktree — treat as a normal repo
git rev-parse --show-superproject-working-tree 2>/dev/null
```

- **`GIT_DIR != GIT_COMMON` and not a submodule:** already in a linked worktree. Skip to Step 3. Do not create another one.
- **`GIT_DIR == GIT_COMMON` (or a submodule):** normal checkout. Ask for consent before creating a worktree unless the user already stated a preference: *"Would you like me to set up an isolated worktree? It protects your current branch from changes."*

## Step 1: Create Isolated Workspace

### 1a. Native tools (preferred)

This session has an `EnterWorktree` tool. Use it — it handles directory placement, branch creation, and this repo's `worktree` settings (`baseRef`, `symlinkDirectories`, `sparsePaths`, `bgIsolation` in `.claude/settings.json`) automatically. Using manual `git worktree add` instead creates phantom state the harness can't track.

Only proceed to 1b if no native tool is available in the current runtime.

### 1b. Git worktree fallback

```bash
SOURCE_ROOT=$(git rev-parse --show-toplevel)
LOCATION="$SOURCE_ROOT/.worktrees"
mkdir -p "$LOCATION"
path="$LOCATION/$BRANCH_NAME"
```

**Verify `.worktrees/` is ignored before creating anything:**

```bash
git check-ignore -q .worktrees 2>/dev/null
```

If not ignored, add it to `.gitignore` and commit that change first — an untracked worktree accidentally committed pollutes the whole repo.

**Capture `SOURCE_ROOT` before `git worktree add`** — after `cd` into the new worktree, `git rev-parse --show-toplevel` resolves to the worktree path, not the main checkout where `.claude/settings*.json` lives.

```bash
git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

**Sandbox fallback:** if `git worktree add` fails with a permission error, tell the user the sandbox blocked worktree creation and continue in the current directory instead.

**Copy Claude configuration** (git fallback only — native tools already propagate this):

```bash
for f in ".claude/settings.json" ".claude/settings.local.json"; do
    if [ -f "$SOURCE_ROOT/$f" ]; then
        mkdir -p ".claude"
        cp -p "$SOURCE_ROOT/$f" "./$f"
    fi
done
```

## Step 2: Project Setup (Go-first, this repo)

```bash
go mod download
go build ./...
```

Fall back to the appropriate installer only if the worktree is for a different stack (`npm install` for Node, `poetry install` / `pip install -r requirements.txt` for Python, `cargo build` for Rust).

## Step 3: Verify Clean Baseline

```bash
go test ./...
```

Report failures before proceeding; get explicit permission to continue on a red baseline — you cannot otherwise tell a pre-existing failure from one you introduced.

## Step 4: Cleanup — Remove the Worktree When Done

"Done" means: branch merged, PR closed, the experiment discarded, or the user explicitly confirmed they no longer need the isolated workspace.

### 4.1 Detect Whether Cleanup Applies

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
```

If `GIT_DIR == GIT_COMMON`, you were never in a linked worktree — nothing to clean up.

### 4.2 Verify Work Is Saved

```bash
git status --porcelain      # must be empty
git log @{u}.. 2>/dev/null  # must be empty
```

If either returns output: **stop**. Report the unsaved work and ask how to proceed (commit/push, stash, or explicit discard). Never delete a worktree with unsaved work without confirmation.

### 4.3 Remove

- **Native tool used to create it:** use the matching native cleanup (`ExitWorktree` or equivalent).
- **Git fallback:**
  ```bash
  cd "$GIT_COMMON/.."
  git worktree remove "$WORKTREE_PATH"
  git branch -d "$BRANCH_NAME"     # safe delete; refuses if unmerged
  git worktree prune               # if the directory was removed manually
  ```

### 4.4 Verify Cleanup

```bash
git worktree list                 # WORKTREE_PATH must no longer appear
ls -d "$WORKTREE_PATH" 2>/dev/null # must return nothing
```

## Quick Reference

| Situation | Action |
|-----------|--------|
| Already in a linked worktree | Skip creation (Step 0) |
| In a submodule | Treat as a normal repo (Step 0 guard) |
| `EnterWorktree` available | Use it (Step 1a) |
| No native tool | Git fallback (Step 1b) |
| Worktree location | `<repo>/.worktrees/<branch>` |
| Directory not ignored | Add to `.gitignore` + commit, before creating |
| Permission error on create | Sandbox fallback, work in place |
| Baseline tests fail | Report + ask before proceeding |
| Uncommitted/unpushed changes at cleanup | Stop and ask |
| Worktree created natively | Clean up natively (`ExitWorktree`) |
| Worktree created via git | Clean up via `git worktree remove` |

## Red Flags

**Never:**
- Create a worktree when Step 0 already detects isolation.
- Use `git worktree add` when a native tool (`EnterWorktree`) is available — the #1 mistake.
- Force-delete a branch (`git branch -D`) without confirming it's merged or explicitly no longer needed.
- Run `git worktree remove` on a worktree a native tool created, or vice versa.
- Remove a worktree with unsaved/unpushed work without explicit user confirmation.

**Always:**
- Run Step 0 detection first.
- Prefer native tools over the git fallback.
- Verify `.worktrees/` is gitignored before a manual create.
- Verify clean test baseline before implementation.
- Verify nothing is lost (`git status --porcelain`, `git log @{u}..`) before removal.
