extends SceneTree
func _initialize() -> void: call_deferred("run_probe")
func run_probe() -> void:
	var all_checks := {}
	for name in ["equipment_dialogue_presentation_test.gd","sword_presentation_test.gd","mixed_finisher_test.gd"]:
		var module = load("res://tests/" + name)
		var checks: Dictionary = await module.run(root)
		for key in checks:
			if checks[key] is bool: all_checks[name+":"+str(key)] = checks[key]
	var chapter = load("res://tests/chapter_travel_test.gd").run()
	for key in chapter:
		if chapter[key] is bool: all_checks["chapter:"+str(key)] = chapter[key]
	var failures := []
	for key in all_checks:
		if not all_checks[key]: failures.append(key)
	print("PRESENTATION_CONTRACT_RESULT=" + JSON.stringify({"checks":all_checks,"assertions":all_checks.size(),"failures":failures,"scope":"Developer source/component UI, existing finisher/trail and story-state regressions; not independent QA"}))
	quit(0 if failures.is_empty() else 3)
