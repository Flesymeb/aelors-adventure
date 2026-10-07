# Title entry increment

Launch now starts ui/title_menu.tscn. GameEntry owns routing, mouse/focus and
entry lifecycle. AdventureState owns saved facts; title construction loads only
preferences. Load previews read ConfigFile metadata without restoring or writing
history. Two manual slots retain the existing save format and paths.

The materialized Maaack MIT menu/focus/loading unit is adapted under
ui/menu_foundation. Its independent AppConfig, settings owners, FPS artwork,
fixed margins and clipboard exit hook are omitted. SceneLoader first loads
world.tscn in a worker; Preview.tscn then loads on the main thread with that world
cached. Thread-loading Preview directly stalled on its preload dependency chain
in the first compatibility probe. The revised boundary completed entry.

Entry retains a snapshot until all player, sword and bow training placements
are grounded and held confirmation controls are released. Resource completion
alone does not mark readiness. New/manual entry promotes the automatic history
only after safe initialization. Failure frees the partial world, rolls back the
snapshot, and offers retry/back. Continue permits a structurally valid depleted
auto history and restores the existing Game Over. New Game never deletes manual
slots. Return-to-title retires the world/audio; unresolved failed commits remain
visible instead of discarding progress. Existing Forest, player, equipment,
dialogue, training and Snaiel bindings are retained.

Developer checks on Godot 4.7 Forward+: rescan/import, real title boot, disabled
Continue/no-save load slots, submenu/back, fresh unarmed three-life entry, safe
world readiness, F10 menu return, settings persistence/scaling, New Game cancel,
and actual captured focus/confirm/back audio (Master capture
75208058-2296370b: non-silent waveform, no clipping). Revised scripts booted with clean
runtime logs. Initial panel slicing and non-inherited text-scale overrides were
found and corrected. Headings/old-lamp ornament remain outside the scrolling
action list, preventing automatic focus scrolling from clipping the title. Spot views covered 1280x720 (100/200%) and a runtime-resized
1920x1080 (150%). The complete resolution/scale matrix, pointer interaction,
pressed/hover states, two distinct manual histories, corrupted/failed saves,
zero-life continuation, actual exit/restart and muted/unavailable/failure audio
still require independent Host/Tester observation. Background project-use authority was checked against PRD 6.10 and its original
generation record; the registered receipt remains unchanged. No phase acceptance or
historical performance/actor-quality closure is claimed.

Architecture recovery: ui/menu_foundation/main_menu.tscn now inherits the
registered Maaack base PackedScene under ui/menu_foundation/maaack. Its exact
sibling main_menu.gd extends MainMenu, preserving the source scene hierarchy,
button signal routes and base submenu lifecycle. The product overrides entry,
exit confirmation, focus restoration and layout; the same authored background,
headings, focus container and four buttons populate the qualified parchment
layout. Continue remains the added product action. ui/title_menu.gd is a
compatibility subclass of that product menu.

The complete base-scene dependency closure, including native confirmation
windows, source focus and UI sound controller, is retained with its transfer
receipt, attribution and MIT license. The base source script resolves its old
AppConfig/SceneLoader singleton dependencies through an explicit scene path and
injected loader. Its existing submenu construction assigns the product host
before ready. WindowContainer.show retains its implementation with a local
native_method_override warning annotation for this pinned runtime. Inherited
source music and diagnostic version display are disabled;
product confirmation and audio remain the active owners. Unrelated bundle files
are omitted. Earlier observations above remain limited to their original runs;
independent game_title_entry_review acceptance remains pending.


# Gameplay interface increment

GameplayHUD owns player HP/XP, five lit/extinguished life lanterns, one short
tracked objective, contextual interaction and event notifications. CombatHUD
retains enemy danger/health and combat outcomes; its player/checkpoint card and
Preview's objective/prompt/permanent F10 creation paths are retired. ArcheryHUD
retains the reticle and scaled ammunition readout and hides during modal ownership.
The inherited Maaack journal uses the live CaptureFocus utility and parchment
page adapter. J opens it, H collapses/reopens the tracker; current/completed/help
tabs, selection and tracking project dialogue_state facts. Unreached quest rows
are hidden. The journal's tracking/collapse fields are backward-compatible save
fields, not quest/reward authorities. Its persistent footer states exact lives
and the existing checkpoint rules. Confirmed save results emit one signal;
success notices last 2.7 seconds of exploration time, failure persists with F5
retry. Restoration clears old notices. Life changes/recovery are observed from
existing facts; this increment grants no chapter life rewards. Legal 0–5-life
histories now validate/restore faithfully instead of clamping to three.

The existing player remains the sole camera/input owner. Free distance is
clamped to 2.0–6.5 metres, wheel steps are 0.45 metres, and smoothing is independent
of collision shortening. Aiming freezes the free target and returns to it;
first person ignores wheel zoom. Mouse sensitivity is a persisted multiplier
(0.25–2.5) available in title and existing pause controls. Modal owners suspend
world input, preserve nested journal/dialogue ownership, and retain held-input
guards. Focus loss cancels aiming/draw; the first recapture click is consumed.
Arrow collision, launch direction, poses and IK are unchanged.

Load Return now occupies the shared page footer outside the scrolling slot list
and receives initial focus after settled layout. Mute is applied by the state
setter and restored preferences to Master, with one reused AudioEffectAmplify
before downstream effects. Bus mute alone left pre-mute capture samples audible
in the first diagnostic; gain attenuation plus bus mute was retested. Unmuting
restores gain without creating/restarting any sound source.

Developer observations: native Godot 4.7 Forward+ import/rescan and title/world
boot; corrected one parser error and one inherited journal cancellation error.
1280x720 at 200% showed the original clipped Return and the complete revised
focused Return. Ordinary J/F10/Esc showed journal pause and nested return;
relative mouse/wheel changed actual camera angle and free target with settled
collision length. Real Isha acceptance changed XP to 10 and added the sword
quest row. In-memory diagnostic configuration checks restored 0–5, rejected
fractional/six-life records and did not replay a committed reward. They are
Developer checks, not independently supplied legal-history observations.

Audio diagnostics: baseline forest output was non-silent (290434787-3c3ba2c4).
The initial bus-only mute capture failed (149542728-fbdfc63a); corrected muted
forest output (8705988-50dfe57d) reported silence_frame_ratio 1.0 and -120 dB RMS,
with actual ambient source transitions. Full title/loading/gameplay/manual-load/
return/restart audio and all six resolution/scale combinations still belong to
independent Host/Tester acceptance. The Runtime window-size operation did apply
1920x1080; it is environment setup, not physical-pointer qualification.

Independent closeout remains pending: complete HUD/journal/prompt/death/reward
and notification timing matrix; ordinary mouse/wheel, sensitivity, aim/shoulder,
wall/low-ceiling collision and focus-loss regression; isolated valid/empty/corrupt/
write-failure histories; audio, absolute-pointer and background qualification.
No phase pass, formal issue closure, chapter award or later progression claim
is made. The supplied Computer-Use backend remains unready; a supported native
probe does not establish independent collector readiness.

Official API decisions used ScrollContainer.ensure_control_visible timing and
follow_focus, Control input propagation/focus, SpringArm3D.spring_length and
get_hit_length, AudioServer.set_bus_mute and AudioEffectAmplify.volume_db from
the corresponding stable class references at docs.godotengine.org/en/stable/classes/.

# RPG actor foundation increment

TrainingMonster.tscn now inherits the reusable Snaiel-derived HybridEnemy and
BaseEnemy scene unit. combat/enemy_product_adapter.gd injects the existing
training eligibility, ground support, player hitbox, cues and defeat settlement.
training_monster.gd is only a compatibility alias; its former hand-written
state driver and body-centered contact scan are retired. The reusable unit owns
blackboard decisions, patrol/chase/return, terrain-qualified navigation,
AnimationTree timing, enemy health, hurt/death and posed palm contact. Existing
Snaiel melee windows and hitbox instance deduplication retain one damage path.
SwordTraining owns acquisition, defense, recovery and presentation policy;
DialogueState retains quest, save and one-time reward facts. No new map or floor.

The actual Orc catalog maps Idle/Walk/Punch/HitReact/Death through the scoped
Hybrid blend tree and animation recipients. LowerArm.R carries the posed fist
source; this rig has no separate wrist, so its palm offset is measured from
Middle1.R's rest transform. Anticipation, delayed active contact and recovery
are separate stages. Hurt, target loss, load, recovery and death close contact.
Dead restoration seeks the terminal Death pose; alive restoration reactivates
its tree. Private runtime meshes repair zero-area UV triangles without changing
source geometry, skin or materials. Remaining map UV findings are out of scope.

Blender 4.5.14 LTS conversion and native Godot 4.7 Forward+ import of upstream
YBot/combat-library probes succeeded. YBot contained only a bind-pose clip;
the combat library contained slash/thrust/block/death clips but lacked the
retained Orc LowerArm.R contact binding. These temporary probes were removed.
The live scoped rig remains the qualified Quaternius Orc. A bounded alternate
NPC outfit acquisition failed: provider_unavailable, Quaternius itch.io file
resolution failed. No downloaded outfit is claimed. Existing licensed village
geometry supplies the variants; independent visual suitability remains pending.

Ronen and Hers instantiate actors/npc_presentation.tscn, a Node3D presentation
unit without input, cameras, traversal, projectiles or save authority. Complete
base heads, UAL1/UAL2 and KayKit bow retarget/IK and calibrated mounts remain.
Hers removes the hood and carries authored mirrored metal shoulders; Ronen
removes shoulder armor and carries an authored arrow bundle. Materials are
private. Both retain ordinary interaction and sword/bow demonstrations.

H is reserved in both current rebinding and saved-settings sanitization; valid
unrelated logical-key preferences survive repair. Shared sensitivity telemetry
safely handles parents without DialogueState. Teaching/reward notices use the
HUD lane immediately rather than queuing behind autosaves; persistence failures
retain priority. Restoration/reward messages expose no CP01/Q02 identifiers.
The notice and contextual prompt lane stays above scaled bow ammunition.

Developer checks: initial NPC telemetry debugger error reproduced, then broad
observation retested safely; live H rejection and isolated in-memory saved-key
sanitization passed. Early isolated enemy/contact prototype checked progressing
Punch/HitReact/Death, anticipation HP100/hits0, active HP94/hits1, hurt/death
interruption and dead/alive restoration. Ordinary inputs accepted Isha's task,
earned/equipped the sword, hit the grass target, completed directional blocking,
walked the real route, acquired the enemy and observed advancing Punch frames
with HP100 then HP94 and one recorded contact. Two sword hits produced HP24→12→0,
HitReact/Death, one committed remnant and XP10→20. Ronen's bow grant and draw/release
demonstration completed with twelve arrows and no NPC projectile authority.
These are Developer integration checks, not independent foundation acceptance.
Audio capture 419413322-dc08a7eb was non-silent with no clipped frames but captured
mainly ambient source events; exact combat-cue causality remains unverified.

Independent rpg_template_foundation_review remains unverified. Retain the full
HUD closeout matrix: 1280x720 and 1920x1080 at 100/150/200%; ordinary teaching,
reward/restoration with ammo, pause/nested modal and remaining camera/focus
boundaries; legal 3→4→5 and 3→2→1→0 life histories with restart/load; valid/empty/
corrupt/depleted histories, persistence failure and retry, and audio/mute across
entry/loading/gameplay/load/return/restart. Host life-history and persistence-fault
fixtures were requested and remain unavailable. Isolated layout/configuration
checks cannot replace these histories. title_entry_closeout_evidence_missing
remains unresolved. No phase pass or formal independent issue closure is claimed.

Additional isolated HUD layout probes exercised both viewport sizes and all
three text scales with twelve visible arrows. Notice bounds stayed above ammo;
200% shipped-camera frames were readable at 720p and 1080p. A scale-transition
probe exposed a retained Control minimum that briefly placed a hidden prompt
below its intended gap; positioning now uses its actual clamped height. These
synthetic notices/scales do not validate ordinary restoration/fault histories.

Retest after the lane/arrow corrections: ordinary E refill displayed the teaching
message immediately for its requested duration beside a live contextual prompt
and twelve arrows. An isolated 200→100% transition kept both bounds above ammo.
Ronen rear recapture shows the authored arrow bundle; its original +Z mesh axis
is now rotated up the back. Ordinary replay, charged bow draw/release and first
contact killed the enemy once for 24 HP, consumed one arrow and retained XP20.
Latest mesh audit clears newly bound NPC/enemy surfaces; unchanged stowed player
sword and three existing map surfaces retain UV findings. Latest Preview runtime
logs contain only engine/bridge startup, with no debugger break.

The editor's earlier import buffer also retained missing res:// texture and
Objects/Grass_Texture.psd messages from qualification work. They are preserved
as failed probe evidence; temporary upstream media is not shipped. Final-launch
logs must be assessed from the new run rather than treating historic diagnostics
or successful exit codes as clean import evidence.

Final main-scene check restored the earned bow, HP94, eleven arrows and XP20
without replaying the reward. The exact F10→Enter→H→Escape→H sequence retained
Roll B; a focused recapture showed readable H rejection, then controls returned
and H changed the tracker while B moved the player. Incremental editor and fresh
runtime logs were clean. Final inspection found dead-restoration telemetry reading
the inactive tree's Start node instead of the paused Death clip; the animation
observer now reads the actual AnimationPlayer while its tree is inactive.

# Shared settings, pause and save module (loop 04)

The active LOCOMOTION CONTROLS construction and F6/F7/F8 settings routes are
retired. Preview now binds the same live Maaack MainMenu scene used at title,
with product pause actions and the original CaptureFocus container, approved
background, serif fonts, Kenney frames and source license/receipt closure.
Existing source button callbacks are disconnected only in the pause adapter:
resume cannot call New Game. Child settings/save/help/confirmation pages retain
the `controls` owner; the source OverlaidWindow's saved-boolean pause/mouse
restoration is deliberately excluded from these active product paths.

Four settings groups share AdventureState: master/music/effects gain, mute,
normal/low rendering quality, sensitivity, existing reserved-key-safe bindings,
100/150/200% text, reveal speed/instant text, reduced motion, camera shake
(including zero) and damage numbers. They apply immediately and atomically save
to the separate preference record; a failed write is explicit and retryable.
Adventure restoration/rollback never assigns preference fields or reloads the
preference file: even an unsaved session setting survives adventure loads. Valid existing
manual histories and equipment/reward/teaching facts retain their format.
Key migration keeps valid B/X and other unrelated bindings, repairs conflicts,
and atomically persists the effective binding set; failures remain inspectable.

Effects and menu/dialogue cues route through Effects. A single router-owned
Music source plays the necessary unmodified Elven Dawn loop (see audio license).
All three buses use an output gain before capture, without a second fader gain;
no volume update restarts a source. Low quality applies the existing native
0.7 render scale, shorter shadow/foliage ranges and fewer Terrain3D mesh LODs;
the engine/renderer are unchanged. Camera shake is a short resolved-contact
camera offset, frozen with the player and suppressed by reduced motion. Turning
off damage numbers removes the amount from the outcome cue without changing HP
or suppressing XP and block/contact feedback.

Pause shows current lives and the existing CP01 checkpoint. Two manual-slot
pages read actual metadata, disable unavailable loads/unsafe saves with reasons,
confirm overwrite/load, and retain write-failure/retry feedback. MainMenu keeps
parent focus/scroll on child return. Settings maintain focused options when
rebuilt, with a fixed back footer and focus-following content scroll. Existing
player held-input tracking and pause-owner model remain the only gameplay gate.
Help is reached explicitly and displays equipment teaching only when earned.

Inspected reference: Maaack MainMenu/CaptureFocus and OverlaidWindow sources
(the latter restores a stale saved pause boolean on close). Compared Broken
Seals IngameMenu/InterfaceOptions source layout: a compact pause action list
and a separate options surface. Its desktop screenshot was also inspected:
compact framed actions/icons leave the world visible; its tiny bitmap text
and dense action bars are unsuitable for this product’s serif scaled menu.
It is a source/screenshot reference, not a current rendered candidate comparison or engine-compatible adoption; no assets copied.
Supplied concepts guide the parchment/old-lamp hierarchy and background safe
area. Actual pixels and all six resolution/text-scale cells remain unobserved.
Official docs consulted: tutorials/scripting/pausing_games.html (Pausable versus
Always; animation/audio/particles pause but signals still execute), Control
class description (GUI event consumption/focus), AudioServer methods (bus
routing/gain), and tutorials/rendering/renderers.html (renderer feature table).
The previous research audio_effects.rst section was read; no new shader or
renderer change is needed for this menu.

Self-validation: bounded source checks found no duplicate functions, missing
literal resource dependencies or trailing whitespace, and confirmed the native
project marker, shared menu binding and retirement of prototype construction.
A read-only hoh-history diff against loop 03 verified the preview replacement.
These are not engine parse/boot or business-postcondition checks.

The bridge was initially unavailable and the allowed rebind was requested.
It later connected to this exact project. Rescan imported the music/theme and
native 4.7 Forward+ title boot succeeded. Title settings at 100/150% were
captured, ordinary controls saved 200% text and a fresh process restored it.
The test user had no earned history, so ordinary New Game was used; no teaching,
equipment or reward was injected. Entry exposed a quest-journal inheritance
conflict with the new menu `world` field; the adapter was renamed `pause_world`
and native entry then passed with clean runtime logs. A debugger summary also
referenced inherited PSD/import diagnostics; the actionable runtime parser
message was the duplicate member, absent after the repair.

Ordinary pause froze gameplay time/physics through child pages. Both empty
manual slots were saved through their actual buttons; previews showed real
chapter/time/checkpoint/lives. A confirmed manual load restored the player and
kept 200% preferences. Paused positions remained constant across slot visits;
post-load small grounding correction was observed. The deferred submenu return
initially focused a hidden pause button after load; focus restoration is now
visibility-guarded. The opaque illustrated pause
page disables covered 3D rendering, restored on close/title, so its UI does not
pay the hidden world's rendering cost. This is not overall environment
performance acceptance.

Music snapshot found the real looping Music source and Effects UI voice. A
Master/Music/Effects capture (117063250-f685d09a, before the inheritance repair)
was non-silent on Music/Master and silent on idle Effects, with no clipping.
This supports source/output readiness only; heard quality and independently
paired volume adjustments remain unvalidated. 1280x720 title/settings/pause and
slot pages were captured at selected scales; window resize to 1920x1080 and
slot display at 200% were observed. The complete visual/fault/caller matrix,
earned equipment route and independent settings acceptance remain pending.
Early short key windows missed some GUI actions on the slow covered 3D view;
longer bounded ordinary key holds and pointer input completed save/load.
No candidate mutation or test-only history setup was used.

The pinned wrapper reports 4.7.stable.official.5b4e0cb0f. OGG headers/pages and
finite duration were checked. Capture 63647637-3d3b63b0 on the repaired candidate
again found non-silent Music/Master without clipping. Ordinary input set music
to 60%, with 200% text retained. Its source snapshot exposed inherited forest
ambience bypassing Effects through Master; configure now routes those sources
to Effects without replacing streams or changing their lifecycle. Final native
checks follow this routing repair; no phase or broader debt closure is claimed.

Final restart restored music 60% and text 200% with clean game logs. Continue
then timed out in the existing threaded world loader at 50%, before adventure
construction; final nested/load/dialogue retests could not use that entry.
This failed check is not independent acceptance or a pending pass. Source
inspection also guarded the slot-confirmation deferred focus return against
the hidden/deleted page after successful loading. A separate native Preview
boot check is used to distinguish world/script loading from title entry.

Direct Preview boot succeeded with clean native game logs and verified forest
sources on Effects. It exposed two fallback music players in the direct-scene
path; the journal now shares the world's existing menu audio owner. Ordinary
unfrozen title Continue then completed loading and grounding, unlike the frozen
debug-entry attempt; that frozen timeout remains a failed scenario, with no
claim about its cause. Final native main-route checks passed Audio → Settings →
Pause with constant position, zero gameplay/physics during child pages and focus
returned to Settings. Both slots remained genuine pre-event histories; safe
overwrite of slot 1 and confirmed load of slot 2 worked. Loading removed all
pause owners, restored captured mouse and cleared GUI focus, retaining 60%
music/200% text. Dialogue → F10 added controls alongside dialogue; closing the
menu removed only controls, and closing dialogue resumed coherently. Final
snapshot found one looping router Music source and forest sources on Effects.
Post-interaction game logs were clean. The startup-only preference assertion
was corrected to the actual `load_preferences` spelling and passed alongside
native marker, dependencies, duplicate functions and prototype-retirement
checks. These results are Developer self-validation, not phase acceptance.

Host/Tester dependencies: provide isolated legal pre-teaching/pre-reward
histories for six layout cells, 4/5-life/depleted recovery and conflicting-H
fixtures, and persistent save-failure/successful-retry fixtures. Preserve all
committed one-time facts; replay/restoration notices are not first-event proof.
Exercise held attack/aim/advance, menu scroll, dialogue/journal callers, nested
world/cue freeze and final-owner resume, focus loss/load/title boundaries, actual
renderer costs and HP-identical number toggles. Cinematic/skill callers are not
implemented by this owning phase and remain unavailable observations. Ordinary
obstacle pursuit/return and rendered contact/audio/VFX still need independent
capture. ISSUE-0006, ISSUE-0008 and ISSUE-0009 remain unresolved.

## Loop 05 — illustrated opening and shared layout

Ordinary New Game now routes through ui/illustrated_opening.tscn before loading
the village. Continue/manual histories keep the existing loading path. The four
approved illustrations and unchanged storyboard/provenance were materialized
through game-asset-provider into assets/cinematics/opening. Existing Maaack
MainMenu/CaptureFocus scenes, parchment, source receipts, serif fonts, and the
single menu audio/preferences owner remain live.

The native canvas presentation uses the storyboard's 10/8/10/10 second beats,
independent Chinese subtitles, a 0.5-second crossfade, 2–4% slow push-in and
sparse margin wear/dust. Reduced motion stops the push and motes; low quality
also omits margin drawing. All motion follows the presentation clock rather
than shader TIME. The pause caller reuses the live MainMenu lifecycle, with
resume/settings/skip/title/exit; it offers no fictional cinematic save slot.
Closing a child leaves its caller paused. Focus loss opens pause. Resume waits
for confirm/attack/aim release; final world entry also waits for release and
retains the existing player input gate. Temporary subtitle/art/audio nodes are
removed before loading. No additional actor/controller or settings authority
was introduced.

New Game does not touch valid history during playback. Completion and skip
share one router path: reset only adventure facts, mark opening_completed,
prepare the unarmed village with three lives, then use the existing atomic
.tmp/rename save after safe readiness. A failed write restores the previous
in-memory adventure and preserves the existing on-disk history. Retry starts
at the complete opening boundary. Exit before commit retains the previous
history; starting New Game again replays from beat one. Legacy saves without
the cinematic marker default to completed and preserve choices/equipment/XP.
Preferences are excluded from rollback and remain independent. Presentation
never confirms a dialogue choice or grants rewards/equipment.

Slider labels/current values and their controls now share a row. Focus scrolls
the complete row into view after container sorting; rebuilds restore control
identity without reapplying an obsolete scroll offset. Capture/rejection/save
feedback occupies the fixed page footer. Tracker width changes now release
retained height each frame, allowing current wrapping/collapse to set the size.
Read-only observations expose actual focused-row, viewport, feedback and tracker
rectangles plus opening clock/owners; they do not drive gameplay or assert passes.

Documentation consulted through registered godot_docs on Godot 4.7/Forward+:
stable/tutorials/scripting/pausing_games.html (Always versus Pausable, audio
pause), classes/class_scrollcontainer.html#class-scrollcontainer-method-ensure-control-visible,
and stable/tutorials/rendering/renderers.html (native 2D canvas support).
Native controls/drawing were chosen instead of a new shader/CompositorEffect.
An early runnable probe found an inherited toolbar theme was null; font overrides
fixed that failure. A second probe established that ALWAYS presentation must
also respect external tree freezes; the clock now stops on paused tree state.

Audio comparison: local pool lacked an eligible atmospheric stem. Cyrex's
Fantasy Sound Pack is paid (CC BY 4.0), and registered download returned no URL;
3ddisco's free samples permit personal use only. Kenney RPG Audio has no
registered automated adapter and its public page failed TLS acquisition.
Additional magic packs were paid. Those assets were not copied. The opening
reuses the licensed score and adds original, low-level stereo river-air and
rupture/bell stems. PCM recipe: Python standard library, 24 kHz/16-bit/stereo,
Random seed 261006; two independent 0.995 lowpass-noise accumulators. Air is
12 seconds with a 0.20 filtered-noise term and 0.012 sine at 146.83/146.95 Hz,
slow modulation, and a cosine edge envelope; Vorbis encoded with libvorbis q4.
Rupture is 4 seconds with a 0.08 sine swept around 82.4 Hz, 0.028 inharmonic
partial, 0.28 filtered air, 80 ms attack and exponential 1.1/s decay. Bell
onsets 0.15/0.95 seconds use 293.66 and 708.72 Hz, 65/s attack and 2.1/s decay,
plus a final 200 ms fade. No recordings or external generation service were
used. Music goes to Music; air/rupture go to Effects, downstream of the existing
master/music/effects gains. Their players are Pausable; pause explicitly holds
playback positions and disposal stops the temporary sources.

Developer probes so far: paired Audio baseline/retest confirms the previously
hidden master label now lies inside the scroll viewport; 1280x720 100/200% and
1920x1080 200% focused rows/footer were observed with screenshots and actual
rectangles. Ordinary capture rejected reserved E and conflicting W without
changing bindings, then cancellation worked. Nested cinematic settings retained
the beat timestamp. These are bounded smoke observations, not Tester closure.
Final runnable delivery checks cover imported art/audio, remaining beats and
world handoff. Full six-cell interaction coverage, active earned sword/bow
freeze/effects audio, contact-driven camera-shake/number settings, legacy/manual
history and injected persistent save-fault cells still require independent
Host/Tester evidence. Existing deferred debts are unchanged.

Final smoke observed all four beats at 200% text, normal completion, and a
deliberate held-Space skip at beat one. Both entry paths produced D01, unarmed,
three lives, 100 health, zero XP/choices and no committed rescue reward. Ordinary
Isha acceptance then granted 10 XP exactly once; Hers granted the sword and an
ordinary attack completed the hit practice. Defense/bow progression and active
projectile comparisons were not established. Restarted Continue preserved the
earned history and bypassed the opening; after the skip comparison, another
fresh boot preserved the unarmed baseline. Runtime game logs were clean and no
new editor errors followed cursor 26; earlier base-project texture errors remain.

Returning through 100→150→200→100% Reading rebuilds settled the objective panel
at 430×69 pixels, with minimum 430×69. H collapsed it to 430×40 and expanded it
back to 430×69. At 200% the previous observed size/minimum was 550.4×110.
Positive Master/Effects output was captured without clipping, but subjective
sound quality and the full option-effect matrix remain unvalidated. Several
long steps hit the tool wall budget; post-step state established the handoff,
not precise timing equivalence. Retry source review found and removed a replay
of the already completed opening; retry now retains the original rollback
snapshot and re-enters loading/commit directly. Fresh boot/Continue parsed that
repair; save-fault/retry execution still requires Host fault authorization.

The final ordinary W input window included a shipped 1280×720 frame and a
three-field state watch, followed by clean runtime logs. Loaded-resource boundary
receipts identify the exact project and native process, but return relative raw
artifact paths without a readable absolute prefix here. Native CharacterBody
instance attestation was therefore not established; no instance ID was guessed.
