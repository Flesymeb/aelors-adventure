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
