# HoH Development Record

<!-- HoH generated development record; do not edit. -->

**Product:** `input-project`  
**Workflow:** Project Planner → Developer → QA Tester

This README records high-level autonomous development and QA history.

---

## Publication scope

This product history records iteration goals and QA outcomes. Detailed tool, cache, receipt, and staging provenance remains in the private HoH Runtime audit.

The current issue table is generated from the run-local persistent ledger. Per-loop QA findings are historical observations and do not override current issue states. When `hoh.e2e.issue_sync` runs against this repository, the same ledger is mirrored onto GitHub Issues (namespace label `hoh-ledger`): resolved issues close there, and a defect that reappears reopens its GitHub issue with the `regression` label. GitHub is the operator-facing mirror; the run-local ledger remains the source of truth. Earlier runs' issues remain in the repository and are excluded from this run's counts.

---

## Persistent issue ledger

**Repository-wide GitHub issue counts** (last successful observation; all runs and labels, excluding pull requests).

| Field | Value |
| --- | --- |
| Open | 11 |
| Closed | 5 |
| All | 16 |

GitHub Closed includes verified fixes, waived issues and policy-invalidated issues; it is not a product-fix count.

### Current run ledger

| Field | Value |
| --- | --- |
| Active | 0 |
| Verified closed | 0 |
| Policy invalidated | 0 |
| Waived | 0 |
| All in this run | 0 |

The rows below cover this run. Per-loop QA findings are historical observations, not current issue states.

| Issue ID | GitHub | Current status | Resolution / latest defect |
| --- | --- | --- | --- |

### HoH-managed GitHub issues across runs

Snapshot from the last successful issue sync. These counts include earlier runs; unrelated repository issues are outside the HoH namespace.

| Scope | Open | Closed | All |
| --- | --- | --- | --- |
| GitHub HoH namespace | 11 | 5 | 16 |
| Outside this run's table | 11 | 5 | 16 |

Earlier runs' issues retain their own evidence and are not automatically resolved by this run.

| GitHub | Issue ID | GitHub state | Source run |
| --- | --- | --- | --- |
| [#1](https://github.com/Flesymeb/aelors-adventure/issues/1) | `issue:milestone01-camera-environment` | OPEN | `aelors-adventure-astra-high-20261002` |
| [#2](https://github.com/Flesymeb/aelors-adventure/issues/2) | `issue:milestone01-missing-loop` | OPEN | `aelors-adventure-astra-high-20261002` |
| [#3](https://github.com/Flesymeb/aelors-adventure/issues/3) | `issue:r02-actor-animation-falloff` | OPEN | `aelors-adventure-astra-high-20261002` |
| [#4](https://github.com/Flesymeb/aelors-adventure/issues/4) | `tester.mcp_coverage_incomplete` | CLOSED | `aelors-village-sol-local-20261004` |
| [#5](https://github.com/Flesymeb/aelors-adventure/issues/5) | `adjacent-opening-cinematic` | OPEN | `aelors-village-sol-local-20261004` |
| [#6](https://github.com/Flesymeb/aelors-adventure/issues/6) | `camera-lamp-obstruction` | CLOSED | `aelors-village-sol-local-20261004` |
| [#7](https://github.com/Flesymeb/aelors-adventure/issues/7) | `milestone-01-connected-slice-unavailable` | OPEN | `aelors-village-sol-local-20261004` |
| [#8](https://github.com/Flesymeb/aelors-adventure/issues/8) | `r02-input-bindings` | CLOSED | `aelors-village-sol-local-20261004` |
| [#9](https://github.com/Flesymeb/aelors-adventure/issues/9) | `village-grass-import-dependency` | OPEN | `aelors-village-sol-local-20261004` |
| [#10](https://github.com/Flesymeb/aelors-adventure/issues/10) | `milestone-01-demo-overlay-presentation` | OPEN | `aelors-village-sol-local-20261004` |
| [#11](https://github.com/Flesymeb/aelors-adventure/issues/11) | `isha-clothing-deformation` | OPEN | `aelors-village-sol-local-20261004` |
| [#12](https://github.com/Flesymeb/aelors-adventure/issues/12) | `isha-dialogue-finished-presentation` | OPEN | `aelors-village-sol-local-20261004` |
| [#13](https://github.com/Flesymeb/aelors-adventure/issues/13) | `finding-failure-keyboard-navigation` | CLOSED | `aelors-village-sol-local-20261004` |
| [#14](https://github.com/Flesymeb/aelors-adventure/issues/14) | `finding-failure-screen-readability` | CLOSED | `aelors-village-sol-local-20261004` |
| [#15](https://github.com/Flesymeb/aelors-adventure/issues/15) | `finding-adjacent-return-to-title` | OPEN | `aelors-village-sol-local-20261004` |
| [#16](https://github.com/Flesymeb/aelors-adventure/issues/16) | `finding-failure-focus-hover-ambiguity` | OPEN | `aelors-village-sol-local-20261004` |

---

## Loop 09

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-01-6a73d8a4b2b2` | `development_snapshot:attempt-509bfb860486b52bf47be061` | DEVELOPER REPORT READY |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / rpg_template_foundation |
| Objective | Replace the current training enemy and duplicated contact settlement with a dependency-complete, adapted Snaiel combat unit, reachable through existing acquisition and teaching, including counterplay, sword/arrow damage, feedback, one collectible reward and safe death/save recovery. |
| Strategy | `snaiel_live_training_combat_replacement` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 0 |
| Changed paths | 32 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-509bfb860486b52bf47be061` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | UNTESTED |

---

## Current pointers

- Latest candidate: `loop-01-6a73d8a4b2b2`
- Accepted candidate: `none`
- Latest attempted: `loop-01-6a73d8a4b2b2`
- Latest warm start: `none`
- Last published: `loop-01-6a73d8a4b2b2`
- Best verified: `none`
- Generated by the HoH host from immutable run evidence.
