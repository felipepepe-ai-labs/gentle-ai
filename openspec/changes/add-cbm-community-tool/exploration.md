# Exploration: add-cbm-community-tool

## Goal

Investigate what it would take to add `codebase-memory-mcp` (cbm) as a community tool in gentle-ai, with the user's requested scope being full parity with the existing CodeGraph community tool.

## Current State

CodeGraph is a "community tool," architecturally separate from `internal/catalog` regular Components (`model.ComponentID`). It lives under its own `model.CommunityToolID` enum (`internal/model/types.go:179-183`, currently only `CommunityToolCodeGraph = "codegraph"`) and package `internal/components/communitytool/`, with its own TUI screen (`internal/tui/screens/community_tools.go`, "Community Tools/Plugins") driven by `communitytool.Definitions()` — not the Components picker.

Key pieces (all `internal/components/communitytool/` unless noted):

- `tool.go` — `Definition{ID, Name, PackageName, CommandName, RepoURL, Description}`, `Install`/`InstallWithHome` (snapshot/rollback, idempotent-repair-or-full-install), `DetectStatus` (CLI availability + per-agent wiring). **Currently hardcoded to one tool**: every function explicitly does `if def.ID != model.CommunityToolCodeGraph { return error }`.
- `codegraph_contract.go` — `codeGraphCompatibilityTable map[model.AgentID]codeGraphCompatibility{Agent, Strategy, Target, OwnedPaths, Postcondition}` with three strategies: `native` (CodeGraph's installer writes the agent's canonical MCP format directly — Claude `.claude.json`, Antigravity `mcp_config.json`, Kiro `mcp.json`), `reconciled` (agent's config is edited by CodeGraph's own installer CLI rather than gentle-ai, e.g. OpenCode, Pi), `excluded` (Kilocode, VSCode Copilot, Windsurf, Kimi, QwenCode, OpenClaw, Trae — no story). Table is "deliberately exhaustive": `codegraph_contract_test.go`'s `TestCodeGraphCompatibilityTableIsExhaustive` diffs its keys against `reg.SupportedAgents()`.
- `codegraph_guidance.go` — `CodeGraphGuidanceMarkdown()` injected via `filemerge.InjectMarkdownSection` with managed marker `<!-- gentle-ai:codegraph-guidance -->`, plus legacy/unmarked-upstream-guidance stripping logic.
- `pi_codegraph.go` — heavy Pi-only integration: per-child sub-agent tool-allowlist patching, live JSON-RPC MCP handshake probing (`initialize`/`tools/list`) to verify the `codegraph_explore` schema, manifest+journal with before/after file hashes for safe rollback/uninstall, path-escape validation.
- `internal/cli/codegraph.go` — `RunCodeGraph`, the safe `gentle-ai codegraph init --cwd <root>` boundary; validates root via `canonicalCodeGraphProjectRoot`/`isUnsafeCodeGraphRoot` (rejects `$HOME`, temp, volume roots). Deliberately does not proxy other upstream subcommands.
- `internal/tui/model.go` — screens `ScreenCommunityTools`/`Installing`/`Result`, `Selection.CommunityTools []model.CommunityToolID`, persistence via `state.InstallState.CommunityTools []string`.
- `internal/components/uninstall/service.go` — backs up Pi CodeGraph paths and removes Pi's CodeGraph integration before other cleanup (ordering matters for hash-based drift detection).
- `internal/cli/sync.go`/`run.go` — pipeline steps `sync:community-tool:codegraph-guidance`, `community-tool:pi-codegraph-reconcile`/`-deselect`, idempotent guidance/wiring refresh, guidance injected into generated SDD orchestrator content when selected.
- `internal/agents/interface.go` — optional `EffectiveCodeGraphWiringDetector` capability some adapters (kiro, opencode, pi) implement for semantic wiring verification beyond markers.
- `internal/components/engram/download.go` is the reference native-binary pattern: GitHub Releases API lookup (core-tag regex, pagination, anon-token fallback), OS/arch asset naming, mandatory checksums.txt verification (fail-closed), atomic rename-based replacement, install-dir resolution (`/usr/local/bin` → `~/.local/bin`, or `%LOCALAPPDATA%`).

## cbm Distribution (gathered prior to this exploration)

- npm package `codebase-memory-mcp` (runtime: `npx`)
- pypi package `codebase-memory-mcp` (runtime: `uvx`)
- Native prebuilt binaries via `install.sh`/`install.ps1`, downloading from `github.com/DeusData/codebase-memory-mcp/releases/latest/download` — same pattern gentle-ai already uses for Engram.
- Locally configured MCP entry: `{"command": "/home/sandman/.local/bin/codebase-memory-mcp"}` — a plain stdio MCP server binary with no args, analogous to CodeGraph's canonical `{"command": "codegraph", ...}` detection.

## Affected Areas

- `internal/model/types.go` — new `CommunityToolCBM CommunityToolID = "cbm"` (or similar); no new `AgentID`/`ComponentID` expected.
- `internal/components/communitytool/tool.go` — must be generalized from its single-tool-ID hardcoding to table-driven multi-tool dispatch, or forked.
- New `cbm_contract.go`/`cbm_guidance.go` (or a simpler generic path — see recommendation below).
- Possibly `internal/components/cbm/download.go` mirroring Engram's installer, if native-binary distribution is chosen.
- `internal/cli/cbm.go` only if cbm needs a safe init/proxy CLI boundary like CodeGraph's — uncertain, since cbm's `index_repository` may be self-sufficient as an MCP tool call.
- `internal/tui/screens/community_tools.go`/`model.go` — largely reusable as-is (already iterates `Definitions()` generically).
- `internal/components/uninstall/service.go` — only if cbm needs Pi-style child/overlay reconciliation.
- Tests mirroring `codegraph_contract_test.go`'s exhaustiveness/strategy/excluded-agent tests, plus guidance-injection goldens.

## Key Structural Difference

CodeGraph's complexity exists because its own upstream installer writes agent-native config formats directly across structurally different files (JSON/JSONC/TOML/YAML). cbm, per the user's own working config, is a single stdio MCP binary with no args — the same generic shape gentle-ai already uses for Engram/Context7 via each adapter's existing `MCPConfigPath`/settings-merge mechanism. This suggests cbm likely does **not** need CodeGraph's native/reconciled/excluded per-agent strategy table — every MCP-capable agent could get uniform treatment, unless cbm's own installer independently writes agent-specific configs (unconfirmed — not yet investigated from cbm's actual repo/README).

## Approaches

1. **Full CodeGraph parity (compatibility table + bespoke per-format wiring detection)**
   - Pros: consistent with existing pattern, safest if cbm ships an upstream installer with agent-specific quirks.
   - Cons: likely over-engineered if cbm is a uniform stdio MCP server; duplicates ~500 lines of per-agent-format logic that may not apply.
   - Effort: High

2. **Generic MCP-wiring reuse (Engram/Context7 style) + generalized multi-tool `tool.go`**
   - Pros: much smaller surface, reuses proven adapter MCP-writing paths, avoids the native/reconciled/excluded table entirely if every agent handles cbm identically.
   - Cons: risks missing a real agent-specific quirk if one exists; requires generalizing the currently-hardcoded single-tool dispatch in `tool.go`.
   - Effort: Medium

3. **Native-binary distribution owned by gentle-ai (mirror `engram/download.go`) vs. delegate to cbm's own install.sh/npx/uvx**
   - Pros of gentle-ai-owned: consistent UX/checksum verification with Engram; predictable binary location.
   - Cons: duplicates Engram's ~900-line downloader for a third-party project gentle-ai doesn't control the release cadence of.
   - Effort: Medium-High (owned) vs Low (delegate to upstream installer)

## Recommendation

Investigate cbm's actual upstream repo (README, install.sh, MCP tool schemas) before committing to full CodeGraph-level parity — the "full parity" framing may over-engineer if cbm is structurally simpler. A right-sized proposal likely: (a) generalizes `tool.go`'s single-tool hardcoding to table-driven multi-tool dispatch, (b) reuses generic per-agent MCP-writing (Engram/Context7 pattern) unless upstream cbm behavior requires the heavier CodeGraph-style table, (c) resolves distribution mechanism (native binary owned by gentle-ai vs. delegating to cbm's own installer) as an explicit open decision in `sdd-propose`.

## Risks

- The "full parity" premise may be based on an incomplete picture of cbm's actual constraints — needs a follow-up read of the upstream repo before design commits to CodeGraph-level complexity.
- `tool.go`'s hardcoded single-community-tool assumption is a blocking refactor prerequisite for adding any second tool, regardless of chosen approach.
- If cbm needs Pi-style per-agent child/overlay reconciliation, that is the single most expensive piece to replicate (`pi_codegraph.go` is ~1075 lines).
- Distribution ownership (native binary via gentle-ai vs. delegate to cbm's install.sh) has real security/maintenance tradeoffs (checksum verification, release-cadence coupling) not yet resolved.

## Ready for Proposal

Yes — codebase understanding is complete. Recommend the proposal phase begin with a short investigation of cbm's upstream README/install.sh/MCP schema before finalizing scope, to avoid over-building CodeGraph-level compatibility machinery that may not be needed.
