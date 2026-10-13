extends Node3D
var encounter: Node3D
var inspections := 0
func configure(owner: Node3D) -> void:
	encounter = owner
	var stone: Node3D = preload("res://Prefabs/Prop/Sign/EA03_Prop_Sign_Chapel_01_PRE.prefab.scn").instantiate()
	stone.scale *= 0.35
	add_child(stone)
func interaction_prompt() -> String:
	if not encounter.state.veyne_defeated or not encounter.grounded or not encounter.can_save() or not encounter.world.travel_safe(): return ""
	var player: Node3D = encounter.world.player
	if player.global_position.distance_to(global_position) > 2.3: return ""
	var ray := PhysicsRayQueryParameters3D.create(player.global_position+Vector3.UP,global_position+Vector3.UP,1,[player.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty() and not is_ancestor_of(hit.collider): return ""
	return "[E] 检查解除钥印" if not encounter.state.veyne_release_key else "[E] 查看解除钥印"
func interact() -> bool:
	if interaction_prompt() == "": return false
	if not encounter.state.veyne_defeated:
		encounter.world.training.tell("维恩仍控制祭坛 · 先击败维恩，再检查钥印。",4)
		return true
	if encounter.state.veyne_release_key:
		encounter.world.training.tell("解除钥印已取得。四位村民仍需逐人释放，召唤核心仍需关闭。",5)
		return true
	var snapshot: Dictionary = encounter.state.adventure_snapshot()
	if not encounter.state.take_veyne_key(): return true
	if not encounter.world.training.commit():
		encounter.state.restore_adventure(snapshot)
		return true
	inspections += 1
	encounter.state.progression_changed.emit()
	encounter.world.training.tell("取得解除钥印 · 四位村民尚未释放，召唤核心仍待处理。",6)
	encounter.world.menu_audio.play_cue("confirm")
	return true
func _mcp_state() -> Dictionary:
	return {"inspections":inspections,"lock_released":encounter.state.veyne_release_key if encounter else null,"prompt":interaction_prompt() if encounter else ""}
