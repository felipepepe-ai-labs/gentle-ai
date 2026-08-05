# Community Tool Catalog Specification

## Purpose

Define table-driven registration and dispatch for community tools (install, status, sync, uninstall), replacing single-tool ID hardcoding.

## Requirements

### Requirement: Table-driven dispatch

The system MUST register community tools in a table keyed by tool ID rather than comparing against a single hardcoded ID. Install, `DetectStatus`, sync, and uninstall MUST dispatch through this table for every registered tool.

#### Scenario: New tool needs no hardcoded branch

- GIVEN a new community tool definition is added to the table
- WHEN Install, DetectStatus, sync, or uninstall run
- THEN the new tool is dispatched without adding an `if def.ID != X` branch

#### Scenario: CodeGraph unaffected by the refactor

- GIVEN the table-driven refactor is applied
- WHEN CodeGraph is selected, installed, or uninstalled
- THEN its existing behavior and tests remain unchanged

### Requirement: Catalog-driven TUI listing

The Community Tools TUI screen MUST list every tool present in the registry via `Definitions()`.

#### Scenario: Registered tool appears in the TUI

- GIVEN a tool is present in the registry
- WHEN the Community Tools screen renders
- THEN the tool is listed as selectable

#### Scenario: Unregistered tool is absent

- GIVEN a tool ID has no registry entry
- WHEN the Community Tools screen renders
- THEN that tool does not appear
