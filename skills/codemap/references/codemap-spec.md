# codemap deliverable spec

Full requirements for the three generated files. Read this in full before delegating.

## Scope & discovery

- Target repo = cwd (or user-specified path). Ignore vendor, build, dist, cache, node_modules, .git, and other generated/dependency directories. Exclude non-code doc/config trees (SDD change folders, skill markdown folders) from the module graph — they may be referenced as context only.
- If `docs/codemap/codemap.lock` exists: read it, recompute per-module fingerprints from current tracked files, diff against stored fingerprints, and list which top-level modules changed/are new/are removed before regenerating.
- If no lock exists: treat every module as new, generate the full map from scratch.
- Prefer codebase-memory-mcp (CBM) tools when a project index exists: `get_architecture` (clusters/boundaries/layers/hotspots/file_tree), `search_graph`, `trace_path` (real call/data-flow edges), `get_code_snippet` (evidence citations), `query_graph` for anything else. These are deferred — `ToolSearch("select:mcp__codebase-memory-mcp__...")` first. No index found → offer `index_repository`, or fall back to Read/Glob/Grep.
- Every claimed node role, edge, or flow step MUST be backed by something found in source (real path + symbol). Can't evidence it → mark `"unknown"`. Never fabricate.

## Deliverable 1: docs/codemap/codemap.html

Single self-contained interactive HTML (all CSS/JS inline, zero network/CDN dependencies, opens standalone in a browser). Follow this exact reference layout (a validated "swimlane" design, not a generic force-directed blob):

**Layout — vertical swimlane columns, not free-floating physics.** Group primary nodes into labeled columns by architectural boundary/layer (e.g. "ENTRYPOINTS & TOOLING", "CORE/DOMAIN", "TRUST GATES", "EXTERNAL DEPENDENCIES" — derive real column names from the actual boundaries found in discovery, don't copy example names). Each column is a bordered rounded container with an uppercase header label. Nodes stack vertically inside their column; edges are curved bezier lines crossing between columns. This IS the "automatic layout minimizing edge crossings" requirement — column assignment by boundary + vertical stacking replaces a force simulation.

**Header (top bar):** small repo icon/avatar + repo name + "interactive code map" subtitle on the left; "Generated <timestamp> · commit <hash>" as a smaller line beneath it; zoom controls (`+`/`-`/fit-to-screen) and "Fit map" / "Clear focus" buttons on the top right.

**Left sidebar** (fixed, ~250px):
- "FIND A MODULE" — a search input filtering nodes by name/role/path live as you type.
- "END-TO-END FLOWS" — one row per flow (the 3-5 evidenced flows), each showing the flow's `trigger` as a bold title and its `outcome` as a one-line description below; clicking a row selects that flow.
- "MODULE FILTERS" — one checkbox per role/type (entrypoint, service, build, runtime, core/domain, validation, external, schema/contract — use whatever roles actually appear), toggling visibility of matching nodes.
- "LEGEND" — one color swatch + label per role/type, matching the node badge colors.

**Node cards:** rounded rectangle, node title bold at top, a small colored role badge pill in the top-right corner of the card (color-coded, matching the legend), a one-line description (from the node's `constraints`/role), and the node's `path` rendered in monospace at the bottom.

**Right sidebar — "Selection" panel** (populated on node click, empty/hidden state otherwise): node name + description + path; then labeled subsections with pill-style tags: "ENTRYPOINTS", "RELATED TESTS", "CONSTRAINTS", "FLOWS" (colored per matching flow), "EVIDENCE" (each evidence string shown as a monospace line).

**Interaction & relationship colors:**
- Click a node → dim/gray out unrelated nodes and edges; highlight its upstream callers' edges in one color (e.g. pink/red) and downstream dependencies' edges in a second color (e.g. blue); populate the right Selection panel. A small bottom-left status pill shows "`<node name>` · N upstream · M downstream".
- Select a flow (from the sidebar list) → highlight that flow's full edge path in a third distinct color (e.g. amber/gold), overriding the upstream/downstream colors for that path.
- A small "RELATIONSHIP COLORS" key (upstream callers / downstream dependencies / selected flow) belongs near the Selection panel or legend so the three edge colors are self-explanatory.
- Search and filter checkboxes both dim/hide non-matching nodes on the same canvas (don't open a separate view).
- Pan (drag canvas) and zoom (scroll + the header's +/-/fit controls) on the whole diagram.

**Palette:** dark navy-black background (not pure black), one consistent accent color (e.g. cyan/teal) for header text, active states, and borders; muted low-contrast card borders at rest; sans-serif for labels/titles, monospace for paths and evidence/code snippets. Selected/focused nodes get a visible glow/border-color change; everything else dims rather than disappearing, so the overall structure stays visible even while focused on one node.

## Deliverable 2: docs/codemap/codemap.json

Exact shape:
```json
{ "generated_at": "", "generated_from_commit": "", "scope": [], "nodes": [], "edges": [], "flows": [] }
```
- node: `id, path, role, entrypoints, tests, constraints, evidence`.
- edge: `from, to, type, evidence`. `type` is ONLY one of: `imports | calls | reads | writes | publishes | subscribes`.
- flow: `trigger, steps, outcome`. Each step references an existing node id.
- Every node/edge carries the matching source path + symbol. No source evidence → `"unknown"`.

## Deliverable 3: docs/codemap/codemap.lock

Parseable JSON recording: current commit, whether the working tree has uncommitted changes, generation time, scanned scope, excluded directories, the fingerprint algorithm name, and a deterministic per-top-level-module fingerprint computed from that module's tracked file paths + current file contents (e.g. sha256 over sorted path+content hashes).

## Mandatory self-validation before reporting done

1. `codemap.json` parses as valid JSON.
2. Every node path exists on disk; every evidence symbol is actually findable in that source (re-check, don't trust memory).
3. Every edge/flow-step references an existing node id.
4. `codemap.html` embeds the exact same nodes/edges/flows as `codemap.json` (no drift).
5. `codemap.lock` matches the actual current commit, working-tree dirty state, and module fingerprints (spot-check by recomputing one by hand).
6. Every evidence-less relationship is explicitly `"unknown"`.

## Final report format

Always end with: files created/modified; stale/changed/removed modules (vs previous lock, or "N/A, first run"); remaining unknowns and why; validation results per check above; the complete diff (unified diff or full contents — HTML may be summarized structurally if very large, but codemap.json/codemap.lock must be shown in full).
