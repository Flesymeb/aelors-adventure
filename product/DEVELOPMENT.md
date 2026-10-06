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
