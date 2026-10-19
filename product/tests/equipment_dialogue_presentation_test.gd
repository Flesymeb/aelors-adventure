extends Node
var test_results: Dictionary = {}
var inspection: CanvasLayer
var inspection_state: Node
const ENTRY_NODES := {"isha": "D01", "hers": "H01", "ronen": "R01"}
func _ready() -> void:
	test_results = await run(self)
	inspection_state = preload("res://dialogue_state.gd").new()
	inspection = preload("res://IshaDialogue.tscn").instantiate()
	inspection.state = inspection_state
	add_child(inspection)
	show_case("hers",1.0)
func show_case(kind: String, scale: float) -> void:
	inspection_state.dialogue_kind = kind
	inspection_state.logical_node = ENTRY_NODES[kind]
	inspection_state.text_scale = scale
	inspection.opened = true
	inspection.root.show()
	inspection._show_node()
func _exit_tree() -> void:
	if is_instance_valid(inspection_state): inspection_state.free()
func _mcp_state() -> Dictionary:
	return {"diagnostic_fixture":true,"results":test_results,"inspection":inspection._mcp_state() if is_instance_valid(inspection) else null}
## Explicit isolated presentation checks. Never mounted on ordinary startup;
## no inventory grants, preference writes or adventure saves occur here.
static func run(holder: Node) -> Dictionary:
	var checks := {}
	var state: Node = preload("res://dialogue_state.gd").new()
	var dialogue: CanvasLayer = preload("res://IshaDialogue.tscn").instantiate()
	dialogue.state = state
	holder.add_child(dialogue)
	await holder.get_tree().process_frame
	var hers: AtlasTexture = load("res://assets/dialogue/hers_portrait.tres")
	var ronen: AtlasTexture = load("res://assets/dialogue/ronen_portrait.tres")
	checks.distinct_counterparts = hers != ronen and hers.region != ronen.region
	checks.clipped_regions = hers.filter_clip and ronen.filter_clip
	checks.native_alpha = hers.atlas.get_image().detect_alpha() != Image.ALPHA_NONE
	var views: Array = []
	for kind in ["isha", "hers", "ronen"]:
		state.dialogue_kind = kind
		state.logical_node = ENTRY_NODES[kind]
		dialogue.opened = true
		dialogue.root.show()
		for scale in [1.0, 1.5, 2.0]:
			state.text_scale = scale
			dialogue._show_node()
			await holder.get_tree().process_frame
			var observation: Dictionary = dialogue._mcp_state()
			views.append(observation)
			var prefix: String = "%s_%s" % [kind, str(scale)]
			checks[prefix + "_binding"] = observation.portraits_bound and observation.counterpart_portrait_path == "res://assets/dialogue/%s_portrait.tres" % kind
			checks[prefix + "_speaker"] = observation.counterpart_portrait_active and not observation.player_portrait_active
			checks[prefix + "_reading_area"] = dialogue.reading_scroll.size.x > 0 and dialogue.reading_scroll.size.y >= 60
			checks[prefix + "_separate_columns"] = dialogue.portraits[0].get_global_rect().end.x <= dialogue.panel.get_global_rect().position.x and dialogue.panel.get_global_rect().end.x <= dialogue.portraits[1].get_global_rect().position.x
			checks[prefix + "_deliberate_choices"] = not observation.reveal_complete and observation.choices_disabled
			dialogue._complete_line()
			checks[prefix + "_readable_choices"] = dialogue.reveal_complete and dialogue.choice_buttons.all(func(button): return not button.disabled)
	# Existing real player-speaker line exercises the dimming branch unchanged.
	state.dialogue_kind = "isha"
	state.logical_node = "promise"
	dialogue._show_node(true)
	checks.player_speaker_highlight = dialogue.portraits[0].modulate == Color.WHITE and dialogue.portraits[1].modulate != Color.WHITE
	state.dialogue_kind = "hers"
	state.logical_node = "H02"
	dialogue._show_node()
	dialogue.nested_menu = true
	var reveal_before: float = dialogue.reveal_count
	dialogue._process(1.0)
	checks.nested_reveal_suspended = dialogue.reveal_count == reveal_before
	dialogue.nested_menu = false
	dialogue._process(1.0)
	checks.reveal_resumed = dialogue.reveal_count > reveal_before
	checks.merge(label_ownership_checks())
	dialogue.free()
	state.free()
	return {"checks": checks, "views": views, "scope": "isolated presentation; no ordinary conversation or earned-state proof"}

static func label_ownership_checks() -> Dictionary:
	var world: Node3D = preload("res://preview_controller.gd").new()
	world.training = Node3D.new()
	world.bow_training = Node3D.new()
	world.element_abilities = Node3D.new()
	world.add_child(world.training)
	world.add_child(world.bow_training)
	world.add_child(world.element_abilities)
	var visible_cue := Label3D.new()
	var hidden_cue := Label3D.new()
	world.training.add_child(visible_cue)
	world.bow_training.add_child(hidden_cue)
	hidden_cue.hide()
	# Element practice cues are grandchildren, like the live fire/lightning
	# labels. Include a contextually hidden cue to guard against blanket show().
	var practice_target := StaticBody3D.new()
	world.element_abilities.add_child(practice_target)
	var element_cue := Label3D.new()
	var hidden_element_cue := Label3D.new()
	practice_target.add_child(element_cue)
	practice_target.add_child(hidden_element_cue)
	hidden_element_cue.hide()
	world.pause_owners = {"dialogue": true}
	world._sync_dialogue_world_labels()
	var suppressed: bool = not visible_cue.visible and not hidden_cue.visible
	var elements_suppressed: bool = not element_cue.visible and not hidden_element_cue.visible
	world.pause_owners["controls"] = true
	world._sync_dialogue_world_labels()
	var elements_under_menu: bool = not element_cue.visible and not hidden_element_cue.visible
	world.pause_owners.erase("controls")
	world._sync_dialogue_world_labels()
	var nested: bool = not visible_cue.visible and not hidden_cue.visible
	var elements_after_child: bool = not element_cue.visible and not hidden_element_cue.visible
	world.pause_owners.erase("dialogue")
	world._sync_dialogue_world_labels()
	var restored: bool = visible_cue.visible and not hidden_cue.visible
	var elements_restored: bool = element_cue.visible and not hidden_element_cue.visible
	world._sync_dialogue_world_labels()
	var repeated: bool = visible_cue.visible and not hidden_cue.visible and not visible_cue.has_meta("dialogue_cue_visibility")
	var elements_repeated: bool = element_cue.visible and not hidden_element_cue.visible and not element_cue.has_meta("dialogue_cue_visibility") and not hidden_element_cue.has_meta("dialogue_cue_visibility")
	world.free()
	return {"labels_suppressed": suppressed, "nested_labels_stay_suppressed": nested, "contextual_visibility_restored": restored, "label_restoration_idempotent": repeated,
		"element_labels_suppressed": elements_suppressed, "element_labels_under_menu": elements_under_menu, "element_labels_after_child": elements_after_child,
		"element_contextual_visibility_restored": elements_restored, "element_restoration_idempotent": elements_repeated}
