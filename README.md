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
| Open | 21 |
| Closed | 5 |
| All | 26 |

GitHub Closed includes verified fixes, waived issues and policy-invalidated issues; it is not a product-fix count.

### Current run ledger

| Field | Value |
| --- | --- |
| Active | 4 |
| Verified closed | 0 |
| Policy invalidated | 0 |
| Waived | 0 |
| All in this run | 4 |

The rows below cover this run. Per-loop QA findings are historical observations, not current issue states.

| Issue ID | GitHub | Current status | Resolution / latest defect |
| --- | --- | --- | --- |
| `title_entry_adjacent_hud_checkpoint_text` | [#23](https://github.com/Flesymeb/aelors-adventure/issues/23) | OPEN | Adjacent HUD continuity fails: checkpoint code/name and textual life count remain permanently visible. |
| `title_entry_closeout_evidence_missing` | [#24](https://github.com/Flesymeb/aelors-adventure/issues/24) | OPEN | RECAPTURE_REQUEST: Complete the missing resolution, pointer and fault-recovery closeout evidence using authorized Host controls. |
| `title_entry_empty_load_focus_clipped` | [#25](https://github.com/Flesymeb/aelors-adventure/issues/25) | OPEN | Empty-slot Load hides the initially focused Return button at 200% Chinese text. |
| `title_entry_mute_leaks_world_audio` | [#26](https://github.com/Flesymeb/aelors-adventure/issues/26) | OPEN | The title mute preference silences menu cues but leaves gameplay forest ambience audible. |

### HoH-managed GitHub issues across runs

Snapshot from the last successful issue sync. These counts include earlier runs; unrelated repository issues are outside the HoH namespace.

| Scope | Open | Closed | All |
| --- | --- | --- | --- |
| GitHub HoH namespace | 21 | 5 | 26 |
| Outside this run's table | 17 | 5 | 22 |

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
| [#17](https://github.com/Flesymeb/aelors-adventure/issues/17) | `rpg.combat.audio_quality_unverified` | OPEN | `aelors-template-sol-local-20261006` |
| [#18](https://github.com/Flesymeb/aelors-adventure/issues/18) | `rpg.continuity.return_to_title_stub` | OPEN | `aelors-template-sol-local-20261006` |
| [#19](https://github.com/Flesymeb/aelors-adventure/issues/19) | `rpg.dialogue.portraits_unbound` | OPEN | `aelors-template-sol-local-20261006` |
| [#20](https://github.com/Flesymeb/aelors-adventure/issues/20) | `rpg.pause.inherited_control_inventory` | OPEN | `aelors-template-sol-local-20261006` |
| [#21](https://github.com/Flesymeb/aelors-adventure/issues/21) | `rpg.recovery.ammunition_not_restored` | OPEN | `aelors-template-sol-local-20261006` |
| [#22](https://github.com/Flesymeb/aelors-adventure/issues/22) | `rpg.village.performance_below_target` | OPEN | `aelors-template-sol-local-20261006` |

---

## Loop 10

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-01-bc472e88fd14` | `development_snapshot:attempt-8dd74e022f602277e93af594` | FAIL |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / game_title_entry |
| Objective | Deliver a finished, state-bound title screen and ordinary boot-to-game, load, settings, return-to-title and exit journeys for 艾洛的冒险, using the existing playable world and authoritative save interfaces. |
| Strategy | `title_entry_with_template_backed_navigation_and_existing_save_authority` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 64 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-8dd74e022f602277e93af594` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-01-bc472e88fd14` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 4 (3 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `title_entry_empty_load_focus_clipped` | MAJOR | DEGRADED | HIGH | Empty-slot Load hides the initially focused Return button at 200% Chinese text. |
| `title_entry_mute_leaks_world_audio` | MAJOR | DEGRADED | HIGH | The title mute preference silences menu cues but leaves gameplay forest ambience audible. |
| `title_entry_closeout_evidence_missing` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: Complete the missing resolution, pointer and fault-recovery closeout evidence using authorized Host controls. |
| `title_entry_adjacent_hud_checkpoint_text` | MINOR | DEGRADED | MEDIUM | Adjacent HUD continuity fails: checkpoint code/name and textual life count remain permanently visible. |

---

## Current pointers

- Latest candidate: `loop-01-bc472e88fd14`
- Accepted candidate: `none`
- Latest attempted: `loop-01-bc472e88fd14`
- Latest warm start: `none`
- Last published: `loop-01-bc472e88fd14`
- Best verified: `loop-01-bc472e88fd14`
- Generated by the HoH host from immutable run evidence.
