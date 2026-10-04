# HoH Development Record

<!-- HoH generated development record; do not edit. -->

**Product:** `input-project`  
**Workflow:** Project Planner → Developer → QA Tester

This README records high-level autonomous development and QA history.

---

## Publication scope

This product history records iteration goals and QA outcomes. Detailed tool, cache, receipt, and staging provenance remains in the private HoH Runtime audit.

This README is the canonical issue ledger for this product: the host-derived persistent ledger table and per-loop QA findings below are the authoritative issue record. When `hoh.e2e.issue_sync` runs against this repository, the same ledger is mirrored onto GitHub Issues (namespace label `hoh-ledger`): resolved issues close there, and a defect that reappears reopens its GitHub issue with the `regression` label. GitHub is the operator-facing mirror; this file and the run-local ledger remain the source of truth.

---

## Persistent issue ledger

| Field | Value |
| --- | --- |
| Open | 5 |
| Closed | 2 |
| All | 7 |

---

## Loop 03

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-03-895de5d3f855` | `development_snapshot:attempt-a380265e4f02f5e9099ffa56` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_01 |
| Objective | Deliver adjustable locomotion controls whose effective bindings and prompts agree, beginning with default B roll and reserved F ownership, while preserving the existing unarmed village traversal slice. |
| Strategy | `repair-adjustable-control-ownership` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 3 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-a380265e4f02f5e9099ffa56` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-03-895de5d3f855` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 4 (1 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `finding-connected-slice-unavailable` | MAJOR | USER BLOCKING | HIGH | The mandatory connected-slice closure recipe remains unavailable. |
| `milestone-01-demo-overlay-presentation` | MINOR | DEGRADED | MEDIUM | Default gameplay still exposes plain demo controls and internal status cards. |
| `finding-village-grass-import-dependency` | MINOR | DEGRADED | MEDIUM | The authored-village grass texture dependency remains broken. |
| `finding-adjacent-opening-cinematic` | MINOR | DEGRADED | MEDIUM | Next-phase opening cinematic continuity remains absent. |

---

## Loop 02

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-02-17d8efa129da` | `development_snapshot:attempt-9b963f4ee27ecfdecb381c76` | FAIL |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_01 |
| Objective | Repair default shoulder-switch ownership in the frozen loop-02 candidate: Tab switches shoulders during ordinary unarmed exploration, E stops switching shoulders, and the visible shoulder prompt reflects Tab. |
| Strategy | `repair-default-shoulder-input-ownership` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 2 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-9b963f4ee27ecfdecb381c76` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-02-17d8efa129da` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 6 (3 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `finding-r02-input-bindings` | MAJOR | DEGRADED | HIGH | r02-input-bindings remains open: Tab/E is repaired, but B/F roll ownership and configurable bindings are unfinished. |
| `finding-connected-slice-unavailable` | MAJOR | USER BLOCKING | HIGH | The mandatory connected-slice closure recipe remains unavailable; milestone acceptance is insufficiently evidenced. |
| `milestone-01-demo-overlay-presentation` | MINOR | DEGRADED | MEDIUM | The visible slice interface still uses plain demo control/status cards. |
| `finding-adjacent-opening-cinematic` | MINOR | DEGRADED | MEDIUM | Next-phase opening cinematic continuity remains absent. |
| `finding-village-grass-import-dependency` | MINOR | DEGRADED | MEDIUM | The existing authored-village grass texture import dependency remains broken. |
| `tester.mcp_coverage_incomplete` | MAJOR | unlabelled | unlabelled | Tester did not complete every required live MCP, source, state, log, and screenshot probe after bounded same-session corrections. |

---

## Loop 01

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-01-a800549cea91` | `development_snapshot:attempt-614ee9905c0fa7023b86ad55` | FAIL |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_01 |
| Objective | Make Aelor's fresh unarmed idle-to-walk transition usable on the existing authored village terrain, using the selected complete Ranger and animation bindings, while keeping full R02 acceptance pending until independently demonstrated. |
| Strategy | `reuse-intact-village-unarmed-idle-walk` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 2 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-614ee9905c0fa7023b86ad55` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-01-a800549cea91` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 6 (3 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `r02-input-bindings` | MAJOR | DEGRADED | HIGH | Required shoulder and roll bindings are inactive; demo controls occupy reserved product keys. |
| `milestone-01-connected-slice-unavailable` | MAJOR | USER BLOCKING | HIGH | Full milestone acceptance is blocked: only the exploration increment is reachable. |
| `camera-lamp-obstruction` | MINOR | DEGRADED | MEDIUM | A nearby lamp obstructs the Ranger in the shipped camera on a reachable route. |
| `village-grass-import-dependency` | MINOR | INTERNAL | MEDIUM | The authored village retains a missing grass texture import dependency. |
| `adjacent-opening-cinematic` | MINOR | USER BLOCKING | MEDIUM | Next-phase continuity gap: the declared opening cinematic has no reachable implementation. |
| `tester.mcp_coverage_incomplete` | MAJOR | unlabelled | unlabelled | Tester did not complete every required live MCP, source, state, log, and screenshot probe after bounded same-session corrections. |

---

## Current pointers

- Latest candidate: `loop-03-895de5d3f855`
- Accepted candidate: `none`
- Latest attempted: `loop-03-895de5d3f855`
- Latest warm start: `loop-03-17d8efa129da`
- Last published: `loop-03-895de5d3f855`
- Best verified: `loop-03-895de5d3f855`
- Generated by the HoH host from immutable run evidence.
