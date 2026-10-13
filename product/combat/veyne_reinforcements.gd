extends Node3D
## Two temporary melee actors on the retained Orc rig; no durable reward owner.
var encounter: Node3D
var units: Array = []
var wave_count := 0
var placement_failed := false

class Reinforcement extends "res://combat/snaiel/scripts/entities/enemy.gd":
	var encounter: Node3D
	var stable_id := "veyne_reinforcement"
	var display_name := "裂隙近战者"
	func _ready() -> void:
		target = encounter.world.player
		enabled_policy = func(): return encounter.combat_allowed() and navigation_ready
		ground_query = func(point: Vector3):
			if point.x > -2.5 or point.x < -5.8 or point.z > -8.5 or point.z < -14.2: return {}
			return encounter.world.ground_policy.support(encounter.world,Vector2(point.x,point.z),[get_rid(),target.get_rid()])
		contact_policy = func(source,point): return encounter.world.training.player_hitbox.contact(source,point)
		result_listener = encounter.world.training.resolved_enemy_contact
		attack_cue = encounter.world.training.feedback_swing
		super()
		health_component.max_health = 32
		health_component.health = 32

func configure(owner: Node3D) -> void: encounter = owner

func summon() -> bool:
	if wave_count > 0: return false
	# No synthetic SQ02 state: the base encounter always uses the ordinary wave.
	wave_count += 1
	for x in [-5.0,-3.2]:
		var unit: CharacterBody3D = preload("res://combat/snaiel/scenes/entities/BaseEnemy.tscn").instantiate()
		unit.set_script(Reinforcement)
		unit.encounter = encounter
		unit.name = "RiftMelee" + str(units.size()+1)
		add_child(unit)
		if not encounter.world.ground_policy.place(encounter.world,unit,Vector2(x,-9.4)):
			placement_failed = true
			unit.queue_free()
			encounter.world.entry_failed.emit("增援落脚点缺少原生支撑。")
			return false
		unit.home = unit.global_position
		unit.build_navigation()
		unit.engaged = true
		units.append(unit)
	return true

func registry() -> Dictionary:
	var result := {}
	if not encounter.combat_allowed(): return result
	for unit in units:
		if is_instance_valid(unit) and unit.health > 0: result[unit] = unit.hitbox
	return result

func clear_wave(reset := false) -> void:
	for unit in units:
		if not is_instance_valid(unit): continue
		unit.interrupt_action()
		unit.hitbox.enabled = false
		unit.collision_layer = 0
		unit.hide()
		unit.queue_free()
	units.clear()
	if reset: wave_count = 0; placement_failed = false
