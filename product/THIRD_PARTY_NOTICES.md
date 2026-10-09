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

## RPG inventory and loot components

- GLoot 3.0.2, Peter Kish, MIT. Source: https://github.com/peter-kish/gloot,
  revision `6b09b87ac07a8536779ef1ab0fafc7e99830f948`. The complete
  `addons/gloot` dependency unit is retained. License: `addons/gloot/LICENSE`.
  This pin uses `Inventory.protoset` and declares Godot 4.7; no plugin is enabled
  and the product adapter binds its actual Inventory, ItemSlot and CtrlInventory
  APIs after Godot 4.7 native compatibility probes.
  The pin references an absent `images/icon_item.svg`; the candidate's optional
  `InventoryItem` editor icon annotation uses the included
  `images/icon_ctrl_inventory_item.svg` instead. No item artwork is replaced.
- Godot loot tables, David Mahany, MIT. Source:
  https://github.com/PieKing1215/godot-loot-tables, revision
  `159ab6b7116e36929c149a807d6cc1cb361e98f7`. The complete runtime
  `addons/loot_tables/src` unit is retained; its optional editor is omitted.
  License: `addons/loot_tables/LICENSE`. The candidate's `Pool.gd` uses each
  effective weight consistently for summation and selection, rejects invalid
  weights and roll counts, supports an injected RNG, and returns no entry for
  all-zero weights. Source pool bytes remain unchanged. These components are
  adapted through inventory/loot_adapter.gd for once-only bridge death rewards.
  Native probes cover effective weights; ordinary play covers stored pickups.

## Old lamp model
Poly Haven, Lantern 01 — https://polyhaven.com/a/Lantern_01 — CC0-1.0. Original mesh and textures staged under `assets/equipment/lantern.zip/`; acquisition receipt retained. Product hand/stow transform is an adaptation. The rejected Polygonal Mind chandelier is retained as an unbound acquisition only.

## Permanent clue interaction
Nodragem Action Adventure, revision `efc171fd37682811c9efe0df83b02e9102d4f5f5`, project CC0 license retained in `interaction/nodragem/LICENSE`. The selected SwitchComponent and ShortSwitch source units are adapted into permanent reveal activation with optional animation; investigation and rewards remain product-owned in DialogueState/LampTraining.

## RPG item and ability icons

Icons by Delapouite, https://game-icons.net, CC BY 3.0,
https://creativecommons.org/licenses/by/3.0/. Existing pooled bundle revision
`82d948812bfe3f269ef8f731dcdb07b08160edc4` is copied without texture changes.
Individual titles, source links and licenses remain in
`assets/ui/icons/ATTRIBUTION.txt`, `SOURCE.json` and `license.txt`.
The product shares these textures across prototype images, backpack tiles,
pickups, ability choices and ownership-driven shortcuts. This artwork license
is separate from the GLoot and loot-table MIT code licenses.


Aelor/Isha dialogue portraits: waist-up atlas v3. Original generated artwork under applicable OpenAI service terms, https://openai.com/policies/terms-of-use/ . Not CC0 or MIT. Operator-declared provenance, original prompts and registered unchanged materialization are retained under assets/dialogue/portrait_source/v3/. Native AtlasTexture regions bind the original transparent RGBA image; no pixel modifications. V2 remains source history, with its original receipt preserved, and is retired from both live portrait bindings. Independent identity/framing and full resolution/text-scale review remain pending.

Bridge resident and lamp: use the CC0 Quaternius Ranger packed by the registered asset provider into assets/bridge/resident.glb, with its buffer and six image dependencies embedded unchanged. Acquisition, dependency hashes and packing provenance are in assets/bridge/resident.glb.receipt.json. Source: https://quaternius.com/packs/modularcharacteroutfitsfantasy.html . Retain the base-head assembly, UAL1 rig/clips, Emaceart container prop and Poly Haven Lantern 01. Civilian clothing visibility and colour, interaction, supported return waypoints and native warm illumination are product adaptations. Permanent switches reuse the retained Nodragem units and license.

The resident's scene explicitly binds actors/npc_presentation.tscn. Its model,
animation-player reparenting and head assembly derive from the inspected
examples/emaceart-village-demo/player_controller.gd and ranger_head_assembly.gd.
Only the retained presentation is reused; the example's input, camera and
traversal controller are not activated for this resident.

## Retained world and channel guards (loop 24)

The live `Preview.tscn` / `preview_controller.gd` instantiates `world.tscn`
once, under `Forest`. This is the retained Forest-Godot4 environment, revision
`885de5769b2d0cf7ea0808752e44d680abecfd5b`,
https://github.com/Lakshman-YT/Forest-Godot4. It is not a new transfer in this
iteration and is not the complete Emaceart village scene. The retained village
building prefabs, Ranger, complete head, animation libraries and medieval
equipment keep their original notices and local-use restrictions. The world
uses the retained Terrain3D data and collision; no replacement ground is added.

Forest has no blanket MIT license. Terrain3D and Sky3D code licenses apply to
those plugins; models, vegetation, textures, sky images and audio retain their
individual rights. Source credits are in `forest_source/!Credits-README!.txt`.
Unconfirmed asset redistribution rights remain unresolved. The inherited
`Objects/Grass_Texture.psd` / empty Texture2D import findings are also unresolved.
Native cache-independent world/house loading and dependency traversal succeed,
but do not establish clean import. The retained original
`Objects/EA03_Plant_Grass_02a.fbx` and `Objects/EA03_Plant_Grass_02b.fbx` contain
the missing PSD reference; the registered original village source also lacks
the PSD. The retained `Textures/Grass_Texture.png` is unchanged from that source.
No texture restoration, conversion, scenery removal or new source transfer is
claimed. These import owners require separately authorized repair; the Forest
versus complete-village adoption requirement still needs Host adjudication.

Channel melee guards reuse `assets/training/Orc.gltf` (Quaternius CC0).
The ranged guard binds the newly provider-packed `assets/guards/ranged_guard.glb`
(Quaternius Modular Character Outfits - Fantasy, CC0); the adjacent acquisition
receipt records unchanged embedded geometry, buffer and texture dependencies.
Its complete head, UAL1/UAL2 libraries, KayKit ranged clips, bow and arrow are
retained dependencies. `combat/channel_ranged_adapter.gd` uses
`actors/npc_presentation.tscn`, not a second player controller. The action
adapter derives from the inspected Snaiel NonMeleeComponent and
EnemyNonMeleeComponent lifecycle; MIT attribution remains in
`combat/snaiel/LICENSES.txt`. Projectile contact uses the product's retained
tip sweep instead of the upstream unswept projectile. Cat sensing was inspected
as a mechanism comparison and no Cat code was copied.

## CH01 guard approach illustrations

Three generated paintings are bound in assets/cinematics/guard_approach.
They use image_gen.imagegen provider service terms, not CC0 or MIT.
SOURCE.json preserves original source hashes and source-to-runtime filenames;
adjacent provider receipts retain acquisition records. Source paintings remain
unchanged. Engine captions and the presentation adapter are product code.
The selected character-identity-v2 bundle depicts the green-hood Ranger and
Isha's red shawl and white bonnet. Its original provenance, generation prompts,
storyboard and acquisition receipts are retained in `identity_v2/`; SOURCE.json
maps those unchanged source paintings to guard_01/02/03.png. Earlier root-level
receipts describe the superseded paintings. Independent style and ordinary-route
acceptance remain pending.

## CH01 departure illustrations

`assets/cinematics/departure/farewell.png`, `passage.png` and `arrival.png`
are unchanged generated paintings acquired from the registered Aelor Departure
Three Paintings and Provenance Bundle. Applicable provider service terms govern;
no CC0, MIT or other asset-specific public licence grant was observed. The
generation backend model identifier was not exposed. `SOURCE.json` preserves
the generated-file provenance and limitations; adjacent acquisition receipts
record the registered transfers. Native captions and the existing storyboard
remain product-owned. These illustrations do not establish playable terrain or
quest completion.

## Chapter overlay/tween adapter

`ui/chapter_transition.gd` adapts the overlay and awaited tween mechanism from Pandita Studio scene-switcher, revision aa88ab647143f8d0448c4deaa8805b97027852ea, MIT. Original license: `ui/scene_switcher_LICENSE.txt`. Source: https://github.com/Pandita-Studio/scene-switcher-godot-addon . Product chapter state, rollback and input ownership remain in the entry router.
