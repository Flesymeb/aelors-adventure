extends "res://combat/channel_ranged_adapter.gd"
## Retained Ranger/KayKit draw, Snaiel ranged timeline and swept arrow contact.
## E02 adds lifecycle ownership; it does not introduce another damage authority.
const WITHDRAWAL_BURST := 0.9
const WITHDRAWAL_STAND := 0.7
var withdrawal_active := false
var withdrawal_elapsed := 0.0
var withdrawal_recovery_remaining := 0.0

func _ready() -> void:
	super()
	handler.eligibility = func(): return encounter.combat_allowed() and navigation_ready and health > 0

func interrupt_action() -> void:
	super()
	engaged = false
	returning = false
	lost_time = 0
	velocity = Vector3.ZERO
	withdrawal_active = false
	withdrawal_elapsed = 0
	withdrawal_recovery_remaining = 0
	if health > 0: phase = "idle"

func reset_encounter() -> void:
	super()
	# Cooldowns and input requests belong to this disposable combat execution.
	action.cooldown = 0
	action.can_perform_action = true
	blackboard.set_value("perform_action", false)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(encounter) or not encounter.grounded: return
	if not encounter.combat_allowed():
		if engaged or returning or action.executing_action or not projectiles.is_empty(): interrupt_action()
		return
	withdrawal_recovery_remaining = maxf(0, withdrawal_recovery_remaining - delta)
	if withdrawal_active:
		withdrawal_elapsed = minf(WITHDRAWAL_BURST, withdrawal_elapsed + delta)
		if withdrawal_elapsed >= WITHDRAWAL_BURST:
			withdrawal_active = false
			withdrawal_recovery_remaining = WITHDRAWAL_STAND
	# Do not let an old blackboard request start an attack after another actor
	# acquired the encounter's attack slot during the preceding physics frame.
	if not action.executing_action and not encounter.attack_slot_available(self):
		blackboard.set_value("perform_action", false)
	super(delta)

func _move(destination: Vector3, stage: String) -> void:
	if stage != "retreat":
		withdrawal_active = false
		withdrawal_elapsed = 0
		super(destination, stage)
		return
	if withdrawal_recovery_remaining > 0:
		# A readable stationary opening after each bounded withdrawal; the
		# inherited update has already zeroed horizontal velocity this frame.
		phase = "withdrawal_recovery"
		return
	if not withdrawal_active:
		withdrawal_active = true
		withdrawal_elapsed = 0
	super(destination, stage)

func can_save() -> bool:
	if engaged or returning or phase in ["telegraph", "attack", "recovery", "hurt"] or action.executing_action: return false
	for projectile in projectiles:
		if is_instance_valid(projectile) and not projectile.settled: return false
	return true

func _mcp_state() -> Dictionary:
	var result := super()
	result.withdrawal_active = withdrawal_active
	result.withdrawal_elapsed = withdrawal_elapsed
	result.withdrawal_recovery_remaining = withdrawal_recovery_remaining
	return result
