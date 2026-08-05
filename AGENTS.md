# Gentle AI — Agent Skills Index

When working on this project, load the relevant skill(s) BEFORE writing any code.

Naming convention: `gentle-ai-*` skills are repo-specific workflow skills. Unprefixed skills are portable writing or work-unit skills and intentionally keep their canonical names.

## How to Use

1. Check the trigger column to find skills that match your current task
2. Load the skill by reading the SKILL.md file at the listed path
3. Follow ALL patterns and rules from the loaded skill
4. Multiple skills can apply simultaneously

## Skills

| Skill | Trigger | Path |
|-------|---------|------|
| `gentle-ai-issue-creation` | When creating a GitHub issue, reporting a bug, or requesting a feature. | [`skills/issue-creation/SKILL.md`](skills/issue-creation/SKILL.md) |
| `gentle-ai-branch-pr` | When creating a pull request, opening a PR, or preparing changes for review. | [`skills/branch-pr/SKILL.md`](skills/branch-pr/SKILL.md) |
| `gentle-ai-chained-pr` | When a change is too large for one review, or when creating chained/stacked pull requests. | [`skills/chained-pr/SKILL.md`](skills/chained-pr/SKILL.md) |
| `cognitive-doc-design` | When writing docs that must reduce cognitive load for readers or reviewers. | [`skills/cognitive-doc-design/SKILL.md`](skills/cognitive-doc-design/SKILL.md) |
| `comment-writer` | When drafting human comments, PR feedback, issue replies, or async updates. | [`skills/comment-writer/SKILL.md`](skills/comment-writer/SKILL.md) |
| `work-unit-commits` | When splitting implementation work into deliverable commits or chained PRs. | [`skills/work-unit-commits/SKILL.md`](skills/work-unit-commits/SKILL.md) |
| `update-docs` | When implementation is done and existing docs might be stale, before opening a PR. | [`skills/update-docs/SKILL.md`](skills/update-docs/SKILL.md) |
| `using-git-worktrees` | When starting feature work that needs isolation from the current workspace. | [`skills/using-git-worktrees/SKILL.md`](skills/using-git-worktrees/SKILL.md) |
| `gitflow` | Before any code change in a project using classic Gitflow (main + develop). Branch creation, release cuts, hotfixes. main/develop are PR-only, never direct commits. | [`skills/gitflow/SKILL.md`](skills/gitflow/SKILL.md) |
| `gentle-ai-collab-perfect` | When contributing to Gentleman-Programming/gentle-ai as an external collaborator (scope, PR-body honesty, permission gates). Load alongside `branch-pr`/`chained-pr`/`issue-creation` for mechanics. | [`skills/gentle-ai-collab-perfect/SKILL.md`](skills/gentle-ai-collab-perfect/SKILL.md) |
| `rdd-defect-workflow` | When RDD defects involve receipts, authority, recovery, delivery gates, or kill switches. | [`skills/rdd-defect-workflow/SKILL.md`](skills/rdd-defect-workflow/SKILL.md) |
| `session-start` | At the start of a session in a project, or on explicit `/session-start`, to gather functional/technical context from CBM, Engram, and docs. | [`skills/session-start/SKILL.md`](skills/session-start/SKILL.md) |
| `session-end` | Before concluding a session, or on explicit `/session-end`, to persist the session summary to Engram and refresh the CBM index if code changed. | [`skills/session-end/SKILL.md`](skills/session-end/SKILL.md) |
| `codemap` | When asked to map, chart, or document the codebase architecture as an interactive artifact under `docs/codemap/`. | [`skills/codemap/SKILL.md`](skills/codemap/SKILL.md) |
