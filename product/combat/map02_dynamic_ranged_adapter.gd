extends "res://combat/map02_ranged_adapter.gd"
## Existing Ranger, bow sockets, ranged action and projectile/contact owner.
var activated := false
var archetype := "ranged"

func _ready() -> void:
	super()
	display_name = "草甸游荡弓守"
	handler.eligibility = func(): return activated and navigation_ready and encounter.combat_allowed() and health > 0
	collision_layer = 0
	hitbox.enabled = false
	visible = false

func _physics_process(delta: float) -> void:
	if not activated: return
	# A different map iteration cannot qualify this actor's own restored region.
	var map := navigation_agent.get_navigation_map()
	if not is_instance_valid(navigation_region) or NavigationServer3D.region_get_iteration_id(navigation_region.get_rid()) == 0 or NavigationServer3D.map_get_iteration_id(map) == 0:
		navigation_ready = false
		return
	if NavigationServer3D.region_get_map(navigation_region.get_rid()) != map or NavigationServer3D.map_get_closest_point(map,home).distance_to(home) > 0.75:
		navigation_ready = false
		return
	super(delta)

func restore_record(record: Dictionary) -> void:
	interrupt_action()
	home = record.home
	global_position = record.position
	health_component.health = record.hp
	hitbox.reset_contacts()
	hitbox.enabled = true
	activated = true
	visible = true
	collision_layer = 2
	phase = "idle"
	presentation.current_animation = ""
	presentation._play_animation("Idle")

func interrupt_action() -> void:
	super()
	engaged = false
	returning = false
	velocity = Vector3.ZERO
	lost_time = 0
	if health > 0:
		phase = "idle"
		if presentation:
			presentation.current_animation = ""
			presentation._play_animation("Idle")
	if is_instance_valid(navigation_agent): navigation_agent.target_position = global_position

func _mcp_state() -> Dictionary:
	var result := super()
	result.archetype = archetype
	result.activated = activated
	return result
