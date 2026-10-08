extends CharacterBody3D
## Civilian presentation reuses the retained Quaternius rig. Physics owns travel.
## The scene binds the retained village-demo presentation; no second controller.
@export var presentation_scene: PackedScene = preload("res://actors/npc_presentation.tscn")
@export var model_scene: PackedScene
var presentation: Node3D
var rescued := false
var interaction_time := 0.0
var route: Array[Vector3] = []
var route_index := 0
var movement_blocked := false

func _ready() -> void:
	presentation = presentation_scene.instantiate()
	presentation.model_scene = model_scene
	var appearance = preload("res://actors/npc_appearance.gd").new()
	appearance.hidden_parts = PackedStringArray(["Male_Ranger_Head_Hood", "Male_Ranger_Acc_Pauldron", "Male_Ranger_Body_Belt_2"])
	appearance.cloth_color = Color(0.38, 0.30, 0.22)
	presentation.appearance = appearance
	add_child(presentation)
	presentation._play_animation("Fixing_Kneeling")

func restore(rescue_fact: bool, trapped: Vector3, safe: Vector3, waypoints: Array[Vector3]) -> void:
	rescued = rescue_fact
	route = waypoints
	route_index = route.size() if rescued else 0
	interaction_time = 0
	movement_blocked = false
	global_position = safe if rescued else trapped
	velocity = Vector3.ZERO
	presentation._play_animation("Idle" if rescued else "Fixing_Kneeling")

func release() -> void:
	rescued = true
	interaction_time = 1.0
	presentation._play_animation("Interact")

func _physics_process(delta: float) -> void:
	if not rescued:
		presentation._play_animation("Fixing_Kneeling")
		return
	if interaction_time > 0:
		interaction_time = maxf(0, interaction_time - delta)
		return
	if route_index >= route.size():
		velocity = Vector3.ZERO
		presentation._play_animation("Idle_Talking")
		return
	var target := route[route_index]
	var direction := target - global_position
	direction.y = 0
	if direction.length() < 0.45:
		route_index += 1
		return
	velocity = direction.normalized() * 1.4
	velocity.y = -2.0
	var before := global_position
	move_and_slide()
	movement_blocked = global_position.distance_to(before) < 0.002
	presentation.rotation.y = atan2(direction.x, direction.z)
	presentation._play_animation("Walk")

func _mcp_state() -> Dictionary:
	return {"rescued":rescued, "route_index":route_index, "route_complete":route_index >= route.size(), "movement_blocked":movement_blocked, "animation":presentation.current_animation, "position":str(global_position)}
