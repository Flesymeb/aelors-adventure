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
| Active | 8 |
| Verified closed | 4 |
| Policy invalidated | 1 |
| Waived | 0 |
| All in this run | 13 |

The rows below cover this run. Per-loop QA findings are historical observations, not current issue states.

| Issue ID | GitHub | Current status | Resolution / latest defect |
| --- | --- | --- | --- |
| `adjacent-opening-cinematic` | [#5](https://github.com/Flesymeb/aelors-adventure/issues/5) | OPEN | Next-phase opening cinematic continuity remains absent. |
| `camera-lamp-obstruction` | [#6](https://github.com/Flesymeb/aelors-adventure/issues/6) | CLOSED | Independently verified resolved at loop 4. |
| `r02-input-bindings` | [#8](https://github.com/Flesymeb/aelors-adventure/issues/8) | CLOSED | Independently verified resolved at loop 3. |
| `tester.mcp_coverage_incomplete` | [#4](https://github.com/Flesymeb/aelors-adventure/issues/4) | POLICY_INVALIDATED | Policy-invalidated; this closure does not assert a product repair. |
| `village-grass-import-dependency` | [#9](https://github.com/Flesymeb/aelors-adventure/issues/9) | OPEN | The authored-village grass texture dependency remains broken. |
| `milestone-01-connected-slice-unavailable` | [#7](https://github.com/Flesymeb/aelors-adventure/issues/7) | OPEN | Full connected-slice acceptance remains unverified; fresh sword acquisition and recovery now work. |
| `milestone-01-demo-overlay-presentation` | [#10](https://github.com/Flesymeb/aelors-adventure/issues/10) | OPEN | The settings/save surface retains unfinished demo presentation. |
| `isha-clothing-deformation` | [#11](https://github.com/Flesymeb/aelors-adventure/issues/11) | OPEN | Isha's shoulder-to-sleeve bands remain visible. |
| `isha-dialogue-finished-presentation` | [#12](https://github.com/Flesymeb/aelors-adventure/issues/12) | BLOCKED | Required dialogue portraits remain absent. |
| `finding-failure-keyboard-navigation` | [#13](https://github.com/Flesymeb/aelors-adventure/issues/13) | CLOSED | Independently verified resolved at loop 7. |
| `finding-failure-screen-readability` | [#14](https://github.com/Flesymeb/aelors-adventure/issues/14) | CLOSED | Independently verified resolved at loop 7. |
| `finding-adjacent-return-to-title` | [#15](https://github.com/Flesymeb/aelors-adventure/issues/15) | OPEN | Return to Title remains a message-only placeholder outside this increment. |
| `finding-failure-focus-hover-ambiguity` | [#16](https://github.com/Flesymeb/aelors-adventure/issues/16) | OPEN | Hovered and keyboard-focused recovery buttons look identical. |

### HoH-managed GitHub issues across runs

Snapshot from the last successful issue sync. These counts include earlier runs; unrelated repository issues are outside the HoH namespace.

| Scope | Open | Closed | All |
| --- | --- | --- | --- |
| GitHub HoH namespace | 11 | 5 | 16 |
| Outside this run's table | 3 | 0 | 3 |

Earlier runs' issues retain their own evidence and are not automatically resolved by this run.

| GitHub | Issue ID | GitHub state | Source run |
| --- | --- | --- | --- |
| [#1](https://github.com/Flesymeb/aelors-adventure/issues/1) | `issue:milestone01-camera-environment` | OPEN | `aelors-adventure-astra-high-20261002` |
| [#2](https://github.com/Flesymeb/aelors-adventure/issues/2) | `issue:milestone01-missing-loop` | OPEN | `aelors-adventure-astra-high-20261002` |
| [#3](https://github.com/Flesymeb/aelors-adventure/issues/3) | `issue:r02-actor-animation-falloff` | OPEN | `aelors-adventure-astra-high-20261002` |

---

## Loop 08

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-08-cdda87c96e1a` | `development_snapshot:attempt-90ea453fbc153d95748ce383` | DEVELOPER REPORT READY |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_02 |
| Objective | Connect the existing archery component to Ronen's ordinary bow acquisition and repeatable charged-shot lesson, including truthful contact, ammunition, feedback and saved continuity, without declaring the larger connected slice complete. |
| Strategy | `connect-existing-archery-to-ronen-progression` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 0 |
| Changed paths | 12 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-90ea453fbc153d95748ce383` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | UNTESTED |

---

## Loop 07

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-07-b224d335aee8` | `development_snapshot:attempt-517299cab1050bde6634c836` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_02 |
| Objective | Restore the ordinary Game Over-to-New Game transition so the player can deliberately begin a clean, grounded, unarmed adventure through readable keyboard controls, enabling independent fresh sword-acquisition replay. |
| Strategy | `failure-modal-lifecycle-to-fresh-sword-replay` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 0 |
| Changed paths | 3 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-517299cab1050bde6634c836` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-07-b224d335aee8` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 5 (3 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `isha-dialogue-finished-presentation` | MAJOR | USER BLOCKING | HIGH | Required dialogue portraits remain absent. |
| `isha-clothing-deformation` | MAJOR | DEGRADED | HIGH | Isha's shoulder-to-sleeve bands remain visible. |
| `finding-connected-slice-unavailable` | MAJOR | USER BLOCKING | HIGH | Full connected-slice acceptance remains unverified; fresh sword acquisition and recovery now work. |
| `finding-failure-focus-hover-ambiguity` | MINOR | DEGRADED | MEDIUM | Hovered and keyboard-focused recovery buttons look identical. |
| `finding-adjacent-return-to-title` | MINOR | USER BLOCKING | HIGH | Return to Title remains a message-only placeholder outside this increment. |

---

## Loop 06

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-06-58691b2c8b7f` | `development_snapshot:attempt-b73d9d4b65b509ed3d101857` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_02 |
| Objective | Make the displayed Hers objective lead to playable sword acquisition, truthful practice and a first isolated combat encounter with coherent reward, checkpoint recovery and saved progress. |
| Strategy | `hers-sword-module-authoritative-combat-and-recovery` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 0 |
| Changed paths | 26 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-b73d9d4b65b509ed3d101857` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-06-58691b2c8b7f` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 6 (4 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `isha-dialogue-finished-presentation` | MAJOR | USER BLOCKING | HIGH | Required dialogue portraits remain absent; the prior issue cannot close. |
| `isha-clothing-deformation` | MAJOR | DEGRADED | HIGH | Isha's shoulder-to-sleeve bands remain visible in current native views. |
| `milestone-01-demo-overlay-presentation` | MINOR | DEGRADED | MEDIUM | The settings/save surface retains unfinished demo presentation. |
| `finding-failure-keyboard-navigation` | MAJOR | DEGRADED | HIGH | Game Over exposes enabled recovery buttons without a usable observed keyboard route. |
| `finding-failure-screen-readability` | MINOR | DEGRADED | MEDIUM | Game Over instructions and choices have poor contrast. |
| `finding-connected-slice-unavailable` | MAJOR | USER BLOCKING | HIGH | Connected-slice acceptance remains unverified despite working monster damage and checkpoint recovery. |

---

## Loop 05

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-05-ab819162d75d` | `development_snapshot:attempt-34fd62398287690f6ddff48b` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_02 |
| Objective | Finish the existing ordinary Isha opening conversation's portraits, reading surface and clothed idle actor while preserving its verified behavior and exposing the actual boundary of the still-incomplete connected slice. |
| Strategy | `isha-source-binding-comparison-and-ordinary-reachability` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | BLOCKED |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 0 |
| Changed paths | 13 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-34fd62398287690f6ddff48b` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-05-ab819162d75d` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 4 (3 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `isha-dialogue-finished-presentation` | MAJOR | USER BLOCKING | HIGH | Required dual portraits remain absent, and 200% last-choice scrolling hides the speaker name. |
| `isha-clothing-deformation` | MAJOR | DEGRADED | HIGH | Isha's revised clothing still has conspicuous shoulder-to-sleeve bands during idle. |
| `finding-connected-slice-unavailable` | MAJOR | USER BLOCKING | HIGH | The connected-slice closure recipe remains unavailable beyond Isha/Q01. |
| `milestone-01-demo-overlay-presentation` | MINOR | DEGRADED | MEDIUM | The nested settings/save surface retains unfinished demo presentation. |

---

## Loop 04

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-04-f807d73b8dd7` | `development_snapshot:attempt-a928f5bad736ac033b08560c` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_02 |
| Objective | Let an unarmed player approach a readable Isha, experience the themed D01–D03 rescue-request conversation, accept Q01 once and return safely to exploration; repair the nearby lamp obstruction as its necessary camera dependency. |
| Strategy | `isha-opening-module-with-lamp-source-isolation` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 0 |
| Changed paths | 445 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-a928f5bad736ac033b08560c` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-04-f807d73b8dd7` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 4 (3 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `isha-dialogue-finished-presentation` | MAJOR | DEGRADED | HIGH | The opening conversation lacks both required character portraits and finished illustrated framing. |
| `isha-clothing-deformation` | MAJOR | DEGRADED | HIGH | Isha's adapted idle pose deforms clothing and exposes torso regions through separated garment surfaces. |
| `milestone-01-demo-overlay-presentation` | MINOR | DEGRADED | MEDIUM | Gameplay diagnostics are hidden at boot, but the owning nested settings/save surface remains unfinished. |
| `finding-connected-slice-unavailable` | MAJOR | USER BLOCKING | HIGH | The existing connected-slice closure recipe remains unavailable despite the newly working opening conversation and save recovery. |

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

- Latest candidate: `loop-08-cdda87c96e1a`
- Accepted candidate: `none`
- Latest attempted: `loop-08-cdda87c96e1a`
- Latest warm start: `loop-08-b224d335aee8`
- Last published: `loop-08-cdda87c96e1a`
- Best verified: `loop-07-b224d335aee8`
- Generated by the HoH host from immutable run evidence.
