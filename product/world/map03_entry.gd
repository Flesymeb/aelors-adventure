extends "res://preview_controller.gd"
## Thin destination adapter: retained product controls/combat/UI, Warden after the LN02 boundary.
const TOMB_GROUND = preload("res://world/map03_ground.gd")
var ritual_record: Node3D
var return_passage: Node3D
var entrance_circuit: Node3D
var warden_encounter: Node3D
var veyne_encounter: Node3D
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
		if not state.lamp_owned or world.player.weapon_mode != "lamp": world.training.tell("按 3 装备旧灯，再按 F 显形。",4); return true
		if cooldown > 0: world.training.tell("旧灯恢复中 · %.1f 秒" % cooldown,3); return true
		if not world.travel_safe(): return true
		if world.entrance_circuit.reveal(): cooldown = 3.0
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
	_bind_entrance_lights()
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
	# The retained crypt has a 0.60 m first tread, then 0.49 m treads.
	player.traversal.step_height_limit = 0.65
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
	lamp_training.process_mode = Node.PROCESS_MODE_PAUSABLE
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
	entrance_circuit = preload("res://world/map03_barrier.tscn").instantiate()
	add_child(entrance_circuit)
	entrance_circuit.configure(self)
	warden_encounter = preload("res://combat/map03_warden.tscn").instantiate()
	add_child(warden_encounter)
	warden_encounter.configure(self)
	veyne_encounter = preload("res://combat/map03_veyne.tscn").instantiate()
	add_child(veyne_encounter)
	veyne_encounter.configure(self)
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
			if "Floor" in mesh.name or "Stairs" in mesh.name: body.set_meta("tomb_floor",true)
			for shape in body.get_children():
				if shape is CollisionShape3D and shape.shape is ConcavePolygonShape3D: shape.shape.backface_collision = true
		collision_meshes += 1

func _place_player() -> void:
	var xz := restored_xz(restored_position.get("position",Vector3.ZERO),restored_position.get("map_id",""))
	for attempt in 120:
		await get_tree().physics_frame
		if not TOMB_GROUND.place(self,player,xz): xz = TOMB_GROUND.ENTRY; continue
		if not ritual_record.grounded or not return_passage.grounded or not entrance_circuit.grounded or not warden_encounter.grounded or not veyne_encounter.grounded: continue
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
	return route_ready and is_instance_valid(player) and player.has_meta("spawn_position") and ritual_record.grounded and return_passage.grounded and entrance_circuit.grounded and warden_encounter.grounded and veyne_encounter.grounded

func restore_destination_history() -> void:
	super()
	ritual_record.restore_history()
	entrance_circuit.restore_history()
	warden_encounter.restore_history()
	veyne_encounter.restore_history()

func restored_xz(position: Vector3, map_id: String) -> Vector2:
	var xz := TOMB_GROUND.entry_xz(position,map_id)
	return TOMB_GROUND.ENTRY if not dialogue_state.ln02_purified and xz.y < -7.2 else xz

func checkpoint_xz() -> Vector2: return TOMB_GROUND.ENTRY
func active_map_id() -> String: return dialogue_state.MAP03
func contextual_interaction_target() -> Node3D:
	for target in [veyne_encounter.device,warden_encounter.device,entrance_circuit,ritual_record,return_passage]:
		if is_instance_valid(target) and target.interaction_prompt() != "": return target
	return null

func _load_opening(slot: int) -> void:
	super(slot)
	if is_instance_valid(ritual_record): ritual_record.restore_history()
	if is_instance_valid(entrance_circuit): entrance_circuit.restore_history()
	if is_instance_valid(warden_encounter): warden_encounter.restore_history()
	if is_instance_valid(veyne_encounter): veyne_encounter.restore_history()

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

func _bind_entrance_lights() -> void:
	for point in [Vector3(-7,3,0),Vector3(7,3,0),Vector3(-7,3,-6),Vector3(7,3,-6),Vector3(4,5,-11)]:
		var torch := OmniLight3D.new()
		torch.position = point
		torch.light_color = Color(1,0.52,0.18)
		torch.light_energy = 1.0
		torch.omni_range = 7
		village.add_child(torch)

func _set_pause_owner(owner_id: String, enabled: bool) -> void:
	# A cinematic locks input while its rig/clock continue. Menu owners pause.
	var was_paused: bool = pause_owners.keys().any(func(owner): return owner not in ["warden_reveal","veyne_presentation"])
	if enabled: pause_owners[owner_id] = true
	else: pause_owners.erase(owner_id)
	var now_paused: bool = pause_owners.keys().any(func(owner): return owner not in ["warden_reveal","veyne_presentation"])
	_sync_dialogue_world_labels()
	player.set_controls_open(not pause_owners.is_empty())
	if was_paused != now_paused: get_tree().paused = now_paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if not pause_owners.is_empty() else Input.MOUSE_MODE_CAPTURED
	if is_instance_valid(warden_encounter) and is_instance_valid(warden_encounter.music):
		warden_encounter.music.stream_paused = now_paused
		warden_encounter.cue.stream_paused = now_paused
		warden_encounter.effects.stream_paused = now_paused

	if is_instance_valid(veyne_encounter): veyne_encounter.set_menu_paused(now_paused)
