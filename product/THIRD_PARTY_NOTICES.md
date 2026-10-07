# Third-party notices

## Title menu foundation
Maaack Godot-Menus-Template, Marek Belski, MIT. Upstream commit
250147d0e5d573061d7393d127f7f4295b119e73, https://github.com/Maaack/Godot-Menus-Template.
The registered local bundle was materialized before extracting/adapting its
main-menu navigation, capture-focus, confirmation and scene-loading unit.
Full MIT notice: ui/menu_foundation/source/LICENSE.txt.
ui/menu_foundation/main_menu.tscn inherits the original Maaack base menu
PackedScene under ui/menu_foundation/maaack. Its sibling main_menu.gd extends
MainMenu. The source scene, menu class, focus utility, confirmation/window
dependencies, label scripts and inactive source sound/music nodes are retained.
The product subclass supplies layout, typography, artwork and adventure routing.
The architecture-recovery transfer receipt, attribution and MIT notice remain
under ui/menu_foundation/maaack. Earlier transfer receipts remain preserved.
The FPS skin, AppConfig/OptionsMenu authorities, music/branding and clipboard
exit hook are omitted. All live dependencies are product-local.

Kenney Fantasy UI Borders and Interface Sounds: CC0; existing notices remain
in assets/dialogue/borders/License.txt and assets/dialogue/sounds/License.txt.
EB Garamond and Zhuque Fangsong: existing bundled font licenses remain in
assets/dialogue/garamond and assets/dialogue/zhuque.

Title background and original vector icon provenance: assets/ui/LICENSES.md.

## Gameplay interface
The journal inherits the same Maaack main-menu scene and product layout/focus
adapter; no second menu framework or quest authority was added. The gameplay
theme reuses the bundled serif fonts and Kenney border textures above.

assets/ui/journal_check.png: Kenney Game Icons by Kenney Vleugels, CC0-1.0,
https://kenney.nl/assets/game-icons. Materialized from PNG/Black/2x/checkmark.png
through the policy-bound asset provider; its adjacent receipt retains provenance.

assets/ui/life_icons.svg and journal_icons.svg adapt the original product-authored
old-lamp and book atlas in assets/ui/main_menu_icons.svg. They are source artwork,
not extracted glyphs or editor icons. Lit flame and extinguished/slashed variants
make life state distinct by shape as well as color.

## RPG actor foundation
Snaiel Godot4ThirdPersonCombatPrototype, revision
cbfecf427f9a703ebf7e940fd067ed31a729d637,
https://github.com/Snaiel/Godot4ThirdPersonCombatPrototype, MIT code.
The source-derived BaseEnemy/HybridEnemy, CharacterAnimations recipients and
Patrol decision tree extend the retained melee, health, hitbox and Beehave unit.
Full Snaiel and bitbrain MIT notices and adaptation boundary remain in
combat/snaiel/LICENSES.txt. Registered source transfer:
reference-stage:620f2754a12c5aae6930d289b21302065ded91d259df209cf3e4f5fefefca462.
Only required scoped modules ship; the staged sample maps, Globals, additional
controllers, Blender/Mixamo media and unrelated sounds are omitted.

The live enemy reuses assets/training/Orc.gltf, its embedded animation catalog
and texture under Quaternius CC0; provenance and original notices remain in
assets/training/LICENSES.txt, License.txt and adjacent receipts. Temporary
Blender conversion probes are not shipped or live bindings.

NPC presentation reuses the selected village Ranger and complete base-head
assembly, Quaternius UAL1/UAL2 and sword/bow/arrow assets (CC0), and KayKit
Character Animations (CC0). Existing source notices remain in README.md,
Characters/QuaterniusAnimations/License.txt, Characters/KayKitAnimations/License.txt
and the retained source licenses/receipts. Ronen and Hers use private material
instances, selected mesh visibility, mirrored authored armor and authored arrows;
no source asset bytes were overwritten. Zero-area UV repair operates on private
runtime mesh instances. The environment remains under its existing licenses.

Settings/pause background music: “Elven Dawn” (loop), by alkakrab, from
https://alkakrab.itch.io/free-fantasy-medieval-ambient-music-pack .
Author's explicit permission: “Absolutely Free For Commercial use”.
Unmodified OGG source member and acquisition details: assets/audio/LICENSES.md.
This is custom author permission; no CC0 or SPDX license is asserted.

## Illustrated opening (loop 05)
The four approved full-screen illustrations, storyboard and original generation
prompts are retained under assets/cinematics/opening. Registered selection:
Aelor opening illustrated cinematic four full-screen slides,
e46d3829d599426ba8b7c55c67bf9d4dcce89751a7f683931799c5a85d640ef6:
df98995d187690a866b0643a821785b33b9f4492b50cc66caa2a67e2b6980ac6.
These images were generated with image_gen.imagegen. Provider service terms
apply; the illustrations are not CC0 or MIT. The adjacent registered acquisition
receipt and generation-prompts.json preserve their provenance.

Opening music reuses alkakrab's Elven Dawn under the permission cited above.
ambience.ogg and rift_transition.wav are original procedural audio authored for
this project, without sampled recordings or third-party audio models. They are
separate from the image service terms. Their synthesis is described in DEVELOPMENT.md.
No commercial pack or personal-use-only sample from the audio comparison ships.
