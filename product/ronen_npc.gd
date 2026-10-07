extends StaticBody3D
## Uses the retained Ranger, complete head and ranged pose/mount adapter.
var actor: Node3D
var grounded := false
var demonstration := false
var demonstration_time := 0.0

func _ready() -> void:
	collision_layer = 1
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)
	actor = preload("res://actors/npc_presentation.tscn").instantiate()
	actor.name = "RonenPresentation"
	actor.configure_equipment(false, true, "bow")
	actor.appearance = preload("res://actors/ronen_appearance.tres")
	add_child(actor)
	actor.visual.rotation.y = PI
	var marker := Label3D.new()
	marker.text = "罗恩 · 巡路猎人"
	marker.font = preload("res://dialogue_theme.tres").default_font
	marker.font_size = 40
	marker.pixel_size = 0.0035
	marker.position.y = 2.2
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(marker)
	idle()

func idle() -> void:
	demonstration = false
	actor.reset_archery()
	actor.aim_blend = 0
	actor.current_animation = ""
	actor._play_animation("Idle")

func demonstrate() -> void:
	demonstration = true
	demonstration_time = 0
	actor.aim_requested = true
	actor.bow_state = "draw"
	actor.bow_charge = 0
	actor.bow_clock = 0

func _physics_process(delta: float) -> void:
	if not demonstration: return
	demonstration_time += delta
	if demonstration_time >= 1.6 and actor.bow_state == "hold":
		# Presentation only: no projectile, ammunition or training settlement.
		actor.release_charge = actor.bow_charge
		actor.bow_state = "release"
		actor.bow_clock = 0
		actor.bow_charge = 0
	actor._update_archery(delta)
	if demonstration_time >= 2.5: idle()

func can_interact(player: CharacterBody3D) -> bool:
	if not grounded or player.global_position.distance_to(global_position) > 2.8: return false
	var ray := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP, global_position + Vector3.UP, 1, [player.get_rid(), get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func _mcp_state() -> Dictionary:
	return {"grounded": grounded, "demonstrating": demonstration, "demonstration_time": demonstration_time, "head_components": actor.head_components.size(), "bow_state": actor.bow_state, "bow_charge": actor.bow_charge, "pose_clip": actor.bow_pose.clip, "pose_time": actor.bow_pose.clip_time, "bow_in_hand": actor.bow_holder.visible, "animation": actor.animation_player.current_animation}
