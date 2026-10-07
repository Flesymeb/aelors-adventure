extends Node3D
## Hand and stow sockets follow the same calibrated skeleton as the selected sword.
var player: CharacterBody3D
var state: Node
var hand: BoneAttachment3D
var stow: BoneAttachment3D
var lamp: Node3D

func configure(actor: CharacterBody3D, authority: Node) -> void:
	player = actor
	state = authority
	hand = BoneAttachment3D.new()
	hand.bone_name = "hand_r"
	player.skeleton.add_child(hand)
	stow = BoneAttachment3D.new()
	stow.bone_name = "spine_02"
	player.skeleton.add_child(stow)
	lamp = preload("res://assets/equipment/old_lamp.tscn").instantiate()
	add_child(lamp)

func _process(_delta: float) -> void:
	if hand == null: return
	var held = (player.weapon_mode == "lamp" or (player.abilities and player.abilities.busy())) and player.traversal.posture != "prone"
	lamp.visible = state.lamp_owned and (not player.first_person or held)
	lamp.global_transform = Transform3D(Basis(), hand.global_position + Vector3(0,-0.015,0)) if held else Transform3D(player.visual.global_basis, stow.global_position + player.visual.global_basis * Vector3(-0.22,-0.1,-0.18))

func _mcp_state() -> Dictionary:
	return {"visible": lamp.visible, "held":player.weapon_mode == "lamp", "resource":"res://assets/equipment/old_lamp.tscn", "position":str(lamp.global_position)}
