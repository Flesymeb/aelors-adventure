extends Node
## Snaiel CharacterAnimations recipient/driver boundary, retained product rig.
const BLEND_TREE = preload("res://combat/snaiel/animations/blend_trees/HybridEnemyBlendTree.tres")
var anim_player: AnimationPlayer
var anim_tree: AnimationTree
var playback: AnimationNodeStateMachinePlayback
var active_clip = ""
var skeleton: Skeleton3D
var contact_socket: BoneAttachment3D
var palm_offset = Vector3.ZERO
var idle_driver: Node
var movement_driver: Node
var hit_driver: Node

func configure(model: Node3D) -> void:
	anim_player = model.get_node("AnimationPlayer")
	skeleton = model.find_child("Skeleton3D", true, false)
	for key in ["Idle", "Walk", "Punch", "HitReact", "Death"]:
		if not anim_player.has_animation(key): push_error("Enemy missing imported clip: " + key)
	for key in ["Idle", "Walk"]:
		var clip = anim_player.get_animation(key).duplicate() as Animation
		clip.loop_mode = Animation.LOOP_LINEAR
		var library = anim_player.get_animation_library("")
		library.remove_animation(key)
		library.add_animation(key, clip)
	anim_player.stop()
	anim_tree = AnimationTree.new()
	model.add_child(anim_tree)
	anim_tree.anim_player = anim_tree.get_path_to(anim_player)
	anim_tree.root_node = NodePath("..")
	anim_tree.tree_root = BLEND_TREE.duplicate(true)
	anim_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	anim_tree.active = true
	playback = anim_tree.get("parameters/TimedAction/Action/playback")
	contact_socket = BoneAttachment3D.new()
	contact_socket.name = "RightFistSocket"
	contact_socket.bone_name = "LowerArm.R"
	if skeleton.find_bone(contact_socket.bone_name) < 0: push_error("Enemy rig missing right forearm/hand socket")
	skeleton.add_child(contact_socket)
	# This rig has no separate wrist bone: the hand is skinned to the forearm.
	# Distal palm offset is measured in the authored forearm's local coordinates.
	contact_socket.position = Vector3.ZERO
	var forearm_rest = skeleton.get_bone_global_rest(skeleton.find_bone("LowerArm.R"))
	var palm_rest = skeleton.get_bone_global_rest(skeleton.find_bone("Middle1.R"))
	palm_offset = forearm_rest.affine_inverse() * palm_rest.origin
	idle_driver = preload("res://combat/snaiel/scripts/animations/subclasses/idle_animations.gd").new()
	movement_driver = preload("res://combat/snaiel/scripts/animations/subclasses/movement_animations.gd").new()
	hit_driver = preload("res://combat/snaiel/scripts/animations/subclasses/hit_and_death_animations.gd").new()
	for driver in [idle_driver, movement_driver, hit_driver]:
		driver.character = self
		add_child(driver)
	play("Idle")

func play(clip: String, speed: float = 1.0, restart := false) -> void:
	anim_tree.set("parameters/TimedAction/Speed/scale", speed)
	if active_clip == clip and not restart: return
	active_clip = clip
	playback.start(clip, true)

func set_speed(speed: float) -> void:
	anim_tree.set("parameters/TimedAction/Speed/scale", speed)

func interrupt() -> void:
	play("Idle", 1, true)

func execute(target: String, method: StringName, args: Array = []) -> void:
	var recipients = {"Idle": idle_driver, "Movement": movement_driver, "HitAndDeath": hit_driver}
	if recipients.has(target) and recipients[target].has_method(method): recipients[target].callv(method, args)

func current_position() -> float:
	if anim_tree and not anim_tree.active:
		return anim_player.current_animation_position
	return playback.get_current_play_position() if playback else 0

func current_clip() -> String:
	if anim_tree and not anim_tree.active:
		return anim_player.assigned_animation
	return playback.get_current_node() if playback else ""

func fist_position() -> Vector3:
	# Sample the posed forearm after AnimationTree physics update.
	return contact_socket.to_global(palm_offset)

func _mcp_state() -> Dictionary:
	return {"catalog": Array(anim_player.get_animation_list()), "current_clip": current_clip(), "clip_position": current_position(), "tree_active": anim_tree.active, "hand_bone": contact_socket.bone_name, "hand_position": fist_position()}
