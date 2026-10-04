extends Node3D

const SOURCE_SCENE := preload("res://Demo/Slavica Free 2026 Version.scn")
const PLAYER_SCENE := preload("res://Player.tscn")
const ARCHERY_HUD := preload("res://archery_hud.gd")
const ENVIRONMENT_QUALITY := preload("res://environment_quality.gd")
const SPAWN_XZ := Vector2(20.0, 20.0)

var village: Node3D
var player: CharacterBody3D
var dusk := false
var quality: Node
var weapon_label: Label
var ui_font := SystemFont.new()


func _ready() -> void:
	village = SOURCE_SCENE.instantiate()
	add_child(village)
	var source_camera := village.get_node_or_null("Camera/Camera") as Camera3D
	if source_camera:
		source_camera.current = false
	player = PLAYER_SCENE.instantiate()
	player.configure_equipment(false, false)
	add_child(player)
	player.get_node("CameraArm/Camera").current = true
	_place_player.call_deferred()
	quality = Node.new()
	quality.set_script(ENVIRONMENT_QUALITY)
	add_child(quality)
	quality.configure(village)
	_add_snowfall()
	_add_help()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _place_player() -> void:
	await get_tree().physics_frame
	var xz := SPAWN_XZ
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(xz.x, 100.0, xz.y), Vector3(xz.x, -100.0, xz.y)
	)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		player.global_position = hit.position + Vector3(0, 0.08, 0)
	else:
		player.global_position = Vector3(xz.x, 0, xz.y)
	player.set_meta("spawn_position", player.global_position)
	var snow := player.get_node_or_null("LocalSnowfall") as CPUParticles3D
	if snow:
		snow.emitting = true
		snow.restart()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_4: _set_dusk(not dusk)
			KEY_R: player.respawn()
			KEY_G: quality.toggle_quality()
			KEY_ESCAPE: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(_delta: float) -> void:
	if weapon_label and player:
		var view_name := "FIRST PERSON" if player.first_person else ("LEFT SHOULDER" if player.shoulder_side < 0 else "RIGHT SHOULDER")
		var movement: String = player.traversal.action if player.traversal.action != "" else ("sprint" if player.traversal.sprinting else player.traversal.posture)
		var notice: String = player.traversal.feedback if player.traversal.feedback_time > 0 else movement.to_upper()
		weapon_label.text = "%s · %s · %s\n%s · GRAPHICS: %s" % [player.weapon_mode.to_upper(), player.SKIN_NAMES[player.skin_index].to_upper(), view_name, notice, "ENHANCED" if quality.enhanced else "BALANCED"]


func _set_dusk(enabled: bool) -> void:
	dusk = enabled
	quality.set_dusk(dusk)


func _add_help() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui_font.font_names = PackedStringArray(["Inter", "Ubuntu", "Noto Sans"])
	ui_font.font_weight = 500
	var layout := VBoxContainer.new()
	layout.position = Vector2(18, 16)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_theme_constant_override("separation", 7)
	layer.add_child(layout)
	var help := Label.new()
	help.text = "WASD move · Mouse look · Space jump · Shift run · Tab shoulder\nUnarmed · Weapons require ownership · V first/third person\nC crouch · Z prone · F roll · Alt dodge · Shift sprint\n3 skin · 4 dusk/day · G graphics · R respawn · Esc cursor"
	_add_hud_card(layout, help, 15)
	weapon_label = Label.new()
	_add_hud_card(layout, weapon_label, 13)
	var archery_hud := Control.new()
	archery_hud.set_script(ARCHERY_HUD)
	archery_hud.player = player
	layer.add_child(archery_hud)


func _add_hud_card(parent: Control, label: Label, font_size: int) -> void:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.045, 0.065, 0.72)
	style.set_corner_radius_all(7)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", ui_font)
	label.add_theme_color_override("font_color", Color(0.91, 0.95, 0.98))
	label.add_theme_font_size_override("font_size", font_size)
	panel.add_child(label)


func _add_snowfall() -> void:
	var snow := CPUParticles3D.new()
	snow.name = "LocalSnowfall"
	snow.position.y = 5.7
	snow.emitting = false
	snow.amount = 260
	snow.lifetime = 6.0
	snow.preprocess = 6.0
	snow.local_coords = false
	snow.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	snow.emission_box_extents = Vector3(9.0, 1.3, 9.0)
	snow.direction = Vector3(0.08, -1.0, 0.03)
	snow.spread = 12.0
	snow.initial_velocity_min = 0.65
	snow.initial_velocity_max = 1.55
	snow.gravity = Vector3(0.07, -0.18, 0.0)
	snow.scale_amount_min = 0.55
	snow.scale_amount_max = 1.25
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.albedo_color = Color(0.76, 0.85, 0.96, 0.78)
	var quad := QuadMesh.new()
	quad.size = Vector2(0.055, 0.055)
	quad.material = material
	snow.mesh = quad
	player.add_child(snow)
