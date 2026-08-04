---
name: codemap
description: "Trigger: codemap, code map, map the codebase, mapear el codigo, docs/codemap. Generate an interactive, evidence-backed codebase map (html+json+lock) under docs/codemap/."
license: Apache-2.0
metadata:
  author: "felipepepe"
  version: "1.0"
---

## Activation Contract

Load this skill when the user asks to map, chart, or document the architecture of the current codebase as an interactive artifact under `docs/codemap/`, or explicitly invokes `/codemap`. Works in any project, not just one repo.

## Hard Rules

- Never modify product code — writes are scoped strictly to `docs/codemap/`.
- Never fabricate a node role, edge, or flow step. Anything without a real source path + symbol as evidence must be marked `"unknown"`.
- The three deliverables (`codemap.html`, `codemap.json`, `codemap.lock`) are always regenerated together in one run — never hand-edit just one.
- Read `references/codemap-spec.md` in full before doing or delegating any work — it holds the complete file-by-file contract and validation checklist; do not improvise the shape from memory.

## Decision Gates

| Condition | Action |
|---|---|
| `docs/codemap/codemap.lock` exists | Read it, recompute per-module fingerprints from current tracked files, diff vs stored fingerprints, list changed/new/removed modules before regenerating |
| No `docs/codemap/codemap.lock` found | Treat every module as new; generate the full map from scratch |
| CBM (codebase-memory-mcp) has an index for this project | Use it as primary discovery: `get_architecture`, `search_graph`, `trace_path`, `get_code_snippet`, `query_graph` |
| No CBM index exists | Offer `index_repository`, or fall back to Read/Glob/Grep-based analysis |

## Execution Steps

1. Read `references/codemap-spec.md` in full.
2. Determine target repo (cwd unless user specifies otherwise) and capture current commit + working-tree dirty state (`git rev-parse HEAD`, `git status --porcelain`).
3. Apply the Decision Gates above (lock diff vs fresh generation; CBM vs fallback discovery).
4. Delegate the actual exploration and file generation to one foreground general-purpose subagent per run, passing it: the target path, current commit/dirty state, the full contents of `references/codemap-spec.md`, and (if present) the prior lock's module list for diffing. One subagent keeps the three interlocking files internally consistent and returns one clean report.
5. Relay the subagent's final report to the user unedited in substance.

## Output Contract

Return exactly the final report format defined in `references/codemap-spec.md`: files created/modified, module diff vs previous lock (or "N/A, first run"), remaining unknowns, per-check validation results, and the complete diff.

## References

- `references/codemap-spec.md` — full deliverable spec, file shapes, and validation checklist (required reading before every run).
