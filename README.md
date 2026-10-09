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
| Open | 38 |
| Closed | 29 |
| All | 67 |

GitHub Closed includes verified fixes, waived issues and policy-invalidated issues; it is not a product-fix count.

### Current run ledger

| Field | Value |
| --- | --- |
| Active | 21 |
| Verified closed | 20 |
| Policy invalidated | 5 |
| Waived | 0 |
| All in this run | 46 |

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
| `settings_effect_validation_incomplete` | [#34](https://github.com/Flesymeb/aelors-adventure/issues/34) | OPEN | Required independent Music/Effects listening remains unresolved. |
| `default_roll_opens_inventory` | [#37](https://github.com/Flesymeb/aelors-adventure/issues/37) | CLOSED | Independently verified resolved at loop 8. |
| `fps.runtime.candidate-error-19b1aab47037` | [#38](https://github.com/Flesymeb/aelors-adventure/issues/38) | POLICY_INVALIDATED | Policy-invalidated; this closure does not assert a product repair. |
| `fps.runtime.candidate-error-9d723d49756b` | [#39](https://github.com/Flesymeb/aelors-adventure/issues/39) | POLICY_INVALIDATED | Policy-invalidated; this closure does not assert a product repair. |
| `fps.runtime.candidate-error-d6ccfb2695ca` | [#40](https://github.com/Flesymeb/aelors-adventure/issues/40) | POLICY_INVALIDATED | Policy-invalidated; this closure does not assert a product repair. |
| `fps.runtime.candidate-error-fbd2eca17385` | [#41](https://github.com/Flesymeb/aelors-adventure/issues/41) | CLOSED | Independently verified resolved at loop 7. |
| `opening_acceptance_evidence_incomplete` | [#36](https://github.com/Flesymeb/aelors-adventure/issues/36) | OPEN | Successful opening skip and pause do not close the remaining acceptance matrix. |
| `shortcut_panel_narrow_ownership_states` | [#42](https://github.com/Flesymeb/aelors-adventure/issues/42) | CLOSED | Independently verified resolved at loop 12. |
| `vitals_retains_enlarged_geometry` | [#43](https://github.com/Flesymeb/aelors-adventure/issues/43) | CLOSED | Independently verified resolved at loop 13. |
| `forest-review-evidence-incomplete` | [#44](https://github.com/Flesymeb/aelors-adventure/issues/44) | OPEN | untitled issue |
| `fps.runtime.candidate-error-ea18d19a2edb` | [#46](https://github.com/Flesymeb/aelors-adventure/issues/46) | CLOSED | Independently verified resolved at loop 9. |
| `lightning-negative-case-unobserved` | [#45](https://github.com/Flesymeb/aelors-adventure/issues/45) | OPEN | untitled issue |
| `r02_runtime_boundaries_unverified` | [#47](https://github.com/Flesymeb/aelors-adventure/issues/47) | OPEN | untitled issue |
| `milestone_acceptance_evidence_missing` | [#48](https://github.com/Flesymeb/aelors-adventure/issues/48) | OPEN | Missing departure paintings and provenance make ordinary chapter travel unavailable. |
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
| `hers_portrait_continuity_missing` | [#61](https://github.com/Flesymeb/aelors-adventure/issues/61) | OPEN | Adjacent Hers dialogue continuity still lacks the counterpart portrait. |
| `initialization_observation_nil_access` | [#62](https://github.com/Flesymeb/aelors-adventure/issues/62) | CLOSED | Independently verified resolved at loop 25. |
| `practice_obstruction_movement_trap` | [#63](https://github.com/Flesymeb/aelors-adventure/issues/63) | CLOSED | Independently verified resolved at loop 23. |
| `reference_adoption_unverified` | [#58](https://github.com/Flesymeb/aelors-adventure/issues/58) | OPEN | The selected complete village is not adopted, and retained map/actor transfer declarations remain unauthenticated. |
| `full_acceptance_closeout_missing` | [#60](https://github.com/Flesymeb/aelors-adventure/issues/60) | OPEN | untitled issue |
| `dynamic_encounter_matrix_incomplete` | [#64](https://github.com/Flesymeb/aelors-adventure/issues/64) | OPEN | untitled issue |
| `retained_texture_dependencies_missing` | [#66](https://github.com/Flesymeb/aelors-adventure/issues/66) | OPEN | Retained texture dependencies still produce resource-load errors. |
| `guard_closeout_evidence_incomplete` | [#65](https://github.com/Flesymeb/aelors-adventure/issues/65) | OPEN | Guard settlement and ordinary E01 acceptance remain independently unverified. |
| `pillar_approach_camera_occluded` | [#67](https://github.com/Flesymeb/aelors-adventure/issues/67) | OPEN | The pillar approach camera becomes occluded by authored rock and hides the player. |

### HoH-managed GitHub issues across runs

Snapshot from the last successful issue sync. These counts include earlier runs; unrelated repository issues are outside the HoH namespace.

| Scope | Open | Closed | All |
| --- | --- | --- | --- |
| GitHub HoH namespace | 38 | 29 | 67 |
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

- Latest candidate: `loop-25-0718a4434195`
- Accepted candidate: `none`
- Latest attempted: `loop-25-0718a4434195`
- Latest warm start: `loop-25-c7062b95cb09`
- Last published: `loop-25-0718a4434195`
- Best verified: `loop-25-0718a4434195`
- Generated by the HoH host from immutable run evidence.
