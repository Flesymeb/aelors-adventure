extends Node3D
## Product authority: first projectile contact, inventory and confirmed lesson.
const CAPACITY := 12
const GROUND := preload("res://forest_ground.gd")
const RONEN_XZ := GROUND.RONEN
const TARGET_XZ := GROUND.BOW_TARGET
const CRATE_XZ := GROUND.COVER
var world: Node3D
var player: CharacterBody3D
var state: Node
var ronen: StaticBody3D
var target: StaticBody3D
var target_label: Label3D
var obstruction: Node3D
var grounded := false
var pending_demo := false
var next_shot_id := 0
var active_shots: Dictionary = {}
var contact_history: Array[Dictionary] = []
var last_result: Dictionary = {}

func configure(owner_world: Node3D) -> void:
	world = owner_world
	player = world.player
	state = world.dialogue_state
	process_mode = Node.PROCESS_MODE_PAUSABLE
	player.archery = self
	ronen = preload("res://Ronen.tscn").instantiate()
	add_child(ronen)
	target = StaticBody3D.new()
	target.name = "BowPracticeTarget"
	target.collision_layer = 2
	add_child(target)
	var bale = preload("res://Prefabs/Prop/Container/EA03_Prop_Container_Bale_01a_PRE.prefab.scn").instantiate()
	target.add_child(bale)
	bale.scale *= 3
	for body in bale.find_children("*", "CollisionObject3D", true, false):
		body.collision_layer = 0
		body.collision_mask = 0
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.2, 1.15, 1.8)
	collision.shape = box
	collision.position.y = 0.6
	target.add_child(collision)
	var label := Label3D.new()
	target_label = label
	label.text = "蓄力草靶"
	label.font = preload("res://dialogue_theme.tres").default_font
	label.position.y = 1.6
	label.font_size = 36
	label.pixel_size = 0.003
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	target.add_child(label)
	obstruction = preload("res://Prefabs/Prop/Container/EA03_Prop_Container_Crate_01a_PRE.prefab.scn").instantiate()
	obstruction.name = "WoodenObstruction"
	add_child(obstruction)
	obstruction.scale *= 2.4
	ground_module.call_deferred()

func _process(_delta: float) -> void:
	update_target_label()

func update_target_label() -> void:
	if not is_instance_valid(target_label) or not is_instance_valid(player): return
	target_label.visible = false
	if not grounded or not world.pause_owners.is_empty() or player.controls_open: return
	var camera: Camera3D = player.camera
	var point := target_label.global_position
	if camera.is_position_behind(point) or camera.global_position.distance_to(point) < 1.0 or player.global_position.distance_to(target.global_position) > 28.0: return
	var viewport := get_viewport().get_visible_rect().size
	var anchor := camera.unproject_position(point)
	# Preserve native depth testing. Unlike a projected HUD fallback, this label
	# cannot float through scene geometry. Scale is bounded in screen pixels,
	# rather than making a near-camera billboard fill the aiming presentation.
	var pixels_per_unit := anchor.distance_to(camera.unproject_position(point + camera.global_basis.y))
	if pixels_per_unit < 0.01: return
	var text_scale: float = state.text_scale
	# Size the visible glyph em, not the font's taller line spacing; sizing the
	# latter made the Chinese teaching text too small even at the minimum.
	var glyph_height := float(target_label.font_size)
	var native_height := glyph_height * target_label.pixel_size * pixels_per_unit
	var height := clampf(native_height, 18.0 * text_scale, 24.0 * text_scale)
	target_label.scale = Vector3.ONE * height / native_height
	var width := target_label.font.get_string_size(target_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, target_label.font_size).x / glyph_height * height
	var line_height := height * target_label.font.get_height(target_label.font_size) / glyph_height
	var label_rect := Rect2(anchor - Vector2(width, line_height) * 0.5, Vector2(width, line_height)).grow(6.0)
	# A conservative projected body envelope includes the extended bow/arms on
	# either shoulder. Reject the label instead of relocating it onto a false
	# target or letting it collide with the reticle and charge arc.
	var body_rect := Rect2()
	var first := true
	var radius := lerpf(0.65, 1.05, player.aim_blend)
	for y in [0.0, 2.0]:
		for side in [-1.0, 1.0]:
			var body_point: Vector3 = player.global_position + Vector3.UP * y + camera.global_basis.x * radius * side
			if camera.is_position_behind(body_point): return
			var pixel := camera.unproject_position(body_point)
			if first:
				body_rect = Rect2(pixel, Vector2.ZERO)
				first = false
			else: body_rect = body_rect.expand(pixel)
	var aim_rect := Rect2(viewport * 0.5 - Vector2(28, 40), Vector2(95, 80)) if player.aim_blend > 0.01 else Rect2()
	if not marker_fits(label_rect, body_rect.grow(10), aim_rect, viewport): return
	# Test the actual target, not just the elevated text anchor. A wall hiding
	# the bale must not leave a misleading label visible above that wall.
	var ray := PhysicsRayQueryParameters3D.create(camera.global_position, target.global_position + Vector3.UP * 0.65, 3, [player.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty() or hit.collider != target: return
	target_label.visible = true

static func marker_fits(label_rect: Rect2, body_rect: Rect2, aim_rect: Rect2, viewport: Vector2) -> bool:
	return Rect2(Vector2(12, 12), viewport - Vector2(24, 24)).encloses(label_rect) and not label_rect.intersects(body_rect) and (aim_rect.size == Vector2.ZERO or not label_rect.intersects(aim_rect))

func ground_module() -> void:
	if world.meadow_slice:
		grounded = true
		return
	for attempt in 120:
		await get_tree().physics_frame
		grounded = world.training.place_on_ground(ronen, RONEN_XZ) and world.training.place_on_ground(target, TARGET_XZ) and world.training.place_on_ground(obstruction, CRATE_XZ)
		if grounded: break
	ronen.grounded = grounded
	if not grounded: push_error("Bow lesson requires safe authored village ground")

func prerequisite_complete() -> bool:
	return state.sword_owned and state.practice_hit and state.practice_defense and state.remnant_collected

func interaction_prompt() -> String:
	if world.meadow_slice or not grounded or world.training.player_locked() or not ronen.can_interact(player): return ""
	return "[E] 与罗恩交谈" if not state.bow_owned else "[E] 免费补箭 / 查看弓练习"

func interact() -> bool:
	if interaction_prompt() == "": return false
	if not prerequisite_complete():
		world.training.tell("罗恩：先完成赫斯的剑与防御练习，领取初战残响。", 4)
	elif not state.bow_owned:
		world.open_ronen_dialogue()
	elif world.training.can_save() and active_shots.is_empty():
		player.reset_archery()
		state.arrows = CAPACITY
		world.training.commit()
		world.training.tell("箭已免费补满 · 右键瞄准，左键拉弦后松开；松右键取消", 5)
		if not state.bow_demonstrated: pending_demo = true
	else:
		world.training.tell("先离开战斗并等待箭落定，再补箭。")
	return true

func grant_bow() -> void:
	if state.bow_owned or not prerequisite_complete(): return
	state.bow_owned = true
	state.arrows = CAPACITY
	state.ronen_node = "R02"
	player.configure_equipment(state.sword_owned, true, "bow")
	state.selected_equipment = "bow"
	state.sword_selected = false
	pending_demo = true
	world.training.commit()
	world.training.tell("已取得巡路弓 · 罗恩将示范；可直接尝试蓄力草靶", 5)

func _physics_process(_delta: float) -> void:
	if not grounded or world.training.player_locked(): return
	if pending_demo and world.pause_owners.is_empty():
		pending_demo = false
		ronen.demonstrate()
	if ronen.demonstration and ronen.demonstration_time >= 2.4 and not state.bow_demonstrated:
		state.bow_demonstrated = true
		world.training.commit()
		world.training.tell("罗恩：现在由你试。靶在我前方，木箱会挡住箭；可随时回来补箭。", 5)

func can_draw() -> bool:
	if player.abilities and player.abilities.busy(): return false
	if not state.bow_owned or world.training.player_locked(): return false
	if state.arrows <= 0:
		world.training.tell("箭已用尽 · 回罗恩处按 E 免费补满")
		return false
	return true

func can_save() -> bool:
	return active_shots.is_empty() and player.bow_state not in ["draw", "hold"]

func register_shot(arrow: Node3D, charge: float, origin: Vector3) -> bool:
	if not can_draw(): return false
	state.arrows -= 1
	next_shot_id += 1
	var id := next_shot_id
	active_shots[id] = {"arrow": arrow, "charge": charge, "origin": origin, "ammunition_after": state.arrows, "source": make_arrow_source(arrow, charge)}
	arrow.first_contact.connect(_contact.bind(id))
	arrow.missed.connect(_miss.bind(id))
	world.training.feedback.sound(preload("res://assets/dialogue/sounds/Audio/pluck_002.ogg"), -18, 0.8)
	return true

func make_arrow_source(arrow: Node3D, charge: float) -> SnaielDamageSource:
	var source = SnaielDamageSource.new()
	source.entity = player
	source.damage_attributes.health = lerpf(8.0, 24.0, charge)
	source.instance = next_shot_id
	source.can_damage = true
	arrow.add_child(source)
	return source

func _contact(hit: Dictionary, id: int) -> void:
	if not active_shots.has(id): return
	var shot: Dictionary = active_shots[id]
	active_shots.erase(id)
	var body: Object = hit.collider
	var result := "obstruction"
	var loss := 0.0
	if body == target:
		result = "target"
		if shot.charge >= 0.12:
			state.bow_training_complete = true
		world.training.feedback.impact(hit.position, "蓄力靶命中", 0, "straw")
		world.training.tell("蓄力靶命中 · 可重复练习；返回伊莎处领取旧灯", 4)
	elif body != null and body.has_method("receive_contact"):
		var resolved: Dictionary = body.receive_contact(shot.source, hit.position)
		loss = resolved.get("hp_loss", 0.0)
		result = "enemy" if loss > 0 else "blocked"
		if loss <= 0: world.training.feedback.impact(hit.position, "未造成伤害", 0, "obstruction")
	else:
		world.training.feedback.impact(hit.position, "箭被挡住", 0, "obstruction")
		world.training.tell("箭被近处物体挡住 · 换一个清晰射击位置")
	_record(id, shot, result, str(body.get_path()) if body is Node else "", loss)
	if world.training.can_save(): world.training.commit()

func _miss(id: int) -> void:
	if not active_shots.has(id): return
	var shot: Dictionary = active_shots[id]
	active_shots.erase(id)
	_record(id, shot, "miss", "", 0)
	world.training.tell("箭未命中草靶 · 调整瞄准后重试")
	world.training.feedback.sound(preload("res://assets/dialogue/sounds/Audio/select_007.ogg"), -24, 0.85)
	if world.training.can_save(): world.training.commit()

func _record(id: int, shot: Dictionary, result: String, collider: String, loss: float) -> void:
	last_result = {"shot_id": id, "charge": shot.charge, "origin": shot.origin, "result": result, "collider": collider, "hp_loss": loss, "ammunition_after": shot.ammunition_after}
	contact_history.append(last_result.duplicate())
	if contact_history.size() > 12: contact_history.pop_front()

func clear_transients() -> void:
	for shot in active_shots.values():
		if is_instance_valid(shot.arrow): shot.arrow.queue_free()
	active_shots.clear()
	for arrow in world.get_children():
		if arrow.get_script() == preload("res://arrow_projectile.gd"): arrow.queue_free()
	player.reset_archery()
	pending_demo = state.bow_owned and not state.bow_demonstrated
	ronen.idle()
	last_result.clear()
	contact_history.clear()

func _mcp_state() -> Dictionary:
	return {"grounded": grounded, "owned": state.bow_owned, "arrows": state.arrows, "selected": state.selected_equipment, "training_complete": state.bow_training_complete, "demonstrated": state.bow_demonstrated, "active_shots": active_shots.size(), "last_contact": last_result, "contact_history": contact_history, "ronen_position": ronen.global_position, "target_position": target.global_position, "obstruction_position": obstruction.global_position}
