extends "res://combat/channel_melee_adapter.gd"
## Same Snaiel movement, fist contact, health and animation owner.
func _ready() -> void:
	# The scene binds the retained Ranger and driver directly. Complete its
	# head/appearance before the combat unit initializes sockets.
	var guard: Node3D = get_node("Model")
	var rig: Skeleton3D = guard.find_child("Skeleton3D", true, false)
	preload("res://ranger_head_assembly.gd").assemble(rig)
	var dresser := preload("res://actors/npc_presentation.gd").new()
	dresser.character_model = guard
	dresser.appearance = preload("res://assets/guards/e02_melee_appearance.tres")
	dresser._apply_appearance()
	dresser.free()
	super()
	ground_query = func(point: Vector3): return encounter.world.ground_policy.support(encounter.world, Vector2(point.x,point.z), [get_rid(),target.get_rid()])
	enabled_policy = func(): return encounter.combat_allowed() and navigation_ready and not encounter.state.reward_history.has(stable_id)
	acquired_cue = func(): encounter.world.training.tell("路障近战者 · 抬手后出拳；格挡、闪避后反击，退回灯台可整顿", 4)
