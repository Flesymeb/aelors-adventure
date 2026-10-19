extends Node3D
## Product release/cooldown authority; Snaiel contacts still settle enemy damage.
const GROUND = preload("res://forest_ground.gd")
const CONTACT_ENEMY = preload("res://combat/snaiel/scripts/entities/enemy.gd")
const RANGED_ENEMY = preload("res://combat/channel_ranged_adapter.gd")
const SKILL_EFFECTS = preload("res://combat/skill_effects.gd")
var skill_effects
var warning_effect := -1
var world: Node3D
var state: Node
var player: CharacterBody3D
var targets: Array[StaticBody3D] = []
var grounded = false
var cast = ""
var phase = "idle"
var clock = 0.0
var cooldowns = {"fire":0.0,"lightning":0.0}
var projectiles: Array[Dictionary] = []
var burns: Array[Dictionary] = []
var stagger_immunity: Dictionary = {}
var next_instance = 10000
var practice_hits = {"fire":0,"lightning":0}
var e02_ranged_lightning_immunity_remaining: Variant:
	get:
		# Resolve the current live E02 actor; never cache a disposable identity or
		# prune immunity while observing. Zero means available without immunity.
		if not is_instance_valid(world) or world.is_queued_for_deletion(): return null
		var pressure = world.get("pressure_encounter")
		if not is_instance_valid(pressure) or pressure.is_queued_for_deletion(): return null
		for enemy in pressure.enemies:
			if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or not enemy.is_node_ready(): continue
			if enemy.stable_id == "map02_e02_ranged": return stagger_immunity.get(enemy.get_instance_id(),0.0)
		return null

func configure(owner_world: Node3D) -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	world = owner_world
	state = world.dialogue_state
	player = world.player
	player.abilities = self
	ensure_effects()
	for id in ["fire","lightning"]:
		var target = StaticBody3D.new()
		target.name = "FirePractice" if id == "fire" else "LightningPractice"
		target.set_meta("element",id)
		target.collision_layer = 2
		var bale = preload("res://Prefabs/Prop/Container/EA03_Prop_Container_Bale_01a_PRE.prefab.scn").instantiate()
		target.add_child(bale)
		bale.scale *= 3
		for body in bale.find_children("*","CollisionObject3D",true,false): body.collision_layer = 0; body.collision_mask = 0
		var collision = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(1.1,1.2,1.8)
		collision.shape = shape
		collision.position.y = 0.6
		target.add_child(collision)
		var label = Label3D.new()
		label.text = "火焰练习 [4]" if id == "fire" else "雷电练习 [5]"
		label.font = preload("res://dialogue_theme.tres").default_font
		label.font_size = 32
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position.y = 1.8
		target.add_child(label)
		add_child(target)
		targets.append(target)
	ground.call_deferred()

func ground() -> void:
	for attempt in 120:
		await get_tree().physics_frame
		grounded = GROUND.place(world,targets[0],Vector2(119,107)) and GROUND.place(world,targets[1],Vector2(119,110))
		if grounded: break
	if not grounded: push_error("Element practice lacks authored terrain support")

func busy() -> bool:
	return phase != "idle"

func can_save() -> bool:
	return not busy() and projectiles.is_empty() and burns.is_empty()

func request(id: String) -> bool:
	if not state.skills.has(id): world.training.tell("元素尚未解锁 · 取得旧灯并升级后按 K 选择"); return true
	if cooldowns[id] > 0: world.training.tell("能力冷却中 · %.1f 秒" % cooldowns[id]); return true
	if busy() or world.training.player_locked() or world.training.hurt_time > 0 or player.switch_timer > 0 or player.traversal.action != "" or world.training.phase in ["contact","recovery"] or player.bow_state == "release": return true
	if id == "lightning" and lightning_target() == null: world.training.tell("雷电需要 12 米内视线清晰的目标 · 未消耗冷却"); return true
	if world.training.phase == "anticipation": world.training.interrupt("cast")
	player.cancel_aim()
	world.training.set_block(false)
	cast = id
	phase = "startup"
	clock = 0.25
	ensure_effects()
	var socket: Node3D = world.lamp_training.visual.lamp
	warning_effect = skill_effects.warning(id, socket.global_position, socket)
	player._set_weapon_visibility()
	player.current_animation = ""
	player._play_animation("Interact",2.0)
	return true

func interrupt() -> void:
	if is_instance_valid(skill_effects) and warning_effect >= 0: skill_effects.finish(warning_effect)
	warning_effect = -1
	cast = ""
	phase = "idle"
	clock = 0
	player._set_weapon_visibility()
	player.current_animation = ""

func clear_transients() -> void:
	interrupt()
	if is_instance_valid(skill_effects): skill_effects.clear_transients()
	for projectile in projectiles: projectile.node.queue_free(); projectile.source.queue_free()
	projectiles.clear()
	burns.clear()
	stagger_immunity.clear()
	cooldowns = {"fire":0.0,"lightning":0.0}

func _physics_process(delta: float) -> void:
	# MAP03 cinematics lock the world without pausing their own presentation.
	# Keep attacks, cooldowns, burns and effects suspended under the same lock.
	if not world.pause_owners.is_empty(): return
	if is_instance_valid(skill_effects): skill_effects.tick(delta)
	for id in cooldowns: cooldowns[id] = maxf(0,cooldowns[id] - delta)
	for id in stagger_immunity: stagger_immunity[id] = maxf(0,stagger_immunity[id] - delta)
	if busy():
		if world.training.player_locked() or world.training.hurt_time > 0 or player.traversal.action != "": interrupt()
		else:
			clock -= delta
			if clock <= 0:
				if phase == "startup":
					release()
					phase = "recovery"
					clock = 0.25
				else: interrupt()
	for projectile in projectiles.duplicate():
		var next: Vector3 = projectile.node.global_position + projectile.direction * 14.0 * delta
		var query = PhysicsRayQueryParameters3D.create(projectile.node.global_position,next,3,[player.get_rid()])
		var hit = get_world_3d().direct_space_state.intersect_ray(query)
		projectile.distance += 14.0 * delta
		if not hit.is_empty():
			settle(hit.collider,projectile.source,hit.position,"fire")
			remove_projectile(projectile)
		elif projectile.distance >= 18:
			if is_instance_valid(skill_effects): skill_effects.contact(projectile.node.global_position, "fire", "miss", 0)
			remove_projectile(projectile)
		else: projectile.node.global_position = next
	for status in burns.duplicate():
		if not is_instance_valid(status.target) or status.target.health <= 0: burns.erase(status); continue
		status.remaining -= delta
		status.tick += delta
		if status.tick >= 1.0:
			status.tick -= 1.0
			var src = source(3)
			# Periodic damage uses the same eligibility/reaction/result owner as
			# direct skills, including Veyne's threshold and transition suspension.
			var reaction: Callable = status.target.handler.reaction
			status.target.handler.reaction = Callable()
			var result: Dictionary = status.target.receive_contact(src,status.target.global_position+Vector3.UP)
			status.target.handler.reaction = reaction
			if result.get("hp_loss",0)>0 and status.target.has_method("enter_pressure_if_needed"): status.target.enter_pressure_if_needed()
			if result.get("accepted",false) and is_instance_valid(skill_effects):
				skill_effects.contact(status.target.global_position+Vector3.UP,"fire",str(result.get("outcome","")),float(result.get("hp_loss",0)))
			src.queue_free()
		if status.remaining <= 0: burns.erase(status)

func source(amount: float) -> SnaielDamageSource:
	var src = SnaielDamageSource.new()
	src.entity = player
	src.damage_attributes.health = amount
	src.can_damage = true
	next_instance += 1
	src.instance = next_instance
	add_child(src)
	return src

func release() -> void:
	ensure_effects()
	if warning_effect >= 0: skill_effects.finish(warning_effect, 0.12)
	warning_effect = -1
	if cast == "lightning":
		var target = lightning_target()
		if target == null: world.training.tell("目标离开视线 · 未消耗冷却"); return
		var point = target.global_position + Vector3.UP
		var origin: Vector3 = world.lamp_training.visual.lamp.global_position
		# Camera visibility alone cannot establish an unobstructed socket contact.
		var obstruction = get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin, point, 1, [player.get_rid(),target.get_rid()]))
		if not obstruction.is_empty():
			lightning_beam(origin, obstruction.position)
			skill_effects.contact(obstruction.position, "lightning", "obstruction", 0)
			world.training.feedback.impact(obstruction.position, "能力被挡住", 0, "obstruction")
			return
		cooldowns.lightning = 8.0
		var src = source(22)
		settle(target,src,point,"lightning")
		lightning_beam(world.lamp_training.visual.lamp.global_position,point)
		src.queue_free()
	else:
		cooldowns.fire = 6.0
		var origin: Vector3 = world.lamp_training.visual.lamp.global_position
		var direction = -player.camera.global_basis.z.normalized()
		var camera_ray = PhysicsRayQueryParameters3D.create(player.camera.global_position,player.camera.global_position + direction * 100,3,[player.get_rid()])
		var aim = get_world_3d().direct_space_state.intersect_ray(camera_ray)
		var destination: Vector3 = aim.position if not aim.is_empty() else player.camera.global_position + direction * 50
		direction = origin.direction_to(destination)
		var fire: MeshInstance3D = skill_effects.projectile("fire", origin)
		projectiles.append({"node":fire,"source":source(18),"direction":direction,"distance":0.0,"effect_id":skill_effects.records.back().id})
	world.training.feedback.swing()

func lightning_target() -> Node3D:
	# duplicate() preserves the practice array's StaticBody3D element type.
	# Copy its elements into a fresh, untyped collection for both body types.
	var candidates: Array = []
	candidates.append_array(targets)
	if world.training.monster: candidates.append(world.training.monster)
	if world.bridge_encounter: candidates.append_array(world.bridge_encounter.enemies)
	if world.dynamic_encounters: candidates.append_array(world.dynamic_encounters.enemies)
	if world.pressure_encounter: candidates.append_array(world.pressure_encounter.enemies)
	if world.get("ambush_encounter"): candidates.append_array(world.ambush_encounter.enemies)
	if world.get("line_encounter"): candidates.append_array(world.line_encounter.enemies)
	if world.get("route_patrols"): candidates.append_array(world.route_patrols.enemies)
	if world.channel_guards: candidates.append_array(world.channel_guards.enemies)
	for name in ["warden_encounter", "veyne_encounter"]:
		var encounter = world.get(name)
		if is_instance_valid(encounter) and is_instance_valid(encounter.get("actor")): candidates.append(encounter.actor)
	var best: Node3D
	var score = 0.92
	var forward = -player.camera.global_basis.z.normalized()
	for target in candidates:
		if not eligible_target(target): continue
		var point = target.global_position + Vector3.UP
		if player.global_position.distance_to(target.global_position) > 12: continue
		var alignment = forward.dot(player.camera.global_position.direction_to(point))
		if alignment < score: continue
		var query = PhysicsRayQueryParameters3D.create(player.camera.global_position,point,1,[player.get_rid(),target.get_rid()])
		if not get_world_3d().direct_space_state.intersect_ray(query).is_empty(): continue
		score = alignment
		best = target
	return best

func eligible_target(target) -> bool:
	# Stale collection entries must be rejected before any property access.
	if not is_instance_valid(target) or not target is Node3D: return false
	if target.is_queued_for_deletion() or not target.is_inside_tree() or not target.is_node_ready(): return false
	if target is StaticBody3D and target in targets: return true
	if not (target is CONTACT_ENEMY or target is RANGED_ENEMY): return false
	if not is_instance_valid(target.health_component) or not is_instance_valid(target.handler): return false
	if not target.health_component.enabled or not target.health_component.is_alive(): return false
	if not is_instance_valid(target.hitbox) or not target.hitbox.enabled: return false
	# Use the same product eligibility policy as the authoritative hit handler.
	return target.handler.eligibility.is_valid() and target.handler.eligibility.call()

func settle(target: Object, src: SnaielDamageSource, point: Vector3, element: String) -> void:
	if not is_instance_valid(target) or not target is Node3D: return
	if target.is_queued_for_deletion(): return
	if target is StaticBody3D and target in targets:
		world.training.feedback.impact(point,"元素靶命中",0,"straw")
		ensure_effects()
		skill_effects.contact(point, element, "straw", 0)
		if target.get_meta("element") == element and state.trace_investigated:
			practice_hits[element] += 1
			if not state.element_practice_complete:
				state.element_practice_complete = true
				state.experience += 25
				state.tracked_quest = "bridge"
				world.training.feedback.reward(25)
				world.training.commit()
			world.training.tell("元素练习完成 · 沿村路穿过石桥，清除对岸两名巡守",5)
		return
	if target != null and target.has_method("receive_contact"):
		if not eligible_target(target): return
		var reaction = target.handler.reaction
		if element == "lightning": target.handler.reaction = Callable()
		var result: Dictionary = target.receive_contact(src,point)
		target.handler.reaction = reaction
		if result.get("hp_loss",0)>0 and target.has_method("enter_pressure_if_needed"): target.enter_pressure_if_needed()
		if result.get("accepted", false):
			ensure_effects()
			skill_effects.contact(point, element, result.get("outcome", "hit"), result.get("hp_loss", 0.0))
		if result.get("hp_loss",0) > 0 and target.health > 0:
			if element == "fire":
				for status in burns:
					if status.target == target: status.remaining = 3.0; return
				burns.append({"target":target,"remaining":3.0,"tick":0.0})
			elif stagger_immunity.get(target.get_instance_id(),0) <= 0:
				target.on_hurt(result)
				target.hurt_remaining = 0.4
				stagger_immunity[target.get_instance_id()] = 2.0
			else: target.blackboard.set_value("got_hit",false)
	else:
		world.training.feedback.impact(point,"能力被挡住",0,"obstruction")
		ensure_effects()
		skill_effects.contact(point, element, "obstruction", 0)

func remove_projectile(projectile: Dictionary) -> void:
	projectiles.erase(projectile)
	projectile.node.queue_free()
	projectile.source.queue_free()

func _mcp_state() -> Dictionary:
	# Observation only: never step, settle, prune or refresh live entities here.
	# Native identities distinguish motion/tick suspension from unchanged counts.
	var projectile_states: Array[Dictionary] = []
	for projectile in projectiles:
		if not is_instance_valid(projectile.node): continue
		var position: Vector3 = projectile.node.global_position
		var direction: Vector3 = projectile.direction
		projectile_states.append({
			"instance_id": projectile.node.get_instance_id(),
			"path": str(projectile.node.get_path()),
			"position": [position.x, position.y, position.z],
			"direction": [direction.x, direction.y, direction.z],
			"distance": projectile.distance,
			"speed": 14.0, "max_distance": 18.0,
			"remaining_flight_seconds": maxf(0, (18.0 - projectile.distance) / 14.0),
			"queued_for_deletion": projectile.node.is_queued_for_deletion()
		})
	var burn_states: Array[Dictionary] = []
	for status in burns:
		if not is_instance_valid(status.target): continue
		var position: Vector3 = status.target.global_position
		burn_states.append({
			"target_instance_id": status.target.get_instance_id(),
			"target_path": str(status.target.get_path()),
			"target_position": [position.x, position.y, position.z],
			"target_health": status.target.health,
			"remaining": status.remaining, "tick": status.tick,
			"tick_interval": 1.0, "next_tick_seconds": maxf(0, 1.0 - status.tick),
			"target_queued_for_deletion": status.target.is_queued_for_deletion()
		})
	return {"phase":phase,"cast":cast,"clock":clock,"cooldowns":cooldowns.duplicate(),"projectiles":projectiles.size(),"burns":burns.size(),"practice_hits":practice_hits.duplicate(),"grounded":grounded,
		"e02_ranged_lightning_immunity_remaining":e02_ranged_lightning_immunity_remaining,
		"projectile_states":projectile_states,"burn_states":burn_states,
		"process_frame":Engine.get_process_frames(),"physics_frame":Engine.get_physics_frames(),
		"tree_paused":get_tree().paused,"pause_owners":world.pause_owners.keys(),"skill_effects":skill_effects.snapshot() if is_instance_valid(skill_effects) else null}

func ensure_effects() -> void:
	if is_instance_valid(skill_effects): return
	skill_effects = SKILL_EFFECTS.new()
	skill_effects.name = "SkillEffects"
	add_child(skill_effects)
	skill_effects.configure(world, state)

func lightning_beam(origin: Vector3, destination: Vector3) -> void:
	ensure_effects()
	skill_effects.line(origin, destination, "lightning", 0.22)
