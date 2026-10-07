extends Node
## Only confirmed choices commit rewards. Focus and reveal position are UI state.
const GROUND := preload("res://forest_ground.gd")
const SAVE_PATH := "user://isha_opening.cfg"
const NODES := preload("res://data/isha_dialogue.json")
const RONEN_NODES := preload("res://data/ronen_dialogue.json")
const HERS_NODES := preload("res://data/hers_dialogue.json")
var dialogue_kind := "isha"
signal sword_granted
signal lamp_granted
signal progression_changed
signal bow_granted
signal save_finished(slot: int, error: int)
var logical_node := "D01"
var conversation_active := false
var q01_accepted := false
var q01_reward_committed := false
var experience := 0
var opening_completed := false
var confirmed_choices: Array[String] = []
var text_scale := 1.0
var mouse_sensitivity := 1.0
signal preferences_changed
const PREFERENCE_DEFAULTS := {"text_scale": 1.0, "reveal_speed": 30.0, "instant_text": false, "reduced_motion": false, "muted_sound": false, "mouse_sensitivity": 1.0, "master_volume": 1.0, "music_volume": 0.65, "effects_volume": 1.0, "graphics_quality": "normal", "camera_shake": 0.5, "damage_numbers": true}
var master_volume := 1.0
var music_volume := 0.65
var effects_volume := 1.0
var graphics_quality := "normal"
var camera_shake := 0.5
var damage_numbers := true
var preference_error := ""
var tracked_quest := "rescue"
var tracker_collapsed := false
var reveal_speed := 30.0
var instant_text := false
var save_feedback := ""
var reward_feedback := ""
# Versioned, independent facts. Q02 remains incomplete in this sword increment.
const POST_DEFAULTS := {"lamp_owned": false, "trace_revealed": false, "trace_investigated": false, "lamp_reward_committed": false, "element_practice_complete": false, "skills": {}, "reward_history": {}, "bag_history": {}, "quick_item": "healing"}
var lamp_owned := false
var trace_revealed := false
var trace_investigated := false
var lamp_reward_committed := false
var element_practice_complete := false
var skills: Dictionary = {}
var reward_history: Dictionary = {}
var bag_history: Dictionary = {}
var quick_item := "healing"
var inventory: Node
var bow_owned := false
var arrows := 0
var bow_training_complete := false
var bow_demonstrated := false
var selected_equipment := "unarmed"
var ronen_node := "R01"
var sword_owned := false
var practice_hit := false
var practice_defense := false
var practice_parry := false
var encounter_defeated := false
var remnant_collected := false
var remnant_position := Vector3.ZERO
var health := 100.0
var lives := 3
var recovery_pending := false
var hers_node := "H01"
var reduced_motion := false
var muted_sound := false:
	set(value):
		muted_sound = value
		apply_global_audio()
var sword_selected := false
var persistence_error := ""
const TRAINING_KEYS := ["bow_owned", "arrows", "bow_training_complete", "bow_demonstrated", "selected_equipment", "ronen_node", "sword_owned", "practice_hit", "practice_defense", "practice_parry", "encounter_defeated", "remnant_collected", "remnant_position", "health", "lives", "recovery_pending", "hers_node", "reduced_motion", "muted_sound", "sword_selected", "dialogue_kind"]

func _ready() -> void:
	# Title previews never restore history. Entry owns loading.
	load_preferences()
	apply_global_audio()
	inventory = preload("res://inventory/product_inventory.gd").new()
	inventory.state = self
	add_child(inventory)
	inventory.restore()

func apply_global_audio() -> void:
	for bus in ["Music", "Effects"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, "Master")
	for bus in ["Master", "Music", "Effects"]:
		var volume: float = master_volume if bus == "Master" else (music_volume if bus == "Music" else effects_volume)
		var index := AudioServer.get_bus_index(bus)
		var gain: AudioEffectAmplify
		for effect_index in AudioServer.get_bus_effect_count(index):
			var effect := AudioServer.get_bus_effect(index, effect_index)
			if effect is AudioEffectAmplify and effect.resource_name == "AdventureOutputGain": gain = effect
		if gain == null:
			gain = AudioEffectAmplify.new()
			gain.resource_name = "AdventureOutputGain"
			AudioServer.add_bus_effect(index, gain, 0)
		# Keep capture and audible output behind the same gain, without doubling it.
		gain.volume_db = -80.0 if bus == "Master" and muted_sound else linear_to_db(maxf(volume, 0.0001))
		AudioServer.set_bus_volume_db(index, 0)
		AudioServer.set_bus_mute(index, (bus == "Master" and muted_sound) or volume <= 0)

func apply_preferences() -> void:
	apply_global_audio()
	preferences_changed.emit()

func reset_preferences() -> void:
	for key in PREFERENCE_DEFAULTS: set(key, PREFERENCE_DEFAULTS[key])
	apply_preferences()

func preference_snapshot() -> Dictionary:
	var result := {}
	for key in PREFERENCE_DEFAULTS: result[key] = get(key)
	result["persistence_error"] = preference_error
	return result

func begin() -> void:
	if not conversation_active:
		logical_node = ronen_node if dialogue_kind == "ronen" else (hers_node if dialogue_kind == "hers" else ("D02" if q01_accepted else "D01"))
		if dialogue_kind == "isha" and bow_training_complete and remnant_collected:
			logical_node = "L02" if lamp_owned else "L01"
	reward_feedback = ""
	conversation_active = true

func choose(index: int) -> bool:
	var node: Dictionary = current_nodes().get(logical_node, {})
	var choices: Array = node.get("choices", [])
	if index < 0 or index >= choices.size():
		return false
	var choice: Dictionary = choices[index]
	if choice.get("grant_sword", false) and dialogue_kind == "hers" and q01_accepted:
		sword_granted.emit()
	if choice.get("grant_bow", false) and dialogue_kind == "ronen":
		bow_granted.emit()
	if choice.get("grant_lamp", false) and dialogue_kind == "isha" and bow_training_complete and remnant_collected and not lamp_owned:
		lamp_owned = true
		inventory.ensure_equipment()
		lamp_granted.emit()
		reward_feedback = "取得奥伦的旧灯 · 3 装备 · F 显形"
	if choice.get("accept", false):
		q01_accepted = true
		if not q01_reward_committed:
			experience += 10
			q01_reward_committed = true
			confirmed_choices.append("Q01_accept")
			reward_feedback = "救援请求已接受 · 获得 10 点经验"
	logical_node = choice.next
	if dialogue_kind == "ronen": ronen_node = "R02" if bow_owned else "R01"
	if dialogue_kind == "hers": hers_node = "H02" if sword_owned else "H01"
	return true

func save_progress(position: Vector3, yaw: float, slot := 0) -> Error:
	var config := ConfigFile.new()
	config.set_value("cinematic", "version", 1)
	config.set_value("cinematic", "completed", opening_completed)
	config.set_value("journal", "tracked", tracked_quest)
	config.set_value("journal", "collapsed", tracker_collapsed)
	config.set_value("opening", "node", logical_node)
	config.set_value("opening", "conversation", conversation_active)
	config.set_value("opening", "accepted", q01_accepted)
	config.set_value("opening", "reward", q01_reward_committed)
	config.set_value("opening", "choices", confirmed_choices)
	config.set_value("opening", "experience", experience)
	config.set_value("opening", "position", position)
	config.set_value("opening", "yaw", yaw)
	config.set_value("training", "version", 3)
	config.set_value("opening", "map_id", GROUND.MAP_ID)
	for key in TRAINING_KEYS:
		config.set_value("training", key, get(key))
	bag_history = inventory.snapshot() if inventory else bag_history
	for key in POST_DEFAULTS: config.set_value("post_bow", key, get(key))
	config.set_value("reading", "scale", text_scale)
	config.set_value("reading", "speed", reveal_speed)
	config.set_value("reading", "instant", instant_text)
	var path := SAVE_PATH if slot == 0 else "user://isha_slot_%d.cfg" % slot
	var error := config.save(path + ".tmp")
	if error == OK:
		error = DirAccess.rename_absolute(path + ".tmp", path)
	save_feedback = "进度已保存" if error == OK else "保存失败，请重试"
	persistence_error = "" if error == OK else save_feedback
	save_finished.emit(slot, error)
	return error

func load_progress(slot := 0) -> Dictionary:
	var config := ConfigFile.new()
	var path := SAVE_PATH if slot == 0 else "user://isha_slot_%d.cfg" % slot
	if config.load(path) != OK:
		return {}
	var invalid := slot_unavailable_reason(slot, true)
	if invalid != "":
		persistence_error = invalid
		return {}
	return restore_config(config)


func restore_config(config: ConfigFile) -> Dictionary:
	# Existing adventure histories predate the presentation marker. They have
	# already crossed the village boundary and must never replay/reset progress.
	opening_completed = bool(config.get_value("cinematic", "completed", true))
	tracked_quest = str(config.get_value("journal", "tracked", "rescue"))
	tracker_collapsed = bool(config.get_value("journal", "collapsed", false))
	save_feedback = ""
	logical_node = str(config.get_value("opening", "node", "D01"))
	if not NODES.data.has(logical_node) and not HERS_NODES.data.has(logical_node) and not RONEN_NODES.data.has(logical_node):
		logical_node = "D01"
	conversation_active = bool(config.get_value("opening", "conversation", false))
	q01_accepted = bool(config.get_value("opening", "accepted", false))
	q01_reward_committed = bool(config.get_value("opening", "reward", false))
	confirmed_choices.assign(config.get_value("opening", "choices", []))
	experience = int(config.get_value("opening", "experience", 0))
	# Missing fields in an opening-only save do not erase its choices or XP.
	var defaults := {"bow_owned": false, "arrows": 0, "bow_training_complete": false, "bow_demonstrated": false, "selected_equipment": "sword" if bool(config.get_value("training", "sword_selected", false)) else "unarmed", "ronen_node": "R01", "sword_owned": false, "practice_hit": false, "practice_defense": false, "practice_parry": false, "encounter_defeated": false, "remnant_collected": false, "remnant_position": Vector3.ZERO, "health": 100.0, "lives": 3, "recovery_pending": false, "hers_node": "H01", "reduced_motion": false, "muted_sound": false, "sword_selected": false, "dialogue_kind": "isha"}
	for key in TRAINING_KEYS:
		if key not in PREFERENCE_DEFAULTS: set(key, config.get_value("training", key, defaults[key]))
	for key in POST_DEFAULTS: set(key, config.get_value("post_bow", key, POST_DEFAULTS[key]).duplicate(true) if POST_DEFAULTS[key] is Dictionary else config.get_value("post_bow", key, POST_DEFAULTS[key]))
	if inventory: inventory.restore()
	arrows = clampi(arrows, 0, 12) if bow_owned else 0
	if (selected_equipment == "bow" and not bow_owned) or (selected_equipment == "sword" and not sword_owned) or (selected_equipment == "lamp" and not lamp_owned): selected_equipment = "unarmed"
	health = clampf(health, 0, 100)
	lives = clampi(lives, 0, 5)
	if remnant_collected: encounter_defeated = true
	if lives == 0: health = 0
	var map_id := str(config.get_value("opening", "map_id", "village-v2"))
	var saved: Vector3 = config.get_value("opening", "position", Vector3.ZERO)
	var xz := GROUND.restored_xz(saved, map_id)
	if map_id != GROUND.MAP_ID and encounter_defeated and not remnant_collected:
		remnant_position = Vector3(GROUND.ENCOUNTER.x, 0, GROUND.ENCOUNTER.y)
	persistence_error = ""
	return {"position": Vector3(xz.x, saved.y if map_id == GROUND.MAP_ID else 0, xz.y), "yaw": config.get_value("opening", "yaw", 0.0), "map_id": GROUND.MAP_ID}

func objective() -> String:
	if not q01_accepted: return "救援请求 · 与广场边的伊莎交谈"
	if not sword_owned: return "出发前的训练 · 找村口的赫斯"
	if not practice_hit: return "剑练习 · 用剑击中赫斯旁的草靶"
	if not practice_defense: return "防御练习 · 靠近赫斯，挡住或躲开模拟攻击"
	if not encounter_defeated: return "初场实战 · 沿路前往训练怪；危险区外可退回"
	if not remnant_collected: return "初战获胜 · 靠近金色残响自动拾取经验"
	if not bow_owned: return "巡路弓 · 找草地边的罗恩"
	if not bow_training_complete: return "弓练习 · 瞄准罗恩前方草靶，蓄力后松开；罗恩处免费补箭"
	if not lamp_owned: return "奥伦的旧灯 · 返回伊莎处领取"
	if not trace_revealed: return "旧灯练习 · 伊莎旁的路碑，3 装备后按 F 显形"
	if not trace_investigated: return "旧灯线索 · 靠近显形路碑按 E 调查"
	if skills.is_empty(): return "首次升级 · 按 K 选择火焰或雷电"
	if not element_practice_complete: return "元素练习 · 罗恩草靶旁，4 火焰 / 5 雷电；可重复尝试"
	if reward_history.size() < 2: return "追踪救援 · 从罗恩草靶左侧的木板入口过桥，清除对岸两名巡守"
	return "桥边巡守已清除 · 继续寻找被带走的村民（后续旅程尚未开放）"

func _mcp_state() -> Dictionary:
	return {"opening_completed": opening_completed, "logical_node": logical_node, "conversation_active": conversation_active, "q01_accepted": q01_accepted, "reward_committed": q01_reward_committed, "experience": experience, "confirmed_choices": confirmed_choices, "objective": objective(), "save_feedback": save_feedback, "training": training_snapshot(), "preferences": preference_snapshot()}

func training_snapshot() -> Dictionary:
	var facts := {}
	for key in TRAINING_KEYS: facts[key] = get(key)
	for key in POST_DEFAULTS: facts[key] = get(key)
	return facts

func reset_adventure() -> void:
	for key in POST_DEFAULTS: set(key, POST_DEFAULTS[key].duplicate(true) if POST_DEFAULTS[key] is Dictionary else POST_DEFAULTS[key])
	if inventory: inventory.restore()
	opening_completed = false
	tracked_quest = "rescue"
	tracker_collapsed = false
	dialogue_kind = "isha"
	logical_node = "D01"
	conversation_active = false
	q01_accepted = false
	q01_reward_committed = false
	experience = 0
	confirmed_choices.clear()
	bow_owned = false
	arrows = 0
	bow_training_complete = false
	bow_demonstrated = false
	selected_equipment = "unarmed"
	ronen_node = "R01"
	sword_owned = false
	practice_hit = false
	practice_defense = false
	practice_parry = false
	encounter_defeated = false
	remnant_collected = false
	remnant_position = Vector3.ZERO
	health = 100
	lives = 3
	recovery_pending = false
	hers_node = "H01"
	sword_selected = false
	if inventory: inventory.restore()
	save_feedback = ""
	reward_feedback = ""
	persistence_error = ""

func current_nodes() -> Dictionary:
	return RONEN_NODES.data if dialogue_kind == "ronen" else (HERS_NODES.data if dialogue_kind == "hers" else NODES.data)


func adventure_snapshot() -> Dictionary:
	if inventory: bag_history = inventory.snapshot()
	var snapshot := training_snapshot()
	for key in ["opening_completed", "logical_node", "conversation_active", "q01_accepted", "q01_reward_committed", "experience", "confirmed_choices", "reward_feedback", "text_scale", "reveal_speed", "instant_text", "persistence_error", "tracked_quest", "tracker_collapsed"]:
		snapshot[key] = get(key)
	return snapshot.duplicate(true)


func restore_adventure(snapshot: Dictionary) -> void:
	for key in snapshot:
		if key not in PREFERENCE_DEFAULTS: set(key, snapshot[key])
	if inventory: inventory.restore()


func slot_unavailable_reason(slot: int, allow_depleted := false) -> String:
	var config := ConfigFile.new()
	var path := SAVE_PATH if slot == 0 else "user://isha_slot_%d.cfg" % slot
	if not FileAccess.file_exists(path): return "暂无存档"
	if config.load(path) != OK: return "存档无法读取"
	return config_unavailable_reason(config, allow_depleted)


func config_unavailable_reason(config: ConfigFile, allow_depleted := false) -> String:
	var saved_position: Variant = config.get_value("opening", "position", null)
	var saved_lives: Variant = config.get_value("training", "lives", 3)
	var yaw: Variant = config.get_value("opening", "yaw", 0.0)
	if not saved_position is Vector3 or not saved_position.is_finite(): return "存档位置无效"
	var map_id: Variant = config.get_value("opening", "map_id", "village-v2")
	if not map_id is String: return "存档地图无效"
	if not (saved_lives is int or saved_lives is float): return "存档命数无效"
	if not (yaw is int or yaw is float) or not is_finite(float(yaw)): return "存档方向无效"
	if int(saved_lives) < 0 or (int(saved_lives) == 0 and not allow_depleted): return "命数已耗尽"
	if not is_finite(float(saved_lives)) or float(saved_lives) != floor(float(saved_lives)) or float(saved_lives) > 5: return "存档命数无效"
	var saved_health: Variant = config.get_value("training", "health", 100.0)
	if not (saved_health is int or saved_health is float) or not is_finite(float(saved_health)) or float(saved_health) < 0 or float(saved_health) > 100: return "存档生命无效"
	var node: Variant = config.get_value("opening", "node", "D01")
	if not node is String or (not NODES.data.has(node) and not HERS_NODES.data.has(node) and not RONEN_NODES.data.has(node)): return "存档对话无效"
	var choices: Variant = config.get_value("opening", "choices", [])
	if not choices is Array: return "存档选择无效"
	for choice in choices:
		if not choice is String: return "存档选择无效"
	for key in ["accepted", "reward", "conversation"]:
		if not config.get_value("opening", key, false) is bool: return "存档进度无效"
	var xp: Variant = config.get_value("opening", "experience", 0)
	if not xp is int or xp < 0: return "存档经验无效"
	for key in ["bow_owned", "bow_training_complete", "bow_demonstrated", "sword_owned", "practice_hit", "practice_defense", "practice_parry", "encounter_defeated", "remnant_collected", "recovery_pending", "sword_selected", "reduced_motion", "muted_sound"]:
		if not config.get_value("training", key, false) is bool: return "存档训练无效"
	var ammo: Variant = config.get_value("training", "arrows", 0)
	if not ammo is int or ammo < 0 or ammo > 12: return "存档箭数无效"
	var equipment: Variant = config.get_value("training", "selected_equipment", "unarmed")
	if equipment not in ["unarmed", "sword", "bow", "lamp"]: return "存档装备无效"
	if equipment == "bow" and not config.get_value("training", "bow_owned", false): return "存档装备无效"
	if config.get_value("training", "ronen_node", "R01") not in ["R01", "R02"]: return "存档对话无效"
	var remnant: Variant = config.get_value("training", "remnant_position", Vector3.ZERO)
	if not remnant is Vector3 or not remnant.is_finite(): return "存档残响无效"
	if config.get_value("training", "dialogue_kind", "isha") not in ["isha", "hers", "ronen"]: return "存档对话无效"
	if config.get_value("training", "hers_node", "H01") not in ["H01", "H02"]: return "存档训练无效"
	for key in ["scale", "speed"]:
		var reading: Variant = config.get_value("reading", key, 1.0 if key == "scale" else 30.0)
		if not (reading is int or reading is float) or not is_finite(float(reading)): return "存档设置无效"
	if not config.get_value("reading", "instant", false) is bool: return "存档设置无效"
	for key in ["lamp_owned", "trace_revealed", "trace_investigated", "lamp_reward_committed", "element_practice_complete"]:
		if not config.get_value("post_bow", key, false) is bool: return "存档旧灯进度无效"
	for key in ["skills", "reward_history", "bag_history"]:
		if not config.get_value("post_bow", key, {}) is Dictionary: return "存档物品进度无效"
	if not preload("res://inventory/product_inventory.gd").valid_history(config.get_value("post_bow", "bag_history", {})): return "存档背包无效"
	var saved_skills: Dictionary = config.get_value("post_bow", "skills", {})
	for key in saved_skills:
		if key not in ["fire", "lightning"] or saved_skills[key] != 1: return "存档技能无效"
	if saved_skills.size() > earned_points(int(xp)): return "存档技能点无效"
	var rewards: Dictionary = config.get_value("post_bow", "reward_history", {})
	for id in rewards:
		if id not in ["bridge_patrol_a","bridge_patrol_b"] or not rewards[id] is Dictionary: return "存档掉落无效"
		var reward: Dictionary = rewards[id]
		if reward.get("xp",0) != 10 or not reward.get("collected",false) is bool: return "存档掉落无效"
		var position: Variant = reward.get("position",Vector3.INF)
		if not position is Vector3 or not position.is_finite(): return "存档掉落位置无效"
		var drop: Variant = reward.get("drop",{})
		if not drop is Dictionary: return "存档掉落物品无效"
		if not drop.is_empty() and (drop.get("id","") not in ["healing","lifeflame"] or drop.get("quantity",0) != 1): return "存档掉落物品无效"
	return ""


func save_preferences() -> Error:
	apply_preferences()
	var config := ConfigFile.new()
	for key in PREFERENCE_DEFAULTS: config.set_value("settings", key, get(key))
	var error := config.save("user://adventure_preferences.cfg.tmp")
	if error == OK: error = DirAccess.rename_absolute("user://adventure_preferences.cfg.tmp", "user://adventure_preferences.cfg")
	preference_error = "" if error == OK else "设置仅本次生效 · 保存失败，请重试"
	return error

func load_preferences() -> void:
	var config := ConfigFile.new()
	if config.load("user://adventure_preferences.cfg") == OK:
		for key in PREFERENCE_DEFAULTS:
			var value: Variant = config.get_value("settings", key, get(key))
			if PREFERENCE_DEFAULTS[key] is bool:
				if value is bool: set(key, value)
			elif PREFERENCE_DEFAULTS[key] is float:
				if (value is float or value is int) and is_finite(float(value)): set(key, float(value))
			elif key == "graphics_quality" and value in ["low", "normal"]: set(key, value)
	mouse_sensitivity = clampf(mouse_sensitivity, 0.25, 2.5)
	text_scale = 1.0 if text_scale < 1.25 else (1.5 if text_scale < 1.75 else 2.0)
	reveal_speed = clampf(reveal_speed, 15, 60)
	for key in ["master_volume", "music_volume", "effects_volume", "camera_shake"]: set(key, clampf(get(key), 0, 1))
	apply_preferences()


func slot_preview(slot: int) -> Dictionary:
	# Read-only: no restore_config, signals, preference loads or writes.
	var reason := slot_unavailable_reason(slot, slot == 0)
	var facts := {"slot": slot, "reason": reason}
	if reason != "": return facts
	var config := ConfigFile.new()
	var path := SAVE_PATH if slot == 0 else "user://isha_slot_%d.cfg" % slot
	if config.load(path) != OK:
		facts.reason = "存档无法读取"
		return facts
	facts.chapter = "第一章 · 河谷聚落"
	facts.time = Time.get_datetime_string_from_unix_time(FileAccess.get_modified_time(path)).replace("T", " ")
	facts.checkpoint = "河谷村庄灯台"
	facts.experience = int(config.get_value("opening", "experience", 0))
	facts.lives = int(config.get_value("training", "lives", 3))
	facts.arrows = int(config.get_value("training", "arrows", 0))
	facts.progress = "弓练习已完成" if config.get_value("training", "bow_training_complete", false) else ("已取得巡路弓" if config.get_value("training", "bow_owned", false) else ("已取得巡路剑" if config.get_value("training", "sword_owned", false) else ("已接受救援请求" if config.get_value("opening", "accepted", false) else "伊莎的求援")))
	return facts

# Read-only journal projection. These rows never grant equipment or rewards.
func quest_entries() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	rows.append({"id": "rescue", "title": "伊莎的请求", "complete": false,
		"context": "伊莎的父亲和三位村民被怪物带走。出发前，先在河谷聚落做好准备。" if q01_accepted else "广场边的伊莎似乎需要帮助。靠近她，听听发生了什么。",
		"action": objective(), "steps": ["答应伊莎的求援"] if q01_accepted else []})
	if q01_accepted:
		var steps: Array[String] = []
		if sword_owned: steps.append("从村口的赫斯处取得巡路剑")
		if practice_hit: steps.append("用剑击中草靶")
		if practice_defense: steps.append("挡住或躲开模拟攻击")
		if practice_parry: steps.append("成功振刀")
		if encounter_defeated: steps.append("击败路边的训练怪")
		if remnant_collected: steps.append("拾取初战残响")
		rows.append({"id": "sword", "title": "出发前的训练", "complete": remnant_collected,
			"context": "老战士赫斯在村口教授巡路剑。先练习，再到道路旁验证所学。",
			"action": "剑训练已完成" if remnant_collected else objective(), "steps": steps})
	if remnant_collected or bow_owned:
		var steps: Array[String] = []
		if bow_owned: steps.append("从草地边的罗恩处取得巡路弓")
		if bow_demonstrated: steps.append("观看罗恩的射箭示范")
		if bow_training_complete: steps.append("射中罗恩前方的草靶")
		rows.append({"id": "bow", "title": "巡路弓练习", "complete": bow_training_complete,
			"context": "猎人罗恩在草地边等候。练习用弓控制距离，箭用尽后可找他补充。",
			"action": "返回伊莎处" if bow_training_complete else objective(), "steps": steps})
	if lamp_owned or bow_training_complete:
		var steps: Array[String] = []
		if lamp_owned: steps.append("从伊莎处取得奥伦的旧灯")
		if trace_revealed: steps.append("用旧灯显形路碑魔法痕迹")
		if trace_investigated: steps.append("调查显形的线索：村民被带过石桥")
		if not skills.is_empty(): steps.append("选择第一个元素能力")
		if element_practice_complete: steps.append("实际命中元素练习目标 · Q02 完成")
		rows.append({"id":"lamp", "title":"奥伦的旧灯", "complete":element_practice_complete, "context":"旧灯能显形隐藏的痕迹；显形与调查是两个步骤。元素练习可反复尝试。", "action":objective(), "steps":steps})
	if element_practice_complete:
		rows.append({"id":"bridge", "title":"石桥对岸", "complete":false, "context":"伊莎看见四人被带过石桥。先清除对岸的两名巡守；更远的救援仍未完成。", "action":objective(), "steps":[]})
	return rows

func tracked_entry() -> Dictionary:
	var rows := quest_entries()
	for row in rows:
		if row.id == tracked_quest: return row
	tracked_quest = "rescue"
	return rows[0]

func track_quest(id: String) -> bool:
	for row in quest_entries():
		if row.id == id:
			tracked_quest = id
			return true
	return false

# Cumulative XP is retained for legacy histories; thresholds are per level.
static func earned_points(total: int) -> int:
	var left = total
	var earned = 0
	for threshold in [30, 50, 80, 110, 150, 200]:
		if left < threshold: break
		left -= threshold
		earned += 1
	return earned

func level() -> int:
	return 1 + earned_points(experience)

func xp_progress() -> int:
	var left = experience
	for threshold in [30, 50, 80, 110, 150, 200]:
		if left < threshold: return left
		left -= threshold
	return left

func xp_threshold() -> int:
	return [30, 50, 80, 110, 150, 200][mini(5, level() - 1)]

func pending_points() -> int:
	return maxi(0, earned_points(experience) - skills.size())

func unlock_element(id: String) -> bool:
	if not lamp_owned or id not in ["fire", "lightning"] or skills.has(id) or pending_points() <= 0: return false
	skills[id] = 1
	progression_changed.emit()
	return true
