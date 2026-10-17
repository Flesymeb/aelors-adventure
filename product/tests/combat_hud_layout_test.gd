extends Node
## Explicit disposable geometry fixture. No actors, rewards or saves are
## created; numeric layout and cue-binding checks do not accept ordinary combat.
var observations: Dictionary = {}

class CueActor extends Node:
	var health := 100.0
	var phase := "idle"
	var attack_kind := ""
	var hurt_remaining := 0.0
	var pressure_phase := false
	var melee_events: Node = preload("res://combat/snaiel/melee_animations.gd").new()
	var cast_action: Node = preload("res://combat/snaiel/veyne_cast_action.gd").new()
	var dragon_actions: Node = preload("res://combat/veyne_dragon_actions.gd").new()
	func _init() -> void:
		add_child(melee_events)
		add_child(cast_action)
		add_child(dragon_actions)

class CueEncounter extends Node:
	var phase := "battle"
	var actor: Node

func _ready() -> void:
	observations = await run(self)

func _mcp_state() -> Dictionary:
	return {"diagnostic_fixture": true, "observations": observations}

static func run(holder: Node) -> Dictionary:
	var hud: CanvasLayer = preload("res://combat_hud.gd").new()
	hud.process_mode = Node.PROCESS_MODE_DISABLED
	holder.add_child(hud)
	hud.set_process(false)
	hud.enemy.hide()
	hud.boss_rows.hide()
	var checks := {}
	var cases: Array[Dictionary] = []
	var viewport := Vector2(1280, 720)
	var safe := Rect2(Vector2(12, viewport.y * 0.24), Vector2(viewport.x - 24, viewport.y * 0.76 - 130))
	for scale in [1.0, 1.5, 2.0]:
		var occupied: Array[Rect2] = [Rect2(Vector2(780, 180), Vector2(470, 120))]
		var raw_rows: Array[Dictionary] = []
		var case_rows: Array[Control] = []
		var separated := true
		var contained := true
		for i in 3:
			var rows := VBoxContainer.new()
			var title := Label.new()
			title.text = ["前哨守卫 · 抬手预告", "河道守卫 · 36/36", "河道守卫 · 抬手预告"][i]
			title.add_theme_font_size_override("font_size", int(17 * scale))
			rows.add_child(title)
			rows.add_child(hud.meter(Color(0.75, 0.18, 0.11), 36))
			hud.root.add_child(rows)
			case_rows.append(rows)
			await holder.get_tree().process_frame
			var anchor := Vector2(860 + i * 6, 390 + i * 4)
			var placed: bool = hud.place_enemy_bar(rows, anchor, viewport, occupied)
			await holder.get_tree().process_frame
			var rect := rows.get_global_rect()
			var prior := occupied.slice(0, occupied.size() - 1) if placed else occupied
			for other in prior:
				if rect.grow(4).intersects(other): separated = false
			contained = contained and placed and safe.encloses(rect)
			raw_rows.append({"title": title.text, "placed": placed, "position": [rect.position.x, rect.position.y], "size": [rect.size.x, rect.size.y], "minimum_size": [rows.get_combined_minimum_size().x, rows.get_combined_minimum_size().y]})
		checks["scale_%s_separated" % str(scale)] = separated
		checks["scale_%s_contained" % str(scale)] = contained
		cases.append({"scale": scale, "rows": raw_rows})
		for rows in case_rows: rows.free()
	# Exhaust every vertical candidate at the projected x. A free lateral area
	# remains: the former finite vertical search retained an overlapping origin.
	var blocked: Array[Rect2] = [Rect2(Vector2(470, safe.position.y), Vector2(320, safe.size.y))]
	var lateral: Rect2 = hud.find_enemy_bar_placement(Vector2(220, 55), Vector2(510, 300), safe, blocked)
	checks.vertical_exhaustion_uses_free_lateral_space = lateral.size != Vector2.ZERO and not lateral.grow(4).intersects(blocked[0]) and safe.encloses(lateral)
	var full: Array[Rect2] = [safe]
	checks.no_overlapping_fallback = hud.find_enemy_bar_placement(Vector2(220, 55), Vector2(510, 300), safe, full).size == Vector2.ZERO
	var empty: Array[Rect2] = []
	checks.oversized_row_rejected = hud.find_enemy_bar_placement(Vector2(2000, 55), Vector2.ZERO, safe, empty).size == Vector2.ZERO
	var cue_cases := check_boss_cues(hud, checks)
	hud.boss_rows.show()
	hud.boss_cue.show()
	hud.boss_name.text = "维恩 · 420 / 420"
	hud.boss_cue.text = "震荡蓄势 · 离开范围或闪避\n留意紫色裂隙 · 避开预告区域"
	for scale in [1.0, 1.5, 2.0]:
		hud.layout_boss(viewport, scale)
		await holder.get_tree().process_frame
		hud.layout_boss(viewport, scale)
		await holder.get_tree().process_frame
		var rect: Rect2 = hud.boss_rows.get_global_rect()
		checks["boss_scale_%s_contained" % str(scale)] = Rect2(Vector2.ZERO, viewport).encloses(rect)
		checks["boss_scale_%s_above_aim" % str(scale)] = rect.end.y < viewport.y * 0.45
		checks["boss_scale_%s_cue_unclipped" % str(scale)] = hud.boss_cue.size.y >= hud.boss_cue.get_minimum_size().y and hud.boss_cue.size.x >= hud.boss_cue.get_minimum_size().x
		cases.append({"boss_scale": scale, "position": [rect.position.x, rect.position.y], "size": [rect.size.x, rect.size.y]})
	hud.free()
	return {"checks": checks, "cases": cases, "cue_cases": cue_cases, "scope": "disposable native Control geometry and retained action-owner field binding; ordinary earned combat, camera, settings and cue timing require independent observation"}

static func check_boss_cues(hud: CanvasLayer, checks: Dictionary) -> Array[Dictionary]:
	var actor := CueActor.new()
	var encounter := CueEncounter.new()
	encounter.actor = actor
	var cases: Array[Dictionary] = []
	for kind in ["heavy", "wave", "melee", "beam", "fire_breath", "charge", "dive"]:
		var is_veyne: bool = kind not in ["heavy", "wave"]
		actor.attack_kind = kind
		actor.melee_events.attacking = kind in ["heavy", "melee"]
		actor.cast_action.executing_action = kind == "beam"
		actor.dragon_actions.kind = kind if kind in ["fire_breath", "charge", "dive"] else ""
		var rows: Array[String] = []
		for phase in ["telegraph", "attack", "recovery"]:
			actor.phase = phase
			actor.melee_events.stage = {"telegraph":"anticipation", "attack":"contact", "recovery":"recovery"}[phase]
			actor.cast_action.stage = {"telegraph":"anticipation", "attack":"active", "recovery":"recovery"}[phase]
			actor.dragon_actions.stage = {"telegraph":"warning", "attack":"active", "recovery":"recovery"}[phase]
			rows.append(hud.boss_advice(encounter, is_veyne))
		checks["%s_stage_cues_distinct" % kind] = not rows[0].is_empty() and not rows[1].is_empty() and rows[2].contains("反击") and rows[0] != rows[1] and rows[1] != rows[2]
		actor.melee_events.attacking = false
		actor.cast_action.executing_action = false
		actor.dragon_actions.kind = ""
		if kind != "wave": checks["%s_interrupted_owner_clears" % kind] = hud.boss_advice(encounter, is_veyne).is_empty()
		for phase in ["idle", "hurt", "death"]:
			actor.phase = phase
			checks["%s_%s_no_stale_recovery" % [kind, phase]] = hud.boss_advice(encounter, is_veyne).is_empty()
		cases.append({"kind": kind, "anticipation": rows[0], "active": rows[1], "recovery": rows[2]})
	actor.attack_kind = "dive"
	actor.phase = "telegraph"
	actor.dragon_actions.kind = "dive"
	actor.dragon_actions.stage = "flight"
	checks.dive_flight_retains_landing_warning = hud.boss_advice(encounter, true).contains("离开落点")
	actor.phase = "recovery"
	actor.dragon_actions.stage = "active"
	checks.phase_alone_cannot_invent_recovery = hud.boss_advice(encounter, true).is_empty()
	actor.phase = "stagger"
	actor.hurt_remaining = 0.6
	checks.live_parry_stagger_advises_counter = hud.boss_advice(encounter, true).contains("振刀奏效")
	actor.hurt_remaining = 0
	checks.expired_stagger_no_counter = hud.boss_advice(encounter, true).is_empty()
	actor.phase = "recovery"
	actor.dragon_actions.stage = "recovery"
	actor.pressure_phase = true
	checks.recovery_retains_rift_warning = hud.boss_advice(encounter, true).contains("反击") and hud.boss_advice(encounter, true).contains("紫色裂隙")
	for phase in ["waiting", "reveal", "victory"]:
		encounter.phase = phase
		checks["encounter_%s_no_stale_advice" % phase] = hud.boss_advice(encounter, true).is_empty()
	encounter.phase = "phase_transition"
	checks.phase_transition_warns_without_counter = hud.boss_advice(encounter, true).contains("先预告后生效") and not hud.boss_advice(encounter, true).contains("反击")
	encounter.phase = "battle"
	actor.health = 0
	checks.defeated_actor_no_advice = hud.boss_advice(encounter, true).is_empty()
	actor.free()
	encounter.free()
	return cases
