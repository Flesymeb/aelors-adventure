extends RefCounted
## Isolated checks for the existing elemental contact and ranged reaction contract.

class ContactFeedback extends Node:
	func sound(_stream: AudioStream, _volume: float, _pitch: float) -> void: pass

class ContactTraining extends Node:
	var feedback: ContactFeedback
	var contacts := 0
	var hp_loss := 0.0
	func resolved_enemy_contact(result: Dictionary) -> void:
		contacts += 1
		hp_loss += result.get("hp_loss",0.0)

class ContactWorld extends Node3D:
	var player: CharacterBody3D
	var training: ContactTraining

class ContactEncounter extends Node3D:
	var world: ContactWorld
	var grounded := true
	var allowed := true
	var defeats := 0
	func combat_allowed() -> bool: return allowed
	func attack_slot_available(_enemy: Node) -> bool: return false
	func settle_defeat(_enemy: Node) -> void: defeats += 1

static func lightning_contact_checks(parent: Node, actor_script: GDScript = null) -> Dictionary:
	# Explicit disposable real-adapter fixture. This tests Snaiel settlement and
	# reaction/timeline integration; it cannot establish ordinary cast/audio QA.
	var stage := ContactWorld.new()
	stage.process_mode = Node.PROCESS_MODE_DISABLED
	parent.add_child(stage)
	stage.player = CharacterBody3D.new()
	stage.player.disable_mode = CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE
	stage.add_child(stage.player)
	stage.player.position = Vector3(0,50,8)
	stage.training = ContactTraining.new()
	stage.add_child(stage.training)
	stage.training.feedback = ContactFeedback.new()
	stage.training.add_child(stage.training.feedback)
	var encounter := ContactEncounter.new()
	encounter.world = stage
	stage.add_child(encounter)
	var enemy: CharacterBody3D = preload("res://combat/ChannelRangedGuard.tscn").instantiate()
	if actor_script: enemy.set_script(actor_script)
	# Processing stays disabled, while manual recovery ticks retain a real
	# physics-space body instead of triggering DISABLE_MODE_REMOVE.
	enemy.disable_mode = CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE
	enemy.encounter = encounter
	encounter.add_child(enemy)
	enemy.home = Vector3(0,50,0)
	enemy.position = enemy.home
	enemy.navigation_ready = true
	var abilities := preload("res://element_abilities.gd").new()
	abilities.world = stage
	abilities.player = stage.player
	stage.add_child(abilities)
	abilities.cooldowns.lightning = 8.0
	var original: Callable = enemy.handler.reaction
	var reactions: Array[int] = [0]
	var traced: Callable = func(result: Dictionary):
		reactions[0] += 1
		original.call(result)
	enemy.handler.reaction = traced
	var checks := {"real_reaction_bound":original.is_valid()}
	checks.draw_started = enemy.action.perform_action() and enemy.phase == "telegraph"
	var src: SnaielDamageSource = abilities.source(22)
	abilities.settle(enemy,src,enemy.global_position,"lightning")
	checks.single_damage_and_hurt = enemy.health == 14 and stage.training.contacts == 1 and stage.training.hp_loss == 22 and reactions[0] == 1 and enemy.phase == "hurt" and is_equal_approx(enemy.hurt_remaining,0.4)
	checks.draw_interrupted_pose = not enemy.action.executing_action and enemy.action.stage == "idle" and enemy.presentation.current_animation == "Hit_Chest" and enemy.presentation.bow_state == "idle"
	checks.callback_restored = enemy.handler.reaction == traced
	abilities.settle(enemy,src,enemy.global_position,"lightning")
	checks.duplicate_source_ignored = enemy.health == 14 and stage.training.contacts == 1 and reactions[0] == 1
	src.free()
	enemy._physics_process(0.1)
	var remaining: float = enemy.hurt_remaining
	enemy.navigation_ready = true
	src = abilities.source(7)
	abilities.settle(enemy,src,enemy.global_position,"lightning")
	checks.immunity_damage_without_reaction = enemy.health == 7 and stage.training.contacts == 2 and reactions[0] == 1 and enemy.hurt_remaining == remaining and not enemy.blackboard.get_value("got_hit",true)
	src.free()
	enemy._physics_process(0.31)
	checks.hurt_releases_idle = enemy.hurt_remaining == 0 and enemy.phase == "idle" and enemy.presentation.current_animation == "Idle" and not enemy.blackboard.get_value("got_hit",true)
	if enemy.has_method("can_save"): checks.inherited_active_combat_blocks_save = not enemy.can_save()
	enemy.action.tick(2.1,false)
	checks.weapon_control_restored = enemy.action.can_perform_action and enemy.action.perform_action() and enemy.phase == "telegraph"
	enemy.navigation_ready = true
	src = abilities.source(2)
	abilities.settle(enemy,src,enemy.global_position,"fire")
	checks.fire_keeps_reaction_and_burn = enemy.health == 5 and reactions[0] == 2 and abilities.burns.size() == 1 and abilities.burns[0].target == enemy and enemy.handler.reaction == traced
	src.free()
	encounter.allowed = false
	src = abilities.source(7)
	abilities.settle(enemy,src,enemy.global_position,"lightning")
	checks.ineligible_no_settlement = enemy.health == 5 and stage.training.contacts == 3 and reactions[0] == 2 and enemy.handler.reaction == traced
	src.free()
	encounter.allowed = true
	enemy.navigation_ready = true
	src = abilities.source(50)
	abilities.settle(enemy,src,enemy.global_position,"lightning")
	checks.lethal_once_without_hurt = enemy.health == 0 and stage.training.hp_loss == 36 and stage.training.contacts == 4 and reactions[0] == 2 and encounter.defeats == 1 and enemy.phase == "death" and enemy.hurt_remaining == 0 and not enemy.hitbox.enabled and not enemy.action.executing_action and enemy.projectiles.is_empty()
	abilities.settle(enemy,src,enemy.global_position,"lightning")
	checks.lethal_repeat_ignored = encounter.defeats == 1 and stage.training.contacts == 4 and reactions[0] == 2
	checks.cooldown_unchanged = abilities.cooldowns.lightning == 8.0
	src.free()
	stage.free()
	return checks
