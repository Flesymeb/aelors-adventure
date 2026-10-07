extends "res://combat/snaiel/scripts/entities/enemy.gd"
var encounter: Node3D
var stable_id = ""
var display_name = ""

func _ready() -> void:
	target = encounter.world.player
	enabled_policy = func(): return encounter.grounded and encounter.state.element_practice_complete and not encounter.world.training.player_locked() and not encounter.state.reward_history.has(stable_id)
	ground_query = func(point: Vector3): return preload("res://forest_ground.gd").support(encounter.world,Vector2(point.x,point.z),[get_rid(),target.get_rid()])
	contact_policy = func(damage_source,point): return encounter.world.training.player_hitbox.contact(damage_source,point)
	result_listener = encounter.world.training.resolved_enemy_contact
	attack_cue = encounter.world.training.feedback_swing
	acquired_cue = func(): encounter.world.training.tell(display_name + " · 抬手后出拳；退回石桥可脱离",4)
	dead.connect(func(): encounter.settle_defeat(self))
	super()
	var label = Label3D.new()
	label.text = display_name
	label.font = preload("res://dialogue_theme.tres").default_font
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 2.0
	label.font_size = 28
	add_child(label)

func reset_encounter() -> void:
	reset_unit(encounter.state.reward_history.has(stable_id),false)
