extends "res://lamp_training.gd"
## MAP02 lamp pulse: automatic recovery, no consumable or reward duplication.
func reveal() -> bool:
	if not state.lamp_owned or world.player.weapon_mode != "lamp":
		world.training.tell("按 [3] 装备旧灯，再按 [F] 显形")
		return true
	if cooldown > 0:
		world.training.tell("旧灯恢复中 · %.1f 秒" % cooldown)
		return true
	if world.player.switch_timer > 0 or world.training.player_locked() or world.player.traversal.action != "" or world.element_abilities.busy() or world.player.attack_timer > 0 or not world.pause_owners.is_empty(): return true
	if not world.ambush_encounter.approach_allowed():
		world.training.tell("先调查岩石后的固定路碑，再追踪林缘魔痕")
		return true
	cooldown = 3.0
	world.player.current_animation = ""
	world.player.attack_timer = 0.6
	world.player._play_animation("Interact", 1.8)
	world.training.feedback.spark(world.player.global_position + Vector3.UP, Color(0.4,0.85,1))
	var result: int = world.ambush_encounter.reveal(world.player.global_position)
	if result == 0: world.training.tell("灯光照亮周围 7 米 · 尚未触及魔痕，靠近或绕开遮挡后重试",4)
	elif result == 1: world.training.tell("伏击者已持续显形 · 留意突进预告",3)
	return true

func interaction_prompt() -> String:
	if not is_instance_valid(world.ambush_encounter) or not world.ambush_encounter.grounded or not state.mf01_acquired or state.ambush_defeated(): return ""
	if Vector2(world.player.global_position.x,world.player.global_position.z).distance_to(world.ground_policy.AMBUSH_APPROACH) > 7: return ""
	return "[3] 旧灯 · [F] 显形 · 7 米范围" if not state.e03_revealed else "伏击者抬手后突进 · 闪避或格挡，再反击"

func _mcp_state() -> Dictionary:
	return {"ready":is_instance_valid(state),"cooldown":cooldown,"range":7.0,"revealed":state.e03_revealed,"lamp":visual._mcp_state()}
