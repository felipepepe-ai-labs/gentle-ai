---
name: session-end
description: "Trigger: session end, closing session, finalizar sesion, session-end, before saying done. Persist session outcome to Engram and refresh CBM index."
license: Apache-2.0
metadata:
  author: "felipepepe"
  version: "1.0"
---

## Activation Contract

Load this skill right before concluding or finishing work in a session — i.e. immediately before any "done"/final-summary reply — or when the user explicitly invokes `/session-end`. Skip if session outcome was already persisted this turn.

## Hard Rules

- Always call `mem_session_summary` before the final user-facing reply — this is mandatory per the always-active Engram protocol, never optional.
- Only trigger CBM re-index when source code files actually changed this session; never re-index on doc-only or no-op sessions.
- Never let memory/CBM calls replace the final answer — save first, then deliver the complete user-facing response with no tool calls after it.
- If a memory or CBM call fails or times out, deliver the final answer anyway.

## Decision Gates

| Condition | Action |
|---|---|
| Source code files were edited/created/deleted this session | Call `detect_changes`, then `index_repository` (or targeted re-index) |
| Only docs/config/no files changed | Skip CBM re-index |
| Session had no decisions/fixes/discoveries worth persisting | Still call `mem_session_summary` with minimal content — never skip it |

## Execution Steps

1. Determine if source code changed this session (git status / edited files in context).
2. If changed: call `mcp__codebase-memory-mcp__detect_changes`, then `index_repository` to refresh the graph for the next `session-start`.
3. Call `mem_session_summary` with Goal, Discoveries, Accomplished, Next Steps, Relevant Files.
4. Compose the final user-facing reply after persistence completes — no tool calls after it.

## Output Contract

End with the normal task summary to the user (what changed, what's next). Do not surface raw tool output from `mem_session_summary` or CBM calls; persistence is bookkeeping, not the reply.

## References

None — mirrors `~/.claude/skills/session-start/SKILL.md` as its session-close counterpart.
