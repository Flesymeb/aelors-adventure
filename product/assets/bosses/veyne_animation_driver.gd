extends "res://combat/snaiel/scripts/animations/character_animations.gd"
## Complete Quaternius Demon native rig and clips. Product physics owns travel;
## casting adapts the native raised-left-arm/staff Wave, reveal the No gesture.
const NATIVE_CLIPS := {
	"Idle": "Idle", "Walk": "Walk", "Punch": "Punch",
	"HitReact": "HitReact", "Death": "Death", "Cast": "Wave", "Reveal": "No"
}
var casting_socket: BoneAttachment3D

func configure(model: Node3D) -> void:
	anim_player = model.find_child("AnimationPlayer", true, false)
	skeleton = model.find_child("Skeleton3D", true, false)
	if not anim_player or not skeleton:
		push_error("Veyne native animation player/skeleton missing")
		return
	var library := AnimationLibrary.new()
	for alias in NATIVE_CLIPS:
		var native_key: String = NATIVE_CLIPS[alias]
		if not anim_player.has_animation(native_key):
			push_error("Veyne missing imported native clip: " + native_key)
			return
		var clip: Animation = anim_player.get_animation(native_key).duplicate()
		clip.loop_mode = Animation.LOOP_LINEAR if alias in ["Idle", "Walk"] else Animation.LOOP_NONE
		anchor_horizontal_root(clip)
		library.add_animation(alias, clip)
	anim_player.add_animation_library("veyne", library)
	# The inherited defeated-save restore addresses Death in the default library.
	var native_library: AnimationLibrary = anim_player.get_animation_library("")
	native_library.remove_animation("Death")
	native_library.add_animation("Death", library.get_animation("Death"))
	anim_player.stop()
	anim_tree = AnimationTree.new()
	model.add_child(anim_tree)
	anim_tree.anim_player = anim_tree.get_path_to(anim_player)
	anim_tree.root_node = NodePath("..")
	anim_tree.tree_root = BLEND_TREE.duplicate(true)
	var action: AnimationNodeStateMachine = anim_tree.tree_root.get_node("TimedAction").get_node("Action")
	for alias in ["Idle", "Walk", "Punch", "HitReact", "Death"]:
		action.get_node(alias).animation = "veyne/" + alias
	anim_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	anim_tree.active = true
	playback = anim_tree.get("parameters/TimedAction/Action/playback")
	# The authored punch uses the right forearm. The native trident is weighted
	# entirely to Middle1.L and remains in the other hand; it is not a fist socket.
	contact_socket = BoneAttachment3D.new()
	contact_socket.name = "NativeRightPalmContact"
	contact_socket.bone_name = "LowerArm.R"
	var forearm := skeleton.find_bone(contact_socket.bone_name)
	var palm := skeleton.find_bone("Middle1.R")
	if forearm < 0 or palm < 0:
		push_error("Veyne native right hand bones missing")
		return
	skeleton.add_child(contact_socket)
	palm_offset = skeleton.get_bone_global_rest(forearm).affine_inverse() * skeleton.get_bone_global_rest(palm).origin
	var staff_hand := skeleton.find_bone("Middle1.L")
	if staff_hand < 0:
		push_error("Veyne native left casting/staff hand missing")
		return
	casting_socket = BoneAttachment3D.new()
	casting_socket.name = "NativeStaffCastingContact"
	casting_socket.bone_name = "Middle1.L"
	skeleton.add_child(casting_socket)
	idle_driver = preload("res://combat/snaiel/scripts/animations/subclasses/idle_animations.gd").new()
	movement_driver = preload("res://combat/snaiel/scripts/animations/subclasses/movement_animations.gd").new()
	hit_driver = preload("res://combat/snaiel/scripts/animations/subclasses/hit_and_death_animations.gd").new()
	for driver in [idle_driver, movement_driver, hit_driver]:
		driver.character = self
		add_child(driver)
	play("Idle", 1.0, true)

static func anchor_horizontal_root(clip: Animation) -> void:
	# Root is the native Y-up exported skeleton root. Preserve vertical pose,
	# but prevent a clip from adding X/Z motion to collision-backed movement.
	for track in clip.get_track_count():
		if clip.track_get_type(track) != Animation.TYPE_POSITION_3D or not str(clip.track_get_path(track)).ends_with(":Root"):
			continue
		if clip.track_get_key_count(track) == 0:
			continue
		var first: Vector3 = clip.track_get_key_value(track, 0)
		for key in clip.track_get_key_count(track):
			var value: Vector3 = clip.track_get_key_value(track, key)
			value.x = first.x
			value.z = first.z
			clip.track_set_key_value(track, key, value)

func play(clip: String, speed: float = 1.0, restart := false) -> void:
	if clip in ["Cast", "Reveal"]:
		anim_tree.active = false
		if active_clip != clip or restart:
			anim_player.speed_scale = 1.0
			anim_player.play("veyne/" + clip, 0.08, speed)
		else:
			anim_player.speed_scale = speed
		active_clip = clip
		return
	if not anim_tree.active:
		anim_player.stop()
		anim_player.speed_scale = 1.0
		anim_tree.active = true
	super(clip, speed, restart)

func set_speed(speed: float) -> void:
	if anim_tree.active:
		super(speed)
	else:
		anim_player.speed_scale = speed

func get_state_bindings() -> Dictionary:
	return NATIVE_CLIPS.duplicate()

func casting_position() -> Vector3:
	return casting_socket.global_position if is_instance_valid(casting_socket) else fist_position()

func _mcp_state() -> Dictionary:
	var result := super()
	result["native_states"] = NATIVE_CLIPS.duplicate()
	result["native_visual_forward"] = "+Z"
	result["native_staff_bone"] = "Middle1.L"
	result["casting_position"] = casting_position()
	return result
