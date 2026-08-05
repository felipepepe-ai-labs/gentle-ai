---
name: gentle-ai-collab-perfect
description: "Trigger: contributing to Gentleman-Programming/gentle-ai as an external collaborator (not the maintainer). Contributor-vs-maintainer scope, PR-body honesty protocol, and empirically-verified permission gates. Delegates branch/PR/issue mechanics to skills/branch-pr, skills/chained-pr, skills/issue-creation — load this skill alongside them, not instead of them."
license: Apache-2.0
metadata:
  author: ardelperal
  version: "0.2"
---

## When to use

Use this skill when the active repo is `Gentleman-Programming/gentle-ai` and the contributor is an **external collaborator** (not the maintainer). It answers the questions the mechanics skills don't: *can I even do this action*, and *is my PR body actually telling the truth*.

- Deciding whether an action is contributor-scope or maintainer-scope
- Auditing a PR body against the live GitHub API before requesting review
- Choosing between Stacked-to-main and Feature Branch Chain when slice branches live only in the contributor's working repo (no upstream push access)

This skill does **not** duplicate the mechanics of branching, committing, PR creation, chained-PR structure, or issue creation — load the relevant one alongside it:

| Need | Skill |
|---|---|
| Branch naming, `gh pr create`, PR template mechanics | `skills/branch-pr/SKILL.md` |
| Chained/stacked PR structure and dependency diagrams | `skills/chained-pr/SKILL.md` |
| Opening a new issue | `skills/issue-creation/SKILL.md` |
| Splitting work into reviewable commits | `skills/work-unit-commits/SKILL.md` |
| Doc-writing principles, comment tone | `skills/cognitive-doc-design/SKILL.md`, `skills/comment-writer/SKILL.md` |

Do NOT load this skill for: using gentle-ai as an installer, reading docs or debugging tests in general, or work on a different repository.

The skill assumes the contributor is working from wherever they push — a fork, a personal working repo, or anywhere they have write access. It deliberately does not assume a fork.

---

## Source of truth — read the repo, don't infer

Before recommending any contribution action, read the relevant local file. The repo documents every constraint; pulling rules verbatim beats guessing.

| File | What it tells you |
|---|---|
| `CONTRIBUTING.md` | Issue-first workflow, label taxonomy, branch naming regex, Conventional Commits format, 400-line review budget |
| `.github/PULL_REQUEST_TEMPLATE.md` | Required PR body sections |
| `.github/ISSUE_TEMPLATE/*.yml` | Issue body structure, `status:needs-review` auto-label, `status:approved` blocking gate |
| `.github/workflows/pr-check.yml` | Automated gates: `Check Issue Reference`, `Check Issue Has status:approved`, `Check PR Has type:* Label`, `Check PR Cognitive Load` |

These files evolve. Re-read them at the start of every contribution.

---

## Contributor vs maintainer scope

This is the split that catches external contributors most often. Verify with `gh` before recommending any action that requires elevated permissions.

| Action | Contributor | Maintainer |
|---|---|---|
| Open / comment on issues | ✅ | — |
| Open a PR from a working branch | ✅ | — |
| Edit own PR body, push commits to own branches | ✅ | — |
| Add `status:approved` to an issue | ❌ | ✅ |
| Apply `type:*` or `size:exception` label to a PR | ❌ | ✅ |
| Approve `action_required` fork-PR workflows | ❌ | ✅ |
| Review a PR (approve / request changes), merge a PR | ❌ | ✅ |
| Push `slice/*` branches to upstream so cross-fork base refs work | ❌ | ✅ |

If the contributor's PR is "stuck," the next step is almost always a maintainer action — not the contributor trying it. Trying it surfaces GraphQL 403s (`AddLabelsToLabelable`, `requestReviewsByLogin`, deployment-protection API) and makes the contributor look unaware of the workflow.

**Verified empirically** in this repo (July 2026): `gh pr edit --add-label type:feature` returns **403** `ardelperal does not have the correct permissions to execute AddLabelsToLabelable`. Treat that error as policy, not as a bug.

---

## PR body honesty — the single most often-abused rule

Every `[x]` in the Contributor Checklist is a public claim that `pr-check.yml` and the maintainer will verify.

1. **Mark `[x]` only when the assertion is true against the API.**
   ```bash
   gh pr view <N> --json labels,closingIssuesReferences,additions,deletions,changedFiles
   ```
   If `labels: []`, do not check the "type:* added" box. Instead add:
   ```markdown
   ## Pending maintainer actions

   The following are **maintainer-applied per `pr-check.yml` and CONTRIBUTING.md`** — not within contributor scope:

   - [ ] `type:feature` label applied to this PR — pending Alan
   - [ ] `size:exception` consideration — see rationale below
   - [ ] Fork workflow approval — 4 runs in `action_required` awaiting Alan
   ```

2. **Numbers and file counts must match the API.** If you can't trust the API, recount locally: `git diff --stat <base>..<head>`.

3. **Pre-existing test failures must be named honestly**, with the verification method. This repo has pre-existing failures in `internal/components/communitytool/pi_codegraph`, `internal/tui/sync`, and similar packages — confirm they exist on `main` via a `git stash` baseline (stash → run → `git stash pop`) before claiming they're not introduced by your change. "Tests pass" without that context is dishonest.

Honest rewrites often look like **adding** content, not removing. Adding `## Pending maintainer actions` and a quoted callout for pre-existing failures is normal and expected.

### Standard honest-rewrite pattern

When the contributor checks a box that doesn't reflect reality:
- Move the unfulfillable contributor-side check into `## Pending maintainer actions` with a `pending Alan`-style suffix.
- Update diff numbers to match the API exactly; qualify them if needed (e.g. "slice-specific commits only").
- For test claims, state the exact local commands run and PASS/SKIP counts observed — don't aggregate to "all pass" if any were skipped.
- Name pre-existing repo failures the contributor observed but did not fix, with the verification method.
- For process claims (e.g. "blind dual review approved"), reference the artifact that IS the evidence.

---

## Chained PR strategy — the cross-fork limitation

Use `skills/chained-pr/SKILL.md` for the Stacked-vs-Feature-Branch-Chain mechanics. The piece that skill doesn't cover: **GitHub does not support cross-fork base refs.** If your slice branches live only in your own working repo (not pushed upstream), your options collapse to:

- **Stacked to main**, accepting polluted diffs (previous-slice commits show up in later PRs) — request `size:exception` if slice-specific additions exceed 400 lines.
- Ask the maintainer to push your `slice/*` branches upstream so **Feature Branch Chain** becomes possible.

The maintainer is the only one who can make Feature Branch Chain work; the contributor alone cannot force it.

---

## Verification protocol

Before recommending any action that touches permissions, label state, or commit history:

1. **Dry-verify with `gh` first.** Attempt the action and surface the error if it fails:
   ```
   $ gh pr edit 1132 --add-label type:feature
   → GraphQL: ardelperal does not have the correct permissions to execute `AddLabelsToLabelable`
   ```
   That output IS your answer. Don't try to work around it.

2. **Cross-check PR body claims against the GitHub API.**
   ```bash
   gh pr view <N> --json \
     labels,closingIssuesReferences,additions,deletions,changedFiles,\
     headRefName,baseRefName,isCrossRepository,headRepository,maintainerCanModify,\
     reviewDecision,statusCheckRollup
   ```

3. **Cross-check the linked issue state.**
   ```bash
   gh issue view <N> --json number,title,state,labels,comments
   ```

4. **After a body rewrite**, round-trip it and confirm `closingIssuesReferences` is populated:
   ```bash
   gh pr view <N> --json body --jq '.body'
   gh pr view <N> --json closingIssuesReferences
   ```

5. **Trust the contributor's lived permissions over inferred defaults.** If they say "I can only do X," route everything else to the maintainer — don't waste review budget on GraphQL 403s.

6. **Always run the actual test command before claiming it passes** — `go test ./path/to/pkg -v` output, not hope.

---

## Pre-PR self-audit checklist (delta over `branch-pr`/`chained-pr`)

Run this in your head before requesting review, on top of the checklists in `skills/branch-pr/SKILL.md` and `skills/chained-pr/SKILL.md`:

- [ ] No `[x]` claims contradict what the API shows; maintainer-only actions moved to `## Pending maintainer actions`
- [ ] Line counts in `## 📂 Changes` match `gh pr view --json additions,deletions,changedFiles`
- [ ] Pre-existing failures named with verification method (`git stash` baseline)
- [ ] Chained-slice strategy agreed with the maintainer (Stacked vs Feature Branch Chain), cross-fork limitation acknowledged if relevant
- [ ] Docstring coverage on exported items in the diff ≥80% (CodeRabbit pre-merge check)

---

## Anti-patterns

| Anti-pattern | Symptom | Fix |
|---|---|---|
| `[x]` "type:* added" while `labels: []` | CodeRabbit or maintainer catches the lie on first read | Move to `## Pending maintainer actions` with `pending Alan` |
| `Refs #N` instead of `Closes #N` | `Check Issue Reference` fails; PR auto-rejected | Use `Closes`/`Fixes`/`Resolves` |
| `[x] PR stays within 400 changed lines` for a 3,200-line PR | `Check PR Cognitive Load` fails | Compute real totals, document `size:exception` rationale |
| Slice branches all base on `main` with stale carry-over commits | Reviewers can't isolate slice-specific changes | Accept Stacked-to-main (request exception) OR ask maintainer to push slice branches upstream |
| Trying `gh pr edit --add-label` as contributor | GraphQL 403 `AddLabelsToLabelable` | Stop, ask the maintainer via comment on the issue |
| Pretending local test run = clean `go test ./...` | Repo has pre-existing failures (`pi_codegraph`, `tui/sync`) | Run with `git stash` baseline, name pre-existing failures explicitly |
| Calling a working repo a "fork" in code or docs | Misrepresents the contributor's relationship to upstream | Use neutral language: "your working branch," not "your fork" |

---

## How to apply this skill — workflow for the AI assistant

1. **Before recommending any action**, check whether it's contributor-scope or maintainer-scope using the table above; if maintainer-only, route to the maintainer instead of suggesting the contributor try it.
2. **Before recommending body rewrites**, fetch the PR's current state and cross-check every claim against the API.
3. **Before recommending chained-PR structure**, load `skills/chained-pr/SKILL.md` for the mechanics, then apply the cross-fork base-ref limitation above.
4. For everything else — branching, commit structure, issue creation, PR template mechanics — load the corresponding mechanics skill instead of re-deriving it here.

When in doubt, the right move is more verification, less action.

---

## References

- `CONTRIBUTING.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `.github/ISSUE_TEMPLATE/*.yml`, `.github/workflows/pr-check.yml` — the actual rules this skill cites.
- `skills/branch-pr/SKILL.md`, `skills/chained-pr/SKILL.md`, `skills/issue-creation/SKILL.md`, `skills/work-unit-commits/SKILL.md` — mechanics this skill delegates to.
- GitHub Actions docs for the `action_required` fork-PR gate: https://docs.github.com/actions/managing-workflow-runs/approving-workflow-runs-from-public-forks
