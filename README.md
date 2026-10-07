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
| Open | 24 |
| Closed | 7 |
| All | 31 |

GitHub Closed includes verified fixes, waived issues and policy-invalidated issues; it is not a product-fix count.

### Current run ledger

| Field | Value |
| --- | --- |
| Active | 7 |
| Verified closed | 2 |
| Policy invalidated | 0 |
| Waived | 0 |
| All in this run | 9 |

The rows below cover this run. Per-loop QA findings are historical observations, not current issue states.

| Issue ID | GitHub | Current status | Resolution / latest defect |
| --- | --- | --- | --- |
| `title_entry_adjacent_hud_checkpoint_text` | [#23](https://github.com/Flesymeb/aelors-adventure/issues/23) | OPEN | Adjacent HUD continuity fails: checkpoint code/name and textual life count remain permanently visible. |
| `title_entry_empty_load_focus_clipped` | [#25](https://github.com/Flesymeb/aelors-adventure/issues/25) | CLOSED | Independently verified resolved at loop 2. |
| `title_entry_mute_leaks_world_audio` | [#26](https://github.com/Flesymeb/aelors-adventure/issues/26) | CLOSED | Independently verified resolved at loop 2. |
| `dialogue_portraits_absent` | [#27](https://github.com/Flesymeb/aelors-adventure/issues/27) | OPEN | Adjacent dialogue continuity fails because declared portraits are absent. |
| `hud_h_binding_conflict` | [#28](https://github.com/Flesymeb/aelors-adventure/issues/28) | OPEN | H can be assigned to Roll but is consumed by tracker collapse. |
| `hud_legacy_feedback_integration` | [#29](https://github.com/Flesymeb/aelors-adventure/issues/29) | OPEN | Restoration coverage is complete; distinct first-teaching and first-reward layout variants remain insufficiently evidenced. |
| `player_mcp_npc_parent_error` | [#30](https://github.com/Flesymeb/aelors-adventure/issues/30) | OPEN | Shared controller telemetry breaks when an observer reaches NPC instances. |
| `title_entry_closeout_evidence_missing` | [#24](https://github.com/Flesymeb/aelors-adventure/issues/24) | OPEN | Prior HUD closeout remains unresolved despite completed restoration coverage; broader debt does not expand frozen acceptance. |
| `actor_foundation_evidence_remaining` | [#31](https://github.com/Flesymeb/aelors-adventure/issues/31) | OPEN | RECAPTURE_REQUEST: Deliberate obstacle negotiation remains unverified; prior contact-feedback evidence gaps are retained. |

### HoH-managed GitHub issues across runs

Snapshot from the last successful issue sync. These counts include earlier runs; unrelated repository issues are outside the HoH namespace.

| Scope | Open | Closed | All |
| --- | --- | --- | --- |
| GitHub HoH namespace | 24 | 7 | 31 |
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

## Loop 12

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-03-2137fc261b16` | `development_snapshot:attempt-9bafc597fad86ddb6bf30b85` | FAIL |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / rpg_template_foundation |
| Objective | Complete the frozen RPG actor foundation on candidate c74511592252f547: replace the hand-written training-enemy execution path with a live, dependency-complete Snaiel enemy unit, separate NPC presentation from player control, and repair the assigned input, notification and observation defects without rebuilding the map or advancing unrelated gameplay. |
| Strategy | `complete_snaiel_actor_unit_with_product_owned_adapters` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 41 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-9bafc597fad86ddb6bf30b85` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-03-2137fc261b16` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 3 (2 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `actor_foundation_evidence_remaining` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: Deliberate obstacle negotiation remains unverified; prior contact-feedback evidence gaps are retained. |
| `feedback_layout_evidence_remaining` | MAJOR | INTERNAL | HIGH | Restoration coverage is complete; distinct first-teaching and first-reward layout variants remain insufficiently evidenced. |
| `hud_closeout_evidence_remaining` | MAJOR | INTERNAL | HIGH | Prior HUD closeout remains unresolved despite completed restoration coverage; broader debt does not expand frozen acceptance. |

---

## Loop 11

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-02-c74511592252` | `development_snapshot:attempt-06a91d4e394840c8d3272e32` | FAIL |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / gameplay_hud |
| Objective | Deliver the revised gameplay HUD and quest journal with correct camera/UI input ownership, repair Load focus visibility and global mute propagation, and provide a bounded handoff for independent validation of the unchanged frozen gates. |
| Strategy | `shared_gameplay_interface_with_existing_template_and_state_authority` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 0 |
| Changed paths | 19 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-06a91d4e394840c8d3272e32` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-02-c74511592252` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 5 (1 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `hud_legacy_feedback_integration` | MINOR | DEGRADED | MEDIUM | Retained combat notices expose Q02 and overlap bow ammunition. |
| `hud_h_binding_conflict` | MINOR | DEGRADED | MEDIUM | H can be assigned to Roll but is consumed by tracker collapse. |
| `player_mcp_npc_parent_error` | MINOR | INTERNAL | MEDIUM | Shared controller telemetry breaks when an observer reaches NPC instances. |
| `title_closeout_evidence_remaining` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: Remaining life-history, fault-recovery and camera/modal boundary evidence prevents full HUD closeout. |
| `dialogue_portraits_absent` | MINOR | USER BLOCKING | MEDIUM | Adjacent dialogue continuity fails because declared portraits are absent. |

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

- Latest candidate: `loop-03-2137fc261b16`
- Accepted candidate: `none`
- Latest attempted: `loop-03-2137fc261b16`
- Latest warm start: `loop-03-c74511592252`
- Last published: `loop-03-2137fc261b16`
- Best verified: `loop-03-2137fc261b16`
- Generated by the HoH host from immutable run evidence.
