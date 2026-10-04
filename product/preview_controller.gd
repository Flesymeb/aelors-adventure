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
var help_label: Label
var controls_panel: PanelContainer
var controls_list: VBoxContainer
var controls_feedback: Label
var control_buttons: Array[Button] = []
var controls_selection := 0
var capturing_control := ""
var previous_mouse_mode := Input.MOUSE_MODE_CAPTURED
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
	_add_controls()
	player.controls_changed.connect(_refresh_control_prompts)
	_refresh_control_prompts()
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
	if player.controls_open:
		return
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
	help_label = Label.new()
	_add_hud_card(layout, help_label, 15)
	weapon_label = Label.new()
	_add_hud_card(layout, weapon_label, 13)
	var archery_hud := Control.new()
	archery_hud.set_script(ARCHERY_HUD)
	archery_hud.player = player
	layer.add_child(archery_hud)


func _refresh_control_prompts() -> void:
	help_label.text = "%s/%s/%s/%s move · Mouse look · %s jump · %s sprint · %s shoulder\nUnarmed · Weapons require ownership · E interact / F old lamp (reserved)\n%s crouch · %s prone · %s roll · %s dodge · %s perspective\nF10 controls · 3 skin · 4 dusk/day · G graphics · R respawn · Esc cursor" % [
		player.key_prompt("forward"), player.key_prompt("left"), player.key_prompt("back"), player.key_prompt("right"),
		player.key_prompt("jump"), player.key_prompt("sprint"), player.key_prompt("shoulder"),
		player.key_prompt("crouch"), player.key_prompt("prone"), player.key_prompt("roll"), player.key_prompt("dodge"), player.key_prompt("perspective")]
	for i in control_buttons.size():
		var action: String = player.CONTROL_DEFAULTS.keys()[i]
		control_buttons[i].text = "%s    [%s]" % [player.CONTROL_LABELS[action], player.key_prompt(action)]


func _add_controls() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)
	controls_panel = PanelContainer.new()
	controls_panel.name = "LocomotionControls"
	controls_panel.custom_minimum_size = Vector2(530, 0)
	center.add_child(controls_panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.045, 0.065, 0.97)
	style.border_color = Color(0.65, 0.55, 0.32)
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	controls_panel.add_theme_stylebox_override("panel", style)
	controls_list = VBoxContainer.new()
	controls_list.add_theme_constant_override("separation", 3)
	controls_list.add_theme_font_override("font", ui_font)
	controls_list.add_theme_font_size_override("font_size", 17)
	controls_panel.add_child(controls_list)
	var title := Label.new()
	title.text = "LOCOMOTION CONTROLS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_list.add_child(title)
	for action in player.CONTROL_DEFAULTS:
		var button := Button.new()
		button.pressed.connect(_begin_capture.bind(String(action)))
		button.focus_entered.connect(_select_control.bind(control_buttons.size()))
		controls_list.add_child(button)
		control_buttons.append(button)
	controls_feedback = Label.new()
	controls_feedback.custom_minimum_size.x = 490
	controls_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls_list.add_child(controls_feedback)
	var restore := Button.new()
	restore.text = "Restore defaults [Backspace]"
	restore.pressed.connect(_restore_controls)
	controls_list.add_child(restore)
	var close := Button.new()
	close.text = "Return to exploration [Esc / F10]"
	close.pressed.connect(_close_controls)
	controls_list.add_child(close)
	controls_panel.hide()


func _select_control(index: int) -> void:
	controls_selection = index


func _begin_capture(action: String) -> void:
	# A GUI button held while the panel closes can emit its callback later.
	# It must not arm the next visit's capture or consume exploration input.
	if not player.controls_open:
		return
	capturing_control = action
	controls_feedback.text = "Press an unused key for %s. Esc cancels.\nE / F and menu keys stay reserved." % player.CONTROL_LABELS[action]


func _restore_controls() -> void:
	capturing_control = ""
	var error: String = player.restore_controls()
	controls_feedback.text = "Default controls restored." if error == "" else error
	control_buttons[controls_selection].grab_focus()


func _close_controls() -> void:
	player.set_controls_open(false)
	controls_panel.hide()
	capturing_control = ""
	Input.mouse_mode = previous_mouse_mode


# Called at the start of the player's _input, before mouse attacks and before
# either script's _unhandled_input. Captured keys cannot leak into the world.
func handle_controls_input(event: InputEvent) -> bool:
	if not player.controls_open:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
			capturing_control = ""
			previous_mouse_mode = Input.mouse_mode
			player.set_controls_open(true)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			controls_panel.show()
			controls_feedback.text = "Up / Down select · Enter changes key · Backspace restores\nEsc / F10 returns. Release held controls before acting."
			control_buttons[controls_selection].grab_focus()
			return true
		return false
	if event is InputEventKey:
		if not event.pressed or event.echo:
			return true
		if capturing_control != "":
			if event.keycode == KEY_ESCAPE:
				capturing_control = ""
				controls_feedback.text = "Key change cancelled. Enter to try again."
			else:
				var error: String = player.rebind_control(capturing_control, event.keycode)
				if error == "":
					controls_feedback.text = "%s now uses %s. Esc returns to exploration." % [player.CONTROL_LABELS[capturing_control], player.key_prompt(capturing_control)]
					capturing_control = ""
				else:
					controls_feedback.text = error + " Esc cancels."
		elif event.keycode in [KEY_ESCAPE, KEY_F10]:
			_close_controls()
		elif event.keycode == KEY_BACKSPACE:
			_restore_controls()
		elif event.keycode in [KEY_UP, KEY_DOWN]:
			controls_selection = posmod(controls_selection + (1 if event.keycode == KEY_DOWN else -1), control_buttons.size())
			control_buttons[controls_selection].grab_focus()
		elif event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
			_begin_capture(player.CONTROL_DEFAULTS.keys()[controls_selection])
		return true
	# Mouse clicks may reach controls buttons; the player suppresses all world
	# mouse input while the panel is open. Mouse motion never drives its camera.
	return not event is InputEventMouseButton


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
