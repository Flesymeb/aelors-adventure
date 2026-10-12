extends "res://world/chapter_pillar.gd"
## Retains the live chapter-pillar geometry/flow unit, adapts only destination/input.
func configure(owner_world: Node3D) -> void:
	return_passage = true
	anchor = preload("res://world/map03_ground.gd").RETURN
	super(owner_world)
	var label := Label3D.new()
	label.text = "林缘草甸 · 返回通道"
	label.font = preload("res://dialogue_theme.tres").default_font
	label.position.y = 4.8
	label.font_size = 38
	label.pixel_size = 0.003
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func _physics_process(delta: float) -> void:
	# Same flow/pause clock, without inherited village destination prompts.
	if not grounded: return
	elapsed += delta
	var pulse := 0.85 if state.reduced_motion else 0.85 + sin(elapsed)*0.08
	flow.scale.x = pulse
	flow.scale.z = pulse
	light.light_energy = pulse*2
	particles.emitting = not state.reduced_motion

func interaction_prompt() -> String:
	return "[E] 返回林缘草甸" if grounded and world.travel_safe() and world.player.global_position.distance_to(global_position) < 2.5 else ""

func interact() -> bool:
	if interaction_prompt() == "": return false
	world.entry_router.travel_to(state.MAP02)
	return true

func _unhandled_input(_event: InputEvent) -> void:
	# One E recipient: the retained product world owner.
	pass

func _mcp_state() -> Dictionary:
	return {"ready":is_node_ready() and grounded,"destination":state.MAP02 if is_instance_valid(state) else null,"grounded":grounded,"eligible":interaction_prompt() != "" if grounded else null,"prompt":interaction_prompt() if grounded else "","position":str(global_position) if grounded else null}
