extends StaticBody3D
## Retained complete Ranger assembly, differentiated as the village's guard.
var actor: Node3D
var marker: Label3D
var grounded = false

func _ready() -> void:
	collision_layer = 1
	var collision = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.32
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	add_child(collision)
	actor = preload("res://actors/npc_presentation.tscn").instantiate()
	actor.name = "GuardPresentation"
	actor.configure_equipment(true, false, "sword")
	actor.appearance = preload("res://actors/hers_appearance.tres")
	add_child(actor)
	actor.visual.rotation.y = 0
	marker = Label3D.new()
	marker.text = "赫斯 · 留守的老战士"
	marker.font = preload("res://dialogue_theme.tres").default_font
	marker.font_size = 40
	marker.pixel_size = 0.0035
	marker.position.y = 2.2
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(marker)
	idle()
	preload("res://actors/npc_life.gd").attach(self,actor,"hers")

func idle() -> void:
	actor.current_animation = ""
	actor._play_animation("Sword_Idle")

func face_player(player: Node3D) -> void:
	var delta = player.global_position - global_position
	actor.visual.rotation.y = atan2(delta.x, delta.z)

func demonstrate() -> void:
	actor.current_animation = ""
	actor._play_animation("sword/Sword_Regular_A")
	var timer = get_tree().create_timer(1.2, false)
	timer.timeout.connect(idle)

func telegraph() -> void:
	actor.current_animation = ""
	actor._play_animation("sword/Sword_Regular_A", 0.12)

func strike() -> void:
	var anticipation_position = actor.animation_player.current_animation_position
	actor.current_animation = ""
	actor._play_animation("sword/Sword_Regular_A", 1.24)
	actor.animation_player.seek(anticipation_position, true)

func can_interact(player: CharacterBody3D) -> bool:
	if player.global_position.distance_to(global_position) > 2.8: return false
	var query = PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP, global_position + Vector3.UP, 1, [player.get_rid(), get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _mcp_state() -> Dictionary:
	return {"model": actor.MODEL_PATH, "head_components": actor.head_components.size(), "animation": actor.animation_player.current_animation, "animation_position": actor.animation_player.current_animation_position, "sword_visible": actor.sword_holder.visible}
