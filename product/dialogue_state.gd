extends Node
## Only confirmed choices commit rewards. Focus and reveal position are UI state.
const SAVE_PATH := "user://isha_opening.cfg"
const NODES := preload("res://data/isha_dialogue.json")
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

func _ready() -> void:
	load_progress()

func begin() -> void:
	if not conversation_active:
		logical_node = "D02" if q01_accepted else "D01"
	reward_feedback = ""
	conversation_active = true

func choose(index: int) -> bool:
	var node: Dictionary = NODES.data.get(logical_node, {})
	var choices: Array = node.get("choices", [])
	if index < 0 or index >= choices.size():
		return false
	var choice: Dictionary = choices[index]
	if choice.get("accept", false):
		q01_accepted = true
		if not q01_reward_committed:
			experience += 10
			q01_reward_committed = true
			confirmed_choices.append("Q01_accept")
			reward_feedback = "救援请求已接受 · 获得 10 点经验"
	logical_node = choice.next
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
	config.set_value("reading", "scale", text_scale)
	config.set_value("reading", "speed", reveal_speed)
	config.set_value("reading", "instant", instant_text)
	var path := SAVE_PATH if slot == 0 else "user://isha_slot_%d.cfg" % slot
	var error := config.save(path + ".tmp")
	if error == OK:
		error = DirAccess.rename_absolute(path + ".tmp", path)
	save_feedback = "已保存" if error == OK else "保存失败，请重试"
	return error

func load_progress(slot := 0) -> Dictionary:
	var config := ConfigFile.new()
	var path := SAVE_PATH if slot == 0 else "user://isha_slot_%d.cfg" % slot
	if config.load(path) != OK:
		return {}
	logical_node = str(config.get_value("opening", "node", "D01"))
	if not NODES.data.has(logical_node):
		logical_node = "D01"
	conversation_active = bool(config.get_value("opening", "conversation", false))
	q01_accepted = bool(config.get_value("opening", "accepted", false))
	q01_reward_committed = bool(config.get_value("opening", "reward", false))
	confirmed_choices.assign(config.get_value("opening", "choices", []))
	experience = int(config.get_value("opening", "experience", 0))
	text_scale = clampf(float(config.get_value("reading", "scale", 1.0)), 1.0, 2.0)
	reveal_speed = clampf(float(config.get_value("reading", "speed", 30.0)), 15.0, 60.0)
	instant_text = bool(config.get_value("reading", "instant", false))
	return {"position": config.get_value("opening", "position", Vector3.ZERO), "yaw": config.get_value("opening", "yaw", 0.0)}

func objective() -> String:
	return "救援请求 · 到前方木桥旁的广场找赫斯（Hers）" if q01_accepted else "救援请求 · 与广场边的伊莎交谈"

func _mcp_state() -> Dictionary:
	return {"logical_node": logical_node, "conversation_active": conversation_active, "q01_accepted": q01_accepted, "reward_committed": q01_reward_committed, "experience": experience, "confirmed_choices": confirmed_choices, "objective": objective(), "save_feedback": save_feedback}
