---
name: update-docs
description: "Identify and update the documentation a code change affects before it ships. Trigger: implementation complete, before opening a PR, docs might be stale."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

Load this skill after implementation is done and before a PR is opened, whenever the change could make existing documentation inaccurate: new/changed CLI behavior, a new agent integration, a new or renamed skill, a changed component/adapter, or a changed workflow (SDD, RDD, review gates).

Do not use it to design new documentation from scratch — that is [[cognitive-doc-design]]. This skill decides *which existing docs need a touch-up* for a given change, then applies the minimal accurate edit.

## Critical Rules

| Rule | Requirement |
|------|-------------|
| Docs travel with the change | Per `work-unit-commits`, doc updates belong in the same commit/PR as the behavior they describe — never a follow-up "docs later" commit. |
| Read before writing | Never guess a doc's current content or assume a file exists. Read the exact section before editing it. |
| Map the change, don't scan blindly | Use the Doc Map below to go straight to the affected files instead of re-reading all of `docs/`. |
| Skill changes always touch the index | Any add/rename/remove under `skills/` requires updating the skill table in `AGENTS.md`, and conformance with `docs/skill-style-guide.md`. |
| No invented docs | If no doc plausibly covers the change, say so explicitly rather than creating a new file no one asked for. |
| Minimal accurate diff | Update only the stale parts. Do not rewrite unrelated sections or restyle a doc while fixing one fact. |

## Workflow

1. **Scope the change**: `git diff --stat` (or `git diff --stat main...HEAD` on a branch) to see which files/dirs changed.
2. **Map to docs**: use the table below to find candidate documentation files for each changed area.
3. **Read each candidate doc's current text** before deciding whether it needs an edit.
4. **Edit only what's stale** — a changed flag, a renamed command, a new row in a table, a new integration in `README.md`'s support table.
5. **Report**: list which docs were updated, and which were checked but left untouched (with a one-line reason, e.g. "already accurate").

## Doc Map (Quick Reference)

| Changed area | Docs to check |
|---|---|
| `skills/*/SKILL.md` (add/rename/remove) | `AGENTS.md` skill table, `docs/skill-style-guide.md` conformance |
| `internal/components/*`, `internal/catalog/*` | `docs/CODEBASE-GUIDE.md`, `docs/architecture/*`, `docs/components.md` |
| `cmd/gentle-ai/*`, new/changed CLI flag or command | `docs/quickstart.md`, `docs/usage.md`, `README.md` Quick Start |
| New agent integration (adapter) | `README.md` Supported Agent Integrations table, `docs/platforms.md` |
| Review/RDD/receipt behavior | `docs/review-integration.md`, `docs/review-authority-threat-model.md`, `docs/trigger-rules.md` |
| SDD workflow changes | `~/.claude/skills/_shared/sdd-orchestrator-workflow.md` (if present), `docs/openspec-config.md` |
| Release/signing/CI changes | `docs/release-signing.md`, `docs/rollback.md`, `.goreleaser.yaml` references in docs |
| Engram/memory wiring | `docs/engram.md` |
| Non-interactive/CI usage | `docs/non-interactive.md` |

If a change spans an area not in this table, check `docs/CODEBASE-GUIDE.md` first — it indexes which guide page owns which behavior — before concluding no doc applies.

## Commands

```bash
# Scope: what changed
git diff --stat
git diff --stat main...HEAD

# Which docs already reference the changed symbol/flag/command
git grep -l "<changed-name>" -- docs README.md AGENTS.md

# Confirm a doc file actually exists before citing it
ls docs/
```
