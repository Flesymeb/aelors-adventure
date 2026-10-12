extends Node3D
var encounter: Node3D
var inspections := 0
func configure(owner: Node3D) -> void:
	encounter = owner
	var stone: Node3D = preload("res://Prefabs/Prop/Sign/EA03_Prop_Sign_Chapel_01_PRE.prefab.scn").instantiate()
	stone.scale *= 0.35
	add_child(stone)
func interaction_prompt() -> String:
	if not encounter.grounded or not encounter.can_save() or not encounter.world.travel_safe(): return ""
	var player: Node3D = encounter.world.player
	if player.global_position.distance_to(global_position) > 2.3: return ""
	var ray := PhysicsRayQueryParameters3D.create(player.global_position+Vector3.UP,global_position+Vector3.UP,1,[player.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty() and not is_ancestor_of(hit.collider): return ""
	return "[E] 检查锁印装置" if not encounter.state.warden_lock_released else "[E] 查看已解除的锁印"
func interact() -> bool:
	if interaction_prompt() == "": return false
	if not encounter.state.warden_defeated:
		encounter.world.training.tell("看守仍控制锁印 · 先击败看守，再检查装置。",4)
		return true
	if encounter.state.warden_lock_released:
		encounter.world.training.tell("锁印已解除 · 应急解除器已取得。四位村民仍需逐人释放。",5)
		return true
	var snapshot: Dictionary = encounter.state.adventure_snapshot()
	if not encounter.state.inspect_warden_device(): return true
	if not encounter.world.training.commit():
		encounter.state.restore_adventure(snapshot)
		return true
	inspections += 1
	encounter.state.progression_changed.emit()
	encounter.world.training.tell("锁印已解除 · 取得应急解除器；四位村民尚未释放。",6)
	encounter.world.menu_audio.play_cue("confirm")
	return true
func _mcp_state() -> Dictionary:
	return {"inspections":inspections,"lock_released":encounter.state.warden_lock_released if encounter else null,"tool":encounter.state.emergency_release_tool if encounter else null,"prompt":interaction_prompt() if encounter else ""}
