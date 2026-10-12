extends "res://preview_controller.gd"
## Thin destination adapter: retained product controls/combat/UI, no chapter encounters.
const TOMB_GROUND = preload("res://world/map03_ground.gd")
var ritual_record: Node3D
var return_passage: Node3D
var route_ready := false
var route_samples := 0
var collision_meshes := 0

class TombQuality extends Node:
	var enhanced := true
	var developer_lamp_overlay := false
	func toggle_quality() -> void: enhanced = not enhanced
	func toggle_developer_lamps() -> void: pass
	func set_dusk(_enabled: bool) -> void: pass

class TombLamp extends "res://lamp_training.gd":
	func interaction_prompt() -> String: return ""
	func reveal() -> bool:
		if not state.lamp_owned or world.player.weapon_mode != "lamp": return false
		if cooldown > 0 or not world.travel_safe(): return true
		cooldown = 3.0
		world.training.feedback.spark(world.player.global_position + Vector3.UP,Color(0.4,0.85,1))
		world.training.tell("旧灯照亮墓道 · 入口结界尚未解除，先调查仪式记录。",4)
		return true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Shared lesson owners retain damage/recovery APIs; their actors are unavailable.
	meadow_slice = true
	ground_policy = TOMB_GROUND
	village = create_environment()
	village.name = "TombEnvironment"
	village.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(village)
	_bind_collision()
	_bind_entrance_boundary()
	if dialogue_state == null:
		entry_failed.emit("墓殿缺少冒险历史，已保留上一处边界。")
		return
	player = PLAYER_SCENE.instantiate()
	player.ground_policy = ground_policy
	player.minimum_world_height = -8
	player.position = Vector3(TOMB_GROUND.ENTRY.x,5,TOMB_GROUND.ENTRY.y)
	player.owns_lamp = dialogue_state.lamp_owned
	player.configure_equipment(dialogue_state.sword_owned,dialogue_state.bow_owned,dialogue_state.selected_equipment)
	player.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(player)
	player.camera.current = true
	quality = TombQuality.new()
	add_child(quality)
	menu_audio = entry_router.audio
	dialogue = preload("res://IshaDialogue.tscn").instantiate()
	dialogue.state = dialogue_state
	add_child(dialogue)
	dialogue.closed.connect(_dialogue_closed)
	dialogue.menu_requested.connect(_open_controls)
	training = preload("res://sword_training.gd").new()
	training.name = "RetainedCombat"
	add_child(training)
	training.configure(self)
	bow_training = preload("res://bow_training.gd").new()
	bow_training.name = "RetainedArchery"
	add_child(bow_training)
	bow_training.configure(self)
	bow_training.pending_demo = false
	lamp_training = TombLamp.new()
	add_child(lamp_training)
	lamp_training.configure(self)
	element_abilities = preload("res://world/map02_element_abilities.gd").new()
	add_child(element_abilities)
	element_abilities.configure(self)
	for actor in [training.hers,training.target,training.monster,bow_training.ronen,bow_training.target,bow_training.obstruction,lamp_training.signpost]:
		actor.hide()
		actor.position = Vector3(0,-100,0)
		actor.process_mode = Node.PROCESS_MODE_DISABLED
		for body in [actor] + actor.find_children("*","CollisionObject3D",true,false):
			if body is CollisionObject3D: body.collision_layer = 0; body.collision_mask = 0
	_add_help()
	_add_controls()
	_add_product_panels()
	player.controls_changed.connect(_refresh_control_prompts)
	_refresh_control_prompts()
	ritual_record = preload("res://world/map03_ritual_record.gd").new()
	ritual_record.name = "RitualRecord"
	add_child(ritual_record)
	ritual_record.configure(self)
	return_passage = preload("res://world/map03_passage.tscn").instantiate()
	return_passage.name = "ReturnPassage"
	add_child(return_passage)
	return_passage.configure(self)
	_place_player.call_deferred()

func create_environment() -> Node3D:
	return preload("res://assets/maps/map03/environment.tscn").instantiate()

func _bind_collision() -> void:
	for mesh in village.find_children("*","MeshInstance3D",true,false):
		# Cloth/candles have no blocking volume; authored stone owns all support.
		if not ("Floor" in mesh.name or "Wall" in mesh.name or "Pillar" in mesh.name or "Stairs" in mesh.name or "Coffin" in mesh.name): continue
		mesh.create_trimesh_collision()
		for body in mesh.get_children():
			if not body is StaticBody3D: continue
			body.collision_layer = 1
			body.collision_mask = 1
			if "Floor" in mesh.name: body.set_meta("tomb_floor",true)
			for shape in body.get_children():
				if shape is CollisionShape3D and shape.shape is ConcavePolygonShape3D: shape.shape.backface_collision = true
		collision_meshes += 1

func _place_player() -> void:
	var xz := restored_xz(restored_position.get("position",Vector3.ZERO),restored_position.get("map_id",""))
	for attempt in 120:
		await get_tree().physics_frame
		if not TOMB_GROUND.place(self,player,xz): xz = TOMB_GROUND.ENTRY; continue
		if not ritual_record.grounded or not return_passage.grounded: continue
		var stance := Node3D.new()
		add_child(stance)
		route_samples = 0
		for i in TOMB_GROUND.ROUTE.size()-1:
			for j in 5:
				if TOMB_GROUND.place(self,stance,TOMB_GROUND.ROUTE[i].lerp(TOMB_GROUND.ROUTE[i+1],float(j)/4)): route_samples += 1
		stance.queue_free()
		route_ready = route_samples == 25 and collision_meshes > 0
		if not route_ready: entry_failed.emit("墓殿入口路线缺少真实支撑，已保留上一处边界。"); return
		player.set_meta("spawn_position",player.global_position)
		player.prepare_restored_camera(float(restored_position.get("yaw",0.0)))
		player.process_mode = Node.PROCESS_MODE_PAUSABLE
		entry_ready.emit()
		return
	entry_failed.emit("墓殿落脚点无法准备，已保留上一处边界。")

func destination_ready() -> bool:
	return route_ready and is_instance_valid(player) and player.has_meta("spawn_position") and ritual_record.grounded and return_passage.grounded

func restore_destination_history() -> void:
	super()
	ritual_record.restore_history()

func checkpoint_xz() -> Vector2: return TOMB_GROUND.ENTRY
func active_map_id() -> String: return dialogue_state.MAP03
func contextual_interaction_target() -> Node3D:
	for target in [ritual_record,return_passage]:
		if is_instance_valid(target) and target.interaction_prompt() != "": return target
	return null

func _load_opening(slot: int) -> void:
	super(slot)
	if is_instance_valid(ritual_record): ritual_record.restore_history()

func _mcp_state() -> Dictionary:
	var result := super()
	result.authored_map = "res://assets/maps/map03/environment.tscn"
	result.map_id = TOMB_GROUND.MAP03_ID
	result.checkpoint = "CP03"
	result.destination_ready = destination_ready()
	result.route_samples = route_samples
	result.collision_meshes = collision_meshes
	result.record_read = dialogue_state.ritual_record_read if is_instance_valid(dialogue_state) else null
	return result

func _bind_entrance_boundary() -> void:
	# The scoped entrance ends at a visible sealed threshold; LN02 remains unfinished.
	var seal := MeshInstance3D.new()
	seal.name = "UnresolvedEntranceSeal"
	var veil := QuadMesh.new()
	veil.size = Vector2(15.8,6.0)
	seal.mesh = veil
	var mist := StandardMaterial3D.new()
	mist.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mist.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mist.cull_mode = BaseMaterial3D.CULL_DISABLED
	mist.albedo_color = Color(0.2,0.6,0.8,0.09)
	seal.material_override = mist
	seal.position = Vector3(0,3,-7.4)
	village.add_child(seal)
	for x in [-4.0,4.0]:
		var rune := MeshInstance3D.new()
		var ring := TorusMesh.new()
		ring.inner_radius = 0.6
		ring.outer_radius = 0.63
		rune.mesh = ring
		rune.material_override = preload("res://assets/effects/ln01_flow.tres")
		rune.rotation_degrees.x = 90
		rune.position = Vector3(x,2.8,-7.35)
		village.add_child(rune)
	var body := StaticBody3D.new()
	body.name = "UnresolvedEntranceBoundary"
	body.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(16,6,0.3)
	shape.shape = box
	body.add_child(shape)
	body.position = seal.position
	village.add_child(body)
	var label := Label3D.new()
	label.text = "入口结界尚未解除 · 先调查仪式记录"
	label.font = ui_font
	label.font_size = 40
	label.pixel_size = 0.003
	label.position = Vector3(0,3.5,-7.1)
	village.add_child(label)
	for point in [Vector3(-7,3,0),Vector3(7,3,0),Vector3(-7,3,-6),Vector3(7,3,-6)]:
		var torch := OmniLight3D.new()
		torch.position = point
		torch.light_color = Color(1,0.52,0.18)
		torch.light_energy = 1.0
		torch.omni_range = 7
		village.add_child(torch)
