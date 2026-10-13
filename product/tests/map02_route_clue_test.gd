extends RefCounted
## Explicit detached state/config checks; no test facts enter ordinary startup.
const PRESSURE = preload("res://tests/map02_pressure_test.gd")
const HISTORY = preload("res://tests/chapter_travel_test.gd")
const STATE = preload("res://dialogue_state.gd")
const MAP_PAGE = preload("res://ui/map_page.gd")
const JOURNAL = preload("res://ui/quest_journal.gd")

static func run() -> Dictionary:
	var checks := {}
	var state: Node = PRESSURE.prepared()
	var before: ConfigFile = HISTORY.history(state)
	var isolated_before := ConfigFile.new()
	isolated_before.parse(before.encode_to_text())
	before = isolated_before
	checks.legacy_default = not state.mf01_acquired and not state.mf01_information().contains("绕到岩石右侧")
	checks.before_e02_rejected = not state.acquire_mf01()
	checks.unearned_navigation_hidden = MAP_PAGE.mf01_navigation(state) == state.mf01_information() and MAP_PAGE.known_route_marks(state).size() == 2 and JOURNAL.project_entries(state) == state.quest_entries()
	for id in state.PRESSURE_IDS: state.settle_pressure(Vector3(6, 1, 66), {}, id)
	var xp: int = state.experience
	var lives: int = state.lives
	var rewards: Dictionary = state.reward_history.duplicate(true)
	checks.acquired = state.acquire_mf01() and state.mf01_acquired
	checks.once_without_reward = not state.acquire_mf01() and xp == state.experience and lives == state.lives and rewards == state.reward_history
	checks.map_information = state.mf01_information().contains("岩石右侧") and state.mf01_information().contains("返程")
	checks.journal_projection = state.quest_entries().any(func(row): return row.id == "route_record" and row.context == state.mf01_information())
	var facts: Dictionary = state.training_snapshot().duplicate(true)
	var information: String = MAP_PAGE.mf01_navigation(state)
	var projected: Array[Dictionary] = JOURNAL.project_entries(state)
	checks.learned_navigation = information.contains("树根左侧") and information.contains("3 装备旧灯") and information.contains("F 显形") and information.contains("E 提示") and information.contains("返回灯台")
	checks.shared_page_projection = projected.any(func(row): return row.id == "route_record" and row.context == information and row.action.contains("树根左侧"))
	checks.no_future_landmarks = MAP_PAGE.known_route_marks(state).size() == 5 and not information.contains("结界记号") and not information.contains("map02_e03")
	checks.read_only_navigation = facts == state.training_snapshot() and not state.e03_revealed and not state.mf02_acquired and rewards == state.reward_history
	var committed: ConfigFile = HISTORY.history(state)
	checks.valid_config = state.config_unavailable_reason(committed) == ""
	# ConfigFile serialization exercises the persisted shape without filesystem IO.
	var serialized := ConfigFile.new()
	checks.serialized = serialized.parse(committed.encode_to_text()) == OK
	var restored: Node = STATE.new()
	restored.restore_config(serialized)
	checks.continue_information = restored.mf01_acquired and restored.mf01_information() == state.mf01_information() and not restored.acquire_mf01()
	checks.restored_page_projection = MAP_PAGE.mf01_navigation(restored) == information and JOURNAL.project_entries(restored).any(func(row): return row.id == "route_record" and row.context == information)
	restored.health = 0
	restored.recovery_pending = true
	checks.death_preserves_information = restored.mf01_acquired and restored.mf01_information() == state.mf01_information()
	restored.current_map = restored.GROUND.MAP_ID
	checks.return_preserves_information = restored.mf01_information() == state.mf01_information()
	var legacy: Node = STATE.new()
	legacy.restore_config(before)
	checks.legacy_restore = not legacy.mf01_acquired
	var invalid: ConfigFile = HISTORY.history(state)
	invalid.set_value("post_bow", "mf01_acquired", "true")
	checks.reject_wrong_type = state.config_unavailable_reason(invalid) != ""
	before.set_value("post_bow", "mf01_acquired", true)
	checks.reject_unearned_record = state.config_unavailable_reason(before) != ""
	checks.native_resources = load("res://ui/map_page.gd").can_instantiate() and load("res://world/map02_route_clue.gd").can_instantiate()
	# Load the actual inherited prop, checking that visual adaptation did not
	# replace its collision or discard the authored colorsheet dependency.
	var source_sign: Node3D = load("res://Prefabs/Prop/Sign/EA03_Prop_Sign_Chapel_01_PRE.prefab.scn").instantiate()
	var route_sign: Node3D = load("res://world/Map02RouteLandmark.tscn").instantiate()
	var source_mesh: MeshInstance3D = source_sign.get_node("EA03_Prop_Sign_Chapel_01_PRE")
	var route_mesh: MeshInstance3D = route_sign.get_node("EA03_Prop_Sign_Chapel_01_PRE")
	var material: Material = route_mesh.get_active_material(0)
	checks.route_native_geometry = source_mesh.mesh == route_mesh.mesh and source_sign.get_node("MeshCollider/CollisionShape3D").shape == route_sign.get_node("MeshCollider/CollisionShape3D").shape
	var route_height: float = route_mesh.get_aabb().size.y * route_sign.scale.y
	checks.route_standing_scale = route_height >= 1.8 and route_height <= 2.2
	checks.route_material = material is StandardMaterial3D and material.albedo_texture == load("res://Textures/EA03_FREE_Slavica.png") and material.albedo_color.get_luminance() < 0.6 and is_equal_approx(material.roughness, 1.0)
	source_sign.free()
	route_sign.free()
	for node in [state, restored, legacy]: node.free()
	return checks
