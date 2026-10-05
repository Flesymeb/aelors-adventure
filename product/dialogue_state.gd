extends Node
## Only confirmed choices commit rewards. Focus and reveal position are UI state.
const SAVE_PATH := "user://isha_opening.cfg"
const NODES := preload("res://data/isha_dialogue.json")
const HERS_NODES := preload("res://data/hers_dialogue.json")
var dialogue_kind := "isha"
signal sword_granted
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
const TRAINING_KEYS := ["sword_owned", "practice_hit", "practice_defense", "practice_parry", "encounter_defeated", "remnant_collected", "remnant_position", "health", "lives", "recovery_pending", "hers_node", "reduced_motion", "muted_sound", "sword_selected", "dialogue_kind"]

func _ready() -> void:
	load_progress()

func begin() -> void:
	if not conversation_active:
		logical_node = hers_node if dialogue_kind == "hers" else ("D02" if q01_accepted else "D01")
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
	if choice.get("accept", false):
		q01_accepted = true
		if not q01_reward_committed:
			experience += 10
			q01_reward_committed = true
			confirmed_choices.append("Q01_accept")
			reward_feedback = "救援请求已接受 · 获得 10 点经验"
	logical_node = choice.next
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
	config.set_value("training", "version", 1)
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
		return {}
	logical_node = str(config.get_value("opening", "node", "D01"))
	if not NODES.data.has(logical_node) and not HERS_NODES.data.has(logical_node):
		logical_node = "D01"
	conversation_active = bool(config.get_value("opening", "conversation", false))
	q01_accepted = bool(config.get_value("opening", "accepted", false))
	q01_reward_committed = bool(config.get_value("opening", "reward", false))
	confirmed_choices.assign(config.get_value("opening", "choices", []))
	experience = int(config.get_value("opening", "experience", 0))
	# Missing fields in an opening-only save do not erase its choices or XP.
	var defaults := {"sword_owned": false, "practice_hit": false, "practice_defense": false, "practice_parry": false, "encounter_defeated": false, "remnant_collected": false, "remnant_position": Vector3.ZERO, "health": 100.0, "lives": 3, "recovery_pending": false, "hers_node": "H01", "reduced_motion": false, "muted_sound": false, "sword_selected": false, "dialogue_kind": "isha"}
	for key in TRAINING_KEYS:
		set(key, config.get_value("training", key, defaults[key]))
	health = clampf(health, 0, 100)
	lives = clampi(lives, 0, 3)
	if remnant_collected: encounter_defeated = true
	if lives == 0: health = 0
	text_scale = clampf(float(config.get_value("reading", "scale", 1.0)), 1.0, 2.0)
	reveal_speed = clampf(float(config.get_value("reading", "speed", 30.0)), 15.0, 60.0)
	instant_text = bool(config.get_value("reading", "instant", false))
	return {"position": config.get_value("opening", "position", Vector3.ZERO), "yaw": config.get_value("opening", "yaw", 0.0)}

func objective() -> String:
	if not q01_accepted: return "救援请求 · 与广场边的伊莎交谈"
	if not sword_owned: return "出发前的训练 · 找木桥旁的赫斯"
	if not practice_hit: return "剑练习 · 用剑击中赫斯旁的草靶"
	if not practice_defense: return "防御练习 · 靠近赫斯，挡住或躲开模拟攻击"
	if not encounter_defeated: return "初场实战 · 沿路前往训练怪；危险区外可退回"
	if not remnant_collected: return "初战获胜 · 靠近金色残响按 E 领取经验"
	return "剑训练已完成 · 弓与旧灯训练尚未完成"

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

func current_nodes() -> Dictionary:
	return HERS_NODES.data if dialogue_kind == "hers" else NODES.data
