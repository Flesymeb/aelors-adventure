extends Node3D
## Two turns of the real equipped rig; the existing blade sweep and hitbox
## settle contact. One source occurrence per turn, never a radial damage scan.
const COOLDOWN := 6.0
const WINDUP := 0.25
const ACTIVE := 1.30
const RECOVERY := 0.45
var training: Node3D
var active := false
var cooldown := 0.0
var elapsed := 0.0
var start_yaw := 0.0
var turn := 0
var ring: MeshInstance3D
var material: ShaderMaterial
var animation_process: int
func configure(owner_training: Node3D) -> void:
	training = owner_training
	ring = MeshInstance3D.new()
	ring.name = "WhirlwindSwordWake"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(3.2,3.2)
	ring.mesh = mesh
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	material = ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/passage_ring.gdshader")
	material.set_shader_parameter("color",Color(0.25,0.9,0.72,0.4))
	var noise := NoiseTexture2D.new()
	noise.width = 64
	noise.height = 64
	noise.seamless = true
	noise.noise = FastNoiseLite.new()
	material.set_shader_parameter("noise_tex",noise)
	ring.material_override = material
	add_child(ring)
	ring.hide()
func unlocked() -> bool:
	return training.state.sword_owned and training.state.practice_hit and training.state.practice_defense

func request() -> bool:
	if not unlocked(): return false
	if active or cooldown > 0 or training.phase != "idle" or training.blocking or not training.finisher_eligible(): return false
	active = true
	cooldown = COOLDOWN
	elapsed = 0
	turn = 0
	training.combo = training.SPIN_INDEX
	training.start_swing()
	start_yaw = training.player.visual.rotation.y
	training.tell("回旋斩 · 两圈剑刃判定 · 冷却 6 秒",2)
	return true
func begin_pose() -> void:
	animation_process = training.player.animation_player.callback_mode_process
	training.player.animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	var clip := "sword/Sword_Regular_C"
	var length: float = training.player.animation_player.get_animation(clip).length
	training.player._play_animation(clip,length / (WINDUP + ACTIVE + RECOVERY))
	training.player.animation_player.advance(0)
func advance(delta: float) -> void:
	cooldown = maxf(0,cooldown-delta)
	if not active: return
	elapsed += delta
	var progress := clampf((elapsed-WINDUP)/ACTIVE,0,1)
	training.player.visual.rotation.y = start_yaw + TAU * 2.0 * progress
	if progress >= 0.5 and turn == 0:
		turn = 1
		# Hitbox occurrence identity permits at most one accepted hit each turn.
		training.sword_melee.increment_weapon_instance()
		training.feedback.sound(preload("res://assets/audio/world_effects/sword_whirl.ogg"),-18,1.0)
	if progress > 0 and turn == 0 and elapsed-delta <= WINDUP:
		training.feedback.sound(preload("res://assets/audio/world_effects/sword_whirl.ogg"),-18,1.0)
	ring.global_position = training.player.global_position + Vector3.UP * 0.12
	ring.visible = training.phase == "contact" and not training.state.reduced_motion
	material.set_shader_parameter("effect_clock",elapsed)
	material.set_shader_parameter("strength",sin(progress*PI))
func stop() -> void:
	if active:
		training.player.animation_player.callback_mode_process = animation_process
	active = false
	if is_instance_valid(ring): ring.hide()
func reset(reason: String) -> void:
	stop()
	if reason in ["death","load","recovery"]: cooldown = 0.0
