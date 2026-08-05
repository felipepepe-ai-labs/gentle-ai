---
name: gitflow
description: "Classic Gitflow branching model — main, develop, release, feature, hotfix, bugfix, with main/develop protected from direct commits. Trigger: before any code change in a project using Gitflow; branch creation, release cuts, hotfixes."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

Load this skill before creating a branch or opening a PR in a project that uses the classic Gitflow model. Signal: the repo has both a `main` and a `develop` branch.

If the repo only has `main` (no `develop`), it likely uses a trunk-based flow instead — check for a repo-specific branch/PR skill (e.g. this ecosystem's own `branch-pr`) before applying Gitflow here. Do not introduce `develop`/`release/*` into a repo that doesn't already use them without the user's explicit request.

## Branch Model

| Branch | Purpose | Created from | Merges into |
|---|---|---|---|
| `main` | Production-ready history; every commit is a released state | — | never committed to directly |
| `develop` | Integration branch; latest delivered development changes | `main` (once, at repo setup) | never committed to directly |
| `feature/<slug>` | New functionality | `develop` | `develop` (via PR) |
| `release/<version>` | Stabilize a release candidate (freeze, final fixes, version bump) | `develop` | `main` **and** `develop` (via PR), tagged on `main` |
| `hotfix/<slug>` | Urgent production fix that cannot wait for the next release | `main` | `main` **and** `develop` (via PR) |
| `bugfix/<slug>` | Non-urgent bug found during `develop`/`release` testing | `develop` or `release/<version>` | the branch it came from (via PR) |

## Critical Rules

| Rule | Requirement |
|------|-------------|
| `main` and `develop` are protected | No direct commits, no direct pushes, no local `git merge` + `git push` to either. Every change lands through a reviewed Pull Request. |
| One direction of truth | `feature`/`bugfix` never merge into `main` directly — always through `develop` first. |
| Releases and hotfixes sync both lines | A `release/*` or `hotfix/*` branch merges into **both** `main` and `develop` so `develop` never drifts behind production. |
| Tag on `main` | Tag the release commit (`vX.Y.Z`) immediately after a `release/*` or `hotfix/*` PR merges into `main`. |
| Clean up after merge | Delete the source branch once its PR is merged. |
| Detect before applying | Confirm the repo actually uses Gitflow (`main` + `develop` both exist) before creating `release/*` or `hotfix/*` branches — don't invent the model on a trunk-based repo. |

## Naming

```
feature/<slug>
release/<version>
hotfix/<slug>
bugfix/<slug>
```

All lowercase, hyphen-separated, short and descriptive (e.g. `feature/user-login`, `release/2.3.0`, `hotfix/expired-token-crash`, `bugfix/pagination-off-by-one`).

## Workflow

1. **Detect the model**: `git branch -r` — confirm both `main` and `develop` exist before proceeding as Gitflow.
2. **Branch from the right base**:
   ```bash
   # feature
   git checkout develop && git pull && git checkout -b feature/<slug>

   # bugfix (found during develop testing)
   git checkout develop && git pull && git checkout -b bugfix/<slug>

   # release
   git checkout develop && git pull && git checkout -b release/<version>

   # hotfix (urgent, from production)
   git checkout main && git pull && git checkout -b hotfix/<slug>
   ```
3. **Open a PR to the correct target — never push directly to `main` or `develop`:**

   | Source | Target |
   |---|---|
   | `feature/*` | `develop` |
   | `bugfix/*` (from `develop`) | `develop` |
   | `bugfix/*` (from `release/*`) | the same `release/*` branch |
   | `release/*` | `main`, then a follow-up PR (or merge-back) into `develop` |
   | `hotfix/*` | `main`, then a follow-up PR (or merge-back) into `develop` |

4. **After a `release/*` or `hotfix/*` PR merges into `main`**: tag the commit (`vX.Y.Z`), then open the follow-up PR that brings the same changes into `develop` so it stays in sync.
5. **Delete the branch** after its PR merges.

## Quick Reference

| Situation | Action |
|---|---|
| Starting new functionality | `feature/<slug>` from `develop`, PR into `develop` |
| Bug found during development | `bugfix/<slug>` from `develop`, PR into `develop` |
| Bug found during release stabilization | `bugfix/<slug>` from `release/<version>`, PR into the same `release/*` |
| Cutting a release | `release/<version>` from `develop`, PR into `main`, then sync into `develop`, tag `main` |
| Production is broken now | `hotfix/<slug>` from `main`, PR into `main`, then sync into `develop`, tag `main` |
| Considering a direct push/merge to `main` or `develop` | Stop — open a PR instead, no exceptions |
| Repo has no `develop` branch | This is not Gitflow — check for the repo's own trunk-based branch/PR skill instead |

## Commands

```bash
# Confirm the model before doing anything
git branch -r

# Sync develop after a hotfix/release lands on main
git checkout develop && git pull
git merge --no-ff main   # or open the equivalent sync PR, per repo policy
git push

# Tag a release on main
git checkout main && git pull
git tag -a vX.Y.Z -m "vX.Y.Z"
git push origin vX.Y.Z

# Clean up after merge
git branch -d <branch-name>
git push origin --delete <branch-name>
```
