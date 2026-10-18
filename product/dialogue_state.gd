extends Node
## Only confirmed choices commit rewards. Focus and reveal position are UI state.
const GROUND := preload("res://forest_ground.gd")
const SAVE_PATH := "user://isha_opening.cfg"
const OPENING_RECOVERY_PATH := "user://unfinished_opening.cfg"
const HISTORY_READER := preload("res://systems/history_config_reader.gd")
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
var opening_recovery_id := ""
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
var preference_load_error: int = ERR_FILE_NOT_FOUND
var preference_save_error: Variant = null
var tracked_quest := "rescue"
var tracker_collapsed := false
var reveal_speed := 30.0
var instant_text := false
var save_feedback := ""
var reward_feedback := ""
# Versioned, independent facts. Q02 remains incomplete in this sword increment.
const POST_DEFAULTS := {"lamp_owned": false, "trace_revealed": false, "trace_investigated": false, "lamp_reward_committed": false, "element_practice_complete": false, "bridge_briefing_acknowledged": false, "guard_briefing_acknowledged": false, "guard_interlude_seen": false, "bridge_resident_rescued": false, "bridge_lamp_lit": false, "bridge_first_action": "", "bridge_supply_claimed": false, "bridge_later_supply_due": false, "skills": {}, "reward_history": {}, "bag_history": {}, "quick_item": "healing", "dynamic_serial": 0, "dynamic_remaining": 120.0, "dynamic_instances": {}, "meadow_dynamic_serial": 0, "meadow_dynamic_remaining": 120.0, "meadow_dynamic_groups": 0, "meadow_dynamic_instances": {}, "departure_confirmed": false, "current_map": "forest-885de576-v1", "cp02_claimed": false, "pressure_supply_claimed": false, "meadow_branch_supply_claimed": false, "mf01_acquired": false, "e03_revealed": false, "mf02_acquired": false, "line_supply_claimed": false, "ln01_revealed": false, "ln01_supply_cut": false, "ln01_location_purified": false, "cp03_claimed": false, "ritual_record_read": false, "sq02_record_found": false, "sq02_completed": false, "veyne_node_closed": false, "ln02_revealed": false, "ln02_north_cut": false, "ln02_south_cut": false, "ln02_purified": false, "warden_defeated": false, "warden_lock_released": false, "emergency_release_tool": false, "veyne_defeated": false, "veyne_release_key": false, "rescue_released": {}, "rescue_assembled": false, "rescue_supply_claimed": false, "rescue_order": "", "core_closed": false, "homecoming_completed": false}
var lamp_owned := false
var trace_revealed := false
var trace_investigated := false
var lamp_reward_committed := false
var element_practice_complete := false
var bridge_briefing_acknowledged := false
var guard_briefing_acknowledged := false
var guard_interlude_seen := false
var departure_confirmed := false
var current_map := GROUND.MAP_ID
var cp02_claimed := false
var pressure_supply_claimed := false
var meadow_branch_supply_claimed := false
var mf01_acquired := false
var e03_revealed := false
var mf02_acquired := false
var line_supply_claimed := false
var ln01_revealed := false
var ln01_supply_cut := false
var ln01_location_purified := false
const MAP02 := "meadow-entry-v1"
const MAP03 := "tomb-entry-v1"
var cp03_claimed := false
var ritual_record_read := false
var sq02_record_found := false
var sq02_completed := false
var veyne_node_closed := false
var ln02_revealed := false
var ln02_north_cut := false
var ln02_south_cut := false
var ln02_purified := false
var veyne_defeated := false
var veyne_release_key := false
var warden_defeated := false
var warden_lock_released := false
var emergency_release_tool := false
const CAPTIVE_IDS := ["oren", "villager_a", "villager_b", "villager_c"]
var rescue_released: Dictionary = {}
var core_closed := false
var homecoming_completed := false
var rescue_assembled := false
var rescue_supply_claimed := false
var rescue_order := ""
var bridge_resident_rescued := false
var bridge_lamp_lit := false
var bridge_first_action := ""
var bridge_supply_claimed := false
var bridge_later_supply_due := false
var skills: Dictionary = {}
var reward_history: Dictionary = {}
var dynamic_serial := 0
var dynamic_remaining := 120.0
var dynamic_instances: Dictionary = {}
var meadow_dynamic_serial := 0
var meadow_dynamic_remaining := 120.0
var meadow_dynamic_groups := 0
var meadow_dynamic_instances: Dictionary = {}
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

func audio_observation() -> Dictionary:
	# Read the live output configuration, not the requested values or playback flags.
	# No application, signals, file I/O or gameplay mutation belongs in this projection.
	var result := {"master_volume": master_volume, "music_volume": music_volume,
		"effects_volume": effects_volume, "muted_sound": muted_sound,
		"preference_error": preference_error, "preference_load_error": preference_load_error,
		"preference_save_error": preference_save_error}
	for bus in ["Master", "Music", "Effects"]:
		var prefix: String = bus.to_lower() + "_"
		var index := AudioServer.get_bus_index(bus)
		result[prefix + "bus_present"] = index >= 0
		for field in ["gain_db", "gain_enabled", "bus_muted", "bus_bypassed", "bus_volume_db", "bus_send", "effective_gain"]:
			result[prefix + field] = null
		result[prefix + "gain_present"] = false
		if index < 0: continue
		var bypassed := AudioServer.is_bus_bypassing_effects(index)
		var muted := AudioServer.is_bus_mute(index)
		var fader := AudioServer.get_bus_volume_db(index)
		var effect_gain := 1.0
		for effect_index in AudioServer.get_bus_effect_count(index):
			var effect := AudioServer.get_bus_effect(index, effect_index)
			if effect is AudioEffectAmplify and effect.resource_name == "AdventureOutputGain":
				var enabled := AudioServer.is_bus_effect_enabled(index, effect_index)
				result[prefix + "gain_present"] = true
				result[prefix + "gain_db"] = effect.volume_db
				result[prefix + "gain_enabled"] = enabled
				if enabled and not bypassed: effect_gain *= db_to_linear(effect.volume_db)
		result[prefix + "bus_muted"] = muted
		result[prefix + "bus_bypassed"] = bypassed
		result[prefix + "bus_volume_db"] = fader
		result[prefix + "bus_send"] = str(AudioServer.get_bus_send(index))
		# Linear gain at this bus stage, including mute/fader/bypass. This is
		# configuration evidence only; captured and heard sound remains necessary.
		result[prefix + "effective_gain"] = 0.0 if muted else db_to_linear(fader) * effect_gain
	return result

func begin() -> void:
	if not conversation_active:
		logical_node = ronen_node if dialogue_kind == "ronen" else (hers_node if dialogue_kind == "hers" else ("D02" if q01_accepted else "D01"))
		if dialogue_kind == "isha" and bow_training_complete and remnant_collected:
			logical_node = "L02" if lamp_owned else "L01"
		if dialogue_kind == "isha" and bridge_briefing_available():
			logical_node = "B05" if bridge_briefing_acknowledged or bridge_first_action != "" else "B01"
		if dialogue_kind == "isha" and guard_briefing_available():
			logical_node = "G04" if guards_defeated() else "G01"
		if dialogue_kind == "isha" and homecoming_completed:
			logical_node = "END_RESCUE" if bridge_first_action == "rescue" else "END_LIGHT"
	reward_feedback = ""
	conversation_active = true

func bridge_briefing_available() -> bool:
	return q01_accepted and sword_owned and remnant_collected and bow_training_complete and lamp_owned and trace_investigated and not skills.is_empty() and element_practice_complete

const GUARD_IDS := ["channel_melee_a", "channel_melee_b", "channel_ranged"]

# Read-only scalar views of the durable reward owner for external observation.
# These never settle, collect, restore, or save a reward.
var guard_melee_a_reward_state: String:
	get: return guard_reward_state("channel_melee_a")
var guard_melee_b_reward_state: String:
	get: return guard_reward_state("channel_melee_b")
var guard_ranged_reward_state: String:
	get: return guard_reward_state("channel_ranged")
var guard_melee_a_xp: int:
	get: return int(reward_history.get("channel_melee_a", {}).get("xp", 0))
var guard_melee_b_xp: int:
	get: return int(reward_history.get("channel_melee_b", {}).get("xp", 0))
var guard_ranged_xp: int:
	get: return int(reward_history.get("channel_ranged", {}).get("xp", 0))

func guard_reward_state(id: String) -> String:
	if not reward_history.has(id): return "unsettled"
	return "collected" if reward_history[id].get("collected", false) else "pending"

func guard_briefing_available() -> bool:
	return bridge_briefing_available() and bridge_resident_rescued and bridge_lamp_lit

func guards_defeated() -> bool:
	for id in GUARD_IDS:
		if not reward_history.has(id): return false
	return true

func passage_missing_conditions() -> Array[String]:
	var missing: Array[String] = []
	if not lessons_complete(): missing.append("完成剑、弓、旧灯与元素训练")
	if not bridge_resident_rescued: missing.append("救出桥边居民")
	if not bridge_lamp_lit: missing.append("恢复桥灯")
	if not guard_briefing_acknowledged: missing.append("听取伊莎的通道守卫信息")
	if not guards_defeated(): missing.append("击败柱群两名近战守卫与一名弓守")
	if not departure_confirmed: missing.append("与伊莎确认离村")
	return missing

func lessons_complete() -> bool:
	return bridge_briefing_available() and practice_hit and practice_defense and encounter_defeated and trace_revealed

func departure_available() -> bool:
	return lessons_complete() and bridge_resident_rescued and bridge_lamp_lit and guard_briefing_acknowledged and guards_defeated()

func commit_arrival(map_id: String) -> bool:
	if map_id not in [GROUND.MAP_ID, MAP02, MAP03] or not departure_confirmed or not departure_available(): return false
	if map_id == MAP03 and not tomb_missing_conditions().is_empty(): return false
	current_map = map_id
	if map_id == MAP03 and not cp03_claimed:
		cp03_claimed = true
		lives = mini(5, lives + 1)
	if map_id == MAP02 and not cp02_claimed:
		cp02_claimed = true
		lives = mini(5, lives + 1)
	return true

func tomb_missing_conditions() -> Array[String]:
	var missing: Array[String] = []
	if not cp02_claimed: missing.append("抵达林缘灯台")
	if not roadblock_defeated(): missing.append("清除 E01 路障")
	if not pressure_defeated(): missing.append("清除 E02 押送守卫")
	if not mf01_acquired: missing.append("调查 MF01 路线记录")
	if not e03_revealed or not ambush_defeated(): missing.append("显形并清除 E03 伏击")
	if not line_defeated(): missing.append("清除 E04 林路防线")
	if not mf02_acquired: missing.append("调查 MF02 墓殿方向")
	if not ln01_revealed or not ln01_supply_cut or not ln01_location_purified: missing.append("用旧灯完成 LN01：显形、切断供能、净化定位")
	return missing

func acquire_ritual_record() -> bool:
	if ritual_record_read or current_map != MAP03 or not cp03_claimed or health <= 0 or recovery_pending: return false
	if not tomb_missing_conditions().is_empty(): return false
	ritual_record_read = true
	return true

func acquire_deployment_record() -> bool:
	if sq02_record_found or current_map != MAP02 or not cp02_claimed or not pressure_defeated() or health <= 0 or recovery_pending: return false
	sq02_record_found = true
	progression_changed.emit()
	return true

func interpret_deployment_record() -> bool:
	if sq02_completed or not sq02_record_found or current_map != GROUND.MAP_ID or health <= 0 or recovery_pending: return false
	sq02_completed = true
	progression_changed.emit()
	return true

func close_veyne_node() -> bool:
	if veyne_node_closed or not sq02_completed or not ritual_record_read or not ln02_purified or veyne_defeated or current_map != MAP03 or health <= 0 or recovery_pending: return false
	veyne_node_closed = true
	progression_changed.emit()
	return true

func intelligence_information() -> String:
	if veyne_node_closed: return "增援节点已封住 · 维恩每次尝试的二阶段近战增援不会出现；仍须击败维恩。"
	if sq02_completed:
		return "玛拉：你已阻止维恩，记录会帮助我们守住村庄。" if veyne_defeated else "玛拉已核对符文 · 调查墓殿仪式记录、净化入口后，在左阶前的增援节点按 E 封印；只调查不会阻止增援。"
	if sq02_record_found: return "完整布防记录已取得 · 沿已清理林路返回入口蓝光通道，回河谷聚落交给玛拉。"
	return "林缘押送守卫后方、MF01 路碑另一侧的箱中有完整布防记录；回河谷交给玛拉核对。"

func ln02_available() -> bool:
	return current_map == MAP03 and cp03_claimed and lamp_owned and health > 0 and not recovery_pending and tomb_missing_conditions().is_empty()

func reveal_ln02() -> bool:
	if not ln02_available() or ln02_revealed: return false
	ln02_revealed = true
	tracked_quest = "ln02"
	progression_changed.emit()
	return true

func cut_ln02_supply(side: String) -> bool:
	if not ln02_available() or not ln02_revealed or side not in ["north", "south"]: return false
	var key := "ln02_" + side + "_cut"
	if get(key): return false
	set(key, true)
	progression_changed.emit()
	return true

func purify_ln02() -> bool:
	if not ln02_available() or not ln02_revealed or not ln02_north_cut or not ln02_south_cut or ln02_purified: return false
	ln02_purified = true
	progression_changed.emit()
	return true

func defeat_warden() -> bool:
	if warden_defeated or not ln02_available() or not ln02_purified: return false
	warden_defeated = true
	tracked_quest = "warden"
	return true

func inspect_warden_device() -> bool:
	if not warden_defeated or warden_lock_released or current_map != MAP03 or health <= 0 or recovery_pending: return false
	warden_lock_released = true
	emergency_release_tool = true
	return true

func defeat_veyne() -> bool:
	if veyne_defeated or not ln02_available() or not ln02_purified: return false
	veyne_defeated = true
	tracked_quest = "veyne"
	return true

func take_veyne_key() -> bool:
	if not veyne_defeated or veyne_release_key or current_map != MAP03 or health <= 0 or recovery_pending: return false
	veyne_release_key = true
	return true

func rescue_missing_conditions() -> Array[String]:
	var missing: Array[String] = []
	if not warden_lock_released: missing.append("检查右院看守锁印装置")
	if not emergency_release_tool and not veyne_release_key: missing.append("取得应急解除器或维恩钥印")
	if not lamp_owned or selected_equipment != "lamp": missing.append("按 3 装备旧灯")
	return missing

func release_captive(id: String) -> bool:
	if id not in CAPTIVE_IDS or rescue_released.has(id) or current_map != MAP03 or health <= 0 or recovery_pending or not ln02_purified or not rescue_missing_conditions().is_empty(): return false
	if rescue_order == "": rescue_order = "veyne_first" if veyne_defeated else "rescue_first"
	rescue_released[id] = true
	tracked_quest = "rescue"
	return true

func assemble_captives() -> bool:
	if rescue_assembled or current_map != MAP03 or health <= 0 or recovery_pending or not CAPTIVE_IDS.all(func(id): return rescue_released.has(id)): return false
	# Retained inventory owns health/ammunition settlement. The fact and supply
	# form one save transaction in the world adapter, including rollback.
	if inventory == null: return false
	rescue_assembled = true
	inventory.settle_bridge_supply()
	rescue_supply_claimed = true
	return true

func core_missing_conditions() -> Array[String]:
	var missing: Array[String] = []
	if not warden_defeated: missing.append("击败锁印看守")
	if not veyne_defeated: missing.append("击败维恩")
	if not rescue_assembled or not CAPTIVE_IDS.all(func(id): return rescue_released.has(id)): missing.append("四位村民安全集合")
	if not lamp_owned or selected_equipment != "lamp": missing.append("装备旧灯")
	return missing

func close_summoning_core() -> bool:
	if core_closed or current_map != MAP03 or health <= 0 or recovery_pending or conversation_active or not ln02_purified or not core_missing_conditions().is_empty(): return false
	core_closed = true
	tracked_quest = "rescue"
	return true

func commit_homecoming() -> bool:
	if not core_closed or homecoming_completed or current_map != GROUND.MAP_ID or not rescue_assembled or not warden_defeated or not veyne_defeated: return false
	homecoming_completed = true
	return true

static func valid_rescue_facts(released: Variant, assembled: Variant, supplied: Variant, order: Variant, lock: bool, tool: bool, key: bool) -> bool:
	if not released is Dictionary or not assembled is bool or not supplied is bool or not order is String: return false
	if released.size() > 4: return false
	for id in released:
		if id not in CAPTIVE_IDS or not released[id] is bool or released[id] != true: return false
	if order not in ["", "rescue_first", "veyne_first"]: return false
	if released.is_empty() != (order == ""): return false
	if not released.is_empty() and (not lock or not (tool or key)): return false
	if assembled and released.size() != 4: return false
	if supplied != assembled: return false
	return true

func rescue_information() -> String:
	if homecoming_completed: return "奥伦、塔文、米洛和贝伦已平安回村。伊莎与父亲团聚，归路的灯火重新亮起。"
	if core_closed: return "四人已集合，召唤核心已关闭；净化的灵光通道仍能安全回村。"
	if rescue_assembled: return "四人已在入口内侧安全点集合 · 补给已领取。" + ("仍需沿左阶击败维恩，两场战斗都必须完成。" if not veyne_defeated else "两场战斗已完成；召唤核心仍需关闭。")
	return "右院四名被掳者 · 旧灯逐人解除 %d/4。全部释放后，回入口内侧蓝灯集合点按 E 确认。先救人可先获补给，先打维恩可先取钥印；两场战斗都必须完成，无隐藏倒计时。" % rescue_released.size()

func veyne_information() -> String:
	if veyne_release_key: return "维恩已败 · 解除钥印已取得。" 
	if veyne_defeated: return "维恩已败 · 在左侧裂隙祭坛按 E 取得解除钥印。"
	return "维恩 · 沿左侧石阶进入裂隙祭坛。火息离开扇区，冲锋向侧面闪避，俯冲离开落点；青色灯束不能振刀，金色爪击可振刀。"

func warden_information() -> String:
	if warden_lock_released: return "锁印已解除 · 应急解除器已取得，右院可用旧灯逐人解救。" 
	if warden_defeated: return "看守已败 · 检查右侧院内锁印装置，取得应急解除器。四位村民尚未释放。"
	return "看守守住锁印 · 沿右侧石阶进入看守院。金色正面重击可振刀；紫色震荡离开范围或闪避，不能振刀。可退回入口灯台整顿。"

func ln02_remaining() -> Array[String]:
	var remaining: Array[String] = []
	if not ln02_north_cut: remaining.append("北侧螺旋供能")
	if not ln02_south_cut: remaining.append("南侧箭纹供能")
	return remaining

func ln02_information() -> String:
	if ln02_purified: return "入口结界已净化 · " + (veyne_information() if veyne_defeated else "左阶 · 维恩：火息横移、冲锋侧闪、俯冲离开落点；金色爪击可振刀。") + "\n" + (warden_information() if warden_defeated else "右阶 · 锁印看守：重击可振刀，震荡离开范围。")
	if not ln02_revealed: return "入口有两条独立供能。按 3 装备旧灯，靠近入口按 F 显形；北侧螺旋与南侧箭纹均在封锁外。"
	if ln02_north_cut and ln02_south_cut: return "两条供能已切断 · 靠近入口右侧通行装置，按 E 用旧灯主动净化。"
	return "仍在供能：" + "、".join(ln02_remaining()) + "。可按任意顺序靠近节点按 E 切断；只断一条，另一条仍会维持结界。"

func ritual_information() -> String:
	return "维恩需要村长奥伦指出最后封印的位置，仪式尚未完成。四名被掳者的营救状态见下方记录。没有隐藏倒计时。" + ln02_information()  + rescue_information()  if ritual_record_read else "墓殿入口的石碑保存着敌方仪式记录。先在封锁外调查，再决定营救路线。"

func checkpoint_name() -> String:
	return "裂隙墓殿灯台" if current_map == MAP03 else "林缘草甸灯台" if current_map == MAP02 else "河谷村庄灯台"

# The old singleton ID remains the first actor's earned history.
const E01_IDS := ["map02_e01", "map02_e01_b"]

func roadblock_defeated() -> bool:
	return E01_IDS.all(func(id): return reward_history.has(id))

func roadblock_remaining() -> int:
	return E01_IDS.filter(func(id): return not reward_history.has(id)).size()

func settle_roadblock(point: Vector3, drop: Dictionary, id := "map02_e01") -> bool:
	if id not in E01_IDS or current_map != MAP02 or not cp02_claimed or not departure_available() or reward_history.has(id): return false
	reward_history[id] = {"xp":10,"drop":drop,"position":point,"collected":drop.is_empty()}
	experience += 10
	progression_changed.emit()
	return true

const PRESSURE_IDS := ["map02_e02_melee", "map02_e02_ranged"]

func pressure_defeated() -> bool:
	return PRESSURE_IDS.all(func(id): return reward_history.has(id))

func pressure_remaining() -> int:
	return PRESSURE_IDS.filter(func(id): return not reward_history.has(id)).size()

func acquire_mf01() -> bool:
	if mf01_acquired or current_map != MAP02 or not cp02_claimed or not pressure_defeated() or health <= 0 or recovery_pending: return false
	mf01_acquired = true
	tracked_quest = "route_record"
	progression_changed.emit()
	return true

func mf01_information() -> String:
	if not mf01_acquired: return "押送路线尚未调查。击败 E02 守卫后，调查岩石后方的固定路碑。"
	return "它们从农田绕进了林缘，这些标记能对上路边的地形。\n从草甸灯台沿泥路前行，越过两名路障守卫。岩石掩体挡住弓守箭线；绕到岩石右侧，再向前到树线旁的固定路碑。路碑前方的树根可从左侧绕行，旧灯能显露暗处的轮廓。\n返程：沿岩石右侧退回路障，再沿泥路回灯台。路碑独立于尸体，清理战场不会移除记录。\n后续押送痕迹仍待追踪，四位村民尚未获救。"

func settle_pressure(point: Vector3, drop: Dictionary, id: String) -> bool:
	if id not in PRESSURE_IDS or current_map != MAP02 or not cp02_claimed or not departure_available() or not roadblock_defeated() or reward_history.has(id) or not point.is_finite(): return false
	if not drop.is_empty() and (drop.get("id", "") not in ["healing", "lifeflame"] or drop.get("quantity", 0) != 1): return false
	reward_history[id] = {"xp":10, "drop":drop.duplicate(true), "position":point, "collected":drop.is_empty()}
	experience += 10
	progression_changed.emit()
	return true

const AMBUSH_IDS := ["map02_e03_a", "map02_e03_b"]

func ambush_defeated() -> bool:
	return AMBUSH_IDS.all(func(id): return reward_history.has(id))

func ambush_remaining() -> int:
	return AMBUSH_IDS.filter(func(id): return not reward_history.has(id)).size()

func settle_ambush(point: Vector3, drop: Dictionary, id: String) -> bool:
	if id not in AMBUSH_IDS or current_map != MAP02 or not cp02_claimed or not mf01_acquired or not e03_revealed or not pressure_defeated() or reward_history.has(id) or not point.is_finite(): return false
	if not drop.is_empty() and (drop.get("id", "") not in ["healing", "lifeflame"] or drop.get("quantity", 0) != 1): return false
	reward_history[id] = {"xp":10, "drop":drop.duplicate(true), "position":point, "collected":drop.is_empty()}
	experience += 10
	if ambush_defeated(): tracked_quest = "line"
	progression_changed.emit()
	return true

const LINE_IDS := ["map02_e04_melee_a", "map02_e04_melee_b", "map02_e04_ranged"]

func line_defense_available() -> bool:
	return current_map == MAP02 and cp02_claimed and mf01_acquired and e03_revealed and ambush_defeated() and health > 0 and not recovery_pending

func line_defeated() -> bool:
	return LINE_IDS.all(func(id): return reward_history.has(id))

func line_remaining() -> int:
	return LINE_IDS.filter(func(id): return not reward_history.has(id)).size()

func settle_line(point: Vector3, drop: Dictionary, id: String) -> bool:
	if id not in LINE_IDS or not line_defense_available() or reward_history.has(id) or not point.is_finite(): return false
	if not drop.is_empty() and (drop.get("id", "") not in ["healing", "lifeflame"] or drop.get("quantity", 0) != 1): return false
	reward_history[id] = {"xp":10, "drop":drop.duplicate(true), "position":point, "collected":drop.is_empty()}
	experience += 10
	tracked_quest = "line_record" if line_defeated() else "line"
	progression_changed.emit()
	return true

func acquire_mf02() -> bool:
	if mf02_acquired or not line_defense_available() or not line_defeated(): return false
	mf02_acquired = true
	tracked_quest = "ln01"
	progression_changed.emit()
	return true

func mf02_information() -> String:
	if not mf02_acquired: return "墓殿方向尚未查明。沿 E03 树线继续前行，清除 E04 的两名近卫与弓守，再调查固定标记。"
	return "押送队沿林路前往裂隙墓殿。石旁的结界记号指向墓殿入口，拘束仍未解除。\nMF02 标记独立于尸体；M / J 保留墓殿方向与结界记号。返程沿树线与岩石右侧回到草甸灯台。\n四位村民仍待救援。\n" + ln01_information()

func ln01_available() -> bool:
	return mf02_acquired and lamp_owned and line_defense_available() and line_defeated()

func reveal_ln01() -> bool:
	if not ln01_available() or ln01_revealed: return false
	ln01_revealed = true
	tracked_quest = "ln01"
	progression_changed.emit()
	return true

func cut_ln01_supply() -> bool:
	if not ln01_available() or not ln01_revealed or ln01_supply_cut: return false
	ln01_supply_cut = true
	progression_changed.emit()
	return true

func purify_ln01_location() -> bool:
	if not ln01_available() or not ln01_revealed or not ln01_supply_cut or ln01_location_purified: return false
	ln01_location_purified = true
	progression_changed.emit()
	return true

func ln01_information() -> String:
	if ln01_location_purified: return "林缘通道已稳定 · 敌方光纹消退。四位村民仍待救援；裂隙墓殿仍待探索。"
	if ln01_supply_cut: return "螺旋供能已切断 · 靠近箭头定位节点，按 E 用旧灯净化。"
	if ln01_revealed: return "螺旋环形是敌方供能，箭头是通道定位。先在螺旋处按 E 切断供能，再净化箭头。"
	return "沿墓殿路标向前，旧灯显露通道线路 · 3 装备旧灯，F 显形。先断螺旋供能，再净化箭头定位；线索与节点均在结界外。"

func line_supply_available() -> bool:
	return line_defense_available() and line_defeated() and not line_supply_claimed

func claim_line_supply() -> Dictionary:
	if not line_supply_available() or inventory == null: return {}
	var gain: Dictionary = inventory.settle_recovery_supply(20)
	if gain.is_empty(): return {}
	line_supply_claimed = true
	progression_changed.emit()
	return gain

func pressure_supply_available() -> bool:
	return cp02_claimed and pressure_defeated() and not pressure_supply_claimed

func claim_pressure_supply() -> Dictionary:
	if not pressure_supply_available() or current_map != MAP02 or health <= 0 or recovery_pending or inventory == null: return {}
	var gain: Dictionary = inventory.settle_recovery_supply(20)
	if gain.is_empty(): return {}
	pressure_supply_claimed = true
	return gain

func meadow_branch_supply_available() -> bool:
	return cp02_claimed and roadblock_defeated() and bridge_first_action == "rescue" and bridge_later_supply_due and not meadow_branch_supply_claimed

func claim_meadow_branch_supply() -> Dictionary:
	if not meadow_branch_supply_available() or current_map != MAP02 or health <= 0 or recovery_pending or inventory == null: return {}
	# A full player leaves the visible parcel pending instead of wasting it.
	if health >= 100 and (not bow_owned or arrows >= 12): return {}
	var gain: Dictionary = inventory.settle_bridge_supply()
	meadow_branch_supply_claimed = true
	return gain

func settle_guard(id: String, point: Vector3, drop: Dictionary) -> bool:
	if id not in GUARD_IDS or reward_history.has(id) or not guard_briefing_available() or not guard_briefing_acknowledged: return false
	reward_history[id] = {"xp":10,"drop":drop,"position":point,"collected":drop.is_empty()}
	experience += 10
	progression_changed.emit()
	return true

func choose(index: int) -> bool:
	var node: Dictionary = current_nodes().get(logical_node, {})
	var choices: Array = node.get("choices", [])
	if index < 0 or index >= choices.size():
		return false
	var choice: Dictionary = choices[index]
	if choice.get("confirm_departure", false):
		if dialogue_kind != "isha" or not departure_available(): return false
		departure_confirmed = true
		if "departure" not in confirmed_choices: confirmed_choices.append("departure")
	if choice.get("acknowledge_guards", false):
		if dialogue_kind != "isha" or not guard_briefing_available(): return false
		guard_briefing_acknowledged = true
		if "guard_briefing" not in confirmed_choices: confirmed_choices.append("guard_briefing")
		tracked_quest = "guards"
	if choice.get("acknowledge_bridge", false):
		if dialogue_kind != "isha" or not bridge_briefing_available(): return false
		bridge_briefing_acknowledged = true
		if "bridge_briefing" not in confirmed_choices: confirmed_choices.append("bridge_briefing")
		tracked_quest = "bridge"
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
	config.set_value("cinematic", "recovery_id", opening_recovery_id)
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
	config.set_value("opening", "map_id", current_map)
	for key in TRAINING_KEYS:
		config.set_value("training", key, get(key))
	bag_history = inventory.snapshot() if inventory else bag_history
	for key in POST_DEFAULTS: config.set_value("post_bow", key, get(key))
	config.set_value("reading", "scale", text_scale)
	config.set_value("reading", "speed", reveal_speed)
	config.set_value("reading", "instant", instant_text)
	var path := _history_path(slot)
	var error := config.save(path + ".tmp")
	if error == OK:
		error = DirAccess.rename_absolute(path + ".tmp", path)
	save_feedback = "进度已保存" if error == OK else "保存失败，请重试"
	persistence_error = "" if error == OK else save_feedback
	save_finished.emit(slot, error)
	return error

func load_progress(slot := 0) -> Dictionary:
	var path := _history_path(slot)
	var history := HISTORY_READER.read(path)
	if history.reason != "":
		persistence_error = history.reason
		return {}
	var config: ConfigFile = history.config
	var invalid := config_unavailable_reason(config, true)
	if invalid != "":
		persistence_error = invalid
		return {}
	return restore_config(config)


func restore_config(config: ConfigFile) -> Dictionary:
	# Existing adventure histories predate the presentation marker. They have
	# already crossed the village boundary and must never replay/reset progress.
	opening_completed = bool(config.get_value("cinematic", "completed", true))
	opening_recovery_id = str(config.get_value("cinematic", "recovery_id", ""))
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
	current_map = map_id if map_id in [MAP02, MAP03] else GROUND.MAP_ID
	var ground_policy = preload("res://world/map03_ground.gd") if current_map == MAP03 else preload("res://world/map02_ground.gd") if current_map == MAP02 else GROUND
	var xz: Vector2 = ground_policy.entry_xz(saved, current_map) if current_map in [MAP02, MAP03] else GROUND.restored_xz(saved, current_map)
	if current_map == MAP03 and not ln02_purified and xz.y < -7.2: xz = ground_policy.ENTRY
	if map_id != GROUND.MAP_ID and encounter_defeated and not remnant_collected:
		remnant_position = Vector3(GROUND.ENCOUNTER.x, 0, GROUND.ENCOUNTER.y)
	persistence_error = ""
	return {"position": Vector3(xz.x, saved.y if map_id == GROUND.MAP_ID else 0, xz.y), "yaw": config.get_value("opening", "yaw", 0.0), "map_id": current_map}

func objective() -> String:
	if homecoming_completed: return "四人平安归来 · 与伊莎和奥伦交谈，或沿灵光通道重访旧路。"
	if core_closed: return "召唤核心已关闭 · 祭坛旁按 E，沿安全灵光通道回村。"
	if current_map == MAP03 and rescue_assembled: return "四人已在蓝灯旁集合 · 补给已领取。" + ("仍需沿左阶击败维恩。" if not veyne_defeated else "前往左侧祭坛，用旧灯关闭召唤核心（E）。")
	if current_map == MAP03 and warden_lock_released: return "右院 · 旧灯逐人解除拘束 %d/4；全部释放后，入口内侧蓝灯旁按 E 集合。" % rescue_released.size()
	if current_map == MAP03: return "墓殿入口 · 调查右侧仪式石碑（E）；左侧蓝光通道可返回草甸" if not ritual_record_read and not ln02_revealed else ln02_information()
	if current_map == MAP02:
		if not roadblock_defeated(): return "林缘草甸 · 清除路障近战者（剩余 %d/2）；可退回灯台整顿" % roadblock_remaining()
		if not pressure_defeated(): return "E02 押送守卫（剩余 %d/2） · 沿林路前行，利用岩石挡箭；可退回灯台" % pressure_remaining()
		if mf01_acquired:
			if not ambush_defeated(): return "MF01 已记录 · E03 林缘魔痕（剩余 %d/2） · 按 3 装备旧灯，F 显形；M / J 查阅路线" % ambush_remaining() if not e03_revealed else "E03 伏击者已显形（剩余 %d/2） · 闪避或格挡突进，再反击；可退回灯台" % ambush_remaining()
			if not line_defeated(): return "E03 已清除 · 沿树线前行至 E04（剩余 %d/3）；利用岩石挡箭，优先处理弓守" % line_remaining()
			if not mf02_acquired: return "E04 已清除 · 固定石旁标记按 E 调查 MF02；另有一次恢复补给"
			return ln01_information()
		return "E02 已清除 · " + ("领取一次胜利补给；" if pressure_supply_available() else "胜利补给已领取；") + ("MF01 已记录 · M 查看农田至林缘路线，J 查看记录；后续痕迹仍待追踪" if mf01_acquired else "岩石后方固定路碑 · 按 E 调查 MF01")
	if not q01_accepted: return "救援请求 · 与广场边的伊莎交谈"
	if not sword_owned: return "出发前的训练 · 转身沿土路，到木屋旁找赫斯"
	if not practice_hit: return "剑练习 · 用剑击中赫斯旁的草靶"
	if not practice_defense: return "防御练习 · 靠近赫斯，挡住或躲开模拟攻击"
	if not encounter_defeated: return "初场实战 · 沿土路到河边；退回赫斯处可脱离"
	if not remnant_collected: return "初战获胜 · 靠近金色残响自动拾取经验"
	if not bow_owned: return "巡路弓 · 找草地边的罗恩"
	if not bow_training_complete: return "弓练习 · 瞄准罗恩前方草靶，蓄力后松开；罗恩处免费补箭"
	if not lamp_owned: return "奥伦的旧灯 · 返回伊莎处领取"
	if not trace_revealed: return "旧灯练习 · 伊莎旁的路碑，3 装备后按 F 显形"
	if not trace_investigated: return "旧灯线索 · 靠近显形路碑按 E 调查"
	if skills.is_empty(): return "首次升级 · 按 K 选择火焰或雷电"
	if not element_practice_complete: return "元素练习 · 罗恩草靶旁，4 火焰 / 5 雷电；可重复尝试"
	if not bridge_resident_rescued or not bridge_lamp_lit: return bridge_objective()
	# Bridge patrols are optional encounters, not departure prerequisites. Project
	# the same authoritative bridge/guard facts used by the farewell and pillar.
	return guard_objective()

func guard_objective() -> String:
	if not guard_briefing_acknowledged: return "桥头已恢复 · 返回伊莎处听取柱群守卫信息"
	if not guards_defeated(): return "通道守卫 · 过石桥沿对岸林路到蓝色柱群；两名近战、一名弓守，可用岩石挡箭"
	return "离村准备已确认 · 过桥前往蓝色柱群，按 E 出发" if departure_confirmed else "通道守卫已击败 · 返回伊莎处确认离村"

func _mcp_state() -> Dictionary:
	var observation := {"opening_completed": opening_completed, "logical_node": logical_node, "conversation_active": conversation_active, "q01_accepted": q01_accepted, "reward_committed": q01_reward_committed, "experience": experience, "confirmed_choices": confirmed_choices, "objective": objective(), "save_feedback": save_feedback, "training": training_snapshot(), "preferences": preference_snapshot()}
	# Retain the nested observation while exposing its existing scalar history
	# facts to bounded selectors. Never use adventure_snapshot(): it updates bag_history.
	for key in TRAINING_KEYS + POST_DEFAULTS.keys():
		var fact: Variant = get(key)
		if typeof(fact) in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING]:
			observation[key] = fact
	for key in ["guard_melee_a_reward_state", "guard_melee_b_reward_state", "guard_ranged_reward_state", "guard_melee_a_xp", "guard_melee_b_xp", "guard_ranged_xp"]:
		observation[key] = get(key)
	for id in CAPTIVE_IDS: observation["rescue_" + id + "_released"] = rescue_released.has(id)
	observation.rescue_released_count = rescue_released.size()
	observation.merge(audio_observation())
	return observation

func training_snapshot() -> Dictionary:
	var facts := {}
	for key in TRAINING_KEYS: facts[key] = get(key)
	for key in POST_DEFAULTS: facts[key] = get(key)
	return facts

func reset_adventure() -> void:
	for key in POST_DEFAULTS: set(key, POST_DEFAULTS[key].duplicate(true) if POST_DEFAULTS[key] is Dictionary else POST_DEFAULTS[key])
	if inventory: inventory.restore()
	opening_completed = false
	opening_recovery_id = ""
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
	for key in ["opening_completed", "opening_recovery_id", "logical_node", "conversation_active", "q01_accepted", "q01_reward_committed", "experience", "confirmed_choices", "reward_feedback", "text_scale", "reveal_speed", "instant_text", "persistence_error", "tracked_quest", "tracker_collapsed"]:
		snapshot[key] = get(key)
	return snapshot.duplicate(true)


func restore_adventure(snapshot: Dictionary) -> void:
	for key in snapshot:
		if key not in PREFERENCE_DEFAULTS: set(key, snapshot[key])
	if inventory: inventory.restore()


func _history_path(slot: int) -> String:
	return SAVE_PATH if slot == 0 else "user://isha_slot_%d.cfg" % slot

func has_adventure_history() -> bool:
	return FileAccess.file_exists(_history_path(0))

func opening_recovery_path() -> String:
	return OPENING_RECOVERY_PATH

func begin_opening_recovery() -> Error:
	# Presentation intent only: never overwrite committed adventure/manual slots,
	# mutate inventory, or award a checkpoint before the world has safe support.
	var config := ConfigFile.new()
	config.set_value("presentation", "version", 1)
	config.set_value("presentation", "id", Crypto.new().generate_random_bytes(16).hex_encode())
	var path := opening_recovery_path()
	var error := config.save(path + ".tmp")
	if error == OK: error = DirAccess.rename_absolute(path + ".tmp", path)
	persistence_error = "" if error == OK else "无法保存开场恢复边界。原有进度已保留，请重试。"
	return error

func opening_recovery() -> Dictionary:
	var path := opening_recovery_path()
	if not FileAccess.file_exists(path): return {"pending":false, "id":"", "reason":""}
	var record: Dictionary = HISTORY_READER.read(path)
	if record.reason != "": return {"pending":false, "id":"", "reason":"开场恢复记录无法读取；可加载原有存档或重试新游戏。"}
	var config: ConfigFile = record.config
	var id: Variant = config.get_value("presentation", "id", "")
	var version: Variant = config.get_value("presentation", "version", 0)
	if not version is int or version != 1 or not id is String or id.length() != 32 or not id.is_valid_hex_number():
		return {"pending":false, "id":"", "reason":"开场恢复记录无效；可加载原有存档或重试新游戏。"}
	# A crash between the atomic world commit and marker cleanup must not replay
	# New Game or erase the adventure just committed. The commit token is the
	# authority, not whether deleting the now-stale intent file succeeded.
	var committed: Dictionary = HISTORY_READER.read(_history_path(0))
	if committed.reason == "" and config_unavailable_reason(committed.config, true) == "":
		if committed.config.get_value("cinematic", "completed", true) == true and committed.config.get_value("cinematic", "recovery_id", "") == id:
			return {"pending":false, "id":"", "reason":""}
	return {"pending":true, "id":id, "reason":""}

func continue_unavailable_reason() -> String:
	if opening_recovery().pending: return ""
	return slot_unavailable_reason(0, true)

func slot_needs_opening(slot: int) -> bool:
	var history: Dictionary = HISTORY_READER.read(_history_path(slot))
	if history.reason != "" or config_unavailable_reason(history.config, true) != "": return false
	# Legacy histories have already crossed the presentation boundary.
	return history.config.get_value("cinematic", "completed", true) == false

func clear_opening_recovery() -> Error:
	var path := opening_recovery_path()
	return DirAccess.remove_absolute(path) if FileAccess.file_exists(path) else OK

func slot_unavailable_reason(slot: int, allow_depleted := false) -> String:
	var path := _history_path(slot)
	var history := HISTORY_READER.read(path)
	if history.reason != "": return history.reason
	return config_unavailable_reason(history.config, allow_depleted)


func config_unavailable_reason(config: ConfigFile, allow_depleted := false) -> String:
	# A null ConfigFile default itself logs an error for a missing key.
	if not config.has_section_key("opening", "position"): return "存档位置无效"
	var saved_position: Variant = config.get_value("opening", "position", Vector3.ZERO)
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
	if node.begins_with("END") and not config.get_value("post_bow","homecoming_completed",false): return "存档团聚对话前置无效"
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
	for key in ["lamp_owned", "trace_revealed", "trace_investigated", "lamp_reward_committed", "element_practice_complete", "bridge_briefing_acknowledged", "guard_briefing_acknowledged", "guard_interlude_seen", "bridge_resident_rescued", "bridge_lamp_lit", "bridge_supply_claimed", "bridge_later_supply_due"]:
		if not config.get_value("post_bow", key, false) is bool: return "存档旧灯进度无效"
	var bridge_facts := {}
	for key in ["bridge_resident_rescued", "bridge_lamp_lit", "bridge_first_action", "bridge_supply_claimed", "bridge_later_supply_due"]:
		bridge_facts[key] = config.get_value("post_bow", key, POST_DEFAULTS[key])
	if not valid_bridge_facts(bridge_facts): return "存档桥头行动无效"
	if bridge_facts.bridge_first_action != "":
		if not config.get_value("opening", "accepted", false): return "存档桥头行动无效"
		for key in ["sword_owned", "remnant_collected", "bow_training_complete"]:
			if not config.get_value("training", key, false): return "存档桥头行动无效"
		for key in ["lamp_owned", "trace_investigated", "element_practice_complete"]:
			if not config.get_value("post_bow", key, false): return "存档桥头行动无效"
		var bridge_skills: Variant = config.get_value("post_bow", "skills", {})
		if not bridge_skills is Dictionary or bridge_skills.is_empty(): return "存档桥头行动无效"
	# New briefing nodes require actual preparation. Missing knowledge in an
	# older history defaults to false, never to an automatically chosen answer.
	if node in ["B01", "B02", "B03", "B04", "B05"] or config.get_value("post_bow", "bridge_briefing_acknowledged", false):
		if not config.get_value("opening", "accepted", false): return "存档桥头信息无效"
		for key in ["sword_owned", "remnant_collected", "bow_training_complete"]:
			if not config.get_value("training", key, false): return "存档桥头信息无效"
		for key in ["lamp_owned", "trace_investigated", "element_practice_complete"]:
			if not config.get_value("post_bow", key, false): return "存档桥头信息无效"
		var briefing_skills: Variant = config.get_value("post_bow", "skills", {})
		if not briefing_skills is Dictionary or briefing_skills.is_empty(): return "存档桥头信息无效"
		if node in ["B01", "B02", "B03", "B04", "B05"] and config.get_value("training", "dialogue_kind", "isha") != "isha": return "存档桥头信息无效"
		if (node == "B04" or (node == "B05" and bridge_facts.bridge_first_action == "")) and not config.get_value("post_bow", "bridge_briefing_acknowledged", false): return "存档桥头信息无效"
	for key in ["skills", "reward_history", "bag_history"]:
		if not config.get_value("post_bow", key, {}) is Dictionary: return "存档物品进度无效"
	if not preload("res://inventory/product_inventory.gd").valid_history(config.get_value("post_bow", "bag_history", {})): return "存档背包无效"
	var saved_skills: Dictionary = config.get_value("post_bow", "skills", {})
	for key in saved_skills:
		if key not in ["fire", "lightning"] or saved_skills[key] != 1: return "存档技能无效"
	if saved_skills.size() > earned_points(int(xp)): return "存档技能点无效"
	var rewards: Dictionary = config.get_value("post_bow", "reward_history", {})
	for id in rewards:
		if id not in ["bridge_patrol_a","bridge_patrol_b"] + E01_IDS + PRESSURE_IDS + AMBUSH_IDS + LINE_IDS + GUARD_IDS or not rewards[id] is Dictionary: return "存档掉落无效"
		var reward: Dictionary = rewards[id]
		if reward.get("xp",0) != 10 or not reward.get("collected",false) is bool: return "存档掉落无效"
		var position: Variant = reward.get("position",Vector3.INF)
		if not position is Vector3 or not position.is_finite(): return "存档掉落位置无效"
		var drop: Variant = reward.get("drop",{})
		if not drop is Dictionary: return "存档掉落物品无效"
		if not drop.is_empty() and (drop.get("id","") not in ["healing","lifeflame"] or drop.get("quantity",0) != 1): return "存档掉落物品无效"
	var guard_started: bool = config.get_value("post_bow", "guard_briefing_acknowledged", false)
	var guard_seen: bool = config.get_value("post_bow", "guard_interlude_seen", false)
	if guard_seen and not guard_started: return "存档守卫演出无效"
	if str(node).begins_with("G") or guard_started or GUARD_IDS.any(func(id): return rewards.has(id)):
		if not bridge_facts.bridge_resident_rescued or not bridge_facts.bridge_lamp_lit: return "存档守卫前置无效"
		if not config.get_value("post_bow", "element_practice_complete", false): return "存档守卫前置无效"
		if str(node).begins_with("G") and config.get_value("training", "dialogue_kind", "isha") != "isha": return "存档守卫对话无效"
		if (node == "G03" or GUARD_IDS.any(func(id): return rewards.has(id))) and not guard_started: return "存档守卫信息无效"
		if node == "G04" and not GUARD_IDS.all(func(id): return rewards.has(id)): return "存档守卫结果无效"
	if xp < rewards.size() * 10: return "存档固定奖励无效"
	if not valid_dynamic_facts(config.get_value("post_bow", "dynamic_serial", 0), config.get_value("post_bow", "dynamic_remaining", 120.0), config.get_value("post_bow", "dynamic_instances", {})): return "存档动态遭遇无效"
	if config.get_value("post_bow", "dynamic_serial", 0) > 0 and not config.get_value("post_bow", "element_practice_complete", false): return "存档动态遭遇前置无效"
	var collected_xp := 0
	for record in config.get_value("post_bow", "dynamic_instances", {}).values():
		if record.status == "collected": collected_xp += 10
	if xp < rewards.size() * 10 + collected_xp: return "存档动态奖励无效"
	var departure: Variant = config.get_value("post_bow", "departure_confirmed", false)
	var claimed: Variant = config.get_value("post_bow", "cp02_claimed", false)
	var current: Variant = config.get_value("post_bow", "current_map", GROUND.MAP_ID)
	if not departure is bool or not claimed is bool or not current is String: return "存档章节无效"
	if current not in [GROUND.MAP_ID, MAP02, MAP03]: return "存档章节无效"
	if departure and (not guard_started or not GUARD_IDS.all(func(id): return rewards.has(id)) or not config.get_value("training", "practice_hit", false) or not config.get_value("training", "practice_defense", false) or not config.get_value("training", "encounter_defeated", false) or not config.get_value("post_bow", "trace_revealed", false)): return "存档离村前置无效"
	if (claimed or current in [MAP02, MAP03] or map_id in [MAP02, MAP03] or (E01_IDS + PRESSURE_IDS + AMBUSH_IDS + LINE_IDS).any(func(id): return rewards.has(id))) and not departure: return "存档草甸前置无效"
	if (map_id in [MAP02, MAP03] or current in [MAP02, MAP03] or (E01_IDS + PRESSURE_IDS + AMBUSH_IDS + LINE_IDS).any(func(id): return rewards.has(id))) and not claimed: return "存档检查点无效"
	var meadow_records: Variant = config.get_value("post_bow", "meadow_dynamic_instances", {})
	var meadow_serial: Variant = config.get_value("post_bow", "meadow_dynamic_serial", 0)
	if not valid_meadow_dynamic_facts(meadow_serial, config.get_value("post_bow", "meadow_dynamic_remaining", 120.0), config.get_value("post_bow", "meadow_dynamic_groups", 0), meadow_records): return "存档草甸动态遭遇无效"
	if meadow_serial > 0 and (not departure or not claimed or not config.get_value("post_bow", "mf01_acquired", false)): return "存档草甸动态前置无效"
	for record in meadow_records.values():
		if record.status == "collected": collected_xp += int(record.xp)
	if xp < rewards.size() * 10 + collected_xp: return "存档草甸动态奖励无效"
	var e02_earned: bool = PRESSURE_IDS.any(func(id): return rewards.has(id))
	var e02_complete: bool = PRESSURE_IDS.all(func(id): return rewards.has(id))
	var e01_complete: bool = E01_IDS.all(func(id): return rewards.has(id))
	for key in ["pressure_supply_claimed", "meadow_branch_supply_claimed"]:
		if not config.get_value("post_bow", key, false) is bool: return "存档草甸补给无效"
	if e02_earned and not e01_complete: return "存档押送守卫前置无效"
	if config.get_value("post_bow", "pressure_supply_claimed", false) and not e02_complete: return "存档胜利补给无效"
	if config.get_value("post_bow", "meadow_branch_supply_claimed", false) and (not claimed or not e01_complete or bridge_facts.bridge_first_action != "rescue" or not bridge_facts.bridge_later_supply_due): return "存档分支补给无效"
	if not config.get_value("post_bow", "mf01_acquired", false) is bool: return "存档路线记录无效"
	if config.get_value("post_bow", "mf01_acquired", false) and (not claimed or not e02_complete): return "存档路线记录前置无效"
	var revealed: Variant = config.get_value("post_bow", "e03_revealed", false)
	if not revealed is bool: return "存档伏击显形无效"
	if (revealed or AMBUSH_IDS.any(func(id): return rewards.has(id))) and (not claimed or not e02_complete or not config.get_value("post_bow", "mf01_acquired", false)): return "存档伏击前置无效"
	var line_earned: bool = LINE_IDS.any(func(id): return rewards.has(id))
	var line_complete: bool = LINE_IDS.all(func(id): return rewards.has(id))
	var e03_complete: bool = AMBUSH_IDS.all(func(id): return rewards.has(id))
	for key in ["mf02_acquired", "line_supply_claimed"]:
		if not config.get_value("post_bow", key, false) is bool: return "存档墓殿路线记录无效"
	if line_earned and (not e03_complete or not revealed): return "存档林路防线前置无效"
	if (config.get_value("post_bow", "mf02_acquired", false) or config.get_value("post_bow", "line_supply_claimed", false)) and (not claimed or not e03_complete or not revealed or not line_complete): return "存档林路调查前置无效"
	for key in ["ln01_revealed", "ln01_supply_cut", "ln01_location_purified"]:
		if typeof(config.get_value("post_bow", key, false)) != TYPE_BOOL: return "存档通道线路状态无效"
	var circuit_revealed: bool = config.get_value("post_bow", "ln01_revealed", false)
	var supply_cut: bool = config.get_value("post_bow", "ln01_supply_cut", false)
	var purified: bool = config.get_value("post_bow", "ln01_location_purified", false)
	if (circuit_revealed or supply_cut or purified) and (not config.get_value("post_bow", "mf02_acquired", false) or not config.get_value("post_bow", "lamp_owned", false)): return "存档通道调查前置无效"
	if supply_cut and not circuit_revealed or purified and not supply_cut: return "存档通道线路顺序无效"
	for key in ["sq02_record_found", "sq02_completed", "veyne_node_closed"]:
		if typeof(config.get_value("post_bow", key, false)) != TYPE_BOOL: return "存档增援情报状态无效"
	var intelligence_found: bool = config.get_value("post_bow", "sq02_record_found", false)
	var intelligence_complete: bool = config.get_value("post_bow", "sq02_completed", false)
	var node_closed: bool = config.get_value("post_bow", "veyne_node_closed", false)
	if intelligence_found and (not claimed or not e02_complete): return "存档布防记录前置无效"
	if intelligence_complete and not intelligence_found: return "存档情报核对前置无效"
	if node_closed and (not intelligence_complete or not config.get_value("post_bow", "ritual_record_read", false) or not config.get_value("post_bow", "ln02_purified", false)): return "存档增援节点前置无效"
	var tomb_claimed: Variant = config.get_value("post_bow", "cp03_claimed", false)
	var record_read: Variant = config.get_value("post_bow", "ritual_record_read", false)
	if not tomb_claimed is bool or not record_read is bool: return "存档墓殿记录无效"
	if (tomb_claimed or current == MAP03 or map_id == MAP03 or record_read) and (not claimed or not e01_complete or not e02_complete or not e03_complete or not line_complete or not revealed or not config.get_value("post_bow", "mf01_acquired", false) or not config.get_value("post_bow", "mf02_acquired", false) or not purified): return "存档墓殿前置无效"
	if (current == MAP03 or map_id == MAP03 or record_read) and not tomb_claimed: return "存档墓殿检查点无效"
	for key in ["ln02_revealed", "ln02_north_cut", "ln02_south_cut", "ln02_purified"]:
		if typeof(config.get_value("post_bow", key, false)) != TYPE_BOOL: return "存档入口线路状态无效"
	var entrance_revealed: bool = config.get_value("post_bow", "ln02_revealed", false)
	var north_cut: bool = config.get_value("post_bow", "ln02_north_cut", false)
	var south_cut: bool = config.get_value("post_bow", "ln02_south_cut", false)
	var entrance_purified: bool = config.get_value("post_bow", "ln02_purified", false)
	if (entrance_revealed or north_cut or south_cut or entrance_purified) and (not tomb_claimed or not config.get_value("post_bow", "lamp_owned", false)): return "存档入口调查前置无效"
	if (north_cut or south_cut) and not entrance_revealed or entrance_purified and (not north_cut or not south_cut): return "存档入口线路完成条件无效"
	for key in ["warden_defeated","warden_lock_released","emergency_release_tool"]:
		if typeof(config.get_value("post_bow",key,false)) != TYPE_BOOL: return "存档看守事实无效"
	var boss_defeated: bool = config.get_value("post_bow","warden_defeated",false)
	var lock_released: bool = config.get_value("post_bow","warden_lock_released",false)
	var tool: bool = config.get_value("post_bow","emergency_release_tool",false)
	if boss_defeated and not entrance_purified: return "存档看守前置无效"
	if lock_released and not boss_defeated or tool != lock_released: return "存档解除装置条件无效"
	for key in ["veyne_defeated", "veyne_release_key"]:
		if typeof(config.get_value("post_bow",key,false)) != TYPE_BOOL: return "存档维恩事实无效"
	var caster_defeated: bool = config.get_value("post_bow","veyne_defeated",false)
	var release_key: bool = config.get_value("post_bow","veyne_release_key",false)
	if caster_defeated and not entrance_purified: return "存档维恩前置无效"
	if release_key and not caster_defeated: return "存档解除钥印条件无效"
	if not valid_rescue_facts(config.get_value("post_bow","rescue_released",{}), config.get_value("post_bow","rescue_assembled",false), config.get_value("post_bow","rescue_supply_claimed",false), config.get_value("post_bow","rescue_order",""), lock_released, tool, release_key): return "存档营救事实无效"
	if config.get_value("post_bow","rescue_order","") == "veyne_first" and not caster_defeated: return "存档营救顺序无效"
	for key in ["core_closed", "homecoming_completed"]:
		if typeof(config.get_value("post_bow",key,false)) != TYPE_BOOL: return "存档终局事实无效"
	var closed: bool = config.get_value("post_bow","core_closed",false)
	var returned: bool = config.get_value("post_bow","homecoming_completed",false)
	if closed and (not boss_defeated or not caster_defeated or not config.get_value("post_bow","rescue_assembled",false) or not entrance_purified or not config.get_value("post_bow","lamp_owned",false)): return "存档核心关闭前置无效"
	if returned and not closed: return "存档返乡前置无效"
	if config.has_section_key("post_bow", "current_map") and current != map_id: return "存档地图边界无效"
	return ""


func save_preferences() -> Error:
	apply_preferences()
	var config := ConfigFile.new()
	for key in PREFERENCE_DEFAULTS: config.set_value("settings", key, get(key))
	var error := config.save("user://adventure_preferences.cfg.tmp")
	if error == OK: error = DirAccess.rename_absolute("user://adventure_preferences.cfg.tmp", "user://adventure_preferences.cfg")
	preference_save_error = error
	preference_error = "" if error == OK else "设置仅本次生效 · 保存失败，请重试"
	return error

func load_preferences() -> void:
	var config := ConfigFile.new()
	preference_load_error = config.load("user://adventure_preferences.cfg")
	if preference_load_error == OK:
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
	var path := _history_path(slot)
	var history := HISTORY_READER.read(path)
	var reason: String = history.reason
	if reason == "": reason = config_unavailable_reason(history.config, slot == 0)
	var facts := {"slot": slot, "reason": reason}
	if reason != "": return facts
	var config: ConfigFile = history.config
	facts.chapter = "第三章 · 裂隙墓殿" if config.get_value("opening", "map_id", "") == MAP03 else "第二章 · 林缘草甸" if config.get_value("opening", "map_id", "") == MAP02 else "第一章 · 河谷聚落"
	facts.time = Time.get_datetime_string_from_unix_time(FileAccess.get_modified_time(path)).replace("T", " ")
	facts.checkpoint = "裂隙墓殿灯台" if config.get_value("opening", "map_id", "") == MAP03 else "林缘草甸灯台" if config.get_value("opening", "map_id", "") == MAP02 else "河谷村庄灯台"
	facts.experience = int(config.get_value("opening", "experience", 0))
	facts.lives = int(config.get_value("training", "lives", 3))
	facts.arrows = int(config.get_value("training", "arrows", 0))
	facts.progress = "弓练习已完成" if config.get_value("training", "bow_training_complete", false) else ("已取得巡路弓" if config.get_value("training", "bow_owned", false) else ("已取得巡路剑" if config.get_value("training", "sword_owned", false) else ("已接受救援请求" if config.get_value("opening", "accepted", false) else "伊莎的求援")))
	return facts

# Read-only journal projection. These rows never grant equipment or rewards.
func quest_entries() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	rows.append({"id": "rescue", "title": "伊莎的请求", "complete": homecoming_completed,
		"context": ritual_information() if cp03_claimed else "伊莎的父亲和三位村民被怪物带走。出发前，先在河谷聚落做好准备。" if q01_accepted else "广场边的伊莎似乎需要帮助。靠近她，听听发生了什么。",
		"action": objective(), "steps": (["答应伊莎的求援"] + ([rescue_information()] if cp03_claimed else [])) if q01_accepted else []})
	if q01_accepted:
		var steps: Array[String] = []
		if sword_owned: steps.append("从木屋旁的赫斯处取得巡路剑")
		if practice_hit: steps.append("用剑击中草靶")
		if practice_defense: steps.append("挡住或躲开模拟攻击")
		if practice_parry: steps.append("成功振刀")
		if encounter_defeated: steps.append("击败路边的训练怪")
		if remnant_collected: steps.append("拾取初战残响")
		rows.append({"id": "sword", "title": "出发前的训练", "complete": remnant_collected,
			"context": "从灯台转身沿土路，到木屋旁向赫斯学剑。先练草靶，再沿土路到河边挑战训练怪；退回赫斯处可脱离。",
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
		var steps: Array[String] = []
		if bridge_briefing_acknowledged: steps.append("听取伊莎的桥头信息：受困居民另有其人，四名被掳者仍待救援")
		if bridge_resident_rescued: steps.append("桥边居民已救出 · 不是四名被掳者")
		if bridge_lamp_lit: steps.append("桥灯已恢复 · 通路照明可见")
		if bridge_supply_claimed: steps.append("桥头分支补给已领取")
		if bridge_later_supply_due: steps.append("先救人 · 罗恩的前方安全点补给" + ("已交付" if meadow_branch_supply_claimed else "待交付"))
		rows.append({"id":"bridge", "title":"石桥对岸", "complete":false,
			"context":bridge_response(),
			"action":bridge_objective(), "steps":steps})
	if guard_briefing_available():
		var steps: Array[String] = []
		if guard_briefing_acknowledged: steps.append("伊莎交代：奥伦与三位村民仍被掳，追踪前先清除守卫")
		if departure_confirmed: steps.append("已与伊莎确认离村 · 蓝色通道已开放")
		for id in GUARD_IDS:
			if reward_history.has(id): steps.append("弓守已击败" if id == "channel_ranged" else "柱群近战守卫已击败")
		rows.append({"id":"guards", "title":"柱群守卫", "complete":guards_defeated(), "context":"两名近战守卫掩护一名弓守。岩石能挡箭；可退回桥头整顿。胜利只解除守卫条件，四名被掳者仍待救援。", "action":guard_objective(), "steps":steps})
	if cp02_claimed:
		rows.append({"id":"meadow", "title":"林缘草甸", "complete":false, "context":"灯台是安全的落脚点。两名路障近战者抬手后出拳；可退回灯台整顿。四名被掳者仍待救援。", "action":objective(), "steps":["林缘灯台已启用"] + E01_IDS.filter(func(id): return reward_history.has(id)).map(func(id): return "路障前哨已击败" if id == "map02_e01" else "路障后哨已击败") + (["E01 路障已清除 · 前往 E02 调查押送路线"] if roadblock_defeated() else [])})
	if cp02_claimed and roadblock_defeated():
		var steps: Array[String] = []
		for id in PRESSURE_IDS:
			if reward_history.has(id): steps.append("押送近卫已击败" if id == PRESSURE_IDS[0] else "押送弓守已击败")
		if pressure_supply_claimed: steps.append("一次胜利恢复补给已领取")
		if meadow_branch_supply_claimed: steps.append("罗恩的救人分支补给已交付")
		rows.append({"id":"pressure", "title":"押送路线", "complete":pressure_defeated(), "context":"一名近卫掩护弓守。沿林路利用岩石阻断箭线，近身或用弓反击；退回灯台可脱离。战胜守卫后线索仍须调查。", "action":objective(), "steps":steps})
	if cp02_claimed:
		rows.append({"id":"ambush", "title":"林缘魔痕 · E03", "complete":ambush_defeated(), "context":"MF01 路碑前方的树线有遮掩轮廓。旧灯 F 照亮周围 7 米；显形后先辨认，再闪避或格挡抬手突进。", "action":objective(), "steps":(["伏击者已显形"] if e03_revealed else []) + AMBUSH_IDS.filter(func(id): return reward_history.has(id)).map(func(id): return "赤角伏击者已击败" if id == AMBUSH_IDS[0] else "铁颚伏击者已击败")})
		rows.append({"id":"route_record", "title":"农田至林缘 · MF01", "complete":false, "context":mf01_information(), "action":objective() if mf01_acquired else "击败押送守卫，调查岩石后方的固定路碑", "steps":["固定路线记录已取得 · 保存后可继续查阅"] if mf01_acquired else []})
	if cp02_claimed:
		rows.append({"id":"line", "title":"林路防线 · E04", "complete":line_defeated(), "context":"两名近卫与一名弓守占据树线后的林路。用岩石阻断箭线；沿原路可退回灯台。胜利后调查固定标记，恢复补给另行领取。", "action":objective(), "steps":LINE_IDS.filter(func(id): return reward_history.has(id)).map(func(id): return "林路弓守已击败" if id == LINE_IDS[2] else "林路近卫已击败") + (["一次恢复补给已领取"] if line_supply_claimed else [])})
		rows.append({"id":"line_record", "title":"墓殿方向与结界记号 · MF02", "complete":mf02_acquired, "context":mf02_information(), "action":"M 查阅墓殿方向 · 四位村民仍待救援" if mf02_acquired else "清除 E04，调查石旁固定标记", "steps":["固定标记已记录 · 保存后可继续查阅"] if mf02_acquired else []})
	if mf02_acquired:
		rows.append({"id":"ln01", "title":"林缘通道 · 解除结界", "complete":ln01_location_purified, "context":ln01_information(), "action":"旧灯显形 → 切断螺旋供能 → 净化箭头定位", "steps":["线路已显形" if ln01_revealed else "显露线路", "供能已切断" if ln01_supply_cut else "切断供能", "通道已稳定" if ln01_location_purified else "净化定位"]})
	if cp02_claimed:
		rows.append({"id":"sq02", "title":"敌方增援情报 · SQ02", "complete":sq02_completed, "context":intelligence_information(), "action":intelligence_information(), "steps":(["完整布防记录已取得"] if sq02_record_found else []) + (["玛拉已核对情报"] if sq02_completed else []) + (["主动封住增援节点"] if veyne_node_closed else [])})
	if cp03_claimed:
		rows.append({"id":"ritual_record", "title":"墓殿入口 · 仪式记录", "complete":ritual_record_read, "context":ritual_information(), "action":objective(), "steps":["CP03 灯台已启用 · 首次加命已领取"] + ([rescue_information()] if ritual_record_read else [])})
		rows.append({"id":"ln02", "title":"墓殿入口 · 双供能结界", "complete":ln02_purified, "context":ln02_information(), "action":ln02_information(), "steps":["线路已显形" if ln02_revealed else "旧灯显形", "北侧供能已切断" if ln02_north_cut else "切断北侧供能", "南侧供能已切断" if ln02_south_cut else "切断南侧供能", "入口已净化" if ln02_purified else "主动净化入口"]})
	if cp03_claimed and ln02_purified:
		rows.append({"id":"veyne","title":"维恩 · 裂隙祭坛","complete":veyne_release_key,"context":veyne_information(),"action":veyne_information(),"steps":["维恩已败" if veyne_defeated else "击败维恩", "解除钥印已取得" if veyne_release_key else "检查祭坛钥印"]})
	if cp03_claimed and ln02_purified:
		rows.append({"id":"warden","title":"锁印看守","complete":warden_lock_released,"context":warden_information(),"action":warden_information(),"steps":["看守已败" if warden_defeated else "击败看守", "锁印已解除 · 应急解除器已取得" if warden_lock_released else "检查锁印装置"]})
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

# Physical interactions own these commits; briefing and patrol rewards never do.
func perform_bridge_action(action: String) -> bool:
	if not bridge_briefing_available() or health <= 0 or lives <= 0 or recovery_pending: return false
	if action not in ["rescue", "light"]: return false
	if (action == "rescue" and bridge_resident_rescued) or (action == "light" and bridge_lamp_lit): return false
	if bridge_first_action == "":
		bridge_first_action = action
		bridge_later_supply_due = action == "rescue"
	if action == "rescue": bridge_resident_rescued = true
	else: bridge_lamp_lit = true
	tracked_quest = "bridge"
	return true

func bridge_supply_available() -> bool:
	return bridge_first_action == "light" and bridge_lamp_lit and not bridge_supply_claimed

func claim_bridge_supply() -> Dictionary:
	if not bridge_supply_available() or health <= 0 or recovery_pending or inventory == null: return {}
	bridge_supply_claimed = true
	return inventory.settle_bridge_supply()

static func valid_bridge_facts(facts: Dictionary) -> bool:
	for key in ["bridge_resident_rescued", "bridge_lamp_lit", "bridge_supply_claimed", "bridge_later_supply_due"]:
		if not facts.get(key, false) is bool: return false
	var order: Variant = facts.get("bridge_first_action", "")
	if not order is String or order not in ["", "rescue", "light"]: return false
	var rescued: bool = facts.get("bridge_resident_rescued", false)
	var lit: bool = facts.get("bridge_lamp_lit", false)
	var claimed: bool = facts.get("bridge_supply_claimed", false)
	var due: bool = facts.get("bridge_later_supply_due", false)
	if order == "": return not rescued and not lit and not claimed and not due
	if order == "rescue": return rescued and due and not claimed
	return lit and not due

func bridge_objective() -> String:
	if not bridge_resident_rescued and not bridge_lamp_lit:
		return "桥头选择 · 草靶左侧过桥救居民，或先恢复入口桥灯；暗处有巡守，先点灯可领桥头补给"
	if not bridge_resident_rescued: return "桥灯已亮 · " + ("桥头补给可领取；" if bridge_supply_available() else "补给已交付；") + "过桥拉出受困居民"
	if not bridge_lamp_lit: return "居民已救出 · 返回桥入口恢复照明；罗恩将在前方安全点交付补给"
	if bridge_supply_available(): return "桥头两项已完成 · 回入口领取一次补给；通道守卫与离村交谈仍待完成"
	return "桥头两项已完成 · 通道守卫、伊莎离村交谈与章节通道仍待完成；更远旅程尚未开放"

func bridge_response() -> String:
	if bridge_first_action == "rescue":
		return "谢谢你先把桥边居民拉了出来。暗处的巡守很危险。" + ("桥灯也恢复了。" if bridge_lamp_lit else "请再恢复桥灯。") + ("罗恩在 E02 前的补给已经交付。" if meadow_branch_supply_claimed else "罗恩会在前方安全点、E02 前留下补给；尚未交付。") + "父亲和另三名村民仍待救援。"
	if bridge_first_action == "light":
		return "你先点亮桥灯，照清了出口和巡守。" + ("居民感谢你回来拉他出来，也记得等待。" if bridge_resident_rescued else "居民还在等你过桥拉他出来。") + ("桥头补给已经交付。" if bridge_supply_claimed else "桥入口的一次补给留给你。") + "父亲和另三名村民仍待救援，离村准备还未完成。"
	return "桥边居民不是四名被掳者。先救人要面对暗处巡守，罗恩随后在前方安全点留补给；先点灯能看清路线与巡守，立即可领桥头补给。两项都要完成，顺序由你决定。"


static func valid_dynamic_facts(serial: Variant, remaining: Variant, instances: Variant) -> bool:
	if not serial is int or serial < 0 or serial > 10000000: return false
	if not (remaining is int or remaining is float) or not is_finite(float(remaining)) or remaining < 0 or remaining > 120: return false
	if not instances is Dictionary: return false
	var active := 0
	for id in instances:
		if not id is String or not id.begins_with("ch01_dynamic_"): return false
		var suffix: String = id.trim_prefix("ch01_dynamic_")
		if not suffix.is_valid_int() or int(suffix) < 1 or int(suffix) > serial or id != "ch01_dynamic_%d" % int(suffix): return false
		var record: Variant = instances[id]
		if not record is Dictionary or record.get("status", "") not in ["active", "pending", "collected"] or record.get("xp", 0) != 10: return false
		var hp: Variant = record.get("hp", -1)
		if not (hp is int or hp is float) or not is_finite(float(hp)) or hp < 0 or hp > 42: return false
		if (record.status == "active") != (hp > 0): return false
		var home: Variant = record.get("home", Vector3.INF)
		var point: Variant = record.get("position", Vector3.INF)
		if not home is Vector3 or not home.is_finite() or not point is Vector3 or not point.is_finite() or home.distance_to(point) > 7.5: return false
		var home_xz := Vector2(home.x,home.z)
		if minf(home_xz.distance_to(Vector2(126,122)),home_xz.distance_to(Vector2(130,122))) > 1.8: return false
		if record.status == "active": active += 1
	return active <= 2

func collect_dynamic_xp(id: String) -> bool:
	if not dynamic_instances.has(id) or dynamic_instances[id].status != "pending": return false
	dynamic_instances[id].status = "collected"
	experience += 10
	return true

static func valid_meadow_dynamic_facts(serial: Variant, remaining: Variant, groups: Variant, instances: Variant) -> bool:
	# Bounded CH02 history stays separate from legacy CH01 identities.
	if not serial is int or serial < 0 or serial > 4: return false
	if not groups is int or groups < 0 or groups > 2: return false
	if serial < groups or serial > groups * 2: return false
	if not (remaining is int or remaining is float) or not is_finite(float(remaining)) or remaining < 0 or remaining > 120: return false
	if not instances is Dictionary or instances.size() != serial: return false
	var active := 0
	for id in instances:
		if not id is String or not id.begins_with("ch02_dynamic_"): return false
		var suffix: String = id.trim_prefix("ch02_dynamic_")
		if not suffix.is_valid_int() or int(suffix) < 1 or int(suffix) > serial or id != "ch02_dynamic_%d" % int(suffix): return false
		var record: Variant = instances[id]
		if not record is Dictionary or record.get("chapter") != "CH02" or record.get("instance_id") != id: return false
		var archetype: Variant = record.get("archetype", "")
		if archetype not in ["melee", "ranged", "ambusher"]: return false
		if record.get("status", "") not in ["active", "pending", "collected"] or record.get("xp", 0) != (10 if archetype == "melee" else 15): return false
		if archetype == "ambusher":
			if not record.get("revealed") is bool or not record.get("variant") is int or record.variant not in [0, 1]: return false
			if record.status != "active" and not record.revealed: return false
		var hp: Variant = record.get("hp", -1)
		if not (hp is int or hp is float) or not is_finite(float(hp)) or hp < 0 or hp > (42 if archetype == "melee" else 36): return false
		if (record.status == "active") != (hp > 0): return false
		var home: Variant = record.get("home", Vector3.INF)
		var point: Variant = record.get("position", Vector3.INF)
		if not home is Vector3 or not home.is_finite() or not point is Vector3 or not point.is_finite(): return false
		if home.x < -10 or home.x > 0 or home.z < 46 or home.z > 57 or absf(home.y) > 220 or home.distance_to(point) > 15: return false
		var loot: Variant = record.get("loot", null)
		if not loot is Array or loot.size() > 1: return false
		for drop in loot:
			if not drop is Dictionary or drop.get("id", "") not in ["healing", "lifeflame"] or not drop.get("count") is int or drop.count != 1: return false
		if record.status == "active":
			active += 1
			if not loot.is_empty(): return false
	return active <= 2

func collect_meadow_reward(id: String) -> bool:
	if not meadow_dynamic_instances.has(id) or meadow_dynamic_instances[id].status != "pending" or not is_instance_valid(inventory): return false
	var record: Dictionary = meadow_dynamic_instances[id]
	var before: Dictionary = inventory.snapshot()
	for drop in record.loot:
		if not inventory.accept(drop.id, drop.count):
			bag_history = before
			inventory.restore()
			return false
	bag_history = inventory.snapshot()
	record.status = "collected"
	experience += int(record.xp)
	progression_changed.emit()
	return true
