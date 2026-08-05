# Proposal: Add codebase-memory-mcp (cbm) as a community tool

## Intent

CodeGraph is currently the only community tool, and `internal/components/communitytool/tool.go` hardcodes `def.ID != model.CommunityToolCodeGraph` rejections in `Install`, `DetectStatus`, and guidance paths. Users cannot install cbm from the TUI/CLI, so cbm setup stays manual and outside gentle-ai's sync/uninstall lifecycle. Goal: cbm becomes a first-class community tool with the same user-visible experience as CodeGraph (pick in TUI, install, status, sync, uninstall).

## Settled Decisions

| # | Decision | Confirmed choice |
|---|----------|------------------|
| 1 | Parity scope | **UX parity, delegated wiring.** No native/reconciled/excluded table and no per-agent Go MCP config writers for cbm. |
| 2 | Binary ownership | **gentle-ai owns the download.** Mirror `internal/components/engram/download.go`; do NOT shell out to cbm's `install.sh`/`install.ps1`. After the verified binary is placed, gentle-ai invokes `codebase-memory-mcp install -y` for wiring. |
| 3 | Agent-selection scope | **Accepted as-is.** `install -y` may configure every client surface it detects, not only picker-selected agents. Documented behavior difference from other components, not a bug. |
| 4 | Indexing model | **Add `gentle-ai cbm init --cwd <root>`**, mirroring `internal/cli/codegraph.go`'s `RunCodeGraph` root-safety guard. |
| 5 | Uninstall confirmation | **Surface the prompt.** cbm's "delete graph indexes?" confirmation must be re-rendered through the gentle-ai TUI; never auto-confirm, never silently skip. |

## Scope

### In Scope
- Generalize `communitytool` from single-tool hardcoding to table-driven multi-tool dispatch.
- Add `model.CommunityToolCBM` + `Definition` entry so the existing TUI screen lists it.
- Own binary acquisition: GitHub Releases API lookup against `DeusData/codebase-memory-mcp`, OS/arch asset selection, mandatory `checksums.txt` verification (fail-closed), atomic install, version pinned in `internal/versions`.
- After placement, invoke `codebase-memory-mcp install -y` to perform per-agent wiring.
- `gentle-ai cbm init --cwd <root>` safe CLI boundary with unsafe-root rejection ($HOME, temp, volume root).
- Uninstall/deselect via `codebase-memory-mcp uninstall`, surfacing its index-deletion confirmation through the TUI; wired into `internal/components/uninstall/service.go`.
- Status detection (`exec.LookPath` + installed-marker) and a `sync:community-tool:cbm` step.
- cbm guidance markdown injected per selected agent (tools: `search_graph`, `trace_path`, `get_code_snippet`, `query_graph`, `get_architecture`, `search_code`, `index_repository`), including when to run `gentle-ai cbm init`.

### Out of Scope
- Per-agent Go MCP-config writers or a native/reconciled/excluded compatibility table for cbm.
- Pi-style child/overlay reconciliation, manifests, JSON-RPC handshake probing.
- Constraining `install -y` to the picker's selected agent subset (decision 3).
- Proxying cbm subcommands beyond `init` (same boundary discipline as `RunCodeGraph`).
- Changing CodeGraph behavior beyond the mechanical multi-tool refactor.

## Capabilities

### New Capabilities
- `community-tool-catalog`: multi-tool registration, install/status/sync/uninstall dispatch for N community tools.
- `cbm-community-tool`: cbm binary acquisition, install delegation, `cbm init` boundary, guidance injection, and uninstall lifecycle.

### Modified Capabilities
- None.

## Approach

cbm ships its own installer that configures 43 client surfaces (more than gentle-ai's 16 agents), writing each agent's native config, skills, hooks, and instructions, with symmetric uninstall. Replicating CodeGraph's per-agent table would duplicate — and under-cover — logic cbm already owns.

Division of ownership:
- **gentle-ai owns**: discovery, selection, verified binary acquisition and version pinning, the `cbm init` safety boundary, guidance markdown, status, sync, and uninstall orchestration (including surfacing cbm's confirmation prompt).
- **cbm owns**: all per-agent MCP config writing, its own skills/hooks/instructions, and removal of everything it wrote.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `internal/model/types.go` | Modified | Add `CommunityToolCBM` |
| `internal/components/communitytool/` | Modified | Table-driven dispatch; new `cbm.go`, `cbm_guidance.go` |
| `internal/components/cbm/download.go` | New | Releases API + checksum + atomic install (Engram pattern) |
| `internal/versions` | Modified | Pin cbm version |
| `internal/cli/cbm.go` | New | `RunCBM` init boundary + unsafe-root guard |
| `internal/components/uninstall/service.go` | Modified | Delegate cbm uninstall, surface confirmation |
| `internal/cli/sync.go`, `run.go` | Modified | `sync:community-tool:cbm` step; register `cbm init` command |
| `internal/tui/screens/community_tools.go` | Modified | Reuses `Definitions()`; add uninstall-confirmation rendering |
| `internal/tui/model.go` | Modified | Confirmation screen/state for cbm index deletion |
| `internal/state` | Modified | Persist cbm selection |

Not affected: `internal/installcmd/resolver.go` — decision 2 removes the GGA-style script-delegation path.

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| `install -y` configures unselected agents, surprising users | Med | Accepted (decision 3); state it in TUI copy and guidance |
| cbm writes agent configs gentle-ai also manages → drift | Med | Treat cbm-owned paths as external; no gentle-ai marker injection there |
| Sigstore-only signing (no Authenticode) blocks Windows AppLocker publisher rules | Med | Same caveat as gentle-ai's own binary; document, don't block |
| Multi-tool refactor regresses CodeGraph | Med | Keep CodeGraph tests green; refactor before adding cbm (TDD) |
| Upstream release asset naming / `install -y` flag drift | Med | Pin version; fail closed on checksum mismatch or non-zero exit |
| Interactive uninstall prompt blocks non-TTY/CI runs | Med | Detect non-interactive context and abort cbm uninstall with an actionable message rather than auto-confirming |

## Rollback Plan

The multi-tool refactor and the cbm addition land as separate commits. Revert the cbm commit to restore single-tool behavior; CodeGraph tests remain the regression gate. Binary acquisition is atomic — a failed checksum leaves no partial install. At runtime, deselecting cbm runs `codebase-memory-mcp uninstall` (which removes everything cbm owns, with index deletion user-confirmed), then gentle-ai removes its own guidance blocks via managed markers and clears persisted state.

## Dependencies

- `github.com/DeusData/codebase-memory-mcp` GitHub Releases (signed binaries, `checksums.txt`, `install -y`, `uninstall` subcommands).
- Local reference clone: `/home/sandman/sources/codebase-memory-mcp`.

## Success Criteria

- [ ] cbm appears and installs from the Community Tools TUI screen.
- [ ] Binary is downloaded by gentle-ai with verified checksum; mismatch fails closed.
- [ ] `communitytool` has no tool-ID hardcoding; CodeGraph tests still pass.
- [ ] `gentle-ai cbm init --cwd <root>` indexes a valid project and rejects unsafe roots.
- [ ] Status detection reports CLI availability and wiring.
- [ ] Deselect/uninstall surfaces the index-deletion confirmation and leaves no cbm-owned residue.
- [ ] Guidance markdown injected under a managed marker for selected agents.
