extends Node
## Friendly visual animation only. Never advances gameplay, collision or saves.
## Conversation may animate its counterpart; nested menus freeze every rig.
var world: Node
var actor: Node3D
var presentation: Node3D
var player: AnimationPlayer
var skeleton: Skeleton3D
var role := ""
var clock := 0.0
var head := -1
var speaking := false
var isha_rig := false

static func attach(owner_actor: Node3D, body: Node3D, identity: String) -> Node:
	var director := new()
	director.actor = owner_actor
	director.presentation = body
	director.role = identity
	var ancestor: Node = owner_actor.get_parent()
	while ancestor:
		if ancestor.get("dialogue_state") != null:
			director.world = ancestor
			break
		ancestor = ancestor.get_parent()
	if director.world == null:
		director.free()
		return null
	director.isha_rig = identity == "isha"
	director.player = owner_actor.idle_player if director.isha_rig else body.animation_player
	director.skeleton = owner_actor.skeleton if director.isha_rig else body.skeleton
	director.clock = float(absi(identity.hash()) % 700) / 100.0
	director.name = "FriendlyLife"
	director.process_mode = Node.PROCESS_MODE_ALWAYS
	# Manual clock avoids advancing twice, and permits just the conversational
	# visual while the gameplay tree remains correctly paused.
	director.player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	director.player.process_mode = Node.PROCESS_MODE_ALWAYS
	body.process_mode = Node.PROCESS_MODE_ALWAYS
	var current := director.player.current_animation
	if current != "" and director.player.get_animation(current).loop_mode != Animation.LOOP_NONE:
		director.player.seek(fmod(director.clock,director.player.get_animation(current).length),true)
	for i in director.skeleton.get_bone_count():
		if director.skeleton.get_bone_name(i).to_lower() == "head":
			director.head = i
			break
	owner_actor.add_child(director)
	return director

func _process(delta: float) -> void:
	if not is_instance_valid(world) or not actor.is_visible_in_tree(): return
	var owners: Dictionary = world.pause_owners
	var dialogue_only: bool = not owners.is_empty() and owners.keys().all(func(key): return key == "dialogue")
	if not owners.is_empty() and not dialogue_only: return
	if get_tree().paused and not dialogue_only: return
	# Hidden training actors in other chapters have explicit disabled ownership.
	if actor.process_mode == Node.PROCESS_MODE_DISABLED: return
	var talking: bool = dialogue_only and world.dialogue_state.dialogue_kind == role
	if dialogue_only and not talking: return
	var gesture_allowed := true
	if actor.get("demonstration") == true: gesture_allowed = false
	if actor.get("performing_assembly") == true or float(actor.get("release_remaining") if actor.get("release_remaining") != null else 0.0) > 0.0: gesture_allowed = false
	if isha_rig:
		var target := "Isha_Talk" if talking else "Isha_Idle"
		if player.current_animation != target: player.play(target,0.25)
	elif role == "ronen" and gesture_allowed:
		if talking and presentation.current_animation in ["Idle","Idle_Talking"]:
			presentation._play_animation("Idle_Talking")
		elif not talking and speaking and presentation.current_animation == "Idle_Talking":
			presentation._play_animation("Idle")
	speaking = talking
	clock += delta
	player.advance(delta)
	# Head turns layer on the actual authored pose, with a different phase per
	# identity. No actor root motion or collision changes; reduced motion stays
	# on the native breathing/idle clips alone.
	if head >= 0 and gesture_allowed and not world.dialogue_state.reduced_motion:
		var idle: bool = presentation.current_animation in ["Idle","Sword_Idle","Idle_Talking"] if not isha_rig else false
		if idle:
			var turn := sin(clock*0.55)*0.09 + sin(clock*0.21)*0.035
			skeleton.set_bone_pose_rotation(head,skeleton.get_bone_pose_rotation(head)*Quaternion(Vector3.UP,turn))
