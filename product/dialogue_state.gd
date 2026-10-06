extends Node
## Only confirmed choices commit rewards. Focus and reveal position are UI state.
const SAVE_PATH := "user://isha_opening.cfg"
const NODES := preload("res://data/isha_dialogue.json")
const RONEN_NODES := preload("res://data/ronen_dialogue.json")
const HERS_NODES := preload("res://data/hers_dialogue.json")
var dialogue_kind := "isha"
signal sword_granted
signal bow_granted
var logical_node := "D01"
var conversation_active := false
var q01_accepted := false
var q01_reward_committed := false
var experience := 0
var confirmed_choices: Array[String] = []
var text_scale := 1.0
var reveal_speed := 30.0
var instant_text := false
var save_feedback := ""
var reward_feedback := ""
# Versioned, independent facts. Q02 remains incomplete in this sword increment.
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
var muted_sound := false
var sword_selected := false
var persistence_error := ""
const TRAINING_KEYS := ["bow_owned", "arrows", "bow_training_complete", "bow_demonstrated", "selected_equipment", "ronen_node", "sword_owned", "practice_hit", "practice_defense", "practice_parry", "encounter_defeated", "remnant_collected", "remnant_position", "health", "lives", "recovery_pending", "hers_node", "reduced_motion", "muted_sound", "sword_selected", "dialogue_kind"]

func _ready() -> void:
	load_progress()

func begin() -> void:
	if not conversation_active:
		logical_node = ronen_node if dialogue_kind == "ronen" else (hers_node if dialogue_kind == "hers" else ("D02" if q01_accepted else "D01"))
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
	config.set_value("opening", "node", logical_node)
	config.set_value("opening", "conversation", conversation_active)
	config.set_value("opening", "accepted", q01_accepted)
	config.set_value("opening", "reward", q01_reward_committed)
	config.set_value("opening", "choices", confirmed_choices)
	config.set_value("opening", "experience", experience)
	config.set_value("opening", "position", position)
	config.set_value("opening", "yaw", yaw)
	config.set_value("training", "version", 2)
	for key in TRAINING_KEYS:
		config.set_value("training", key, get(key))
	config.set_value("reading", "scale", text_scale)
	config.set_value("reading", "speed", reveal_speed)
	config.set_value("reading", "instant", instant_text)
	var path := SAVE_PATH if slot == 0 else "user://isha_slot_%d.cfg" % slot
	var error := config.save(path + ".tmp")
	if error == OK:
		error = DirAccess.rename_absolute(path + ".tmp", path)
	save_feedback = "检查点已保存" if error == OK else "保存失败，请重试"
	persistence_error = "" if error == OK else save_feedback
	return error

func load_progress(slot := 0) -> Dictionary:
	var config := ConfigFile.new()
	var path := SAVE_PATH if slot == 0 else "user://isha_slot_%d.cfg" % slot
	if config.load(path) != OK:
		load_preferences()
		return {}
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
		set(key, config.get_value("training", key, defaults[key]))
	arrows = clampi(arrows, 0, 12) if bow_owned else 0
	if (selected_equipment == "bow" and not bow_owned) or (selected_equipment == "sword" and not sword_owned): selected_equipment = "unarmed"
	health = clampf(health, 0, 100)
	lives = clampi(lives, 0, 3)
	if remnant_collected: encounter_defeated = true
	if lives == 0: health = 0
	text_scale = clampf(float(config.get_value("reading", "scale", 1.0)), 1.0, 2.0)
	reveal_speed = clampf(float(config.get_value("reading", "speed", 30.0)), 15.0, 60.0)
	instant_text = bool(config.get_value("reading", "instant", false))
	load_preferences()
	return {"position": config.get_value("opening", "position", Vector3.ZERO), "yaw": config.get_value("opening", "yaw", 0.0)}

func objective() -> String:
	if not q01_accepted: return "救援请求 · 与广场边的伊莎交谈"
	if not sword_owned: return "出发前的训练 · 找木桥旁的赫斯"
	if not practice_hit: return "剑练习 · 用剑击中赫斯旁的草靶"
	if not practice_defense: return "防御练习 · 靠近赫斯，挡住或躲开模拟攻击"
	if not encounter_defeated: return "初场实战 · 沿路前往训练怪；危险区外可退回"
	if not remnant_collected: return "初战获胜 · 靠近金色残响按 E 领取经验"
	if not bow_owned: return "巡路弓 · 找训练院右侧的罗恩"
	if not bow_training_complete: return "弓练习 · 瞄准罗恩前方草靶，蓄力后松开；罗恩处免费补箭"
	return "弓练习已完成 · 返回伊莎处；旧灯训练尚未完成"

func _mcp_state() -> Dictionary:
	return {"logical_node": logical_node, "conversation_active": conversation_active, "q01_accepted": q01_accepted, "reward_committed": q01_reward_committed, "experience": experience, "confirmed_choices": confirmed_choices, "objective": objective(), "save_feedback": save_feedback, "training": training_snapshot()}

func training_snapshot() -> Dictionary:
	var facts := {}
	for key in TRAINING_KEYS: facts[key] = get(key)
	return facts

func reset_adventure() -> void:
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
	save_feedback = ""
	reward_feedback = ""
	persistence_error = ""

func current_nodes() -> Dictionary:
	return RONEN_NODES.data if dialogue_kind == "ronen" else (HERS_NODES.data if dialogue_kind == "hers" else NODES.data)


func adventure_snapshot() -> Dictionary:
	var snapshot := training_snapshot()
	for key in ["logical_node", "conversation_active", "q01_accepted", "q01_reward_committed", "experience", "confirmed_choices", "reward_feedback", "text_scale", "reveal_speed", "instant_text"]:
		snapshot[key] = get(key)
	return snapshot.duplicate(true)


func restore_adventure(snapshot: Dictionary) -> void:
	for key in snapshot: set(key, snapshot[key])


func slot_unavailable_reason(slot: int) -> String:
	var config := ConfigFile.new()
	var path := SAVE_PATH if slot == 0 else "user://isha_slot_%d.cfg" % slot
	if not FileAccess.file_exists(path): return "暂无存档"
	if config.load(path) != OK: return "存档无法读取"
	var saved_position: Variant = config.get_value("opening", "position", null)
	var saved_lives: Variant = config.get_value("training", "lives", 3)
	var yaw: Variant = config.get_value("opening", "yaw", 0.0)
	if not saved_position is Vector3 or not saved_position.is_finite(): return "存档位置无效"
	if Vector2(saved_position.x, saved_position.z).distance_to(Vector2(20, 20)) > 35: return "位置不在安全区域"
	if not (saved_lives is int or saved_lives is float): return "存档命数无效"
	if not (yaw is int or yaw is float) or not is_finite(float(yaw)): return "存档方向无效"
	if int(saved_lives) <= 0: return "命数已耗尽"
	if int(saved_lives) > 3: return "存档命数无效"
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
	if equipment not in ["unarmed", "sword", "bow"]: return "存档装备无效"
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
	return ""


func save_preferences() -> Error:
	var config := ConfigFile.new()
	for key in ["text_scale", "reveal_speed", "instant_text", "reduced_motion", "muted_sound"]:
		config.set_value("settings", key, get(key))
	var error := config.save("user://adventure_preferences.cfg.tmp")
	if error == OK: error = DirAccess.rename_absolute("user://adventure_preferences.cfg.tmp", "user://adventure_preferences.cfg")
	return error


func load_preferences() -> void:
	var config := ConfigFile.new()
	if config.load("user://adventure_preferences.cfg") != OK: return
	text_scale = clampf(float(config.get_value("settings", "text_scale", text_scale)), 1, 2)
	reveal_speed = clampf(float(config.get_value("settings", "reveal_speed", reveal_speed)), 15, 60)
	for key in ["instant_text", "reduced_motion", "muted_sound"]:
		set(key, bool(config.get_value("settings", key, get(key))))
