extends CharacterBody3D

var ground_policy = preload("res://forest_ground.gd")
var minimum_world_height := 7.0

const MODEL_PATH := "res://Characters/QuaterniusRanger/Male_Ranger.gltf"
const ANIMATION_PATH := "res://Characters/QuaterniusAnimations/UAL1_Standard.glb"
const SWORD_PATH := "res://Weapons/Sword_Bronze.gltf"
const BOW_PATH := "res://Weapons/Bow_Golden.obj"
const RANGER_PALETTE_SHADER := preload("res://ranger_palette.gdshader")
const SKIN_NAMES := ["Forest", "Frost", "Ember"]
const SKIN_COLORS := [Color.WHITE, Color(0.42, 0.70, 1.0), Color(1.0, 0.28, 0.16)]
const ARROW_SCRIPT := preload("res://arrow_projectile.gd")
const BOW_POSE_SCRIPT := preload("res://bow_pose_modifier.gd")
const BOW_VISUAL_SCRIPT := preload("res://bow_visual.gd")
const HEAD_ASSEMBLY := preload("res://ranger_head_assembly.gd")
const BOW_ANIMATION_PATH := "res://Characters/KayKitAnimations/Rig_Medium_CombatRanged.glb"
const BOW_DRAW_TIME := 1.0
const BOW_IDLE_BASIS := Vector3(-0.556121, -0.448697, 3.117197)
const TRAVERSAL_SCRIPT := preload("res://traversal_controller.gd")
signal controls_changed
var archery: Node
var abilities: Node
var owns_lamp := false
var combat: Node
const SWORD_ANIMATION_PATH := "res://Characters/QuaterniusAnimations/UAL2_Standard.glb"
const AERIAL_CLIP := "sword/Aerial_Heavy"
const AERIAL_SOURCE_START := 2.1
const AERIAL_SOURCE_END := 3.45
const AERIAL_PLAYBACK_SPEED := 2.4
const FINISHER_CLIP := "sword/Grounded_Finisher"
const FINISHER_SOURCE_START := 0.0
const FINISHER_SOURCE_END := 1.0
var heavy_press_held := false
var sword_press_held := false

# One source for dispatch, held input, controls UI and gameplay prompts.
const CONTROL_DEFAULTS := {
	"roll": KEY_B, "dodge": KEY_ALT, "shoulder": KEY_TAB,
	"jump": KEY_SPACE, "sprint": KEY_SHIFT, "forward": KEY_W,
	"back": KEY_S, "left": KEY_A, "right": KEY_D,
	"crouch": KEY_C, "prone": KEY_Z, "perspective": KEY_V, "heavy": KEY_T,
}
const CONTROL_LABELS := {
	"roll": "Roll", "dodge": "Dodge", "shoulder": "Switch shoulder",
	"jump": "Jump", "sprint": "Sprint (hold)", "forward": "Move forward",
	"back": "Move back", "left": "Move left", "right": "Move right",
	"crouch": "Crouch", "prone": "Prone", "perspective": "First / third person",
	"heavy": "Sword finisher (late light recovery)",
}
# E/F retain interaction/lamp ownership, including while their systems are locked.
const RESERVED_KEYS := [KEY_E, KEY_F, KEY_H, KEY_Q, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_I, KEY_K,
	KEY_G, KEY_R, KEY_M, KEY_J, KEY_ESCAPE, KEY_F10,
	KEY_ENTER, KEY_KP_ENTER, KEY_BACKSPACE, KEY_UP, KEY_DOWN,
	KEY_F5, KEY_F6, KEY_F7, KEY_F8, KEY_F9, KEY_F11]
const CONTROLS_FILE := "user://locomotion_controls.cfg"
var control_persistence_error := ""
var effective_bindings: Dictionary = CONTROL_DEFAULTS.duplicate()
var shake_remaining := 0.0
var controls_open := false
var blocked_keys: Dictionary = {}
var blocked_mouse: Dictionary = {}
var controls_animation_was_playing := false

const WALK_SPEED := 5.0
const RUN_SPEED := 8.0
const JUMP_SPEED := 6.8
const GRAVITY := 20.0

@onready var visual: Node3D = $Visual
@onready var arm: SpringArm3D = $CameraArm
@onready var camera: Camera3D = $CameraArm/Camera

var skeleton: Skeleton3D
var character_model: Node3D
var animation_player: AnimationPlayer
var current_animation := ""
var ranger_palette_material: ShaderMaterial
var skin_index := 0
var sword_attachment: BoneAttachment3D
var bow_attachment: BoneAttachment3D
var back_attachment: BoneAttachment3D
var sword_holder: Node3D
var bow_holder: Node3D
var sword_back_holder: Node3D
var bow_back_holder: Node3D
var weapon_mode := "unarmed"
var owns_sword := false
var owns_bow := false
var pending_weapon := ""
var switch_timer := 0.0
var switch_swapped := false
var attack_timer := 0.0
var step_distance := 0.0
var next_foot := "foot_l"
var footstep_count := 0
var aim_requested := false
var aim_blend := 0.0
var shoulder_side := 1.0
var shoulder_blend := 1.0
var first_person := false
var perspective_blend := 0.0
var head_mesh: MeshInstance3D
var head_components: Array[MeshInstance3D] = []
var bow_charge := 0.0
var bow_state := "idle"
var bow_clock := 0.0
var release_charge := 0.0
var bow_pose: SkeletonModifier3D
var bow_visual: Node3D
var bow_ik: TwoBoneIK3D
var bow_draw_target: Node3D
var bow_elbow_target: Node3D
var bow_frame := Transform3D.IDENTITY
var shots_fired := 0
var traversal: Node
var free_camera_distance := 3.8
var smooth_camera_distance := 3.8
var window_focused := true
var recapture_guard := false

var camera_height := 1.65


func owns_weapon(mode: String) -> bool:
	return (mode == "sword" and owns_sword) or (mode == "bow" and owns_bow) or (mode == "lamp" and owns_lamp) or mode == "unarmed"


# The product wrapper supplies possession before tree entry. Later callers can
# use the same boundary without changing the calibrated mounts or traversal.
func configure_equipment(sword_owned: bool, bow_owned: bool, selected_mode: String = "unarmed") -> void:
	owns_sword = sword_owned
	owns_bow = bow_owned
	weapon_mode = selected_mode if owns_weapon(selected_mode) else "unarmed"
	pending_weapon = ""
	switch_timer = 0.0
	switch_swapped = false
	attack_timer = 0.0
	cancel_aim()
	bow_state = "idle"
	bow_charge = 0.0
	bow_clock = 0.0
	release_charge = 0.0
	_set_weapon_visibility()
	if is_node_ready():
		current_animation = ""
		_update_animation(Vector2(velocity.x, velocity.z).length_squared() > 0.01)


func _ready() -> void:
	_setup_controls()
	arm.add_excluded_object(get_rid())
	if ResourceLoader.exists(MODEL_PATH):
		var model := (load(MODEL_PATH) as PackedScene).instantiate() as Node3D
		visual.add_child(model)
		character_model = model
		head_mesh = model.find_child("Male_Ranger_Head_Hood", true, false) as MeshInstance3D
		skeleton = model.get_node_or_null("Armature/Skeleton3D") as Skeleton3D
		if head_mesh:
			head_components.append(head_mesh)
		head_components.append_array(HEAD_ASSEMBLY.assemble(skeleton))
		if ResourceLoader.exists(ANIMATION_PATH):
			var animation_scene := (load(ANIMATION_PATH) as PackedScene).instantiate() as Node3D
			var imported_player := animation_scene.get_node("AnimationPlayer") as AnimationPlayer
			imported_player.owner = null
			animation_scene.remove_child(imported_player)
			model.add_child(imported_player)
			animation_player = imported_player
			animation_scene.queue_free()
			_play_animation("Sword_Idle" if owns_weapon(weapon_mode) and weapon_mode == "sword" else "Idle")
		if animation_player and ResourceLoader.exists(SWORD_ANIMATION_PATH):
			var extra := (load(SWORD_ANIMATION_PATH) as PackedScene).instantiate()
			var library: AnimationLibrary = extra.get_node("AnimationPlayer").get_animation_library("").duplicate(true)
			animation_player.add_animation_library("sword", library)
			extra.free()
			_bind_aerial_sword_segment(library)
			_bind_sword_segment(library, "Grounded_Finisher", FINISHER_SOURCE_START, FINISHER_SOURCE_END)
		_attach_weapons()
		_apply_skin()
		_setup_archery()
	else:
		var marker := MeshInstance3D.new()
		marker.mesh = CapsuleMesh.new()
		marker.position.y = 0.9
		visual.add_child(marker)

	traversal = Node.new()
	traversal.set_script(TRAVERSAL_SCRIPT)
	traversal.player = self
	add_child(traversal)


func _attach_weapons() -> void:
	if skeleton == null:
		return
	sword_attachment = BoneAttachment3D.new()
	sword_attachment.bone_name = "hand_r"
	skeleton.add_child(sword_attachment)
	sword_holder = Node3D.new()
	sword_holder.visible = false
	sword_attachment.add_child(sword_holder)
	# The hand bone starts at the wrist; the palm is about 6.5 cm along its Y axis.
	sword_holder.position.y = 0.065
	sword_holder.basis = Basis.from_euler(Vector3(0.496039, -0.808365, -2.084909))
	if ResourceLoader.exists(SWORD_PATH):
		var sword := (load(SWORD_PATH) as PackedScene).instantiate() as Node3D
		sword.position.y = 0.05  # The center of the handle is at source Y = -0.05.
		sword_holder.add_child(sword)

	bow_attachment = BoneAttachment3D.new()
	bow_attachment.bone_name = "hand_l"
	skeleton.add_child(bow_attachment)
	bow_holder = Node3D.new()
	bow_holder.visible = false
	bow_attachment.add_child(bow_holder)
	bow_holder.position.y = 0.065
	# Source +X points from bow limbs to string. Turn the string toward the
	# archer (local -Z) and the limbs toward the target (local +Z).
	bow_holder.basis = Basis.from_euler(Vector3(-0.556121, -0.448697, 3.117197)) * Basis(Vector3.UP, 0.85)
	if ResourceLoader.exists(BOW_PATH):
		bow_visual = Node3D.new()
		bow_visual.set_script(BOW_VISUAL_SCRIPT)
		bow_holder.add_child(bow_visual)

	back_attachment = BoneAttachment3D.new()
	back_attachment.bone_name = "spine_02"
	skeleton.add_child(back_attachment)
	sword_back_holder = Node3D.new()
	sword_back_holder.visible = false
	back_attachment.add_child(sword_back_holder)
	# The sword mesh extends from its grip along local +Y. Keep the grip above
	# the shoulder and point the blade diagonally down across the back.
	sword_back_holder.position = Vector3(0.12, 0.47, -0.25)
	sword_back_holder.basis = Basis.from_euler(Vector3(0.0681, 0.2316, -0.5581)) * Basis(Vector3.RIGHT, PI)
	if ResourceLoader.exists(SWORD_PATH):
		var stowed_sword := (load(SWORD_PATH) as PackedScene).instantiate() as Node3D
		stowed_sword.position.y = 0.05
		sword_back_holder.add_child(stowed_sword)

	bow_back_holder = Node3D.new()
	bow_back_holder.visible = false
	back_attachment.add_child(bow_back_holder)
	bow_back_holder.position = Vector3(0.0356, 0.1348, -0.1307)
	bow_back_holder.basis = Basis.from_euler(Vector3(-0.0318, 0.2324, 0.4920))
	if ResourceLoader.exists(BOW_PATH):
		var stowed_bow := MeshInstance3D.new()
		stowed_bow.mesh = load(BOW_PATH) as Mesh
		stowed_bow.scale = Vector3.ONE * 0.21
		stowed_bow.position.x = -0.0063
		bow_back_holder.add_child(stowed_bow)
	_set_weapon_visibility()


func _setup_controls() -> void:
	var config := ConfigFile.new()
	if config.load(CONTROLS_FILE) == OK:
		effective_bindings = _sanitize_controls(config)
		for action in effective_bindings:
			if config.get_value("keys", action, CONTROL_DEFAULTS[action]) != effective_bindings[action]:
				_save_controls()
				break
	_apply_controls()


func _sanitize_controls(config: ConfigFile) -> Dictionary:
	var loaded: Dictionary = {}
	# Preserve valid preferences while repairing obsolete UI conflicts.
	var used: Array = []
	for action in CONTROL_DEFAULTS:
		var value: Variant = config.get_value("keys", action, CONTROL_DEFAULTS[action])
		if value is int and value > 0 and value not in RESERVED_KEYS and value not in used:
			loaded[action] = value
			used.append(value)
	for action in CONTROL_DEFAULTS:
		if loaded.has(action): continue
		var fallback: int = CONTROL_DEFAULTS[action]
		if fallback in used:
			for alternative in [KEY_B, KEY_ALT, KEY_TAB, KEY_SPACE, KEY_SHIFT, KEY_W, KEY_S, KEY_A, KEY_D, KEY_C, KEY_Z, KEY_V, KEY_X, KEY_T, KEY_Y, KEY_U, KEY_I, KEY_O, KEY_P, KEY_L, KEY_N]:
				if alternative not in used and alternative not in RESERVED_KEYS:
					fallback = alternative
					break
		loaded[action] = fallback
		used.append(fallback)
	return loaded


func _apply_controls() -> void:
	for action in effective_bindings:
		var mapped := "r02_" + String(action)
		if not InputMap.has_action(mapped):
			InputMap.add_action(mapped)
		InputMap.action_erase_events(mapped)
		var key := InputEventKey.new()
		key.keycode = effective_bindings[action]
		InputMap.action_add_event(mapped, key)
	controls_changed.emit()


func key_prompt(action: String) -> String:
	return OS.get_keycode_string(effective_bindings[action])


func rebind_control(action: String, key: int) -> String:
	if not effective_bindings.has(action) or key <= 0:
		return "请选择一个键盘按键。"
	if key in RESERVED_KEYS:
		return "%s 是保留键，请选择其他按键。" % OS.get_keycode_string(key)
	for other in effective_bindings:
		if other != action and effective_bindings[other] == key:
			return "%s 已用于 %s，请选择未占用的按键。" % [OS.get_keycode_string(key), CONTROL_LABELS[other]]
	effective_bindings[action] = key
	_apply_controls()
	return _save_controls()


func restore_controls() -> String:
	effective_bindings = CONTROL_DEFAULTS.duplicate()
	_apply_controls()
	return _save_controls()


func _save_controls() -> String:
	var config := ConfigFile.new()
	for action in effective_bindings:
		config.set_value("keys", action, effective_bindings[action])
	var error := config.save(CONTROLS_FILE + ".tmp")
	if error == OK: error = DirAccess.rename_absolute(CONTROLS_FILE + ".tmp", CONTROLS_FILE)
	control_persistence_error = "" if error == OK else "本次已生效 · 按键保存失败，请重试。"
	return control_persistence_error


func _block_held_controls() -> void:
	for key in effective_bindings.values() + [KEY_E, KEY_F]:
		if Input.is_key_pressed(key):
			blocked_keys[key] = true
	for button in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		if Input.is_mouse_button_pressed(button):
			blocked_mouse[button] = true


func track_modal_input(event: InputEvent) -> void:
	# The pause owner still receives releases while this actor is pausable.
	if event is InputEventKey:
		if event.pressed: blocked_keys[event.keycode] = true
		else: blocked_keys.erase(event.keycode)
	elif event is InputEventMouseButton:
		if event.pressed: blocked_mouse[event.button_index] = true
		else: blocked_mouse.erase(event.button_index)


func set_controls_open(open: bool) -> void:
	_block_held_controls()
	sword_press_held = false
	heavy_press_held = false
	controls_open = open
	reset_archery()
	# The world pause freezes the action clock, contact and parry window.
	# Only discard buffered future input; opening a menu is not a combat reset.
	if combat:
		combat.clear_attack_buffers()
		if not open and combat.blocking and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			combat.set_block(false)
	# AnimationPlayer inherits the player's pausable process mode. Let the
	# world pause suspend it without play() resetting a custom attack speed.


func control_held(action: String) -> bool:
	return not controls_open and not blocked_keys.has(effective_bindings[action]) and Input.is_action_pressed("r02_" + action)


func _control_pressed(event: InputEvent, action: String) -> bool:
	return not controls_open and not blocked_keys.has(effective_bindings[action]) and event.is_action_pressed("r02_" + action)


func _unhandled_input(event: InputEvent) -> void:
	if controls_open or not window_focused:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sensitivity: float = lerpf(0.003, 0.0017, aim_blend) * _mouse_sensitivity()
		arm.rotation.y -= event.relative.x * sensitivity
		arm.rotation.x = clampf(arm.rotation.x - event.relative.y * sensitivity, -1.25 if first_person else -0.85, 1.1 if first_person else 0.45)
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		if not first_person and not aim_requested and aim_blend < 0.01:
			free_camera_distance = clampf(free_camera_distance + (-0.45 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.45), 2.0, 6.5)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: request_weapon("sword")
			KEY_2: request_weapon("bow")
			KEY_3: request_weapon("lamp")
			KEY_Q: request_weapon("bow" if weapon_mode == "sword" else "sword")
		if _control_pressed(event, "shoulder"): shoulder_side *= -1.0
		elif _control_pressed(event, "perspective"): toggle_perspective()
		elif _control_pressed(event, "crouch"): traversal.request_posture("crouch")
		elif _control_pressed(event, "prone"): traversal.request_posture("prone")
		elif _control_pressed(event, "roll"): traversal.evade("roll")
		elif _control_pressed(event, "dodge"): traversal.evade("dodge")


func toggle_perspective() -> void:
	first_person = not first_person
	if not first_person:
		arm.rotation.x = clampf(arm.rotation.x, -0.85, 0.45)


func cycle_skin() -> void:
	skin_index = (skin_index + 1) % SKIN_NAMES.size()
	_apply_skin()


func _apply_skin() -> void:
	if character_model == null:
		return
	for node in character_model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		for surface in range(mesh_instance.mesh.get_surface_count()):
			var source := mesh_instance.mesh.surface_get_material(surface) as StandardMaterial3D
			if source == null or source.resource_name != "MI_Ranger":
				continue
			if skin_index == 0:
				mesh_instance.set_surface_override_material(surface, null)
				continue
			if ranger_palette_material == null:
				ranger_palette_material = ShaderMaterial.new()
				ranger_palette_material.shader = RANGER_PALETTE_SHADER
				ranger_palette_material.set_shader_parameter("base_texture", source.albedo_texture)
				ranger_palette_material.set_shader_parameter("normal_texture", source.normal_texture)
				ranger_palette_material.set_shader_parameter("orm_texture", source.roughness_texture)
			ranger_palette_material.set_shader_parameter("dye_color", SKIN_COLORS[skin_index])
			mesh_instance.set_surface_override_material(surface, ranger_palette_material)


func _input(event: InputEvent) -> void:
	# Releases clear suppression; menu/capture presses never become gameplay input.
	if event is InputEventKey:
		if not event.pressed:
			blocked_keys.erase(event.keycode)
			if event.keycode == effective_bindings["heavy"]: heavy_press_held = false
		elif controls_open:
			blocked_keys[event.keycode] = true
	elif event is InputEventMouseButton:
		if not event.pressed:
			blocked_mouse.erase(event.button_index)
			if event.button_index == MOUSE_BUTTON_LEFT: sword_press_held = false
		elif controls_open:
			blocked_mouse[event.button_index] = true
	if get_parent().has_method("handle_controls_input") and get_parent().handle_controls_input(event):
		get_viewport().set_input_as_handled()
		return
	if not window_focused:
		return
	if not controls_open and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and (recapture_guard or Input.mouse_mode == Input.MOUSE_MODE_VISIBLE):
		recapture_guard = false
		blocked_mouse[MOUSE_BUTTON_LEFT] = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
		return
	if controls_open:
		# The owner already consumes capture and navigation keys. Allow its
		# focused GUI buttons to receive unconsumed keyboard and pointer input.
		# Gameplay actions and unhandled input remain gated by controls_open.
		return
	if event is InputEventKey and event.keycode == effective_bindings["heavy"]:
		if event.pressed and not event.echo and not heavy_press_held and _control_pressed(event, "heavy"):
			heavy_press_held = true
			if combat and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED: combat.request_finisher()
		return
	if event is InputEventMouseButton and blocked_mouse.has(event.button_index):
		return
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		cancel_aim()
	if not event is InputEventMouseButton or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event.button_index == MOUSE_BUTTON_RIGHT:
		if weapon_mode == "sword" and combat:
			combat.set_block(event.pressed)
		else:
			set_aim(event.pressed)
	elif event.button_index == MOUSE_BUTTON_LEFT:
		if weapon_mode == "bow":
			if event.pressed:
				begin_bow_draw()
			else:
				release_bow()
		elif event.pressed:
			if not sword_press_held:
				sword_press_held = true
				_attack()
		else:
			sword_press_held = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		window_focused = true
		recapture_guard = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		window_focused = false
		_block_held_controls()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		cancel_aim()
		if combat: combat.interrupt("focus")


func _setup_archery() -> void:
	if skeleton == null or not ResourceLoader.exists(BOW_ANIMATION_PATH):
		push_warning("Bow aiming requires KayKit Rig_Medium_CombatRanged.glb; see README.")
		return
	var source := (load(BOW_ANIMATION_PATH) as PackedScene).instantiate() as Node3D
	source.name = "BowAnimationSource"
	source.visible = false
	add_child(source)
	bow_pose = SkeletonModifier3D.new()
	bow_pose.set_script(BOW_POSE_SCRIPT)
	skeleton.add_child(bow_pose)
	bow_pose.configure(source.find_child("Skeleton3D", true, false), source.get_node("AnimationPlayer"))
	bow_draw_target = Node3D.new()
	bow_draw_target.name = "BowDrawTarget"
	visual.add_child(bow_draw_target)
	bow_elbow_target = Node3D.new()
	bow_elbow_target.name = "BowElbowTarget"
	visual.add_child(bow_elbow_target)
	bow_ik = TwoBoneIK3D.new()
	skeleton.add_child(bow_ik)
	bow_ik.set_setting_count(1)
	bow_ik.set_root_bone_name(0, "upperarm_r")
	bow_ik.set_middle_bone_name(0, "lowerarm_r")
	bow_ik.set_end_bone_name(0, "hand_r")
	bow_ik.set_extend_end_bone(0, true)
	bow_ik.set_end_bone_direction(0, SkeletonModifier3D.BONE_DIRECTION_PLUS_Y)
	bow_ik.set_end_bone_length(0, 0.065)
	bow_ik.set_target_node(0, bow_ik.get_path_to(bow_draw_target))
	bow_ik.set_pole_node(0, bow_ik.get_path_to(bow_elbow_target))
	bow_ik.set_pole_direction(0, SkeletonModifier3D.SECONDARY_DIRECTION_PLUS_X)
	bow_ik.influence = 0.0
	bow_pose.modification_processed.connect(_prepare_bow_targets)
	skeleton.skeleton_updated.connect(_update_bow_visual)


func set_aim(enabled: bool) -> void:
	if not enabled:
		cancel_aim()
	elif owns_weapon("bow") and weapon_mode == "bow" and switch_timer <= 0.0 and is_on_floor() and bow_pose != null and (combat == null or not combat.player_locked()) and (traversal == null or (traversal.posture == "standing" and traversal.action == "")):
		aim_requested = true
		if bow_state == "idle":
			bow_state = "ready"


func cancel_aim() -> void:
	aim_requested = false
	if bow_state != "release":
		bow_state = "idle"
		bow_charge = 0.0


func begin_bow_draw() -> void:
	if owns_weapon("bow") and weapon_mode == "bow" and aim_requested and bow_state == "ready" and attack_timer <= 0.0 and (archery == null or archery.can_draw()):
		bow_state = "draw"
		bow_charge = 0.0
		bow_clock = 0.0


func release_bow() -> void:
	if not owns_weapon("bow") or weapon_mode != "bow":
		cancel_aim()
		return
	if bow_state not in ["draw", "hold"]:
		return
	if not aim_requested or bow_charge < 0.12:
		bow_state = "ready" if aim_requested else "idle"
		bow_charge = 0.0
		return
	release_charge = bow_charge
	if not _fire_arrow():
		reset_archery()
		return
	bow_state = "release"
	bow_clock = 0.0
	attack_timer = 0.5
	bow_charge = 0.0


func _update_archery(delta: float) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		cancel_aim()
	aim_blend = lerpf(aim_blend, 1.0 if aim_requested else 0.0, 1.0 - exp(-4.5 * delta))
	perspective_blend = lerpf(perspective_blend, 1.0 if first_person else 0.0, 1.0 - exp(-10.0 * delta))
	# Snap only the final millimetres so the first-person camera reaches the eye.
	if absf(perspective_blend - (1.0 if first_person else 0.0)) < 0.001:
		perspective_blend = 1.0 if first_person else 0.0
	shoulder_blend = lerpf(shoulder_blend, shoulder_side, 1.0 - exp(-8.0 * delta))
	camera.fov = lerpf(lerpf(70.0, 48.0, aim_blend), lerpf(78.0, 55.0, aim_blend), perspective_blend)
	camera.near = lerpf(0.1, 0.045, perspective_blend)
	smooth_camera_distance = lerpf(smooth_camera_distance, free_camera_distance, 1.0 - exp(-8.0 * delta))
	arm.spring_length = lerpf(smooth_camera_distance, minf(2.65, free_camera_distance), aim_blend) * (1.0 - perspective_blend)
	var desired_height: float = lerpf(1.65 if traversal.posture == "standing" else 1.4, traversal.eye_height(), perspective_blend) if traversal else 1.65
	camera_height = lerpf(camera_height, desired_height, 1.0 - exp(-10.0 * delta))
	var pivot := global_position + Vector3(0, camera_height - 0.2 * (1.0 - perspective_blend) + (traversal.camera_step_offset if traversal else 0.0), 0)
	var local_offset := Vector3(lerpf(0.30, 0.52, aim_blend) * shoulder_blend * (1.0 - perspective_blend), 0, -0.06 * perspective_blend)
	var offset := Basis(Vector3.UP, arm.rotation.y) * local_offset
	if offset.length_squared() > 0.001:
		var query := PhysicsRayQueryParameters3D.create(pivot, pivot + offset)
		query.exclude = [get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit:
			offset = (hit.position - pivot) * 0.75
	arm.position = pivot - global_position + offset
	_update_head_visibility()
	if bow_state == "draw":
		bow_charge = minf(1.0, bow_charge + delta / BOW_DRAW_TIME)
		if bow_charge >= 1.0:
			bow_state = "hold"
			bow_clock = 0.0
	elif bow_state == "hold":
		bow_clock += delta
	if bow_state == "release":
		bow_clock += delta
		if bow_clock >= 0.5:
			bow_state = "ready" if aim_requested else "idle"
	if bow_pose:
		var pose_weight := aim_blend if weapon_mode == "bow" and switch_timer <= 0.0 else 0.0
		bow_pose.pose_weight = pose_weight
		bow_pose.lower_body_weight = pose_weight * clampf(1.0 - Vector2(velocity.x, velocity.z).length() / 1.5, 0.0, 1.0)
		# Actor +Z is forward, so positive local X pitch points the body down.
		bow_pose.pitch = -arm.rotation.x
		if bow_state == "release":
			bow_pose.clip = "Ranged_Bow_Release"
			bow_pose.clip_time = minf(1.32, 0.06 + bow_clock * 2.5)
		elif bow_state == "hold":
			bow_pose.clip = "Ranged_Bow_Aiming_Idle"
			bow_pose.clip_time = fmod(bow_clock, 1.833)
		else:
			bow_pose.clip = "Ranged_Bow_Draw"
			bow_pose.clip_time = 0.7 + bow_charge * 0.63
		bow_ik.influence = pose_weight if bow_state != "release" else 0.0


func prepare_restored_camera(yaw: float) -> void:
	# Saved histories retain yaw, not transient aim/perspective/camera shake.
	# Grounding can immediately be followed by dialogue pause, before this
	# native SpringArm has ever processed. Initialize only its collision sweep;
	# never thaw the tree or tick player/combat/ability/animation controllers.
	cancel_aim()
	first_person = false
	perspective_blend = 0.0
	aim_blend = 0.0
	shoulder_blend = shoulder_side
	smooth_camera_distance = free_camera_distance
	camera_height = 1.65
	arm.rotation = Vector3(-0.2, yaw, 0)
	var pivot := global_position + Vector3(0, 1.45, 0)
	var offset := Basis(Vector3.UP, yaw) * Vector3(0.30 * shoulder_side, 0, 0)
	var query := PhysicsRayQueryParameters3D.create(pivot, pivot + offset)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		offset = (hit.position - pivot) * 0.75
	arm.position = pivot - global_position + offset
	arm.spring_length = free_camera_distance
	arm.force_update_transform()
	camera.fov = 70.0
	camera.near = 0.1
	shake_remaining = 0.0
	camera.h_offset = 0.0
	camera.v_offset = 0.0
	_update_head_visibility()
	# Godot 4.7's native notification performs the same camera-shape sweep as
	# ordinary SpringArm processing, including its mask, margin and player RID
	# exclusion. A whole physics frame here would advance unrelated gameplay.
	arm.notification(Node.NOTIFICATION_INTERNAL_PHYSICS_PROCESS)
	reset_physics_interpolation()


func _update_head_visibility() -> void:
	# Face, eyes, eyebrows and hood remain shadow casters in first person.
	for component in head_components:
		component.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY if perspective_blend > 0.75 else GeometryInstance3D.SHADOW_CASTING_SETTING_ON


func _prepare_bow_targets() -> void:
	var left := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("hand_l"))
	var forward := -camera.global_basis.z.normalized()
	var up := camera.global_basis.y.normalized()
	var desired := Basis(-forward, up, (-forward).cross(up).normalized())
	var idle := Basis.from_euler(BOW_IDLE_BASIS) * Basis(Vector3.UP, 0.85)
	bow_holder.basis = Basis(idle.get_rotation_quaternion().slerp((left.basis.inverse() * desired).orthonormalized().get_rotation_quaternion(), aim_blend))
	bow_frame = left * bow_holder.transform
	var draw_amount := bow_charge
	if bow_state == "release":
		draw_amount = release_charge * exp(-bow_clock * 35.0)
	bow_draw_target.global_position = bow_frame * Vector3(0.2105 + draw_amount * 0.36, 0, 0)
	var elbow := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("lowerarm_r"))
	bow_elbow_target.global_position = elbow.origin + visual.global_basis.x * -0.2


func _update_bow_visual() -> void:
	if bow_visual == null:
		return
	var nock := bow_holder.to_local(bow_draw_target.global_position) if aim_blend > 0.001 else Vector3(0.2105, 0, 0)
	bow_visual.set_draw(aim_requested and bow_state != "release", nock, Vector3(-1, 0, 0))


func _physics_process(delta: float) -> void:
	_update_camera_shake(delta)
	# Native release can arrive during a paused/focus boundary. Reconcile only
	# the released physical button; a held click never rearms an attack.
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): sword_press_held = false
	if controls_open:
		return
	if combat:
		combat.advance_player(delta)
		if combat.player_locked(): return
	var forward := -camera.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := camera.global_basis.x
	right.y = 0.0
	right = right.normalized()
	var move_axis := Vector2.ZERO
	if control_held("forward"): move_axis.y += 1.0
	if control_held("back"): move_axis.y -= 1.0
	if control_held("right"): move_axis.x += 1.0
	if control_held("left"): move_axis.x -= 1.0
	move_axis = move_axis.normalized()
	var direction := (forward * move_axis.y + right * move_axis.x).normalized()
	var speed: float = traversal.advance(delta, direction)
	if combat and combat.motion_restricted(): speed *= 0.3
	var acceleration := 18.0 if is_on_floor() else 6.0
	velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	if traversal.action != "":
		var impulse: Vector3 = traversal.action_velocity()
		velocity.x = impulse.x
		velocity.z = impulse.z
	var grounded_before: bool = is_on_floor() or traversal.step_grace > 0.0
	var fall_speed := velocity.y
	if grounded_before:
		if control_held("jump") and traversal.posture == "standing" and traversal.action == "" and (combat == null or not combat.motion_restricted()):
			cancel_aim()
			velocity.y = JUMP_SPEED
			traversal.step_grace = 0.0
			traversal.takeoff_timer = 0.22
			traversal.landing_timer = 0.0
		else:
			velocity.y = 0.0
	else:
		velocity.y -= GRAVITY * delta
	var before := global_position
	traversal.move_with_steps(delta)
	if is_on_floor() and not grounded_before and fall_speed < -1.0 and traversal.air_time > 0.08:
		traversal.landing_timer = 0.28 if fall_speed < -8.0 else 0.18
	if combat and is_on_floor() and not grounded_before:
		combat.sword_landed()
	if is_on_floor():
		traversal.air_time = 0.0
	else:
		traversal.air_time += delta
	if not is_on_floor() and traversal.step_grace <= 0.0:
		cancel_aim()
	if traversal.action != "" or (combat and combat.motion_restricted()):
		pass
	elif aim_requested or first_person:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(forward.x, forward.z), 14.0 * delta)
	elif direction.length_squared() > 0.01:
		# Quaternius' local +Z is the front of this character.
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(direction.x, direction.z), 12.0 * delta)
	traversal.sync_prone_facing()
	_update_switch(delta)
	_update_archery(delta)
	attack_timer = maxf(0.0, attack_timer - delta)
	_update_animation(direction.length_squared() > 0.01)
	_update_footsteps(before)
	if global_position.y < minimum_world_height or not ground_policy.in_bounds(Vector2(global_position.x, global_position.z)):
		if combat: combat.lethal_fall()
		else: respawn()


func request_weapon(mode: String) -> void:
	if (combat and combat.player_locked()) or (abilities and abilities.busy()): return
	if not owns_weapon(mode):
		_equipment_required()
		return
	if mode == weapon_mode or switch_timer > 0.0 or (traversal and (traversal.action != "" or traversal.posture == "prone")):
		return
	if combat: combat.interrupt("switch")
	cancel_aim()
	pending_weapon = mode
	switch_timer = 0.78
	switch_swapped = false
	_play_animation("Interact", 2.5)


func _update_switch(delta: float) -> void:
	if switch_timer <= 0.0:
		return
	switch_timer = maxf(0.0, switch_timer - delta)
	if not switch_swapped and switch_timer <= 0.4:
		weapon_mode = pending_weapon
		if combat:
			combat.state.sword_selected = weapon_mode == "sword"
			combat.state.selected_equipment = weapon_mode
			combat.state.inventory.ensure_equipment()
			combat.state.inventory.select_equipment(weapon_mode)
		_set_weapon_visibility()
		switch_swapped = true
	if switch_timer <= 0.0:
		pending_weapon = ""


func _set_weapon_visibility() -> void:
	var stowed: bool = traversal != null and traversal.posture == "prone"
	stowed = stowed or (abilities != null and abilities.busy())
	if sword_holder: sword_holder.visible = owns_sword and weapon_mode == "sword" and not stowed
	if bow_holder: bow_holder.visible = owns_bow and weapon_mode == "bow" and not stowed
	if sword_back_holder: sword_back_holder.visible = owns_sword and (weapon_mode != "sword" or stowed)
	if bow_back_holder: bow_back_holder.visible = owns_bow and (weapon_mode != "bow" or stowed)


func _update_animation(moving: bool) -> void:
	if (abilities and abilities.busy()) or animation_player == null or switch_timer > 0.0 or attack_timer > 0.0 or (traversal and traversal.action != "") or (combat and combat.pose_owned()):
		return
	if not is_on_floor() and traversal.step_grace <= 0.0:
		_play_animation("Jump_Start", 2.0) if traversal.takeoff_timer > 0 else _play_animation("Jump", 2.0)
	elif traversal.landing_timer > 0 and traversal.posture == "standing":
		_play_animation("Jump_Land", 2.0)
	elif traversal.posture == "crouch":
		_play_animation("Crouch_Fwd" if moving else "Crouch_Idle")
	elif traversal.posture == "prone":
		_play_animation("Idle")
	elif moving:
		_play_animation("Sprint" if traversal.sprinting else "Walk")
	else:
		_play_animation("Sword_Idle" if weapon_mode == "sword" else "Idle")


func _bind_aerial_sword_segment(library: AnimationLibrary) -> void:
	_bind_sword_segment(library, "Aerial_Heavy", AERIAL_SOURCE_START, AERIAL_SOURCE_END)


func _bind_sword_segment(library: AnimationLibrary, clip_name: String, source_start: float, source_end: float) -> void:
	# Extract one cut; physics owns horizontal translation, pose retains height.
	# Preserve the licensed source animation and its rig paths unchanged.
	if not library.has_animation("Sword_Heavy_Combo") or skeleton == null: return
	var source: Animation = library.get_animation("Sword_Heavy_Combo")
	var clip: Animation = source.duplicate(true)
	clip.length = source_end - source_start
	clip.loop_mode = Animation.LOOP_NONE
	var pelvis: int = skeleton.find_bone("pelvis")
	var parent_basis: Basis = skeleton.get_bone_global_rest(skeleton.get_bone_parent(pelvis)).basis
	var anchor: Vector3 = parent_basis * skeleton.get_bone_rest(pelvis).origin
	for track in clip.get_track_count():
		var type: int = source.track_get_type(track)
		if type not in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D]: continue
		for key in range(clip.track_get_key_count(track) - 1, -1, -1): clip.track_remove_key(track, key)
		var times: Array[float] = [source_start, source_end]
		for key in source.track_get_key_count(track):
			var time: float = source.track_get_key_time(track, key)
			if time > source_start and time < source_end: times.append(time)
		for time in times:
			var value: Variant
			if type == Animation.TYPE_POSITION_3D:
				value = source.position_track_interpolate(track, time)
				if str(source.track_get_path(track)).ends_with(":pelvis"):
					# Body physics owns translation, as in the retained roll adapter.
					var world_value: Vector3 = parent_basis * value
					value = parent_basis.inverse() * Vector3(anchor.x, world_value.y, anchor.z)
			elif type == Animation.TYPE_ROTATION_3D: value = source.rotation_track_interpolate(track, time)
			else: value = source.scale_track_interpolate(track, time)
			clip.track_insert_key(track, time - source_start, value)
		clip.track_set_interpolation_loop_wrap(track, false)
	library.add_animation(clip_name, clip)

func _play_animation(name: String, speed: float = 1.0) -> void:
	if animation_player == null or current_animation == name:
		return
	if animation_player.has_animation(name):
		animation_player.play(name, 0.16, speed)
		current_animation = name


func _attack() -> void:
	if abilities and abilities.busy(): return
	if not owns_weapon(weapon_mode):
		_equipment_required()
		return
	if weapon_mode == "sword" and combat:
		combat.request_attack()


func _equipment_required() -> void:
	if traversal:
		traversal.feedback = "先取得装备"
		traversal.feedback_time = 1.8


func _fire_arrow() -> bool:
	if not owns_weapon("bow") or weapon_mode != "bow" or bow_holder == null or bow_visual == null or not ResourceLoader.exists("res://Weapons/Arrow.obj"):
		return false
	if archery and not archery.can_draw(): return false
	var center := get_viewport().get_visible_rect().size * 0.5
	var origin := camera.project_ray_origin(center)
	var ray_direction := camera.project_ray_normal(center)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + ray_direction * 55.0)
	query.exclude = [get_rid()]
	query.collision_mask = 3
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var target: Vector3 = hit.position if hit else origin + ray_direction * 55.0
	var start: Vector3 = bow_visual.held_arrow.global_position
	var speed := lerpf(18.0, 38.0, bow_charge)
	var direction := _ballistic_direction(start, target, speed)
	var arrow := Node3D.new()
	arrow.name = "Arrow"
	arrow.set_script(ARROW_SCRIPT)
	get_parent().add_child(arrow)
	if archery and not archery.register_shot(arrow, bow_charge, start):
		arrow.queue_free()
		return false
	arrow.launch(start, direction, get_rid(), speed, global_position + Vector3.UP * 1.2)
	shots_fired += 1
	return true


func reset_archery() -> void:
	cancel_aim()
	bow_state = "idle"
	bow_charge = 0
	bow_clock = 0
	release_charge = 0
	if bow_ik: bow_ik.influence = 0
	if bow_pose: bow_pose.pose_weight = 0
	if bow_visual: bow_visual.set_draw(false, Vector3(0.2105, 0, 0), Vector3(-1, 0, 0))

func _ballistic_direction(origin: Vector3, target: Vector3, speed: float) -> Vector3:
	var delta := target - origin
	var horizontal := Vector3(delta.x, 0, delta.z)
	var distance := horizontal.length()
	if distance < 0.1:
		return delta.normalized()
	var gravity: float = ARROW_SCRIPT.GRAVITY
	var speed_squared := speed * speed
	var discriminant := speed_squared * speed_squared - gravity * (gravity * distance * distance + 2.0 * delta.y * speed_squared)
	if discriminant < 0.0:
		return delta.normalized()
	var angle := atan((speed_squared - sqrt(discriminant)) / (gravity * distance))
	return horizontal.normalized() * cos(angle) + Vector3.UP * sin(angle)


func _update_footsteps(before: Vector3) -> void:
	if not is_on_floor() or velocity.length_squared() < 0.4 or traversal.posture == "prone" or traversal.action != "":
		step_distance = 0.0
		return
	var moved := global_position - before
	step_distance += Vector2(moved.x, moved.z).length()
	var step_length := 0.90 if control_held("sprint") else 0.72
	if step_distance >= step_length:
		step_distance -= step_length
		# Snow particles belong to the retired winter village.
		next_foot = "foot_r" if next_foot == "foot_l" else "foot_l"


func respawn() -> void:
	cancel_aim()
	bow_state = "idle"
	bow_charge = 0.0
	attack_timer = 0.0
	if traversal:
		traversal.reset()
		_set_weapon_visibility()
	if has_meta("spawn_position"):
		global_position = get_meta("spawn_position")
	velocity = Vector3.ZERO
	step_distance = 0.0

func _mcp_state() -> Dictionary:
	var observation := {"traversal": traversal.observation() if traversal else {}, "camera_yaw": arm.rotation.y, "camera_pitch": arm.rotation.x, "camera_target": free_camera_distance, "camera_requested_length": arm.spring_length, "camera_collision_length": arm.get_hit_length(), "mouse_sensitivity": _mouse_sensitivity(), "controls_open": controls_open, "window_focused": window_focused, "bow_state": bow_state, "bow_charge": bow_charge, "aim_requested": aim_requested, "arrows": archery.state.arrows if archery else 0, "shots_fired": shots_fired, "bow_clip": bow_pose.clip if bow_pose else "", "bow_clip_time": bow_pose.clip_time if bow_pose else 0, "equipment": weapon_mode, "owns_sword": owns_sword, "owns_bow": owns_bow, "animation": animation_player.current_animation if animation_player else "", "animation_position": animation_player.current_animation_position if animation_player else 0, "sword_in_hand": sword_holder.visible if sword_holder else false, "sword_on_back": sword_back_holder.visible if sword_back_holder else false, "combat": combat.player_snapshot() if combat else {}}

	# Scalar aliases retain the combat owner's authority and expose modal
	# suppression separately from physically held buttons. No input dispatch.
	var combat_state: Dictionary = observation.combat
	observation.merge({"attack_instance": combat_state.get("attack_instance", 0),
		"attack_clip": str(animation_player.current_animation) if animation_player else "",
		"attack_clip_position": animation_player.current_animation_position if animation_player else 0.0,
		"attack_clip_playing": animation_player.is_playing() if animation_player else false,
		"aerial_active": combat_state.get("aerial_active", false),
		"aerial_used": combat_state.get("aerial_used", false),
		"damage_window": combat_state.get("damage_window", false),
		"switch_timer": switch_timer, "grounded": is_on_floor(),
		"combat_locked": combat.player_locked() if combat else false,
		"traversal_action": traversal.action if traversal else "", "posture": traversal.posture if traversal else "standing",
		"recapture_guard": recapture_guard,
		"attack_phase": combat_state.get("phase", ""), "attack_phase_time": combat_state.get("phase_time", 0.0),
		"attack_timer": attack_timer, "attack_buffered": combat_state.get("buffered", false),
		"blocking": combat_state.get("blocking", false),
		"attack_button_held": Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT),
		"aim_button_held": Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT),
		"attack_button_blocked": blocked_mouse.has(MOUSE_BUTTON_LEFT),
		"aim_button_blocked": blocked_mouse.has(MOUSE_BUTTON_RIGHT)})
	return observation


func _mouse_sensitivity() -> float:
	var owner_node := get_parent()
	if owner_node != null:
		for property in owner_node.get_property_list():
			if property.name == "dialogue_state":
				var state: Node = owner_node.get("dialogue_state")
				if is_instance_valid(state): return state.mouse_sensitivity
	return 1.0

func start_camera_shake() -> void:
	shake_remaining = 0.18

func _update_camera_shake(delta: float) -> void:
	shake_remaining = maxf(0, shake_remaining - delta)
	var state: Node = archery.state if archery else (combat.state if combat and "state" in combat else null)
	var strength: float = state.camera_shake if state and not state.reduced_motion else 0.0
	var wave := sin(shake_remaining * 180.0) * shake_remaining * strength
	camera.h_offset = wave * 0.12
	camera.v_offset = cos(shake_remaining * 150.0) * shake_remaining * strength * 0.07
