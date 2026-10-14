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
| Open | 73 |
| Closed | 38 |
| All | 111 |

GitHub Closed includes verified fixes, waived issues and policy-invalidated issues; it is not a product-fix count.

### Current run ledger

| Field | Value |
| --- | --- |
| Active | 56 |
| Verified closed | 29 |
| Policy invalidated | 5 |
| Waived | 0 |
| All in this run | 90 |

The rows below cover this run. Per-loop QA findings are historical observations, not current issue states.

| Issue ID | GitHub | Current status | Resolution / latest defect |
| --- | --- | --- | --- |
| `title_entry_adjacent_hud_checkpoint_text` | [#23](https://github.com/Flesymeb/aelors-adventure/issues/23) | OPEN | Adjacent HUD continuity fails: checkpoint code/name and textual life count remain permanently visible. |
| `title_entry_empty_load_focus_clipped` | [#25](https://github.com/Flesymeb/aelors-adventure/issues/25) | CLOSED | Independently verified resolved at loop 2. |
| `title_entry_mute_leaks_world_audio` | [#26](https://github.com/Flesymeb/aelors-adventure/issues/26) | CLOSED | Independently verified resolved at loop 2. |
| `dialogue_portraits_absent` | [#27](https://github.com/Flesymeb/aelors-adventure/issues/27) | CLOSED | Independently verified resolved at loop 22. |
| `hud_h_binding_conflict` | [#28](https://github.com/Flesymeb/aelors-adventure/issues/28) | CLOSED | Independently verified resolved at loop 3. |
| `hud_legacy_feedback_integration` | [#29](https://github.com/Flesymeb/aelors-adventure/issues/29) | CLOSED | Independently verified resolved at loop 17. |
| `player_mcp_npc_parent_error` | [#30](https://github.com/Flesymeb/aelors-adventure/issues/30) | CLOSED | Independently verified resolved at loop 3. |
| `title_entry_closeout_evidence_missing` | [#24](https://github.com/Flesymeb/aelors-adventure/issues/24) | CLOSED | Independently verified resolved at loop 18. |
| `actor_foundation_evidence_remaining` | [#31](https://github.com/Flesymeb/aelors-adventure/issues/31) | CLOSED | Independently verified resolved at loop 11. |
| `hud_tracker_retained_height` | [#32](https://github.com/Flesymeb/aelors-adventure/issues/32) | CLOSED | Independently verified resolved at loop 10. |
| `settings_focus_feedback_hidden` | [#35](https://github.com/Flesymeb/aelors-adventure/issues/35) | CLOSED | Independently verified resolved at loop 5. |
| `pause_active_world_validation_incomplete` | [#33](https://github.com/Flesymeb/aelors-adventure/issues/33) | CLOSED | Independently verified resolved at loop 17. |
| `settings_effect_validation_incomplete` | [#34](https://github.com/Flesymeb/aelors-adventure/issues/34) | OPEN | This client cannot provide the required independent listening evidence. |
| `default_roll_opens_inventory` | [#37](https://github.com/Flesymeb/aelors-adventure/issues/37) | CLOSED | Independently verified resolved at loop 8. |
| `fps.runtime.candidate-error-19b1aab47037` | [#38](https://github.com/Flesymeb/aelors-adventure/issues/38) | POLICY_INVALIDATED | Policy-invalidated; this closure does not assert a product repair. |
| `fps.runtime.candidate-error-9d723d49756b` | [#39](https://github.com/Flesymeb/aelors-adventure/issues/39) | POLICY_INVALIDATED | Policy-invalidated; this closure does not assert a product repair. |
| `fps.runtime.candidate-error-d6ccfb2695ca` | [#40](https://github.com/Flesymeb/aelors-adventure/issues/40) | POLICY_INVALIDATED | Policy-invalidated; this closure does not assert a product repair. |
| `fps.runtime.candidate-error-fbd2eca17385` | [#41](https://github.com/Flesymeb/aelors-adventure/issues/41) | CLOSED | Independently verified resolved at loop 7. |
| `opening_acceptance_evidence_incomplete` | [#36](https://github.com/Flesymeb/aelors-adventure/issues/36) | OPEN | Qualified unfinished-opening Continue remains unobserved. |
| `shortcut_panel_narrow_ownership_states` | [#42](https://github.com/Flesymeb/aelors-adventure/issues/42) | CLOSED | Independently verified resolved at loop 12. |
| `vitals_retains_enlarged_geometry` | [#43](https://github.com/Flesymeb/aelors-adventure/issues/43) | CLOSED | Independently verified resolved at loop 13. |
| `forest-review-evidence-incomplete` | [#44](https://github.com/Flesymeb/aelors-adventure/issues/44) | OPEN | untitled issue |
| `fps.runtime.candidate-error-ea18d19a2edb` | [#46](https://github.com/Flesymeb/aelors-adventure/issues/46) | CLOSED | Independently verified resolved at loop 9. |
| `lightning-negative-case-unobserved` | [#45](https://github.com/Flesymeb/aelors-adventure/issues/45) | OPEN | untitled issue |
| `r02_runtime_boundaries_unverified` | [#47](https://github.com/Flesymeb/aelors-adventure/issues/47) | OPEN | untitled issue |
| `milestone_acceptance_evidence_missing` | [#48](https://github.com/Flesymeb/aelors-adventure/issues/48) | CLOSED | Independently verified resolved at loop 34. |
| `next_chapter_boundary_unverified` | [#49](https://github.com/Flesymeb/aelors-adventure/issues/49) | OPEN | untitled issue |
| `initial_encounter_audio_quality_unverified` | [#50](https://github.com/Flesymeb/aelors-adventure/issues/50) | OPEN | untitled issue |
| `initial_enemy_obstacle_clearance_unverified` | [#51](https://github.com/Flesymeb/aelors-adventure/issues/51) | OPEN | untitled issue |
| `practice_target_foreground_marker_overlap` | [#53](https://github.com/Flesymeb/aelors-adventure/issues/53) | OPEN | Adjacent presentation continuity fails: the foreground practice label overlaps the player. |
| `vitals_pending_content_unobserved` | [#52](https://github.com/Flesymeb/aelors-adventure/issues/52) | OPEN | untitled issue |
| `full_r01_acceptance_unassessed` | [#54](https://github.com/Flesymeb/aelors-adventure/issues/54) | OPEN | untitled issue |
| `continued_dialogue_camera_inside_player` | [#55](https://github.com/Flesymeb/aelors-adventure/issues/55) | OPEN | Restored unfinished dialogue still freezes the camera inside the player. |
| `fps.runtime.candidate-error-0d66533e4786` | [#56](https://github.com/Flesymeb/aelors-adventure/issues/56) | CLOSED | Independently verified resolved at loop 20. |
| `fps.runtime.candidate-error-7766310b3778` | [#57](https://github.com/Flesymeb/aelors-adventure/issues/57) | POLICY_INVALIDATED | Policy-invalidated; this closure does not assert a product repair. |
| `restored_briefing_camera_clipping` | [#59](https://github.com/Flesymeb/aelors-adventure/issues/59) | CLOSED | Independently verified resolved at loop 22. |
| `tester.mcp_coverage_incomplete` | [#4](https://github.com/Flesymeb/aelors-adventure/issues/4) | POLICY_INVALIDATED | Policy-invalidated; this closure does not assert a product repair. |
| `hers_portrait_continuity_missing` | [#61](https://github.com/Flesymeb/aelors-adventure/issues/61) | OPEN | Committed coach acquisition cannot be verified through Continue. |
| `initialization_observation_nil_access` | [#62](https://github.com/Flesymeb/aelors-adventure/issues/62) | CLOSED | Independently verified resolved at loop 25. |
| `practice_obstruction_movement_trap` | [#63](https://github.com/Flesymeb/aelors-adventure/issues/63) | CLOSED | Independently verified resolved at loop 23. |
| `reference_adoption_unverified` | [#58](https://github.com/Flesymeb/aelors-adventure/issues/58) | OPEN | Exact E02 contact and both live E03 binding qualifications remain unresolved despite supported local attribution and read-only observation code. |
| `full_acceptance_closeout_missing` | [#60](https://github.com/Flesymeb/aelors-adventure/issues/60) | OPEN | Partial route observations do not establish complete milestone acceptance. |
| `dynamic_encounter_matrix_incomplete` | [#64](https://github.com/Flesymeb/aelors-adventure/issues/64) | OPEN | Both authored-obstruction outcomes remain unverified despite working local revelation and contact. |
| `retained_texture_dependencies_missing` | [#66](https://github.com/Flesymeb/aelors-adventure/issues/66) | OPEN | Mandatory retained-grass closure remains insufficiently evidenced. |
| `guard_closeout_evidence_incomplete` | [#65](https://github.com/Flesymeb/aelors-adventure/issues/65) | CLOSED | Independently verified resolved at loop 29. |
| `pillar_approach_camera_occluded` | [#67](https://github.com/Flesymeb/aelors-adventure/issues/67) | REGRESSED | RECAPTURE_REQUEST: GAME_JOURNEY:r19-earned-farewell-to-pillar-approach |
| `fps.runtime.candidate-error-3c0e1afbfbb2` | [#69](https://github.com/Flesymeb/aelors-adventure/issues/69) | CLOSED | Independently verified resolved at loop 28. |
| `earned_travel_matrix_unverified` | [#68](https://github.com/Flesymeb/aelors-adventure/issues/68) | OPEN | untitled issue |
| `earned_departure_unverified` | [#70](https://github.com/Flesymeb/aelors-adventure/issues/70) | BLOCKED | RECAPTURE_REQUEST: GAME_JOURNEY:r19-earned-departure-skip-boundary |
| `journey_manifest_empty_input` | [#71](https://github.com/Flesymeb/aelors-adventure/issues/71) | CLOSED | Independently verified resolved at loop 33. |
| `qa.e01-ordinary-reward-gap` | [#72](https://github.com/Flesymeb/aelors-adventure/issues/72) | CLOSED | Independently verified resolved at loop 34. |
| `qa.lightning-ranged-hurt-callback` | [#74](https://github.com/Flesymeb/aelors-adventure/issues/74) | OPEN | Earned E02/E04 combat remains unqualified despite current CH01 lightning observations. |
| `qa.e02-victory-unobserved` | [#73](https://github.com/Flesymeb/aelors-adventure/issues/73) | OPEN | untitled issue |
| `qa.full-closeout-incomplete` | [#75](https://github.com/Flesymeb/aelors-adventure/issues/75) | OPEN | untitled issue |
| `qa.later-rescue-route-continuity` | [#76](https://github.com/Flesymeb/aelors-adventure/issues/76) | OPEN | The existing later rescue-route issue cannot be closed from entrance-fixture evidence. |
| `qa.mf01-earned-path-unverified` | [#77](https://github.com/Flesymeb/aelors-adventure/issues/77) | BLOCKED | MF01 earning, committed Continue and its information/scale matrix remain unverified. |
| `qa.e02-lightning-evidence-gap` | [#78](https://github.com/Flesymeb/aelors-adventure/issues/78) | OPEN | untitled issue |
| `qa.full-milestone-evidence-gap` | [#79](https://github.com/Flesymeb/aelors-adventure/issues/79) | OPEN | untitled issue |
| `qa.channel-threat-label-overlap` | [#80](https://github.com/Flesymeb/aelors-adventure/issues/80) | OPEN | The original crowded CH01 defect was not independently qualified or reproduced. |
| `fps.runtime.candidate-error-3917fc09324e` | [#82](https://github.com/Flesymeb/aelors-adventure/issues/82) | CLOSED | Independently verified resolved at loop 42. |
| `qa.e04-supply-earned-gap` | [#81](https://github.com/Flesymeb/aelors-adventure/issues/81) | OPEN | The E04 recovery-supply condition remains unobserved after ordinary earning. |
| `qa.training-label-dialogue-obstruction` | [#83](https://github.com/Flesymeb/aelors-adventure/issues/83) | OPEN | Training-label obstruction and final cue recovery remain unqualified. |
| `ss-ln01-r13` | [#84](https://github.com/Flesymeb/aelors-adventure/issues/84) | OPEN | untitled issue |
| `ss-ln01-r21` | [#85](https://github.com/Flesymeb/aelors-adventure/issues/85) | OPEN | untitled issue |
| `tomb_entry_acceptance_unverified` | [#86](https://github.com/Flesymeb/aelors-adventure/issues/86) | OPEN | Prepared arena traversal does not qualify earned tomb entry. |
| `qa.case-finalization-unavailable` | [#89](https://github.com/Flesymeb/aelors-adventure/issues/89) | CLOSED | Independently verified resolved at loop 53. |
| `warden-acceptance-unverified` | [#87](https://github.com/Flesymeb/aelors-adventure/issues/87) | OPEN | untitled issue |
| `qa.aerial-validation-gap` | [#88](https://github.com/Flesymeb/aelors-adventure/issues/88) | OPEN | untitled issue |
| `qa.independent-lifecycle-selection-gap` | [#90](https://github.com/Flesymeb/aelors-adventure/issues/90) | CLOSED | Independently verified resolved at loop 48. |
| `qa.warden-counterplay-evidence-gap` | [#91](https://github.com/Flesymeb/aelors-adventure/issues/91) | OPEN | untitled issue |
| `finisher-obstruction-unverified` | [#92](https://github.com/Flesymeb/aelors-adventure/issues/92) | OPEN | untitled issue |
| `grounded-release-deadline-unverified` | [#93](https://github.com/Flesymeb/aelors-adventure/issues/93) | OPEN | untitled issue |
| `veyne-phase-camera-crop` | [#95](https://github.com/Flesymeb/aelors-adventure/issues/95) | OPEN | The moved-Veyne second-phase skip remains unverified. |
| `qa.veyne-acceptance-gap` | [#94](https://github.com/Flesymeb/aelors-adventure/issues/94) | OPEN | untitled issue |
| `veyne-arena-foreground-fragments` | [#96](https://github.com/Flesymeb/aelors-adventure/issues/96) | OPEN | The shipped dive camera crops Veyne and loses the player and landing area. |
| `veyne-dive-warning-drifts` | [#97](https://github.com/Flesymeb/aelors-adventure/issues/97) | OPEN | Fixed flight samples do not establish complete dive-warning acceptance; retained camera coverage also shows partial visibility. |
| `veyne-effects-obscure-combat` | [#99](https://github.com/Flesymeb/aelors-adventure/issues/99) | OPEN | Breath and beam readability and preserved contact behavior remain incompletely verified. |
| `veyne-dragon-validation-incomplete` | [#98](https://github.com/Flesymeb/aelors-adventure/issues/98) | OPEN | untitled issue |
| `attack-lifecycle-retest-incomplete` | [#100](https://github.com/Flesymeb/aelors-adventure/issues/100) | OPEN | untitled issue |
| `qa.e02-visual-coherence` | [#102](https://github.com/Flesymeb/aelors-adventure/issues/102) | CLOSED | Independently verified resolved at loop 54. |
| `qa.e02-local-coverage-gap` | [#101](https://github.com/Flesymeb/aelors-adventure/issues/101) | OPEN | Complete E02 search termination and recovery acceptance remains unverified. |
| `e02-lifecycle-qualification-gap` | [#103](https://github.com/Flesymeb/aelors-adventure/issues/103) | OPEN | untitled issue |
| `e02-cover-contact-gap` | [#104](https://github.com/Flesymeb/aelors-adventure/issues/104) | OPEN | untitled issue |
| `native_source_payload_gap` | [#105](https://github.com/Flesymeb/aelors-adventure/issues/105) | OPEN | untitled issue |
| `journey-loader-gap` | [#108](https://github.com/Flesymeb/aelors-adventure/issues/108) | OPEN | Complete journey-loader validation could not be independently obtained. |
| `journey-validation-gap` | [#106](https://github.com/Flesymeb/aelors-adventure/issues/106) | OPEN | untitled issue |
| `native-source-review-gap` | [#109](https://github.com/Flesymeb/aelors-adventure/issues/109) | OPEN | Actual canonical source declarations were reviewed; native implementation-payload availability remains unresolved. |
| `arena-route-coverage-gap` | [#110](https://github.com/Flesymeb/aelors-adventure/issues/110) | OPEN | Arena traversal is supported locally; complete adjacent-route acceptance remains unverified. |
| `earned-travel-gap` | [#107](https://github.com/Flesymeb/aelors-adventure/issues/107) | OPEN | untitled issue |
| `ordinary-route-recapture` | [#111](https://github.com/Flesymeb/aelors-adventure/issues/111) | OPEN | RECAPTURE_REQUEST: GAME_JOURNEY:r01-earned-mf01-e03-reveal-recognition |

### HoH-managed GitHub issues across runs

Snapshot from the last successful issue sync. These counts include earlier runs; unrelated repository issues are outside the HoH namespace.

| Scope | Open | Closed | All |
| --- | --- | --- | --- |
| GitHub HoH namespace | 73 | 38 | 111 |
| Outside this run's table | 17 | 4 | 21 |

Earlier runs' issues retain their own evidence and are not automatically resolved by this run.

| GitHub | Issue ID | GitHub state | Source run |
| --- | --- | --- | --- |
| [#1](https://github.com/Flesymeb/aelors-adventure/issues/1) | `issue:milestone01-camera-environment` | OPEN | `aelors-adventure-astra-high-20261002` |
| [#2](https://github.com/Flesymeb/aelors-adventure/issues/2) | `issue:milestone01-missing-loop` | OPEN | `aelors-adventure-astra-high-20261002` |
| [#3](https://github.com/Flesymeb/aelors-adventure/issues/3) | `issue:r02-actor-animation-falloff` | OPEN | `aelors-adventure-astra-high-20261002` |
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

## Loop 72

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-63-763b7c2b7817` | `warm_start:loop-62-763b7c2b7817` | PLANNED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Restore readable ordinary Veyne dive counterplay through a focused camera-ownership repair, then qualify the retained combat and recovery surfaces using existing observation methods. Keep opening-history and listening dependencies explicit and preserve all frozen requirements. |
| Strategy | `flight-subject-contract-and-camera-owner-isolation` |
| Tasks | 3 |

### Developer

| Field | Value |
| --- | --- |
| Status | NOT STARTED |

### QA Tester

| Field | Value |
| --- | --- |
| Status | UNTESTED |

---

## Loop 71

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-62-763b7c2b7817` | `development_snapshot:attempt-24357c8134a3e6280de740c3` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Replace repeated broad verification with prerequisite-first qualification and paired obstruction checks: establish the legal opening-history boundary, test both ambusher variants against existing authored geometry, and retain precise Host dependencies for coach persistence, listening and arena coverage. |
| Strategy | `qualified-history-admission-and-authored-obstacle-differential` |
| Tasks | 3 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 3 |
| Changed paths | 0 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-24357c8134a3e6280de740c3` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-62-763b7c2b7817` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 8 (7 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `opening-history-gap` | MAJOR | INTERNAL | HIGH | Qualified unfinished-opening Continue remains unobserved. |
| `ambusher-obstruction-gap` | MAJOR | INTERNAL | HIGH | Both authored-obstruction outcomes remain unverified despite working local revelation and contact. |
| `coach-history-gap` | MAJOR | INTERNAL | HIGH | Committed coach acquisition cannot be verified through Continue. |
| `audio-listening-gap` | MAJOR | INTERNAL | HIGH | This client cannot provide the required independent listening evidence. |
| `arena-route-coverage-gap` | MAJOR | INTERNAL | HIGH | Arena traversal is supported locally; complete adjacent-route acceptance remains unverified. |
| `arena-flight-camera-failure` | MAJOR | DEGRADED | HIGH | The shipped dive camera crops Veyne and loses the player and landing area. |
| `ordinary-route-recapture` | MINOR | INTERNAL | MEDIUM | RECAPTURE_REQUEST: GAME_JOURNEY:r01-earned-mf01-e03-reveal-recognition |
| `tester.mcp_coverage_incomplete` | MAJOR | unlabelled | unlabelled | Tester did not complete every required live MCP, source, state, log, and screenshot probe after bounded same-session corrections. |

---

## Loop 70

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-61-763b7c2b7817` | `development_snapshot:attempt-cb7fcf71033dd714196cc06a` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Distinguish opening-recovery behavior from missing qualified evidence, then perform focused verification of retained encounter and travel interfaces while keeping unavailable independent evidence explicitly unresolved. |
| Strategy | `production-opening-lifecycle-before-qualification` |
| Tasks | 3 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 3 |
| Changed paths | 0 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-cb7fcf71033dd714196cc06a` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-61-763b7c2b7817` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 9 (9 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `opening-recovery-gap` | MAJOR | INTERNAL | HIGH | Opening replay works; qualified unfinished-history Continue remains unverified. |
| `ambusher-counterplay-gap` | MAJOR | INTERNAL | HIGH | Local ambusher behavior is supported; obstruction and production lifecycle coverage remain incomplete. |
| `journey-loader-gap` | MAJOR | INTERNAL | HIGH | Complete journey-loader validation could not be independently obtained. |
| `earned-travel-gap` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:r19-earned-departure-normal-boundary |
| `coach-continue-gap` | MAJOR | INTERNAL | HIGH | Ordinary coach acquisition works; committed-acquisition Continue remains unqualified. |
| `audio-listening-gap` | MAJOR | INTERNAL | HIGH | The current client cannot receive audio input for independent listening acceptance. |
| `arena-coverage-gap` | MAJOR | INTERNAL | HIGH | Arena stair and lateral observations are supported; complete original coverage remains unverified. |
| `native-source-review-gap` | MAJOR | INTERNAL | HIGH | Actual canonical source declarations were reviewed; native implementation-payload availability remains unresolved. |
| `tester.mcp_coverage_incomplete` | MAJOR | unlabelled | unlabelled | Tester did not complete every required live MCP, source, state, log, and screenshot probe after bounded same-session corrections. |

---

## Loop 69

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-60-763b7c2b7817` | `development_snapshot:attempt-962bf1f641f4d787a62ce7ce` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Complete the optional meadow encounter composition with a lamp-revealed ambusher, while retaining production recovery and travel contracts without repeating evidence-only readiness work. |
| Strategy | `complete-chapter-composition-with-instance-isolation` |
| Tasks | 3 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 3 |
| Changed paths | 8 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-962bf1f641f4d787a62ce7ce` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-60-763b7c2b7817` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 8 (8 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `coach-continue-gap` | MAJOR | INTERNAL | HIGH | Ordinary coach acquisition was observed; committed-acquisition Continue remains unqualified. |
| `opening-recovery-gap` | MAJOR | INTERNAL | HIGH | Opening skip and pause/resume worked; unfinished-opening Continue remains unobserved. |
| `audio-listening-gap` | MAJOR | INTERNAL | HIGH | This client's explicit audio-input limitation prevents independent listening acceptance. |
| `arena-closure-gap` | MAJOR | INTERNAL | HIGH | Narrow stair conditions pass; the original arena issue remains incompletely qualified. |
| `earned-travel-gap` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:r19-earned-departure-skip-boundary |
| `journey-validation-gap` | MAJOR | INTERNAL | HIGH | Manifest vocabulary inspection does not establish complete loader-grammar validation. |
| `meadow-qualification-gap` | MAJOR | INTERNAL | HIGH | Local ambusher behavior was observed; earned admission and production recovery remain unqualified. |
| `tester.mcp_coverage_incomplete` | MAJOR | unlabelled | unlabelled | Tester did not complete every required live MCP, source, state, log, and screenshot probe after bounded same-session corrections. |

---

## Loop 68

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-59-7b331072457c` | `development_snapshot:attempt-f0bcf257ebd31bbd6aa04640` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Qualify the existing route and meadow-admission owners through small readiness checkpoints, preserve the pinned opening/settings/coach and arena obligations, and enable independent Host/Tester qualification without rebuilding delivered gameplay. |
| Strategy | `production-binding-discrimination-and-small-readiness-checkpoints` |
| Tasks | 3 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 3 |
| Changed paths | 0 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-f0bcf257ebd31bbd6aa04640` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-59-7b331072457c` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 8 (8 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `opening_recovery_gap` | MAJOR | INTERNAL | HIGH | Opening recovery remains unqualified despite observed control return. |
| `coach_recovery_gap` | MAJOR | INTERNAL | HIGH | Coach committed-Continue and duplicate-grant acceptance remain unobserved. |
| `arena_matrix_gap` | MAJOR | INTERNAL | HIGH | Local stair conditions pass; original arena closure remains incomplete. |
| `audio_listening_gap` | MAJOR | INTERNAL | HIGH | Independent audio listening is blocked by the client capability. |
| `pillar_approach_gap` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:r19-earned-farewell-to-pillar-approach |
| `meadow_admission_gap` | MAJOR | INTERNAL | HIGH | Ordinary meadow admission and persistent settlement remain unqualified. |
| `retained_grass_gap` | MAJOR | INTERNAL | HIGH | Mandatory retained-grass closure remains insufficiently evidenced. |
| `tester.mcp_coverage_incomplete` | MAJOR | unlabelled | unlabelled | Tester did not complete every required live MCP, source, state, log, and screenshot probe after bounded same-session corrections. |

---

## Loop 67

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-58-7b331072457c` | `development_snapshot:attempt-1232e80038a6c6b522ae0d6e` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Deliver bounded optional meadow melee/ranged groups with persistent combat rewards; verify adjacent departure and MF01 routes while retaining full pinned evidence requirements. |
| Strategy | `chapter-scoped-admission-and-persistence-with-retained-evidence-routes` |
| Tasks | 3 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 3 |
| Changed paths | 9 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-1232e80038a6c6b522ae0d6e` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-58-7b331072457c` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 8 (8 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `departure_coverage_remaining` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:r19-earned-departure-skip-boundary |
| `meadow_dynamic_coverage_remaining` | MAJOR | INTERNAL | HIGH | Local meadow admission and combat observations do not qualify ordinary admission, complete counterplay or persistent settlement. |
| `mf01_earned_coverage_remaining` | MAJOR | INTERNAL | HIGH | MF01 earning, committed Continue and its information/scale matrix remain unverified. |
| `audio_listening_remaining` | MAJOR | INTERNAL | HIGH | Audio capture is available, but this session cannot accept its audio attachment for independent listening. |
| `opening_matrix_remaining` | MAJOR | INTERNAL | HIGH | Opening pause/resume was observed; complete qualified opening transition coverage remains unavailable. |
| `coach_matrix_remaining` | MAJOR | INTERNAL | HIGH | Current Hers and Ronen acquisition continuity was observed; the complete coach matrix remains unverified. |
| `native_source_payload_gap` | MAJOR | INTERNAL | HIGH | Actual Host source declarations were collected, but native resource inspection exposed metadata only; native implementation-payload coverage remains unresolved. |
| `tester.mcp_coverage_incomplete` | MAJOR | unlabelled | unlabelled | Tester did not complete every required live MCP, source, state, log, and screenshot probe after bounded same-session corrections. |

---

## Loop 66

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-57-d33b3101ad5f` | `development_snapshot:attempt-23e17f889983e696d1415940` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Complete the actor identities on the existing E02/MF01 route: integrate a distinct, fully animated melee opponent and fitted player hair, preserve authoritative combat and progression, and retain independent qualification of the allocated evidence gaps. |
| Strategy | `e02-complete-actor-replacement-with-preserved-observation-owners` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 31 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-23e17f889983e696d1415940` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-57-d33b3101ad5f` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 7 (7 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `e02-cover-contact-gap` | MAJOR | INTERNAL | HIGH | Exact E02 melee contact against solid cover remains unverified. |
| `mf01-earned-continuity-gap` | MAJOR | INTERNAL | HIGH | MF01 ordinary earning and committed Continue restoration remain unverified. |
| `audio-capture-listening-gap` | MAJOR | INTERNAL | HIGH | Audio collection failed during its stop handler; independent listening acceptance remains unavailable. |
| `opening-variant-gap` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:r21-opening-held-space-skip |
| `coach-variants-gap` | MAJOR | INTERNAL | HIGH | Current Hers acquisition was observed; complete coach continuity remains unverified. |
| `arena-qualification-gap` | MAJOR | INTERNAL | HIGH | Original Veyne arena qualification remains unexecuted. |
| `tester.mcp_coverage_incomplete` | MAJOR | unlabelled | unlabelled | Tester did not complete every required live MCP, source, state, log, and screenshot probe after bounded same-session corrections. |

---

## Loop 65

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-56-abff6ed132c0` | `development_snapshot:attempt-fa20d907db13abb3a75b7f22` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Add bounded remembered-position search to the existing E02 melee guard, preserve its combat and progression consequences, and make the same E02-to-MF01 route ready for focused independent qualification. |
| Strategy | `e02-remembered-search-with-earned-history-validation` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 5 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-fa20d907db13abb3a75b7f22` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-56-abff6ed132c0` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 7 (7 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `e02-local-termination-and-recovery-gap` | MAJOR | INTERNAL | HIGH | Complete E02 search termination and recovery acceptance remains unverified. |
| `mf01-earned-continuity-gap` | MAJOR | INTERNAL | HIGH | MF01 ordinary earning and committed Continue restoration remain unverified. |
| `audio-listening-gap` | MAJOR | INTERNAL | HIGH | Valid audio capture remains insufficient for independent listening acceptance. |
| `opening-variant-gap` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:r21-opening-held-space-skip |
| `coach-variants-gap` | MAJOR | INTERNAL | HIGH | Hers acquisition and restoration were observed; full coach continuity remains incomplete. |
| `arena-qualification-gap` | MAJOR | INTERNAL | HIGH | Original Veyne arena geometry and traversal qualification remains unexecuted. |
| `tester.mcp_coverage_incomplete` | MAJOR | unlabelled | unlabelled | Tester did not complete every required live MCP, source, state, log, and screenshot probe after bounded same-session corrections. |

---

## Loop 64

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-55-f7352aee6f5a` | `development_snapshot:attempt-b248861a53b2bed16e8719d3` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Complete MF01’s learned navigation flow in the existing map/journal pages and make existing lifecycle probes independently launchable, preserving ordinary earning, saves, combat and presentation. |
| Strategy | `complete-mf01-navigation-and-select-probes-at-scene-entry` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 0 |
| Changed paths | 5 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-b248861a53b2bed16e8719d3` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-55-f7352aee6f5a` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 7 (6 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `mf01-earned-restoration-gap` | MAJOR | INTERNAL | HIGH | MF01 ordinary earning and committed Continue restoration remain unverified. |
| `retained-grass-qualification-gap` | MAJOR | INTERNAL | HIGH | Mandatory retained-grass closure remains insufficiently evidenced. |
| `audio-listening-gap` | MAJOR | INTERNAL | HIGH | Successful audio capture cannot supply independent listening in this client. |
| `opening-variant-gap` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:r21-opening-held-space-skip |
| `coach-variants-gap` | MAJOR | INTERNAL | HIGH | Hers acquisition and Continue were observed; the full Hers/Ronen matrix remains incomplete. |
| `veyne-skip-qualification-gap` | MINOR | INTERNAL | MEDIUM | The moved-Veyne second-phase skip remains unverified. |
| `tester.mcp_coverage_incomplete` | MAJOR | unlabelled | unlabelled | Tester did not complete every required live MCP, source, state, log, and screenshot probe after bounded same-session corrections. |

---

## Loop 63

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-54-72c223ea5af5` | `development_snapshot:attempt-0e0feb7d4024ba0a23e7626c` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Deliver a coherent E02 encounter presentation on the existing authored MAP02 route, preserving combat and MF01 progression, and make its repair available for focused independent acceptance. |
| Strategy | `qualify-e02-instance-bindings-and-separate-host-observation-debt` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 13 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-0e0feb7d4024ba0a23e7626c` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-54-72c223ea5af5` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 6 (5 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `e02-lifecycle-qualification-gap` | MAJOR | INTERNAL | HIGH | E02 lifecycle qualification remains incomplete despite successful local animation and contact observations. |
| `mf01-earned-restoration-gap` | MAJOR | INTERNAL | HIGH | MF01 earning and committed Continue restoration remain unverified. |
| `audio-listening-gap` | MAJOR | INTERNAL | HIGH | This client cannot independently listen to the successfully captured audio. |
| `opening-variant-gap` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:r21-opening-held-space-skip |
| `veyne-skip-qualification-gap` | MINOR | INTERNAL | MEDIUM | The moved-Veyne phase skip remains unverified on this candidate. |
| `tester.mcp_coverage_incomplete` | MAJOR | unlabelled | unlabelled | Tester did not complete every required live MCP, source, state, log, and screenshot probe after bounded same-session corrections. |

---

## Loop 62

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-53-52c750a03080` | `development_snapshot:attempt-4b9dc3486927584b724cf8b5` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Complete and qualify E02's playable cover response through the existing encounter owners, preserving the ordinary victory-to-MF01 investigation and Continue handoff, while directing the pinned evidence debts to their existing observation paths. |
| Strategy | `qualify-e02-cover-decisions-and-reuse-existing-evidence-entries` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 3 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-4b9dc3486927584b724cf8b5` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-53-52c750a03080` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 7 (6 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `qa.e02-local-coverage-gap` | MAJOR | INTERNAL | HIGH | E02 local observations do not yet establish every cover, projectile, counterplay and reset outcome. |
| `qa.mf01-earned-gap` | MAJOR | INTERNAL | HIGH | MF01 earning and committed Continue information restoration remain unverified. |
| `qa.audio-listening-gap` | MAJOR | INTERNAL | HIGH | Session audio-input capability prevents independent listening qualification. |
| `qa.opening-timing-gap` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:r21-opening-held-space-skip |
| `qa.coach-variants-gap` | MAJOR | INTERNAL | MEDIUM | Hers and Ronen portraits were observed, but their complete presentation and recovery matrix remains unverified. |
| `qa.e02-visual-coherence` | MINOR | DEGRADED | MEDIUM | E02 actor styles and unfinished white landmarks weaken the supplied visual direction. |
| `tester.mcp_coverage_incomplete` | MAJOR | unlabelled | unlabelled | Tester did not complete every required live MCP, source, state, log, and screenshot probe after bounded same-session corrections. |

---

## Loop 61

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-52-40eedac2149e` | `development_snapshot:attempt-b25fefd4c6df78a2b1723739` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Repair the existing Veyne arena and attack presentation so players can see the approach, escape lanes, grounded dive warning and active breath/beam while retaining real contact, evasion and recovery. Reuse the delivered encounter and resolve the pinned evidence issues through their correct ownership boundary. |
| Strategy | `repair-spatial-ownership-and-retire-conflicting-render-bindings` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 11 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-b25fefd4c6df78a2b1723739` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-52-40eedac2149e` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 7 (7 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `arena-retest-incomplete` | MAJOR | INTERNAL | HIGH | Arena fragment removal and route support remain independently unqualified. |
| `dive-retest-incomplete` | MAJOR | INTERNAL | HIGH | Fixed flight samples do not establish complete dive-warning acceptance; retained camera coverage also shows partial visibility. |
| `effects-retest-incomplete` | MAJOR | INTERNAL | HIGH | Breath and beam readability and preserved contact behavior remain incompletely verified. |
| `attack-lifecycle-retest-incomplete` | MAJOR | INTERNAL | HIGH | Partial breath pause observations leave interruption, CP03 cleanup and final log coverage unresolved. |
| `listening-evidence-incomplete` | MAJOR | INTERNAL | HIGH | Independent audio listening remains unverified. |
| `opening-evidence-incomplete` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:r21-opening-held-space-skip |
| `tester.mcp_coverage_incomplete` | MAJOR | unlabelled | unlabelled | Tester did not complete every required live MCP, source, state, log, and screenshot probe after bounded same-session corrections. |

---

## Loop 60

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-51-46e4bb92d504` | `development_snapshot:attempt-718c1a20cbc3ca25dbf2664f` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Replace Veyne's humanoid presentation and cramped encounter area with a qualified winged-dragon encounter, readable live-bound framing and event-driven attack effects, while retaining existing progression and recovery authority. |
| Strategy | `replace-creature-spatial-bindings-preserve-state-and-isolate-host-debt` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 40 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-718c1a20cbc3ca25dbf2664f` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-51-46e4bb92d504` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 12 (11 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `veyne-arena-foreground-fragments` | MAJOR | DEGRADED | HIGH | Arena shell fragments and oversized leaf sheets obstruct player views. |
| `veyne-dive-warning-drifts` | MAJOR | DEGRADED | HIGH | Dive landing warning follows the airborne dragon instead of the floor. |
| `veyne-effects-obscure-combat` | MAJOR | DEGRADED | HIGH | Opaque breath and beam effects hide the active fight. |
| `veyne-dragon-validation-incomplete` | MAJOR | INTERNAL | HIGH | Dragon animation and charge acceptance remain partially unobserved. |
| `veyne-phase-camera-retest-incomplete` | MINOR | INTERNAL | MEDIUM | Natural moved-phase framing improved; skipped qualification remains missing. |
| `settings-listening-unavailable` | MAJOR | INTERNAL | HIGH | Independent audio listening remains unavailable in this client. |
| `opening-handoff-qualification-incomplete` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:r21-opening-held-space-skip |
| `mf01-earned-verification-incomplete` | MAJOR | INTERNAL | HIGH | MF01 earning and committed information restoration remain unverified. |
| `tomb-earned-verification-incomplete` | MAJOR | INTERNAL | HIGH | Prepared arena traversal does not qualify earned tomb entry. |
| `retained_texture_dependencies_missing` | MAJOR | INTERNAL | HIGH | Mandatory retained-grass closure remains insufficiently evidenced. |
| `pillar_approach_camera_occluded` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:r19-earned-farewell-to-pillar-approach |
| `tester.mcp_coverage_incomplete` | MAJOR | unlabelled | unlabelled | Tester did not complete every required live MCP, source, state, log, and screenshot probe after bounded same-session corrections. |

---

## Loop 59

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-50-19c10f4c7a61` | `development_snapshot:attempt-f387900d5e4842e3bba319bf` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Advance the missing MAP03 dependency with a reachable two-phase base Veyne fight, and make the existing separate lifecycle probes launchable by scene path. Preserve the five allocated evidence findings until independent QA establishes their original conditions. |
| Strategy | `missing-veyne-module-with-scene-selectable-lifecycle-repair` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 0 |
| Changed paths | 37 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-f387900d5e4842e3bba319bf` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-50-19c10f4c7a61` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 8 (6 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `qa.veyne-acceptance-gap` | MAJOR | INTERNAL | HIGH | Veyne counterplay, victory/key persistence and complete recovery acceptance remain unverified. |
| `qa.opening-native-observation-gap` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:r21-opening-held-space-skip |
| `qa.settings-listening-gap` | MAJOR | INTERNAL | HIGH | Lifecycle purity is supported; independent audio listening remains unavailable. |
| `qa.coach-qualification-gap` | MINOR | INTERNAL | MEDIUM | Coach presentation and recovery variants remain unverified. |
| `qa.mf01-earned-gap` | MAJOR | INTERNAL | HIGH | MF01 earning and committed information restoration remain unobserved. |
| `qa.tomb-earned-gap` | MAJOR | INTERNAL | HIGH | Local post-LN02 approach is supported; earned tomb entry and recovery remain unverified. |
| `veyne-phase-camera-crop` | MINOR | DEGRADED | MEDIUM | Phase camera framing crops the moved caster and foreground player. |
| `tester.mcp_coverage_incomplete` | MAJOR | unlabelled | unlabelled | Tester did not complete every required live MCP, source, state, log, and screenshot probe after bounded same-session corrections. |

---

## Loop 58

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-49-2172c7dd693f` | `development_snapshot:attempt-34b095d9193925e80f9fb132` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Make ordinary grounded walking and sprinting stop coherently when movement input is released, preserving traversal and combat, while advancing independent verification of the five allocated evidence issues through existing methods. |
| Strategy | `native-motion-release-reproduction-and-single-owner-gait-repair` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 4 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-34b095d9193925e80f9fb132` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-49-2172c7dd693f` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 7 (7 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `grounded-release-deadline-unverified` | MAJOR | INTERNAL | HIGH | Grounded stopping is observed, but its required next-update deadline remains unqualified. |
| `settings-listening-gap` | MAJOR | INTERNAL | HIGH | Separate audio comparisons were captured; independent listening remains unavailable. |
| `opening-matrix-gap` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:r21-opening-held-space-skip |
| `coach-qualification-gap` | MAJOR | INTERNAL | HIGH | Current Hers acquisition presentation is supported; complete variants and recovery remain unverified. |
| `mf01-earned-gap` | MAJOR | INTERNAL | HIGH | MF01 earning and committed information restoration remain unobserved. |
| `tomb-earned-gap` | MAJOR | INTERNAL | HIGH | Earned production LN02 traversal and recovery remain unverified. |
| `tester.mcp_coverage_incomplete` | MAJOR | unlabelled | unlabelled | Tester did not complete every required live MCP, source, state, log, and screenshot probe after bounded same-session corrections. |

---

## Loop 57

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-48-fec09a00537a` | `development_snapshot:attempt-b6f4a1014d68082874b68501` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Add a usable grounded light-to-heavy sword finisher and make the existing independent lifecycle checks launchable through explicit opt-in scenes, while preserving coach acquisition, ordinary progression and all unresolved acceptance. |
| Strategy | `explicit-lifecycle-scene-selection-and-existing-owner-mixed-finisher` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 6 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-b6f4a1014d68082874b68501` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-48-fec09a00537a` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 7 (7 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `finisher-obstruction-unverified` | MAJOR | INTERNAL | HIGH | Finisher obstruction acceptance remains unverified. |
| `settings-listening-gap` | MAJOR | INTERNAL | HIGH | Settings lifecycle purity is verified; independent listening remains unavailable. |
| `opening-matrix-gap` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:r21-opening-held-space-skip |
| `coach-qualification-gap` | MAJOR | INTERNAL | HIGH | Coach acquisition presentation is supported; complete variants and recovery remain unverified. |
| `mf01-earned-gap` | MAJOR | INTERNAL | HIGH | MF01 earning and committed information restoration remain unobserved. |
| `tomb-earned-gap` | MAJOR | INTERNAL | HIGH | Earned production LN02 and tomb traversal remain unverified. |
| `tester.mcp_coverage_incomplete` | MAJOR | unlabelled | unlabelled | Tester did not complete every required live MCP, source, state, log, and screenshot probe after bounded same-session corrections. |

---

## Loop 56

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-47-63f41ed78f47` | `development_snapshot:attempt-bdcc841f13b17eee8168c671` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Deliver an animated monster Warden with its existing two counterplay moves and one bounded pressure phase on the authored MAP03 route, while making the pinned lifecycle evidence inputs independently inspectable and retaining all outstanding earned-route and restoration acceptance. |
| Strategy | `replace-warden-ranger-wrapper-and-isolate-owner-lifecycle-probes` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 11 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-bdcc841f13b17eee8168c671` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-47-63f41ed78f47` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 10 (8 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `qa.warden-counterplay-evidence-gap` | MAJOR | INTERNAL | HIGH | Remaining Warden counterplay and pressure cells are unqualified. |
| `qa.independent-lifecycle-selection-gap` | MAJOR | INTERNAL | HIGH | Independent settings/audio and opening/router lifecycle selections were not observed. |
| `tomb_entry_acceptance_unverified` | MAJOR | INTERNAL | HIGH | Earned production LN02 and MAP03 access remains unverified. |
| `qa.mf01-earned-path-unverified` | MAJOR | INTERNAL | HIGH | MF01 earning and committed restoration remain unobserved. |
| `settings_effect_validation_incomplete` | MAJOR | INTERNAL | HIGH | Settings routing has current support; lifecycle purity and listening remain unverified. |
| `opening_acceptance_evidence_incomplete` | MAJOR | INTERNAL | HIGH | Opening lifecycle acceptance remains incomplete. |
| `hers_portrait_continuity_missing` | MAJOR | INTERNAL | HIGH | Complete coach presentation and recovery qualification remains unverified. |
| `retained_texture_dependencies_missing` | MAJOR | INTERNAL | HIGH | Mandatory retained-grass closure remains insufficiently evidenced. |
| `pillar_approach_camera_occluded` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:r19-earned-farewell-to-pillar-approach |
| `tester.mcp_coverage_incomplete` | MAJOR | unlabelled | unlabelled | Tester did not complete every required live MCP, source, state, log, and screenshot probe after bounded same-session corrections. |

---

## Loop 55

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-46-8d390ce29b18` | `development_snapshot:attempt-b50587048980f0561b400966` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Extend the existing sword combat with one aerial heavy attack, repair crowded threat-cue presentation, and make retained entry/audio and coach-dialogue observations independently testable within the six-condition budget. |
| Strategy | `extend-live-attack-owner-and-isolate-raw-observations-before-cue-repair` |
| Tasks | 2 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 2 |
| Changed paths | 9 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-b50587048980f0561b400966` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-46-8d390ce29b18` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 8 (8 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `qa.aerial-validation-gap` | MAJOR | INTERNAL | HIGH | Aerial behavior is demonstrated, but complete independent qualification remains unfinished. |
| `qa.settings-observation-gap` | MAJOR | INTERNAL | HIGH | Settings live observations have support; lifecycle purity and independent listening remain unverified. |
| `qa.opening-lifecycle-gap` | MAJOR | INTERNAL | HIGH | Opening normal completion is supported; the complete lifecycle matrix remains unverified. |
| `qa.mf01-restoration-gap` | MAJOR | INTERNAL | HIGH | MF01 earned acquisition and committed restoration remain unobserved. |
| `qa.dialogue-qualification-gap` | MAJOR | INTERNAL | HIGH | Coach presentation has substantial current support, but complete recovery qualification remains unfinished. |
| `qa.channel-qualification-gap` | MAJOR | INTERNAL | HIGH | The original crowded CH01 defect was not independently qualified or reproduced. |
| `qa.case-finalization-unavailable` | MAJOR | INTERNAL | HIGH | Host case queue exhaustion prevented formal finish and remaining finalization receipts. |
| `tester.mcp_coverage_incomplete` | MAJOR | unlabelled | unlabelled | Tester did not complete every required live MCP, source, state, log, and screenshot probe after bounded same-session corrections. |

---

## Loop 54

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-45-e2074c8ab801` | `development_snapshot:attempt-75b91db3e5b3bdae4470aa6b` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Advance the delivered tomb entrance into a playable Warden encounter, complete the bounded equipment-dialogue presentation repairs, and make the allocated evidence issues assessable without rebuilding implemented behavior or weakening frozen acceptance. |
| Strategy | `advance-warden-from-live-combat-foundation-and-qualify-observers-in-isolation` |
| Tasks | 2 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 2 |
| Changed paths | 37 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-75b91db3e5b3bdae4470aa6b` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-45-e2074c8ab801` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 6 (5 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `warden-acceptance-unverified` | MAJOR | INTERNAL | HIGH | Earned Warden encounter and recovery acceptance remain unverified. |
| `mf01-earned-restoration-unverified` | MAJOR | INTERNAL | HIGH | MF01 ordinary acquisition and committed restoration remain unverified. |
| `equipment-dialogue-qualification-unverified` | MAJOR | INTERNAL | HIGH | Coach portrait presence has partial support; complete identity and presentation acceptance remain unverified. |
| `training-label-recovery-unverified` | MINOR | INTERNAL | MEDIUM | Training-label obstruction and final cue recovery remain unqualified. |
| `retained-observer-acceptance-unverified` | MAJOR | INTERNAL | HIGH | Settings listening and opening lifecycle acceptance remain unverified. |
| `tester.mcp_coverage_incomplete` | MAJOR | unlabelled | unlabelled | Tester did not complete every required live MCP, source, state, log, and screenshot probe after bounded same-session corrections. |

---

## Loop 53

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-44-8792688162d9` | `development_snapshot:attempt-dda107618395875e1e791e87` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Replace MAP03's inert entrance seal with the playable LN02 two-supply puzzle and a supported passage beyond it, while qualifying existing observation inputs for the allocated evidence issues without claiming full rescue completion. |
| Strategy | `replace-inert-tomb-seal-with-independent-supply-circuit` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 10 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-dda107618395875e1e791e87` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-44-8792688162d9` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 6 (6 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `ln02-earned-acceptance-unverified` | MAJOR | INTERNAL | HIGH | Diagnostic LN02 observations do not establish earned production-route or recovery acceptance. |
| `later-rescue-continuation-unverified` | MAJOR | INTERNAL | HIGH | The existing later rescue-route issue cannot be closed from entrance-fixture evidence. |
| `mf01-mf02-restoration-unverified` | MAJOR | INTERNAL | HIGH | Earned meadow fragments and committed restoration remain unverified. |
| `settings-observation-unverified` | MAJOR | INTERNAL | HIGH | Settings observation purity and independent audio comparisons remain unverified. |
| `opening-observation-unverified` | MAJOR | INTERNAL | HIGH | Opening observation purity and lifecycle acceptance remain unverified. |
| `tester.mcp_coverage_incomplete` | MAJOR | unlabelled | unlabelled | Tester did not complete every required live MCP, source, state, log, and screenshot probe after bounded same-session corrections. |

---

## Loop 52

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-43-be0b6c2f2375` | `development_snapshot:attempt-661f83cae45b796d93697c4c` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Extend the existing earned meadow route into a distinct playable tomb entrance with CP03, an accessible ritual record and return travel, while preserving prior progression and keeping incomplete rescue and evidence matrices unresolved. |
| Strategy | `implement-third-map-entry-with-destination-readiness` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 42 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-661f83cae45b796d93697c4c` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | BLOCKED |
| Candidate | `loop-43-be0b6c2f2375` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 7 (2 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `tomb_entry_acceptance_unverified` | MAJOR | INTERNAL | HIGH | All six ordinary tomb-entry acceptance conditions remain unverified. |
| `full_acceptance_closeout_missing` | MAJOR | INTERNAL | HIGH | Partial route observations do not establish complete milestone acceptance. |
| `retained_texture_dependencies_missing` | MINOR | INTERNAL | HIGH | Mandatory retained-grass closure remains insufficiently evidenced. |
| `settings_effect_validation_incomplete` | MINOR | INTERNAL | HIGH | Independent audio listening and full settings comparisons remain unverified. |
| `opening_acceptance_evidence_incomplete` | MINOR | INTERNAL | HIGH | Opening lifecycle acceptance remains insufficiently evidenced. |
| `qa.mf01-earned-path-unverified` | MINOR | INTERNAL | HIGH | Earned MF01/MF02 and committed-save restoration remain unobserved. |
| `pillar_approach_camera_occluded` | MINOR | INTERNAL | HIGH | Eligible pillar-camera acceptance remains unverified. |

---

## Loop 51

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-42-42f06a8f602c` | `development_snapshot:attempt-a23185ffe9050f68e4081f03` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Make the existing village-to-MF01 route closure-ready on candidate 81f2644b2d67adcc9d490ff3273f4d8c0659f1b06de301c88fee95627ac376ff: repair unsafe NPC observation and persistent pillar occlusion, preserve earned progression, and support independent verification of existing MF01 acquisition and restoration. |
| Strategy | `repair-observer-lifecycle-and-authoritative-route-bindings` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 5 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-a23185ffe9050f68e4081f03` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-42-42f06a8f602c` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 6 (5 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `qa.later-rescue-route-continuity` | MAJOR | USER BLOCKING | HIGH | The required later rescue journey still lacks a production continuation beyond village and meadow. |
| `pillar_approach_camera_occluded` | MINOR | DEGRADED | MEDIUM | Eligible pillar-camera acceptance remains unverified despite the targeted foliage repair. |
| `qa.mf01-earned-path-unverified` | MAJOR | INTERNAL | HIGH | Earned MF01 acquisition and committed-save M/J restoration remain unobserved. |
| `settings_effect_validation_incomplete` | MAJOR | INTERNAL | HIGH | Valid audio capture is preserved; independent listening and complete settings comparisons remain unavailable. |
| `opening_acceptance_evidence_incomplete` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:r21-opening-pause-resume Publish qualified intermediate timing from the recipe's isolated fresh title state. |
| `full_acceptance_closeout_missing` | MAJOR | INTERNAL | HIGH | Local repair verification does not establish complete milestone acceptance. |

---

## Loop 50

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-41-81f2644b2d67` | `development_snapshot:attempt-b1d1bbbcce541a7c79cdf708` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Advance the earned meadow route from E04/MF02 through a finished, recoverable LN01 circuit puzzle, while preserving candidate inputs needed for independent supply, opening and audio review. |
| Strategy | `complete-missing-ln01-owner-and-separate-host-evidence-debt` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 26 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-b1d1bbbcce541a7c79cdf708` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-41-81f2644b2d67` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 13 (9 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `ss-rescue-route` | MAJOR | USER BLOCKING | HIGH | The required rescue ending remains unreachable because production progression supports only village and meadow. |
| `ss-ln01-r13` | MAJOR | INTERNAL | HIGH | LN01's three selected task conditions lack independent earned-route verification under the R13 owner. |
| `ss-ln01-r21` | MAJOR | INTERNAL | HIGH | Selected LN01 conditions remain unobserved under the R21 owner. |
| `ss-retained-grass` | MAJOR | INTERNAL | HIGH | Mandatory retained-grass closure remains insufficiently evidenced. |
| `ss-e02-e04` | MAJOR | INTERNAL | HIGH | Earned E02/E04 combat remains unqualified despite current CH01 lightning observations. |
| `ss-settings-audio` | MAJOR | INTERNAL | HIGH | Valid audio capture is preserved, but independent listening and complete settings comparisons remain unavailable. |
| `ss-opening` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:r21-opening-pause-resume Publish qualified intermediate pause/resume timing; complete cinematic lifecycle remains unresolved. |
| `ss-e04-supply` | MAJOR | INTERNAL | HIGH | The E04 recovery-supply condition remains unobserved after ordinary earning. |
| `ss-pillar-camera` | MINOR | DEGRADED | MEDIUM | Tree-trunk occlusion remains at the earned eligible pillar stance. |
| `ss-counterpart-portraits` | MINOR | DEGRADED | MEDIUM | Hers and Ronen equipment dialogue still omit their counterpart portraits. |
| `qa.training-label-dialogue-obstruction` | MINOR | DEGRADED | MEDIUM | An oversized element-practice label intrudes into the ordinary Ronen dialogue view. |
| `ss-channel-labels` | MINOR | DEGRADED | MEDIUM | Crowded channel combat still produces overlapping threat labels. |

---

## Loop 49

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-40-856c53c89ddc` | `development_snapshot:attempt-d583ad096dd1eef005c3afde` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Extend the frozen candidate through a grounded, animated E04/MF02 player module, while making existing earned-route and cinematic/settings observation inputs usable without fabricating progress or evidence. |
| Strategy | `advance-e04-with-complete-actor-owner-and-earned-state-contract` |
| Tasks | 3 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 3 |
| Changed paths | 16 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-d583ad096dd1eef005c3afde` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-40-856c53c89ddc` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 12 (9 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `qa.later-rescue-route-continuity` | BLOCKER | USER BLOCKING | CRITICAL | The required rescue ending remains unreachable because production progression supports only village and meadow. |
| `full_acceptance_closeout_missing` | MAJOR | INTERNAL | HIGH | Local ordinary progress does not establish full milestone completion. |
| `retained_texture_dependencies_missing` | MAJOR | INTERNAL | HIGH | Mandatory retained-grass closure still lacks independent cold import and matched visual qualification. |
| `qa.mf01-earned-path-unverified` | MAJOR | INTERNAL | HIGH | MF01 acquisition/restoration and earned MF02 investigation remain unobserved. |
| `qa.e02-e04-combat-observation-gap` | MAJOR | INTERNAL | HIGH | Earned E02 and E04 combat remain unqualified despite successful CH01 lightning observations. |
| `qa.e04-supply-earned-gap` | MAJOR | INTERNAL | HIGH | The E04 recovery-supply condition remains unobserved after ordinary earning. |
| `earned_departure_unverified` | MAJOR | INTERNAL | HIGH | Earned normal departure now reaches CP02; the remaining departure and recovery variants remain unverified. |
| `opening_acceptance_evidence_incomplete` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:r21-opening-pause-resume Publish qualified intermediate pause/resume timing; complete cinematic lifecycle remains unresolved. |
| `settings_effect_validation_incomplete` | MAJOR | INTERNAL | HIGH | Valid audio capture is retained, but independent listening and complete Music/Effects comparisons remain missing. |
| `hers_portrait_continuity_missing` | MINOR | DEGRADED | MEDIUM | Hers and Ronen equipment dialogue still omit their counterpart portraits. |
| `pillar_approach_camera_occluded` | MINOR | DEGRADED | MEDIUM | Tree trunks heavily occlude the shipped camera at the earned eligible pillar stance. |
| `qa.channel-threat-label-overlap` | MINOR | DEGRADED | MEDIUM | Crowded channel combat produces overlapping and cropped threat labels. |

---

## Loop 48

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-39-1ee3072661fd` | `development_snapshot:attempt-04717e66decdf010becb2d85` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Make the existing earned departure-to-MF01 dependency chain reviewable through ordinary player actions, while resolving candidate-owned source-binding and observation faults within three bounded tasks. |
| Strategy | `bridge-missing-earned-actions-and-qualify-live-bindings` |
| Tasks | 3 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 3 |
| Changed paths | 5 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-04717e66decdf010becb2d85` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-39-1ee3072661fd` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 7 (6 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `qa.later-rescue-route-continuity` | MAJOR | USER BLOCKING | HIGH | The required rescue ending remains unreachable because production progression implements only village and meadow destinations. |
| `qa.mf01-earned-path-unverified` | MAJOR | INTERNAL | HIGH | MF01 acquisition and restoration remain unobserved because ordinary play did not reach earned E02 completion. |
| `qa.live-contact-source-bindings-unverified` | MAJOR | INTERNAL | HIGH | Exact E02 contact and both live E03 binding qualifications remain unresolved despite supported local attribution and read-only observation code. |
| `qa.earned-departure-unverified` | MAJOR | INTERNAL | HIGH | Earned farewell, complete pillar approach and CP02 arrival remain unverified; the attempted route exposes a cover-navigation risk. |
| `qa.opening-replay-evidence-gap` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:r21-opening-pause-resume Publish qualified intermediate timing; complete cinematic lifecycle remains unresolved. |
| `qa.audio-settings-evidence-gap` | MAJOR | INTERNAL | HIGH | Valid impact capture is preserved, but independent listening and complete Music/Effects settings comparisons remain missing. |
| `qa.hers-portrait-continuity` | MINOR | DEGRADED | MEDIUM | Adjacent portrait continuity fails: ordinary Hers dialogue has no counterpart portrait. |

---

## Loop 47

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-38-cbeed3818140` | `development_snapshot:attempt-f52d413b5e57ff654af5a200` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Complete the bounded qualification and necessary repairs of the existing earned E02→MF01→E03 player module, while supplying the missing normal-departure comparison and preserving working entry/audio inputs. |
| Strategy | `earned-boundary-isolation-and-retained-module-completion` |
| Tasks | 3 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 3 |
| Changed paths | 3 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-f52d413b5e57ff654af5a200` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | BLOCKED |
| Candidate | `loop-38-cbeed3818140` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 8 (7 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `qa.mf01-e03-evidence-gap` | MAJOR | INTERNAL | HIGH | Earned MF01 acquisition/restoration and E03 reveal, combat and reward conditions remain unverified. |
| `qa.e02-lightning-evidence-gap` | MAJOR | INTERNAL | HIGH | Exact E02 lightning acceptance and live E03 binding qualification remain missing despite supported local attribution and resource loads. |
| `qa.departure-matrix-evidence-gap` | MAJOR | INTERNAL | HIGH | The normal-departure proposal passes inspection; earned normal/skip travel and complete recovery remain unverified. |
| `qa.opening-replay-evidence-gap` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:r21-opening-pause-resume Publish qualified intermediate observations; complete cinematic acceptance remains unresolved. |
| `qa.audio-settings-evidence-gap` | MAJOR | INTERNAL | HIGH | Measured Music/Effects mute and restoration work locally; independent listening and travel/restart settings acceptance remain missing. |
| `qa.adoption-delivery-evidence-gap` | MAJOR | INTERNAL | HIGH | Supported ambusher attribution and native loading do not close historical adoption, live binding, delivery or performance qualification. |
| `qa.full-milestone-evidence-gap` | MAJOR | INTERNAL | HIGH | The bounded independent review does not establish full milestone acceptance or close the existing full-closeout gaps. |
| `qa.later-rescue-route-continuity` | MINOR | USER BLOCKING | HIGH | Adjacent continuity fails: the production destination set still cannot reach the required later rescue ending. |

---

## Loop 46

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-37-f46b76bc8e82` | `development_snapshot:attempt-7cfcd4ab05066f1574d29a97` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Advance frozen candidate 9247accd597c1d3e18b6f69d7c1c3b34885ee0c4f2c20243cc0fbab0ba3580ff through a complete E03 lamp ambush, with necessary retained-dependency qualification and candidate-owned evidence-input repairs. |
| Strategy | `advance-e03-with-bounded-input-repair` |
| Tasks | 3 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 3 |
| Changed paths | 22 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-7cfcd4ab05066f1574d29a97` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | BLOCKED |
| Candidate | `loop-37-f46b76bc8e82` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 7 (7 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `qa.mf01-e03-evidence-gap` | MAJOR | INTERNAL | HIGH | Earned MF01 acquisition/restoration and E03 reveal, combat and reward acceptance remain unverified. |
| `qa.e02-lightning-evidence-gap` | MAJOR | INTERNAL | HIGH | The required independent nonlethal E02 lightning hurt and ranged recovery check remains unexecuted. |
| `qa.audio-settings-evidence-gap` | MAJOR | INTERNAL | HIGH | Correct audio proposal mapping and baseline Music output do not close independent listening and active-event settings acceptance. |
| `qa.opening-replay-evidence-gap` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:r21-opening-pause-resume Publish the Host-bound intermediate observations; complete cinematic equivalence remains unverified. |
| `qa.adoption-delivery-evidence-gap` | MAJOR | INTERNAL | HIGH | Native loading and visible adoption remain partial evidence; authentication, complete licenses, desktop delivery and performance are unqualified. |
| `qa.departure-matrix-evidence-gap` | MAJOR | INTERNAL | HIGH | Ordinary earned departure and MAP02 arrival are verified locally; complete transition and recovery acceptance remains open. |
| `qa.full-milestone-evidence-gap` | MAJOR | INTERNAL | HIGH | The bounded independent playthrough does not establish full milestone acceptance; all nineteen criteria remain blocked. |

---

## Loop 45

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-36-9247accd597c` | `development_snapshot:attempt-7ec8a9ef898498a7a3bf886b` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Complete MF01 as the next ordinary player action after E02, with focused combat and presentation observation support, within six new owner-condition bindings. |
| Strategy | `advance-mf01-with-durable-boundary-observation` |
| Tasks | 3 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 3 |
| Changed paths | 17 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-7ec8a9ef898498a7a3bf886b` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | BLOCKED |
| Candidate | `loop-36-9247accd597c` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 7 (6 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `qa.mf01-earned-path-unverified` | MAJOR | INTERNAL | HIGH | MF01 ordinary acquisition and restored M/J information lack independent evidence. |
| `qa.e02-contact-unverified` | MAJOR | INTERNAL | HIGH | CH01 lightning coverage is preserved; earned E02 and complete ranged-contact acceptance remain unqualified. |
| `qa.audio-settings-unverified` | MAJOR | INTERNAL | HIGH | Independent audible Music/Effects settings qualification remains incomplete. |
| `qa.cinematic-coverage-incomplete` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:r21-opening-pause-resume. Complete cinematic equivalence still needs published intermediate observations. |
| `qa.adoption-delivery-unverified` | MAJOR | INTERNAL | HIGH | Visible live adoption does not close authenticated dependency and delivery acceptance. |
| `qa.departure-loader-unverified` | MAJOR | INTERNAL | HIGH | Safe detached departure selectors are demonstrated; loader admission and complete earned travel remain unqualified. |
| `qa.later-rescue-route-continuity` | MINOR | USER BLOCKING | HIGH | Adjacent continuity fails: the inspected production destination set cannot reach the required later rescue ending. |

---

## Loop 44

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-35-9cc374e4e5a9` | `development_snapshot:attempt-f19d39eb463efdd965131e4d` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | On frozen candidate 5aaf32f41b4a5b4cb52623d3ed476ecdf0bad4678e85d6de6e059a9f5e7d0faa, restore ranged lightning contact and deliver earned travel into a separate authored MAP02 with CP02/E01/E02 migrated safely. Preserve candidate observation contracts for independent qualification. |
| Strategy | `separate-map-with-prerequisite-contact-repair` |
| Tasks | 3 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 0 |
| Changed paths | 150 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-f19d39eb463efdd965131e4d` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | BLOCKED |
| Candidate | `loop-35-9cc374e4e5a9` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 8 (8 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `qa.lightning-ranged-retest-incomplete` | MAJOR | INTERNAL | HIGH | CH01 lightning repair passes locally; complete ranged-contact issue closure remains unverified. |
| `qa.e02-victory-unobserved` | MAJOR | INTERNAL | HIGH | Migrated E02 victory and full cover/recovery acceptance remain unobserved. |
| `qa.earned-departure-incomplete` | MAJOR | INTERNAL | HIGH | Earned MAP02 control return passes; complete departure and boundary variants remain unqualified. |
| `qa.cinematic-matrix-incomplete` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:r21-opening-pause-resume. Complete cinematic equivalence needs published intermediate observations. |
| `qa.audio-listening-incomplete` | MAJOR | INTERNAL | HIGH | Independent audio listening and complete active-event settings qualification remain unavailable. |
| `qa.adoption-delivery-incomplete` | MAJOR | INTERNAL | HIGH | Mandatory adoption closure remains insufficiently evidenced despite observed live assets. |
| `qa.retained-grass-qualification-incomplete` | MAJOR | INTERNAL | HIGH | Mandatory retained-grass closure still lacks independent cold import and matched visual qualification. |
| `qa.full-closeout-incomplete` | MAJOR | INTERNAL | HIGH | Full milestone acceptance remains unassessed beyond the independently completed local conditions. |

---

## Loop 43

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-34-5aaf32f41b4a` | `development_snapshot:attempt-658bc4838bd1b370dd37bae1` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Advance the playable route from E01 to E02 with real ranged cover and recoverable combat, while preparing bounded candidate-side support for independent closure of existing entry, opening, audio and E01 evidence gaps. |
| Strategy | `advance_e02_with_separate_evidence_boundary_diagnosis` |
| Tasks | 2 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 2 |
| Changed paths | 14 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-658bc4838bd1b370dd37bae1` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-34-5aaf32f41b4a` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 8 (8 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `qa.lightning-ranged-hurt-callback` | BLOCKER | USER BLOCKING | HIGH | Lightning contact with the ranged guard stops gameplay on an absent on_hurt callback. |
| `qa.e02-victory-unobserved` | MAJOR | INTERNAL | HIGH | Earned E02 approach and recovery are observed; victory and full cover acceptance remain unverified. |
| `qa.earned-departure-incomplete` | MAJOR | INTERNAL | HIGH | Earned CP02 access is now observed, but complete departure presentation and boundary variants remain unqualified. |
| `qa.cinematic-matrix-incomplete` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:r21-opening-pause-resume. Published intermediate replay and complete cinematic equivalence remain missing. |
| `qa.audio-listening-incomplete` | MAJOR | INTERNAL | HIGH | Independent audio listening and complete active-event settings comparisons remain unavailable. |
| `qa.adoption-delivery-incomplete` | MAJOR | INTERNAL | HIGH | Mandatory adoption closure remains insufficiently evidenced. |
| `qa.retained-grass-qualification-incomplete` | MAJOR | INTERNAL | HIGH | Mandatory retained-grass closure lacks independent cold import and matched visual qualification. |
| `qa.full-closeout-incomplete` | MAJOR | INTERNAL | HIGH | Local verified conditions do not establish full milestone completion. |

---

## Loop 42

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-33-e04c4d55ce5b` | `development_snapshot:attempt-c2cf49459ad3cfb387a2023b` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Repair complete journey admission, qualify existing audio/opening observation inputs, and advance one ordinary E01 defeat while preserving earned departure, full E01 continuity and truthful source declarations. |
| Strategy | `validate_admission_phases_and_active_event_evidence` |
| Tasks | 3 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 2 |
| Changed paths | 3 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-c2cf49459ad3cfb387a2023b` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | BLOCKED |
| Candidate | `loop-33-e04c4d55ce5b` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 5 (5 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `qa.audio-listening-gap` | MAJOR | INTERNAL | HIGH | Routing measurements improved coverage, but independent listening and complete active-event comparisons remain unavailable. |
| `qa.opening-matrix-gap` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:r21-opening-pause-resume. Aggregate admission is verified; the complete opening and cinematic matrix remains unverified. |
| `qa.earned-departure-gap` | MAJOR | INTERNAL | HIGH | Pillar approach and negative interaction gate are verified; qualified earned departure and CP02 arrival remain unavailable. |
| `qa.e01-ordinary-reward-gap` | MAJOR | INTERNAL | HIGH | The first ordinary E01 defeat and once-only reward remain blocked on qualified CP02 access. |
| `qa.adoption-authority-gap` | MAJOR | INTERNAL | HIGH | Truthful retained-resource declarations pass locally; complete adoption and delivery remain unqualified. |

---

## Loop 41

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-32-4f655aff5231` | `development_snapshot:attempt-1486d0f4a7b4628f6e805423` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Repair the malformed journey aggregate and make the existing opening/audio, earned-departure and retained-resource inputs ready for independent qualification, while preserving working gameplay and full frozen acceptance. |
| Strategy | `repair_aggregate_grammar_then_qualify_evidence_boundaries` |
| Tasks | 3 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 2 |
| Changed paths | 1 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-1486d0f4a7b4628f6e805423` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | BLOCKED |
| Candidate | `loop-32-4f655aff5231` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 5 (4 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `journey_manifest_empty_input` | MINOR | INTERNAL | MEDIUM | The passive-wait repair is present, but invalid tag syntax still prevents aggregate admission. |
| `audio_listening_incomplete` | MAJOR | INTERNAL | HIGH | Music output suppression/restoration is measured, but independent listening and complementary Effects isolation remain incomplete. |
| `opening_matrix_incomplete` | MAJOR | INTERNAL | HIGH | Opening pause and skipped safe-world return are supported; the complete required variant matrix remains unverified. |
| `earned_departure_retest_blocked` | MAJOR | INTERNAL | HIGH | Qualified earned consent is unavailable; departure and dependent ordinary CP02/E01 acceptance remain blocked. |
| `retained_grass_qualification_incomplete` | MAJOR | INTERNAL | HIGH | Warm FBX/card inspection succeeds; independent opt-in probe, cold import and matched visual qualification remain incomplete. |

---

## Loop 40

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-31-124f6f0c394f` | `development_snapshot:attempt-43fdb045ff984877dd31e396` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | On frozen candidate e46e049a6004eb63006d68c8ed3704a8708bfed7a7530e34cc993242cbbdcfc1, repair the earned blue-pillar activation variant under R19, preserve authoritative objective and delivered E01 continuity under R01, and retain truthful resource qualification under R16. Keep independent opening, audio, arrival and resource acceptance intact. |
| Strategy | `separate_route_objective_delivery_owners` |
| Tasks | 3 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 3 |
| Changed paths | 3 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-43fdb045ff984877dd31e396` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | BLOCKED |
| Candidate | `loop-31-124f6f0c394f` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 6 (6 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `earned_departure_retest_blocked` | MAJOR | USER BLOCKING | HIGH | Earned departure remains unresolved because the required consent save was unavailable. |
| `ordinary_e01_acceptance_unreached` | MAJOR | INTERNAL | HIGH | Ordinary E01 combat, collection and persistence acceptance remains unreached. |
| `audio_listening_incomplete` | MAJOR | INTERNAL | HIGH | Audio output comparisons improved, but required independent listening and transition coverage remain incomplete. |
| `opening_matrix_incomplete` | MAJOR | INTERNAL | HIGH | Normal and held-Space opening outcomes were observed; the complete required variant matrix remains incomplete. |
| `retained_grass_qualification_incomplete` | MAJOR | INTERNAL | HIGH | Warm loading is supported; independent probe execution and cold-import/material preservation qualification remain incomplete. |
| `adoption_baseline_unresolved` | MAJOR | INTERNAL | HIGH | Host adoption-baseline adjudication and authenticated transfer evidence remain unavailable. |

---

## Loop 39

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-30-e46e049a6004` | `development_snapshot:attempt-35371f82dacef02c1826eda6` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | On candidate 40673ae0f3e68870bf280663cbe99d5bfaa19d93862105ff388e853c3b8351a7, complete the two-melee-actor E01 roadblock with durable rewards and an E02 objective, while preserving earned travel and preparing bounded opening/settings and retained-grass qualification inputs. |
| Strategy | `complete_e01_and_isolate_qualification_debt` |
| Tasks | 3 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 3 |
| Changed paths | 12 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-35371f82dacef02c1826eda6` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-30-e46e049a6004` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 6 (5 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `earned_pillar_activation_fails` | MAJOR | USER BLOCKING | HIGH | The earned, active blue pillar does not start departure after ordinary E input. |
| `e01_acceptance_unreached` | MAJOR | INTERNAL | HIGH | Earned travel failure prevents independent E01 completion and persistence acceptance. |
| `retained_grass_preservation_unverified` | MAJOR | INTERNAL | HIGH | Grass native loads succeed, but cold-import and material-preservation acceptance remain incomplete. |
| `settings_audio_unverified` | MAJOR | INTERNAL | HIGH | Required independent Music/Effects listening remains unverified. |
| `opening_variants_unverified` | MAJOR | INTERNAL | HIGH | Normal opening is preserved; remaining variants and lifecycle coverage are incomplete. |
| `journey_manifest_empty_input` | MINOR | INTERNAL | MEDIUM | An empty input step invalidates the delivered journey manifest. |

---

## Loop 38

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-29-40673ae0f3e6` | `development_snapshot:attempt-e89b852347e4d8982b6c23b6` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | For candidate e636a086e3d65fd3d8c1a17af5dd70e62ef0891d38034160517d93399ffb4745, repair retained grass dependencies and qualify pending ranged-pickup recovery and earned farewell-to-CP02 entry, preserving verified behavior. |
| Strategy | `persistent_dependency_repair_and_earned_recovery_boundary_trace` |
| Tasks | 3 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 3 |
| Changed paths | 9 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-e89b852347e4d8982b6c23b6` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | BLOCKED |
| Candidate | `loop-29-40673ae0f3e6` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 5 (5 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `retained_dependency_import_unverified` | MAJOR | INTERNAL | HIGH | Retained dependency repair has clean live load/log evidence, but independent fresh-import and material-preservation acceptance remains incomplete. |
| `settings_listening_unverified` | MAJOR | INTERNAL | HIGH | Required independent Music/Effects listening remains unverified. |
| `opening_variants_unverified` | MAJOR | INTERNAL | HIGH | Normal opening and pause/resume are verified; the remaining required opening variants are incomplete. |
| `reference_adoption_unverified` | MAJOR | INTERNAL | HIGH | Reference adoption remains blocked by unresolved baseline adjudication and incomplete authenticated operations. |
| `earned_departure_unverified` | MAJOR | INTERNAL | HIGH | Earned farewell-to-CP02 travel and travel-time observation safety remain unverified. |

---

## Loop 37

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-28-e636a086e3d6` | `development_snapshot:attempt-bc6647be8f3e9a4e85a8c2a7` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Deliver a reliable earned departure to CP02 on the retained world and actor bindings, with bounded lifecycle and resource dependency repairs, while preserving all frozen acceptance and unresolved independent evidence obligations. |
| Strategy | `discriminate_entry_support_failure_then_complete_earned_departure` |
| Tasks | 2 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 2 |
| Changed paths | 12 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-bc6647be8f3e9a4e85a8c2a7` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-28-e636a086e3d6` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 4 (4 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `retained_texture_dependencies_missing` | MAJOR | DEGRADED | HIGH | Retained texture dependency errors still reproduce on the current candidate. |
| `reference_adoption_unverified` | MAJOR | INTERNAL | HIGH | Truthful Forest notices do not close the conflicting and unauthenticated adoption requirement. |
| `settings_listening_unverified` | MAJOR | INTERNAL | HIGH | Required independent audio-setting listening remains unverified. |
| `opening_matrix_unverified` | MAJOR | INTERNAL | HIGH | Opening skip reaches usable CH01, but the required opening matrix remains incomplete. |

---

## Loop 36

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-27-1c470d480585` | `development_snapshot:attempt-abc2fe433f844f014d94f5b0` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Repair the earned departure approach as one bounded player-visible increment, while qualifying the existing guard reward-recovery dependency and preserving the full milestone acceptance. |
| Strategy | `repair_native_camera_collision_binding_and_qualify_pending_reward_recovery` |
| Tasks | 2 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 2 |
| Changed paths | 4 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-abc2fe433f844f014d94f5b0` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-27-1c470d480585` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 6 (6 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `pending_guard_recovery_unverified` | MAJOR | INTERNAL | HIGH | Pending ranged-pickup recovery remains independently unverified. |
| `earned_travel_matrix_unverified` | MAJOR | INTERNAL | HIGH | Readable pillar access does not establish complete earned chapter travel. |
| `opening_matrix_unverified` | MAJOR | INTERNAL | HIGH | Normal opening completion passes its observation; the full opening matrix remains incomplete. |
| `settings_listening_unverified` | MAJOR | INTERNAL | HIGH | Required independent audio-setting listening remains unresolved. |
| `reference_acceptance_conflict` | MAJOR | INTERNAL | HIGH | Source-read authentication improved, but conflicting baseline-adoption acceptance prevents closure. |
| `fps.runtime.candidate-error-3c0e1afbfbb2` | MAJOR | unlabelled | unlabelled | Godot reported a candidate-owned runtime error: Bridge encounter lacks authored terrain support |

---

## Loop 35

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-26-50e184341cd7` | `development_snapshot:attempt-a8b2cf2d0d1d41f967b9e354` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Deliver one bounded player increment: an earned blue-pillar trip using the existing three-beat departure presentation and safe CP02 handoff, with the existing guard settlement dependency preserved and qualified. |
| Strategy | `restore_departure_resource_closure_then_qualify_existing_guard_lifecycle` |
| Tasks | 2 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 2 |
| Changed paths | 13 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-a8b2cf2d0d1d41f967b9e354` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | BLOCKED |
| Candidate | `loop-26-50e184341cd7` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 5 (4 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `earned_travel_acceptance_unverified` | MAJOR | INTERNAL | HIGH | Departure resources are restored and farewell consent is independently earned, but the trip and unchanged R19 acceptance matrix remain unverified. |
| `guard_recovery_coverage_incomplete` | MAJOR | INTERNAL | HIGH | Actual guard victories and collected-reward persistence are substantially verified; pending/full-bag recovery and E01 closeout remain incomplete. |
| `pillar_camera_occlusion_reproduced` | MINOR | DEGRADED | MEDIUM | The shipped bridge-to-pillar camera still becomes occluded by authored rock and hides the player. |
| `settings_listening_unverified` | MAJOR | INTERNAL | HIGH | Native audio capture is available, but required independent Music/Effects listening remains unresolved. |
| `opening_matrix_unverified` | MAJOR | INTERNAL | HIGH | Normal opening completion is observed, but the remaining opening acceptance matrix cannot be closed. |

---

## Loop 34

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-25-0718a4434195` | `development_snapshot:attempt-b01bb0e8360be7320ca7286d` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Implement the lawful Isha farewell and deliberate blue-pillar journey to MAP02, separately connect the first meadow roadblock through the existing combat foundation, and qualify only the candidate measurement inputs needed for unresolved presentation evidence. |
| Strategy | `separate_chapter_flow_from_combat_and_isolate_evidence_boundaries` |
| Tasks | 2 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 0 |
| Changed paths | 25 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-b01bb0e8360be7320ca7286d` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-25-0718a4434195` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 5 (4 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `milestone_route_incomplete` | BLOCKER | USER BLOCKING | HIGH | Missing departure paintings and provenance make ordinary chapter travel unavailable. |
| `guard_closeout_evidence_incomplete` | MAJOR | INTERNAL | HIGH | Guard settlement and ordinary E01 acceptance remain independently unverified. |
| `opening_matrix_unverified` | MAJOR | INTERNAL | HIGH | Successful opening skip and pause do not close the remaining acceptance matrix. |
| `settings_listening_unverified` | MAJOR | INTERNAL | HIGH | Required independent Music/Effects listening remains unresolved. |
| `pillar_approach_camera_occluded` | MINOR | DEGRADED | MEDIUM | The pillar approach camera becomes occluded by authored rock and hides the player. |

---

## Loop 33

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-24-c7062b95cb09` | `development_snapshot:attempt-273c1d18b21ef550db2da723` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Deliver the earned guard approach and durable combat outcomes, support exact lifecycle diagnosis, and reconcile retained resource declarations. |
| Strategy | `separate_surfaces_and_isolate_boundaries` |
| Tasks | 3 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 3 |
| Changed paths | 62 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-273c1d18b21ef550db2da723` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-24-c7062b95cb09` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 8 (7 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `milestone_route_incomplete` | MAJOR | USER BLOCKING | HIGH | Required chapter progression remains impossible; the new guards extend an unfinished slice. |
| `selected_village_adoption_incomplete` | MAJOR | DEGRADED | HIGH | The selected complete village is not adopted, and retained map/actor transfer declarations remain unauthenticated. |
| `retained_texture_dependencies_missing` | MAJOR | DEGRADED | HIGH | Retained texture dependencies still produce resource-load errors. |
| `guard_closeout_evidence_incomplete` | MAJOR | INTERNAL | HIGH | Guard skip, victory and durable reward acceptance remain independently unverified. |
| `settings_listening_unverified` | MAJOR | INTERNAL | HIGH | Required independent Music/Effects listening acceptance remains unresolved. |
| `opening_matrix_unverified` | MAJOR | INTERNAL | HIGH | Normal opening success does not close the remaining opening acceptance matrix. |
| `lifecycle_boundary_unverified` | MAJOR | INTERNAL | HIGH | The original absent-controls and pending-teardown observation boundaries remain unverified. |
| `hers_portrait_continuity_failed` | MINOR | DEGRADED | MEDIUM | Adjacent Hers dialogue continuity still lacks the counterpart portrait. |

---

## Loop 32

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-23-4d3b0e1f9e4d` | `development_snapshot:attempt-6558fcd909da09e81348d68d` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Deliver a safe, animated CH01 dynamic melee encounter with collectible, persisted rewards, restore ordinary escape from the practice obstruction, and repair presentation observation readiness so Host and Tester can assess the outstanding settings and opening evidence. |
| Strategy | `r18_safe_dynamic_loop_and_entry_observation_isolation` |
| Tasks | 2 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 2 |
| Changed paths | 13 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-6558fcd909da09e81348d68d` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-23-4d3b0e1f9e4d` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 4 (4 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `dynamic_encounter_matrix_incomplete` | MAJOR | INTERNAL | HIGH | The CH01 encounter works in the observed route, but its complete safety, feedback and recovery acceptance remains unverified. |
| `independent_listening_missing` | MAJOR | INTERNAL | HIGH | Music/Effects listening acceptance remains unresolved; gains and waveform presence do not establish the required perceptual comparison. |
| `opening_matrix_incomplete` | MAJOR | INTERNAL | HIGH | Normal opening and pause behavior passed locally, but the complete opening acceptance evidence debt remains. |
| `entry_lifecycle_sampling_incomplete` | MAJOR | INTERNAL | HIGH | The null-safe callback repair is supported by inspection and startup smoke, but its original absent-controls boundary remains unverified. |

---

## Loop 31

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-22-4c75da9ff70c` | `development_snapshot:attempt-d988cfafd48a7e2e2e3ec352` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Deliver a complete, readable half-body Isha bridge conversation that restores safely from an unfinished save, preserving bridge progression and providing truthful resource and evidence handoff. |
| Strategy | `r10_anatomy_replacement_and_restore_lifecycle` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 15 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-d988cfafd48a7e2e2e3ec352` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-22-4c75da9ff70c` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 7 (5 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `practice_obstruction_movement_trap` | MAJOR | DEGRADED | HIGH | Ordinary movement can trap the player beside Ronen's practice obstruction until a saved game is loaded. |
| `reference_authentication_incomplete` | MAJOR | INTERNAL | HIGH | Declared village actor/map source access and complete adoption remain unauthenticated. |
| `independent_listening_missing` | MAJOR | INTERNAL | HIGH | Music/Effects listening acceptance remains unresolved without an audio-capable independent reviewer. |
| `opening_matrix_incomplete` | MAJOR | INTERNAL | HIGH | The pre-existing complete opening acceptance evidence debt remains unresolved. |
| `full_acceptance_closeout_missing` | MAJOR | INTERNAL | HIGH | Local dialogue acceptance does not establish full R10, milestone or product acceptance. |
| `initialization_observation_nil_access` | MINOR | INTERNAL | MEDIUM | An initialization-time observation callback can break the game by accessing an absent controls panel. |
| `hers_portrait_continuity_missing` | MINOR | USER BLOCKING | MEDIUM | Adjacent Hers dialogue still lacks its counterpart portrait. |

---

## Loop 30

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-21-bf5ee2a58e64` | `development_snapshot:attempt-9def3b104d46eba7461e7436` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Continue ordinary play beyond the implemented preparation and bridge briefing: let the player rescue the separate bridge resident and restore the bridge lamp in either order, see the declared local consequences, and resume that progress after saving. Deliver the missing Aelor/Isha portrait pair on the affected dialogue surface. Keep later R10 and chapter-departure acceptance explicit. |
| Strategy | `r10_bridge_actions_with_qualified_dialogue_resource_delivery` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 0 |
| Changed paths | 34 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-9def3b104d46eba7461e7436` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-21-bf5ee2a58e64` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 6 (5 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `dialogue_half_body_missing` | MAJOR | USER BLOCKING | HIGH | Portrait delivery improved, but required half-body presentation is still absent. |
| `reference_adoption_unverified` | MAJOR | INTERNAL | HIGH | Required actor/reference source-transfer claims remain declared-only in the frozen Host audit. |
| `settings_listening_unverified` | MAJOR | INTERNAL | HIGH | Independent Music/Effects listening remains incomplete. |
| `opening_matrix_unobserved` | MAJOR | INTERNAL | HIGH | The broader opening acceptance matrix remains unobserved. |
| `restored_briefing_camera_clipping` | MINOR | DEGRADED | MEDIUM | Restored unfinished briefing holds the camera inside the player model while dialogue is paused. |
| `tester.mcp_coverage_incomplete` | MAJOR | unlabelled | unlabelled | Tester did not complete every required live MCP, source, state, log, and screenshot probe after bounded same-session corrections. |

---

## Loop 29

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-20-d3ecada011b9` | `development_snapshot:attempt-aa34e9a217d67f60f0e2d504` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Complete ordinary Aelor/Isha illustrated dialogue presentation on the frozen loop-20 candidate and repair malformed-history entry as its recovery dependency. This allocation authorizes the selected R15 increment and R01 dependency repair. The already reachable bridge approach should be preserved; the requested substantive bridge-rescue, guard and departure outcomes cannot be scheduled under their deferred owners in this frozen iteration. |
| Strategy | `qualified_portrait_delivery_and_defensive_history_entry` |
| Tasks | 2 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 0 |
| Changed paths | 9 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-aa34e9a217d67f60f0e2d504` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-20-d3ecada011b9` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 4 (3 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `dialogue_portraits_absent` | MAJOR | USER BLOCKING | HIGH | Required Aelor and Isha illustrated portraits remain absent in ordinary dialogue. |
| `r15_audio_listening_unverified` | MAJOR | INTERNAL | HIGH | Independent Music/Effects listening acceptance remains unavailable. |
| `milestone_05_closeout_unassessed` | MAJOR | USER BLOCKING | HIGH | Local recovery success does not establish complete milestone acceptance or actual older-history compatibility. |
| `continued_dialogue_camera_inside_player` | MINOR | DEGRADED | MEDIUM | Restored unfinished dialogue still freezes the camera inside the player. |

---

## Loop 28

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-19-3b28a5ebfd91` | `development_snapshot:attempt-ad75b361a7f063d4078b0237` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Deliver one bounded post-training Isha briefing: deliberate confirmation records bridge information and tracks its reachable approach, with the illustrated portrait pair and coherent saved-dialogue recovery. |
| Strategy | `conditioned_isha_briefing_with_missing_portrait_delivery` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | BLOCKED |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 0 |
| Changed paths | 2 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-ad75b361a7f063d4078b0237` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-19-3b28a5ebfd91` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 4 (3 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `dialogue_portraits_absent` | MAJOR | USER BLOCKING | HIGH | Required Aelor and Isha portraits remain absent in the ordinary bridge briefing. |
| `r15_audio_listening_unverified` | MAJOR | INTERNAL | HIGH | Heard Music/Effects acceptance remains blocked by unsupported reviewer audio input. |
| `milestone_05_closeout_unassessed` | MAJOR | INTERNAL | HIGH | Local briefing success does not establish complete milestone acceptance or older-history compatibility. |
| `continued_dialogue_camera_inside_player` | MINOR | DEGRADED | MEDIUM | Adjacent continuity fails: Continue still freezes the dialogue camera inside the player. |

---

## Loop 27

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-18-f204bbc48250` | `development_snapshot:attempt-fb1fcfce2e3ca1dc23373f11` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Make the existing R15 title-recovery and audio-settings path independently assessable through a bounded observation-binding check, preserving working behavior and retaining external evidence blockers honestly. |
| Strategy | `isolate_external_evidence_dependencies_and_qualify_existing_bindings` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 4 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-fb1fcfce2e3ca1dc23373f11` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-18-f204bbc48250` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 6 (5 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `dialogue_portraits_absent` | MAJOR | USER BLOCKING | HIGH | Required dialogue portraits remain absent in the live Isha conversation. |
| `r15_audio_listening_unverified` | MAJOR | INTERNAL | HIGH | Heard Music/Effects acceptance remains blocked by unsupported reviewer audio input. |
| `milestone_05_closeout_unassessed` | MAJOR | INTERNAL | HIGH | Complete milestone acceptance remains unestablished despite successful local title-recovery checks. |
| `continued_dialogue_camera_inside_player` | MINOR | DEGRADED | MEDIUM | Continue into saved dialogue freezes the camera inside the player until dialogue is exited. |
| `fps.runtime.candidate-error-0d66533e4786` | MAJOR | unlabelled | unlabelled | Godot reported a candidate-owned runtime error: ConfigFile parse error at user://isha_opening.cfg:0: Unexpected EOF while parsing simple tag. |
| `fps.runtime.candidate-error-7766310b3778` | MAJOR | unlabelled | unlabelled | Godot reported a candidate-owned runtime error: ConfigFile parse error at user://isha_slot_1.cfg:0: Unexpected EOF while parsing simple tag. |

---

## Loop 26

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-17-9f390098914e` | `development_snapshot:attempt-ffcd5ecd5db16191cf82635f` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Complete the R15 acquisition-feedback return boundary: make the first sword notice demonstrable through nested pause and restoration, and preserve deliberate input recovery after settings. Address candidate-owned observation defects only where established; retain external evidence dependencies honestly. |
| Strategy | `qualify_first_event_and_modal_return_boundaries` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 3 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-ffcd5ecd5db16191cf82635f` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-17-9f390098914e` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 2 (1 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `r15_audio_listening_unverified` | MAJOR | INTERNAL | HIGH | Required heard Music/Effects comparisons remain unavailable; captured metrics cannot close audio acceptance. |
| `r15_title_recovery_unverified` | MINOR | INTERNAL | MEDIUM | Continue no-replay passed, but corrupt-history and distinct-history title recovery remain unverified. |

---

## Loop 25

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-16-4664dbf42379` | `development_snapshot:attempt-14c7eff6f9e41a8006659be3` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Make the existing audio-settings flow independently observable and complete its separate Music/Effects, persistence and nested-return checks, repairing demonstrated binding defects while preserving the working game. |
| Strategy | `isolate_effective_audio_binding_and_caller_return` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 2 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-14c7eff6f9e41a8006659be3` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | BLOCKED |
| Candidate | `loop-16-4664dbf42379` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 4 (2 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `settings_audio_listening_unverified` | MAJOR | INTERNAL | HIGH | Independent channel routing, persistence and layout checks progressed, but required heard audio comparisons remain unverified. |
| `held_aim_replay_unverified` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:held-aim-controls-settings-release-fresh. Qualified Host replay and complete intermediate pause/input observations remain unavailable. |
| `sword_notice_closeout_unverified` | MINOR | INTERNAL | MEDIUM | Sword acquisition notice lifetime, presentation variants and no-replay checks remain unverified. |
| `title_recovery_closeout_unverified` | MINOR | INTERNAL | MEDIUM | Slot-1 read-denied recovery passed, but corrupt-history and distinct-history entry-binding coverage remain incomplete. |

---

## Loop 24

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-15-7ca4fd59bfd0` | `development_snapshot:attempt-d2b24ec46f1e7db23142d7e1` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_05 |
| Objective | Make the CH01 safe arrival-to-melee-training route recognizable, grounded and usable through ordinary play, with coherent first-acquisition feedback and preserved recovery. Address the three pinned evidence issues through bounded candidate-interface diagnosis while keeping independent recapture and full product acceptance with Host and Tester. |
| Strategy | `ground_training_route_and_isolate_evidence_binding` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 4 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-d2b24ec46f1e7db23142d7e1` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-15-7ca4fd59bfd0` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 5 (3 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `full_r01_acceptance_unassessed` | MAJOR | USER BLOCKING | HIGH | The verified CH01 training route does not establish the full three-map acceptance contract. |
| `sword_notice_closeout_incomplete` | MINOR | INTERNAL | MEDIUM | First sword ownership and notice identity passed; exact lifetime and complete presentation coverage remain unverified. |
| `title_closeout_remaining_histories` | MINOR | INTERNAL | LOW | Continue and repeated failure followed by successful same-slot Retry passed; remaining title recovery evidence is incomplete. |
| `active_pause_matrix_incomplete` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:held-aim-controls-settings-release-fresh. Independent Host replay and complete pause/recovery coverage remain unverified. |
| `settings_effect_matrix_incomplete` | MAJOR | INTERNAL | HIGH | The selected settings closure candidate remains insufficiently evidenced despite a successful Master-volume comparison. |

---

## Loop 23

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-14-56a7e3f1dbb4` | `development_snapshot:attempt-5811249f7a10d2698c5fdf7a` | FAIL |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_04 |
| Objective | Make the existing combat pause/resume boundary independently observable for one live sword readout and held attack/aim inputs, using bounded candidate-owned measurements and ordinary-input journey recipes. |
| Strategy | `isolate_pause_transitions_with_candidate_journeys` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 5 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-5811249f7a10d2698c5fdf7a` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-14-56a7e3f1dbb4` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 6 (3 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `active_pause_matrix_incomplete` | MAJOR | INTERNAL | HIGH | RECAPTURE_REQUEST: GAME_JOURNEY:held-aim-controls-settings-release-fresh. Local transitions pass; independent Host replay and the complete pause/recovery matrix remain unverified. |
| `milestone_04_closeout_unavailable` | MAJOR | USER BLOCKING | HIGH | Chapter-three implementation availability and complete acceptance remain unresolved. |
| `title_closeout_still_unverified` | MINOR | INTERNAL | LOW | Continue preservation passed, but remaining title recovery and same-slot retry evidence is incomplete. |
| `hud_first_event_coverage_incomplete` | MINOR | INTERNAL | LOW | Earned progression does not close the remaining first-event HUD evidence. |
| `settings_effect_matrix_incomplete` | MAJOR | INTERNAL | HIGH | The settings effect-comparison and persistence matrix remains unverified. |
| `practice_target_foreground_marker_overlap` | MINOR | DEGRADED | MEDIUM | Adjacent presentation continuity fails: the foreground practice label overlaps the player. |

---

## Loop 22

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-13-3efff51ad5c9` | `development_snapshot:attempt-b2862ebf2e28c906c1cd1dc7` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_03 |
| Objective | Deliver reversible, content-sized vitals geometry and the minimal read-only pause correlation needed to inspect active elemental state, while preserving the verified combat HUD. |
| Strategy | `restore_vitals_layout_ownership_and_correlate_pause_entities` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 2 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-b2862ebf2e28c906c1cd1dc7` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | BLOCKED |
| Candidate | `loop-13-3efff51ad5c9` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 2 (1 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `vitals_pending_content_unobserved` | MINOR | INTERNAL | MEDIUM | The pending-point vitals variant remains unobserved despite successful rollback at both resolutions. |
| `active_pause_matrix_incomplete` | MAJOR | INTERNAL | HIGH | Live fire pause correlation is observed, but the complete pause and manual-slot recovery matrix remains unverified. |

---

## Loop 21

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-12-44c465f64d48` | `development_snapshot:attempt-d07ccc5da930257e8cab2213` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_03 |
| Objective | Deliver a readable earned-combat HUD: prevent early ownership states from collapsing the bottom shortcut strip and keep actual sword-hit readouts clear during play. |
| Strategy | `repair_hud_layout_ownership_and_verify_resolved_hit_readability` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 8 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-d07ccc5da930257e8cab2213` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | BLOCKED |
| Candidate | `loop-12-44c465f64d48` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 2 (1 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `milestone_closeout_unavailable` | MAJOR | USER BLOCKING | HIGH | Chapter-two implementation availability and complete acceptance evidence remain unresolved; the local HUD repair does not close the milestone. |
| `vitals_scale_rollback_retains_geometry` | MINOR | DEGRADED | MEDIUM | The known vitals card geometry defect remains visible after returning text scale to 100%. |

---

## Loop 20

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-11-059b740c684a` | `development_snapshot:attempt-c34446e580c9c5659a0ca64a` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_02 |
| Objective | Restore the earned training monster's grounded pursuit and readable, authoritative attack contact on the existing authored terrain, making sword teaching lead into an active encounter. |
| Strategy | `repair_terrain_navigation_dependency_for_earned_encounter` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 3 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-c34446e580c9c5659a0ca64a` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-11-059b740c684a` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 2 (1 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `initial_enemy_obstacle_clearance_unverified` | MAJOR | INTERNAL | HIGH | Task condition 0 remains blocked: grounded pursuit works, but clearance around a reachable existing solid obstacle lacks independent evidence. |
| `initial_encounter_audio_quality_unverified` | MINOR | INTERNAL | MEDIUM | Attack/contact audio output and causality were captured; perceptual audio quality remains unverified. |

---

## Loop 19

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-10-4273fba4ff63` | `development_snapshot:attempt-fc4dfcc399e690f881f04171` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_02 |
| Objective | Restore compact, readable objective tracking after text-scale changes by repairing its upstream life-panel layout dependency within the existing HUD. |
| Strategy | `repair_upstream_life_panel_layout_dependency` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 0 |
| Changed paths | 1 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-fc4dfcc399e690f881f04171` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-10-4273fba4ff63` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 6 (2 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `tracker_geometry_recovery_verified` | NOTE | INTERNAL | LOW | The tracker geometry repair passes the complete short/wrapped matrix; hud_tracker_retained_height is verified. |
| `enemy_pursuit_unavailable` | MAJOR | DEGRADED | HIGH | The first live enemy cannot pursue the player because navigation remains unready; the encounter behaves as a stationary damage target. |
| `milestone_acceptance_evidence_missing` | MAJOR | INTERNAL | HIGH | The local tracker repair passes, but the full milestone and compound R04/R22 acceptance remain incompletely assessed. |
| `title_closeout_still_unverified` | NOTE | INTERNAL | LOW | Continue preservation is observed, but the selected title closeout issue still lacks its remaining boundary evidence. |
| `hud_first_event_coverage_incomplete` | NOTE | INTERNAL | LOW | Earned progression supplies additional HUD observations, but does not complete the selected first-event evidence issue. |
| `next_chapter_boundary_unverified` | MINOR | INTERNAL | LOW | The immediately next chapter-entry boundary has insufficient independent evidence. |

---

## Loop 18

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-09-cee6947a53ab` | `development_snapshot:attempt-88ad297ca79e350efa6128e5` | BLOCKED |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_01 |
| Objective | Restore error-free inventory focus and return to ordinary traversal, then make one automatic step crossing observable on the shipped route without regressing the verified controls. |
| Strategy | `repair_shared_focus_eligibility_then_qualify_authored_step` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 0 |
| Changed paths | 4 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-88ad297ca79e350efa6128e5` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | BLOCKED |
| Candidate | `loop-09-cee6947a53ab` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 1 (1 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `r02_runtime_boundaries_unverified` | MAJOR | INTERNAL | HIGH | The authored step crossing and settled support are demonstrated, but uninterrupted support and complete R02 acceptance remain unverified. |

---

## Loop 17

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-08-ebc3d6646f03` | `development_snapshot:attempt-00f1767cc1a220d482d400c6` | FAIL |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / milestone_01 |
| Objective | Deliver one bounded R02 input-ownership increment: B executes the existing roll, inventory uses a distinct control, and rebinding remains usable and persistent; preserve tracker geometry and support independent completion of its missing evidence. |
| Strategy | `restore_distinct_action_ownership_and_isolate_settled_capture` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 5 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-00f1767cc1a220d482d400c6` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-08-ebc3d6646f03` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 6 (2 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `r02_runtime_boundaries_unverified` | MAJOR | INTERNAL | HIGH | Full R02 acceptance remains blocked by unverified traversal, obstruction and attachment boundaries. |
| `tracker_scale_rollback_position_drift` | MINOR | DEGRADED | MEDIUM | Tracker height recovers, but its vertical position does not; the complete frozen matrix remains unfinished. |
| `shortcut_early_ownership_wrapping` | MINOR | DEGRADED | MEDIUM | Early equipment states still collapse shortcut instructions into excessive wrapping. |
| `vitals_scale_rollback_retains_geometry` | MINOR | DEGRADED | MEDIUM | Vitals retain enlarged width and blank height after text scale returns to 100%. |
| `isha_portrait_continuity_remains_open` | MINOR | USER BLOCKING | MEDIUM | Adjacent dialogue continuity still fails because required portraits are absent. |
| `fps.runtime.candidate-error-ea18d19a2edb` | MAJOR | unlabelled | unlabelled | Godot reported a candidate-owned runtime error: Index p_idx = 0 is out of bounds (items.size() = 0). |

---

## Loop 16

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-07-878836883f1a` | `development_snapshot:attempt-478ab2111ee562369f71b32b` | FAIL |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / forest_environment |
| Objective | Restore reliable lightning hits on real enemies in the retained Forest bridge encounter and make tracker states unambiguous to observe, without replacing working map, actor, progression or save bindings. |
| Strategy | `repair_mixed_lightning_targets_and_correlate_tracker_observations` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 2 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-478ab2111ee562369f71b32b` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-07-878836883f1a` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 3 (2 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `lightning-negative-case-unobserved` | MAJOR | INTERNAL | HIGH | The lightning error repair is verified, but invalid/freed-target and adjacent fire acceptance remain unobserved. |
| `tracker-matrix-incomplete` | MINOR | INTERNAL | MEDIUM | Tracker height recovery is supported, but one required settled screenshot prevents closure of the frozen matrix. |
| `forest-review-evidence-incomplete` | MAJOR | INTERNAL | HIGH | The scoped repair does not establish full Forest environment acceptance. |

---

## Loop 15

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-06-6a7a368c99e8` | `development_snapshot:attempt-12128038f172031fb4b65735` | FAIL |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / first_chapter_lamp |
| Objective | Advance the bound candidate from completed bow training through Isha's old-lamp handoff, real reveal and either first-element practice, then across the authored bridge into a bounded two-enemy encounter whose rewards enter a usable backpack and ownership-driven HUD. Preserve the existing opening, training, camera, pause and save interfaces. |
| Strategy | `implement_missing_post_bow_route_with_shared_reward_inventory_authority` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | PASS |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 0 |
| Changed paths | 152 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-12128038f172031fb4b65735` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-06-6a7a368c99e8` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 11 (8 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `default_roll_opens_inventory` | MAJOR | DEGRADED | HIGH | The default B roll binding is intercepted by inventory, making roll unavailable on its configured key. |
| `shortcut_panel_narrow_ownership_states` | MINOR | DEGRADED | MEDIUM | The shortcut panel collapses into unreadable wrapping during early ownership states. |
| `vitals_retains_enlarged_geometry` | MINOR | DEGRADED | MEDIUM | The vitals panel retains enlarged blank geometry after text scale returns to 100%. |
| `tracker_matrix_incomplete` | MINOR | INTERNAL | MEDIUM | Tracker observations support the repair, but the complete frozen content/resolution matrix remains incomplete. |
| `opening_matrix_incomplete` | MAJOR | INTERNAL | HIGH | Normal opening playback is observed; the selected opening acceptance matrix remains incomplete. |
| `active_pause_matrix_incomplete` | MAJOR | INTERNAL | HIGH | Nested pause timing is partially verified; active-world, held-input and manual-slot fault coverage remains incomplete. |
| `settings_effect_matrix_incomplete` | MAJOR | INTERNAL | HIGH | Settings scale and positive audio observations do not close the required effect-comparison matrix. |
| `fps.runtime.candidate-error-fbd2eca17385` | MAJOR | unlabelled | unlabelled | Godot reported a candidate-owned runtime error: Attempted to push_back an object of type 'CharacterBody3D' into a TypedArray, which does not inherit from 'StaticBody3D'. |
| `fps.runtime.candidate-error-d6ccfb2695ca` | MAJOR | unlabelled | unlabelled | Godot reported a candidate-owned runtime error: Condition "!_p->typed.validate(value, "push_back")" is true. |
| `fps.runtime.candidate-error-19b1aab47037` | MAJOR | unlabelled | unlabelled | Godot reported a candidate-owned runtime error: Attempted to append_array an object of type 'CharacterBody3D' into a TypedArray, which does not inherit from 'StaticBody3D'. |
| `fps.runtime.candidate-error-9d723d49756b` | MAJOR | unlabelled | unlabelled | Godot reported a candidate-owned runtime error: Condition "!_p->typed.validate(write[i], "append_array")" is true. |

---

## Loop 14

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-05-81a46c7da4a0` | `development_snapshot:attempt-ceeb19726c8fd57d268d4f65` | FAIL |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / illustrated_opening |
| Objective | Integrate the approved illustrated opening into ordinary New Game entry, including safe pause/settings and persistence boundaries, while repairing shared settings visibility and objective-panel reflow needed for a readable return to gameplay. |
| Strategy | `integrate_approved_opening_with_shared_menu_visibility_and_safe_handoff` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 21 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-ceeb19726c8fd57d268d4f65` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-05-81a46c7da4a0` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 5 (3 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `opening_acceptance_evidence_incomplete` | MAJOR | INTERNAL | HIGH | Opening implementation is observable, but required audio and persistence/skip boundaries remain unverified. |
| `pause_active_world_evidence_remaining` | MAJOR | INTERNAL | HIGH | Cinematic and active sword pause checks pass observed cases; the broader active-world matrix remains incomplete. |
| `settings_effect_evidence_remaining` | MAJOR | INTERNAL | HIGH | Settings visibility repair is verified; several required option effects remain independently unverified. |
| `hud_reflow_evidence_remaining` | MINOR | INTERNAL | MEDIUM | Tracker measurements support the repair, but its complete required regression recipe remains unverified. |
| `opening_isha_portrait_continuity` | MINOR | USER BLOCKING | MEDIUM | Adjacent Isha dialogue continuity still fails because required portraits are absent. |

---

## Loop 13

> A host-derived record of one Planner → Developer → QA Tester cycle.

| Candidate | Base | Current state |
| --- | --- | --- |
| `loop-04-b183d0425e2a` | `development_snapshot:attempt-d75b663440d699e3922c750b` | FAIL |

### Project Planner

| Field | Value |
| --- | --- |
| Status | PLANNED |
| Focus | phase / game_settings_pause |
| Objective | Complete the player-facing settings/pause module for the bound loop-04 candidate, replacing the combined prototype controls page with consistent state-bound presentation, real persistent options and safe nested navigation, while making existing evidence debt accurately inspectable without fabricating product state or acceptance. |
| Strategy | `replace_combined_controls_with_shared_settings_and_owned_pause_flow` |
| Tasks | 1 |

### Developer

| Field | Value |
| --- | --- |
| Status | NEEDS VISUAL QA |
| Summary | Implementation details are retained in the private HoH Runtime audit. |
| Completed tasks | 1 |
| Changed paths | 19 |
| Blocker | See the QA outcome below. |
| Attempt | `attempt-d75b663440d699e3922c750b` |

### QA Tester

| Field | Value |
| --- | --- |
| Status | FAIL |
| Candidate | `loop-04-b183d0425e2a` |
| Product completion | IN PROGRESS |
| Review scope | `phase` |
| Findings | 7 (3 blocking focus items) |

### Evidence / QA findings

| ID | Severity | Impact | Release risk | Summary |
| --- | --- | --- | --- | --- |
| `settings_focus_feedback_hidden` | MAJOR | DEGRADED | HIGH | Settings can focus invisible controls and hide key-binding rejection feedback. |
| `hud_tracker_retained_height` | MINOR | DEGRADED | MEDIUM | The objective panel retains excessive blank height after settings/layout transitions. |
| `settings_effect_validation_incomplete` | MAJOR | INTERNAL | HIGH | Several release-required settings effects and layout states remain independently unverified. |
| `pause_active_world_validation_incomplete` | MAJOR | INTERNAL | HIGH | Idle nested pause and safe saves pass observed checks; complete active-world freeze and recovery boundaries remain unverified. |
| `hud_legacy_feedback_evidence_remaining` | MINOR | INTERNAL | LOW | Selected HUD first-event evidence remains incomplete; the existing save does not supply the required notice states. |
| `title_closeout_evidence_remaining` | MINOR | INTERNAL | LOW | Saved five-life restoration is observed; remaining title closeout histories and boundaries remain unverified. |
| `actor_continuity_evidence_remaining` | MINOR | INTERNAL | LOW | The existing save supplies an idle enemy, leaving obstacle/contact and perceptual actor evidence incomplete. |

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

- Latest candidate: `loop-63-763b7c2b7817`
- Accepted candidate: `none`
- Latest attempted: `loop-63-763b7c2b7817`
- Latest warm start: `loop-63-763b7c2b7817`
- Last published: `loop-62-763b7c2b7817`
- Best verified: `loop-62-763b7c2b7817`
- Generated by the HoH host from immutable run evidence.
