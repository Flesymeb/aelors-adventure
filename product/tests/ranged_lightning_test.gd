extends RefCounted
## Opt-in qualification of the retained contact owners and their native resources.
## Disposable fixtures cannot establish earned combat, heard audio or delivery QA.
const CONTACT = preload("res://tests/ranged_lightning_contact_test.gd")
const ROOTS := [
	"res://combat/ChannelRangedGuard.tscn",
	"res://combat/map02_ranged_adapter.gd",
	"res://combat/snaiel/scenes/entities/enemies/HybridEnemy.tscn",
	"res://combat/snaiel/scenes/beehave/trees/EnemyActions.tscn",
	"res://actors/npc_presentation.tscn",
	"res://assets/guards/ranged_guard.glb",
	"res://Characters/QuaterniusBase/Superhero_Male_FullBody.gltf",
	"res://Characters/QuaterniusAnimations/UAL1_Standard.glb",
	"res://Characters/QuaterniusAnimations/UAL2_Standard.glb",
	"res://Characters/KayKitAnimations/Rig_Medium_CombatRanged.glb",
	"res://Weapons/Sword_Bronze.gltf",
	"res://Weapons/Bow_Golden.obj",
	"res://Weapons/Arrow.obj",
]
const CLIPS := {
	"res://Characters/QuaterniusAnimations/UAL1_Standard.glb": ["Idle", "Walk", "Hit_Chest", "Death01"],
	"res://Characters/KayKitAnimations/Rig_Medium_CombatRanged.glb": ["Ranged_Bow_Draw", "Ranged_Bow_Aiming_Idle", "Ranged_Bow_Release"],
}

static func run(parent: Node) -> Dictionary:
	var checks := {}
	var pending: Array = ROOTS.duplicate()
	var seen := {}
	var missing: Array[Dictionary] = []
	while not pending.is_empty() and seen.size() < 160:
		var path: String = pending.pop_back()
		if seen.has(path): continue
		seen[path] = true
		if not ResourceLoader.exists(path):
			missing.append({"owner": "root", "dependency": path})
			continue
		for dependency in ResourceLoader.get_dependencies(path):
			var target: String = dependency.split("::")[-1]
			if not ResourceLoader.exists(target):
				missing.append({"owner": path, "dependency": target})
			elif target.get_extension() in ["tscn", "tres", "scn", "res", "gltf", "glb", "gd"]:
				pending.append(target)
	checks.native_dependency_closure = missing.is_empty() and pending.is_empty()
	for path in ROOTS:
		var resource := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
		checks[path + "_loaded"] = resource != null
		if not resource is PackedScene: continue
		var instance: Node = resource.instantiate()
		checks[path + "_instantiated"] = instance != null
		if instance and CLIPS.has(path):
			var player := instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
			for clip in CLIPS[path]:
				checks[path + "_clip_" + clip] = player != null and player.has_animation(clip) and player.get_animation(clip).length > 0
		if instance and path == "res://assets/guards/ranged_guard.glb":
			var skeleton := instance.find_child("Skeleton3D", true, false) as Skeleton3D
			checks.ranged_rig_head_and_hand = skeleton != null and skeleton.find_bone("Head") >= 0 and skeleton.find_bone("hand_r") >= 0
			var geometry := 0
			var materials := 0
			for child in instance.find_children("*", "MeshInstance3D", true, false):
				var mesh := child as MeshInstance3D
				if not mesh.mesh: continue
				for surface in mesh.mesh.get_surface_count():
					geometry += mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX].size()
					if mesh.get_active_material(surface) != null: materials += 1
			checks.ranged_geometry_and_materials = geometry > 0 and materials > 0
		if instance: instance.free()
	var channel: Dictionary = CONTACT.lightning_contact_checks(parent)
	var meadow: Dictionary = CONTACT.lightning_contact_checks(parent, preload("res://combat/map02_ranged_adapter.gd"))
	for key in channel: checks["ch01_" + key] = channel[key]
	for key in meadow: checks["e02_" + key] = meadow[key]
	return {"checks": checks, "missing": missing, "resources_inspected": seen.size(),
		"qualification": "opt_in_native_load_and_disposable_contact; ordinary_input_and_independent_acceptance_pending"}
