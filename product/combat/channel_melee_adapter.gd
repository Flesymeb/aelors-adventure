extends "res://combat/bridge_enemy_adapter.gd"

func _ready() -> void:
	super()
	enabled_policy = func(): return encounter.combat_allowed() and navigation_ready and not encounter.state.reward_history.has(stable_id)
	health_component.max_health = 42.0
	health_component.health = 42.0
	var strategy := SnaielMeleeAttack.new()
	strategy.attack_name = &"Punch"
	strategy.damage_attributes.health = 12.0
	strategy.anticipation = 0.65
	strategy.strike_delay = 0.22
	strategy.contact_time = 0.20
	strategy.recovery = 0.70
	melee_events.stop_attacking()
	melee_events.timeline.free()
	melee_events.configure([strategy])
	acquired_cue = func(): encounter.world.training.tell("柱群近战守卫 · 逼近后抬手；岩石后可避开弓守",4)

func tick_attack(board: SnaielBlackboard) -> int:
	if not melee.attacking and not encounter.attack_slot_available(self): return SnaielBehaviorNode.FAILURE
	return super(board)

func _physics_process(delta: float) -> void:
	super(delta)
	if health > 0 and not engaged and not returning and global_position.distance_to(home) < 0.5:
		health_component.health = health_component.max_health
