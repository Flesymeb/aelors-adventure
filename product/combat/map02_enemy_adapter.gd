extends "res://combat/channel_melee_adapter.gd"
## Same Snaiel movement, fist contact, health and animation owner.
func _ready() -> void:
	super()
	ground_query = func(point: Vector3): return encounter.world.ground_policy.support(encounter.world, Vector2(point.x,point.z), [get_rid(),target.get_rid()])
	enabled_policy = func(): return encounter.combat_allowed() and navigation_ready and not encounter.state.reward_history.has(stable_id)
	acquired_cue = func(): encounter.world.training.tell("路障近战者 · 抬手后出拳；格挡、闪避后反击，退回灯台可整顿", 4)
