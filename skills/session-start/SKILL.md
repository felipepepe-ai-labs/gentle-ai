---
name: session-start
description: "Trigger: session start, new project, iniciar sesion, session-start. Build functional and technical project context from CBM, Engram, and docs."
license: Apache-2.0
metadata:
  author: "felipepepe"
  version: "1.0"
---

## Activation Contract

Load this skill when a new working session begins in a project directory not yet contextualized this session, OR when the user explicitly invokes `/session-start`. Skip if project context was already gathered earlier in the same session.

## Hard Rules

- Read all three sources (CBM, Engram, docs) before summarizing — never skip a source silently; report it as unavailable instead.
- Never fabricate architecture or history when a source returns empty; state "no data" for that source.
- Keep the final summary concise: functional purpose + technical architecture + relevant recent context, not a full dump of raw tool output.

## Decision Gates

| Condition | Action |
|---|---|
| `mcp__codebase-memory-mcp__index_status` reports project not indexed | Run `index_repository` first, then `get_architecture` |
| Project already indexed | Call `get_architecture` and `search_graph` directly |
| Engram has no project memories | Note absence, continue with CBM + docs only |
| No README/CLAUDE.md/docs found | Note absence, continue with CBM + Engram only |

## Execution Steps

1. CBM: check `index_status`; if unindexed, run `index_repository`, then call `get_architecture(aspects)` for structure and `search_graph` for key entry points (routes, main modules).
2. Engram: call `mem_context` for recent session history, then `mem_search` with project-relevant keywords for prior decisions/discoveries.
3. Docs: `Glob` for `README*`, `CLAUDE.md`, `docs/**/*.md` at project root; `Read` the most relevant ones (README + CLAUDE.md always; skip exhaustive docs/ reads unless thin).
4. Synthesize findings into one summary — do not paste raw tool output.

## Output Contract

Return a short summary with three parts:
- **Functional**: what the application does, for whom.
- **Technical**: architecture, stack, key modules/entry points (from CBM).
- **Context**: relevant recent decisions/discoveries (from Engram), or "none found".

## References

None — sources are queried live each run, not cached locally.
