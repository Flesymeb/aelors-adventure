extends Node3D
## A semantic singleton: one retained opaque medieval sign, one transparent
## journal icon, one source/runtime variant, maximum family share 1.0.
## Views: ordinary approach, map, journal. No corpse or reward owns this record.
const GROUND = preload("res://world/map02_ground.gd")
var world: Node3D
var state: Node
var signpost: Node3D
var glyph: Sprite3D
var record_switch: ShortSwitch
var grounded := false
var approach_recalled := false

func configure(owner_world: Node3D) -> void:
	world = owner_world
	state = world.dialogue_state
	signpost = preload("res://Prefabs/Prop/Sign/EA03_Prop_Sign_Chapel_01_PRE.prefab.scn").instantiate()
	signpost.name = "FixedRouteSign"
	add_child(signpost)
	glyph = Sprite3D.new()
	glyph.texture = preload("res://assets/ui/journal_icons.svg")
	glyph.pixel_size = 0.004
	glyph.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	glyph.shaded = false
	glyph.position = Vector3(0, 1.7, 0)
	signpost.add_child(glyph)
	record_switch = preload("res://interaction/nodragem/short_interaction_switch.gd").new()
	add_child(record_switch)
	restore_history()
	record_switch.activation_signal.connect(_activated)
	ground.call_deferred()

func ground() -> void:
	for attempt in 120:
		await get_tree().physics_frame
		if is_queued_for_deletion() or not is_instance_valid(world) or world.is_queued_for_deletion(): return
		grounded = GROUND.place(world, signpost, GROUND.ROUTE_RECORD)
		if grounded: return
	world.entry_failed.emit("固定路线记录缺少安全落脚点。")

func restore_history() -> void:
	# Rehydration projects the saved fact; it does not interact or grant anything.
	record_switch.is_activated = state.mf01_acquired
	glyph.modulate = Color(0.65, 0.73, 0.55) if state.mf01_acquired else Color(1, 0.85, 0.4)

func _physics_process(_delta: float) -> void:
	if approach_recalled or not grounded or not state.roadblock_defeated() or state.pressure_defeated(): return
	if Vector2(world.player.global_position.x, world.player.global_position.z).distance_to(GROUND.PRESSURE_APPROACH) < 3:
		approach_recalled = true
		world.training.tell("想起罗恩的建议：借岩石挡住攻击。你的箭也穿不过石头。", 5)

func reachable() -> bool:
	if not grounded or not world.pause_owners.is_empty() or state.health <= 0 or state.recovery_pending: return false
	if world.player.global_position.distance_to(signpost.global_position) > 2.4: return false
	if world.training.player_locked() or world.element_abilities.busy() or world.player.traversal.action != "": return false
	var query := PhysicsRayQueryParameters3D.create(world.player.global_position + Vector3.UP, signpost.global_position + Vector3.UP, 1, [world.player.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or signpost.is_ancestor_of(hit.collider)

func interact() -> bool:
	if not reachable(): return false
	if not state.pressure_defeated():
		world.training.tell("先清除押送守卫，再安全调查路碑。", 4)
		return true
	if state.mf01_acquired:
		world.training.tell("农田至林缘路线已记录 · M 查看地图，J 查阅 MF01。", 4)
		return true
	record_switch.on_interaction(true)
	return true

func _activated(active: bool) -> void:
	if not active or not state.acquire_mf01(): return
	restore_history()
	world.training.commit()
	world.menu_audio.play_cue("confirm")
	world.training.tell("它们从农田绕进了林缘，这些标记能对上路边的地形。\nMF01 已记录 · M 地图 / J 日志", 7)

func interaction_prompt() -> String:
	if not reachable(): return ""
	return "[E] 查阅固定路线记录 · [M] 地图" if state.mf01_acquired else "[E] 调查农田至林缘路线" if state.pressure_defeated() else "固定路碑 · 先清除押送守卫"

func _mcp_state() -> Dictionary:
	return {"grounded":grounded, "acquired":state.mf01_acquired if is_instance_valid(state) else null, "available":reachable() if grounded else false, "position":str(signpost.global_position) if grounded else null, "prompt":interaction_prompt() if grounded else ""}
