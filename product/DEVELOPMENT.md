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
