extends Node3D
const GROUND = preload("res://forest_ground.gd")
const TRACE_XZ = Vector2(118.6, 96.0)
var world: Node3D
var state: Node
var signpost: Node3D
var glyph: Sprite3D
var reveal_switch: ShortSwitch
var visual: Node3D
var grounded = false
var cooldown = 0.0
var reveal_remaining = 0.0

func configure(owner_world: Node3D) -> void:
	world = owner_world
	state = world.dialogue_state
	signpost = preload("res://Prefabs/Prop/Sign/EA03_Prop_Sign_Chapel_01_PRE.prefab.scn").instantiate()
	add_child(signpost)
	glyph = Sprite3D.new()
	glyph.texture = preload("res://assets/ui/journal_icons.svg")
	glyph.pixel_size = 0.004
	glyph.modulate = Color(0.45,0.85,1.0)
	glyph.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	glyph.no_depth_test = false
	glyph.shaded = false
	signpost.add_child(glyph)
	glyph.position = Vector3(0,1.7,0)
	reveal_switch = preload("res://interaction/nodragem/short_interaction_switch.gd").new()
	add_child(reveal_switch)
	reveal_switch.activation_signal.connect(_revealed)
	visual = preload("res://lamp_visual.gd").new()
	add_child(visual)
	visual.configure(world.player,state)
	state.lamp_granted.connect(func(): world.player.owns_lamp = true; state.tracked_quest = "lamp")
	ground.call_deferred()

func ground() -> void:
	if world.meadow_slice:
		restore_history()
		return
	for attempt in 120:
		await get_tree().physics_frame
		grounded = GROUND.place(world,signpost,TRACE_XZ)
		if grounded: break
	if not grounded: push_error("Lamp clue lacks authored terrain support")
	restore_history()

func restore_history() -> void:
	cooldown = 0
	reveal_remaining = 0
	world.player.owns_lamp = state.lamp_owned
	reveal_switch.is_activated = state.trace_revealed
	glyph.visible = state.trace_revealed

func reveal() -> bool:
	if not state.lamp_owned or world.player.weapon_mode != "lamp": world.training.tell("先从伊莎处取得旧灯，再按 3 装备"); return true
	if cooldown > 0: world.training.tell("旧灯恢复中 · %.1f 秒" % cooldown); return true
	if not grounded or world.player.global_position.distance_to(signpost.global_position) > 4: world.training.tell("靠近伊莎旁的旧路碑，再按 F 显形"); return true
	if world.player.switch_timer > 0 or world.training.player_locked() or world.player.traversal.action != "" or (world.element_abilities and world.element_abilities.busy()): return true
	var ray = PhysicsRayQueryParameters3D.create(world.player.global_position + Vector3.UP, signpost.global_position + Vector3.UP, 1,[world.player.get_rid()])
	var hit = get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty() and not signpost.is_ancestor_of(hit.collider): world.training.tell("灯光被挡住 · 换一个位置"); return true
	world.player.current_animation = ""
	world.player.attack_timer = 0.6
	world.player._play_animation("Interact", 1.8)
	world.training.feedback.spark(signpost.global_position + Vector3.UP * 1.6,Color(0.4,0.85,1))
	cooldown = 3.0
	reveal_remaining = 0.6
	return true

func _physics_process(delta: float) -> void:
	cooldown = maxf(0,cooldown - delta)
	if reveal_remaining <= 0: return
	if state.health <= 0 or world.training.hurt_time > 0 or world.player.weapon_mode != "lamp":
		reveal_remaining = 0
		return
	reveal_remaining = maxf(0,reveal_remaining - delta)
	if reveal_remaining == 0: reveal_switch.on_interaction(true)

func _revealed(active: bool) -> void:
	glyph.visible = active
	if not active or state.trace_revealed: return
	state.trace_revealed = true
	if not state.lamp_reward_committed:
		state.lamp_reward_committed = true
		state.experience += 10
		world.training.feedback.reward(10)
	world.training.commit()
	world.training.tell("魔法痕迹已显形 · 靠近路碑按 E 调查；等级提升，K 选择元素",5)

func interact() -> bool:
	if not state.lamp_owned or not grounded or world.player.global_position.distance_to(signpost.global_position) > 2.4: return false
	if not state.trace_revealed: world.training.tell("路碑隐藏着痕迹 · 取得旧灯后按 3、F 显形"); return true
	if not state.trace_investigated:
		state.trace_investigated = true
		world.training.commit()
	world.training.tell("线索记录：四位村民被带过石桥 · K 选择元素，再到罗恩草靶旁练习",5)
	return true

func interaction_prompt() -> String:
	if not state.lamp_owned or not grounded or world.player.global_position.distance_to(signpost.global_position) > 3: return ""
	return "[E] 调查显形路碑" if state.trace_revealed else ("[3] 旧灯 · [F] 显形路碑" if state.lamp_owned else "旧路碑 · 伊莎保管着旧灯")

func _mcp_state() -> Dictionary:
	return {"grounded":grounded,"revealed":state.trace_revealed,"investigated":state.trace_investigated,"visible_glyph":glyph.visible,"position":str(signpost.global_position),"lamp":visual._mcp_state()}
