extends StaticBody3D
## Presentation only. Stable identity and release/assembly facts belong to DialogueState.
@export_enum("oren", "villager_a", "villager_b", "villager_c") var captive_id := "oren"
@export var model_scene: PackedScene
const CAST = preload("res://data/rescue_cast.json")
const PRESENTATION = preload("res://actors/npc_presentation.tscn")
var presentation: Node3D
var label: Label3D
var released := false
var assembled := false
var release_remaining := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var definition: Dictionary = CAST.data[captive_id]
	presentation = PRESENTATION.instantiate()
	presentation.model_scene = model_scene
	presentation.assembled_head = true
	presentation.configure_equipment(false,false,"unarmed")
	add_child(presentation)
	# Keep loop edits actor-local: the imported libraries are shared with Aelor.
	var library: AnimationLibrary = presentation.animation_player.get_animation_library("").duplicate()
	var captive_clip: Animation = library.get_animation("Fixing_Kneeling").duplicate(true)
	captive_clip.loop_mode = Animation.LOOP_LINEAR
	library.remove_animation("Fixing_Kneeling")
	library.add_animation("Fixing_Kneeling",captive_clip)
	presentation.animation_player.remove_animation_library("")
	presentation.animation_player.add_animation_library("",library)
	presentation.current_animation = ""
	presentation.scale = Vector3(definition.scale[0],definition.scale[1],definition.scale[2])
	# Identity garments, complete rigid head and hair are embedded in model_scene.
	label = Label3D.new()
	label.font = preload("res://assets/dialogue/zhuque/ZhuqueFangsong-Regular.ttf")
	label.font_size = 32
	label.pixel_size = 0.0025
	label.outline_size = 8
	label.position.y = 2.35
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	label.visible = false
	restore(false,false)

func restore(is_released: bool, is_assembled: bool) -> void:
	var just_released := is_released and not released
	released = is_released
	assembled = is_assembled
	if just_released and not assembled:
		release_remaining = presentation.animation_player.get_animation("Interact").length
		presentation._play_animation("Interact")
	else:
		release_remaining = 0
		presentation._play_animation("Idle_Talking" if assembled else "Idle" if released else "Fixing_Kneeling")
	label.text = CAST.data[captive_id].name + " · " + ("已集合" if assembled else "已释放" if released else CAST.data[captive_id].role + " · 受困")

func _physics_process(delta: float) -> void:
	if release_remaining <= 0: return
	release_remaining = maxf(0,release_remaining-delta)
	if release_remaining == 0: presentation._play_animation("Idle")

func _mcp_state() -> Dictionary:
	return {"id":captive_id,"released":released,"assembled":assembled,"current_clip":presentation.animation_player.current_animation,"animation_position":presentation.animation_player.current_animation_position,"complete_head_components":presentation.head_components.size(),"label":label.text,"position":str(global_position)}
