extends RefCounted
## Opt-in disposable component checks. No startup collector or save mutation.
const RESPONSE := preload("res://combat/player_impact_response.gd")
const CONTACT := preload("res://tests/player_contact_feedback_test.gd")

static func heavy_contact() -> Dictionary:
	return {"heavy_impact_requested": true, "accepted": true, "outcome": "hurt", "hp_loss": 12.0, "hp_after": 88.0, "source_id": 17, "attack_instance": 4, "simulated": false}

static func run(holder: Node) -> Dictionary:
	var checks := {}
	var response = RESPONSE.new()
	var resolved := heavy_contact()
	checks.accepts_resolved_surviving_heavy = response.begin(resolved, Vector3(0, 0, 1), Vector3.ZERO)
	checks.upright_planar_away_direction = response.secondary.direction == Vector3(0, 0, -1)
	checks.snaiel_secondary_resource = response.secondary is SnaielSecondaryMovement
	checks.bounded_budget = is_equal_approx(response.travel_remaining, 0.8) and response.remaining <= 0.65
	var original: float = response.remaining
	checks.repeated_trigger_does_not_extend = not response.begin(resolved, Vector3(0, 0, 1), Vector3.ZERO) and response.remaining == original
	response.record_motion(Vector3.ZERO, Vector3(0, 0, -0.21))
	checks.actual_motion_spends_budget = is_equal_approx(response.travel_remaining, 0.59) and is_equal_approx(response.traveled, 0.21)
	for i in 35: response.advance(1.0 / 60.0)
	checks.releases_within_bound = not response.active() and response.secondary == null and response.guard_remaining > 0.0
	checks.guard_cannot_retrigger = not response.begin(resolved, Vector3(0, 0, 1), Vector3.ZERO)
	response.advance(0.51)
	checks.guard_expires = response.begin(resolved, Vector3(0, 0, 1), Vector3.ZERO)
	response.cancel()
	checks.cancel_clears_all_ownership = not response.active() and response.guard_remaining == 0.0 and response.contact.is_empty() and response.secondary == null
	for outcome in ["block", "parry", "dodge", "protected", "miss", "death"]:
		var denied := heavy_contact()
		denied.outcome = outcome
		checks["reject_" + outcome] = not response.begin(denied, Vector3(0, 0, 1), Vector3.ZERO)
	for field in ["hp_after", "hp_loss", "source_id"]:
		var denied := heavy_contact()
		denied[field] = 0
		checks["reject_zero_" + field] = not response.begin(denied, Vector3(0, 0, 1), Vector3.ZERO)
	var simulated := heavy_contact()
	simulated.simulated = true
	checks.reject_simulated = not response.begin(simulated, Vector3(0, 0, 1), Vector3.ZERO)
	var centered := heavy_contact()
	centered.attack_direction = Vector3(2, -3, 0)
	checks.centered_eligible_uses_planar_attack_direction = response.begin(centered, Vector3.ZERO, Vector3.ZERO) and response.secondary.direction == Vector3.RIGHT
	response.cancel()
	checks.centered_missing_direction_rejects_secondary_only = not response.begin(heavy_contact(), Vector3.ZERO, Vector3.ZERO)
	var guarded := guarded_contact_checks(holder)
	for name in guarded: checks[name] = guarded[name]
	return {"scope": "component adapter eligibility/timer/budget and retained contact regression; native supported movement and ordinary input require runtime observations", "checks": checks}

static func guarded_contact_checks(holder: Node) -> Dictionary:
	# Seed a resolved active response; native grounded entry and collision
	# sweeps are covered separately on a normal SceneTree physics route.
	var stage := CONTACT.ContactWorld.new()
	stage.process_mode = Node.PROCESS_MODE_DISABLED
	holder.add_child(stage)
	var training := CONTACT.ContactTraining.new()
	stage.add_child(training)
	training.world = stage
	training.state = CONTACT.ContactState.new()
	stage.add_child(training.state)
	var player := CONTACT.ContactPlayer.new()
	stage.add_child(player)
	player.traversal = CONTACT.Traversal.new()
	player.add_child(player.traversal)
	player.visual = Node3D.new()
	player.add_child(player.visual)
	player.animation_player = AnimationPlayer.new()
	player.add_child(player.animation_player)
	training.player = player
	training.feedback = CONTACT.ContactFeedback.new()
	stage.add_child(training.feedback)
	var enemy := CONTACT.ContactEnemy.new()
	stage.add_child(enemy)
	training.monster = enemy
	var source := SnaielDamageSource.new()
	enemy.add_child(source)
	source.entity = enemy
	source.can_damage = true
	source.damage_attributes.health = 10.0
	source.set_meta("heavy_impact", true)
	var hitbox := SnaielHitbox.new()
	player.add_child(hitbox)
	hitbox.entity = player
	hitbox.policy = training.resolve_player_contact
	training.player_hitbox = hitbox
	training.heavy_impact.begin(heavy_contact(), Vector3(0, 0, 1), Vector3.ZERO)
	var remaining: float = training.heavy_impact.remaining
	var result := hitbox.contact(source, Vector3.UP)
	var checks := {}
	checks.active_stagger_has_no_damage_immunity = result.outcome == "hurt" and result.hp_loss == 10 and training.state.health == 90
	checks.repeated_accepted_heavy_does_not_extend = training.heavy_impact.remaining == remaining and not result.heavy_stagger_started
	checks.contact_identity_is_resolved = result.source_id == source.get_instance_id() and result.attack_instance == source.instance and result.impact_origin == enemy.attack_origin
	checks.duplicate_identity_still_rejected = hitbox.contact(source, Vector3.UP).is_empty() and training.state.health == 90
	training.heavy_impact.advance(0.57)
	source.instance += 1
	result = hitbox.contact(source, Vector3.UP)
	checks.guard_has_no_damage_immunity_or_restriction = result.outcome == "hurt" and training.state.health == 80 and not training.player_locked() and training.hurt_time == 0
	training.heavy_impact.cancel()
	training.heavy_impact.begin(heavy_contact(), Vector3(0, 0, 1), Vector3.ZERO)
	training.state.health = 5.0
	source.instance += 1
	result = hitbox.contact(source, Vector3.UP)
	checks.lethal_precedes_heavy_recovery = training.phase == "death" and training.state.health == 0 and training.state.lives == 3 and not training.heavy_impact.active()
	stage.free()
	return checks

class MovementPlayer extends "res://player_controller.gd":
	# Use the shipped heavy physics function without loading a second Ranger,
	# preferences or controller input owner into the ordinary play session.
	func _ready() -> void: pass
	func _physics_process(_delta: float) -> void: pass

class MovementCombat extends Node:
	var heavy_impact = preload("res://combat/player_impact_response.gd").new()

class MovementFixture extends Node3D:
	var players: Dictionary = {}
	var starts: Dictionary = {}
	var observations: Dictionary = {}
	var ticks := 0
	var complete := false
	var elapsed := 0.0
	var seed: Dictionary = {}
	func _physics_process(delta: float) -> void:
		if complete: return
		ticks += 1
		if ticks <= 6:
			for player: CharacterBody3D in players.values():
				player.velocity = Vector3.DOWN
				player.traversal.move_with_steps(delta)
			return
		if ticks == 7:
			for label in players:
				var player: CharacterBody3D = players[label]
				starts[label] = player.global_position
				observations[label] = {"grounded_start": player.is_on_floor(), "maximum_distance": 0.0}
				player.combat.heavy_impact.begin(seed, player.global_position + Vector3(0, 0, 1), player.global_position)
		elapsed += delta
		for label in players:
			var player: CharacterBody3D = players[label]
			var response = player.combat.heavy_impact
			response.advance(delta)
			if response.active():
				# Exercise the production override against neutral and an opposing
				# locomotion drive. This is physics integration, not input proof.
				player.velocity.x = 0.0
				player.velocity.z = 5.0 if label == "opposing" else 0.0
				player._advance_heavy_impact(delta)
			var start: Vector3 = starts[label]
			var distance := Vector2(player.global_position.x - start.x, player.global_position.z - start.z).length()
			observations[label].maximum_distance = maxf(observations[label].maximum_distance, distance)
			observations[label].position = player.global_position
			observations[label].distance = distance
			observations[label].active = response.active()
			observations[label].velocity = player.velocity
			observations[label].grounded_end = player.is_on_floor()
		if elapsed >= 0.7: complete = true

static func prepare_movement_checks(holder: Node) -> Node3D:
	var fixture := MovementFixture.new()
	fixture.name = "HeavyMovementFixture"
	fixture.seed = heavy_contact()
	var viewport := SubViewport.new()
	viewport.name = "IsolatedPhysics"
	viewport.own_world_3d = true
	fixture.add_child(viewport)
	var stage := Node3D.new()
	viewport.add_child(stage)
	var labels := ["open", "neutral", "opposing", "wall", "edge"]
	for index in labels.size():
		var label: String = labels[index]
		var lane := float(index) * 10.0
		var floor_center := Vector3(lane, -0.1, 1.5 if label == "edge" else 0.0)
		add_fixture_box(stage, floor_center, Vector3(4, 0.2, 4))
		if label == "wall": add_fixture_box(stage, Vector3(lane, 1, -0.62), Vector3(3, 2, 0.2))
		var player := MovementPlayer.new()
		player.name = label
		player.position = Vector3(lane, 0.03, 0)
		var collision := CollisionShape3D.new()
		collision.name = "Collision"
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.32
		capsule.height = 1.8
		collision.shape = capsule
		collision.position.y = 0.9
		player.add_child(collision)
		var visual := Node3D.new()
		visual.name = "Visual"
		player.add_child(visual)
		var arm := SpringArm3D.new()
		arm.name = "CameraArm"
		player.add_child(arm)
		var camera := Camera3D.new()
		camera.name = "Camera"
		arm.add_child(camera)
		var combat := MovementCombat.new()
		player.combat = combat
		player.add_child(combat)
		var traversal = preload("res://traversal_controller.gd").new()
		traversal.player = player
		player.traversal = traversal
		player.add_child(traversal)
		stage.add_child(player)
		fixture.players[label] = player
	holder.add_child(fixture)
	return fixture

static func add_fixture_box(stage: Node3D, center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = center
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	stage.add_child(body)

static func finish_movement_checks(fixture: Node3D) -> Dictionary:
	var checks := {"normal_physics_completed": fixture.complete}
	var observations: Dictionary = fixture.observations.duplicate(true)
	if fixture.complete:
		for label in observations:
			var observed: Dictionary = observations[label]
			checks[label + "_grounded"] = observed.grounded_start and observed.grounded_end
			checks[label + "_bounded"] = observed.maximum_distance <= 0.801
			checks[label + "_released"] = not observed.active and Vector2(observed.velocity.x, observed.velocity.z).is_zero_approx()
		checks.open_displaces = observations.open.distance > 0.65
		checks.neutral_preserves_impulse = absf(observations.neutral.distance - observations.open.distance) < 0.01
		checks.opposing_drive_cannot_add_or_erase = absf(observations.opposing.distance - observations.open.distance) < 0.01
		checks.wall_shortens_displacement = observations.wall.distance < observations.open.distance * 0.5
		checks.edge_shortens_displacement = observations.edge.distance < 0.22
	fixture.free()
	return {"scope": "disposable normal-tree physics with shipped heavy movement and retained traversal; no earned encounter or ordinary input acceptance", "checks": checks, "observations": observations}
