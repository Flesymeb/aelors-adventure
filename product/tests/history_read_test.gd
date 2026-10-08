extends RefCounted
## Explicitly invoked regression test; never attached or run at product startup.
## These synthetic fixtures establish reader behavior, not historical compatibility.
const READER := preload("res://systems/history_config_reader.gd")

class ProbeState extends "res://dialogue_state.gd":
	var corrupt := false
	func _history_path(slot: int) -> String:
		return "res://tests/fixtures/history_corrupt.cfg" if corrupt or slot == 0 else "res://tests/fixtures/history_slot%d.cfg" % slot

static func run() -> Dictionary:
	var state := ProbeState.new()
	var checks := {}
	state.corrupt = true
	var before := FileAccess.get_file_as_bytes(state._history_path(1))
	checks["corrupt_reason"] = state.slot_unavailable_reason(1) == "存档无法读取"
	checks["corrupt_preview"] = state.slot_preview(1).reason == "存档无法读取"
	checks["corrupt_load"] = state.load_progress(1).is_empty()
	checks["corrupt_unchanged"] = before == FileAccess.get_file_as_bytes(state._history_path(1))
	state.corrupt = false
	for slot in [1, 2]:
		var path := state._history_path(slot)
		before = FileAccess.get_file_as_bytes(path)
		var facts := state.slot_preview(slot)
		var restored := state.load_progress(slot)
		checks["valid_slot_%d" % slot] = facts.reason == "" and facts.slot == slot and not restored.is_empty() and state.experience == slot * 10 and state.lives == slot + 3 and state.confirmed_choices == ["Q01_accept"]
		checks["valid_unchanged_%d" % slot] = before == FileAccess.get_file_as_bytes(path)
	for lives in [-1, 0, 1, 3, 4, 5, 6, 1.5, "five", true, INF, NAN]:
		var config := ConfigFile.new()
		config.set_value("opening", "position", Vector3(1, 2, 3))
		config.set_value("training", "lives", lives)
		var history := READER.decode(config.encode_to_text())
		var accepted: bool = history.reason == "" and state.config_unavailable_reason(history.config) == ""
		checks["lives_%s" % str(lives)] = accepted == (lives is int and lives in [1, 3, 4, 5])
	for malformed in ["[opening", "[opening]\nposition=Vector3(1,2)", "[opening]\nchoices=[\"bad\"", "[opening]\nnode=\"D01", "[opening]\nvalue={\"a\" 2}", "[opening]\nvalue=unknown()"]:
		checks[malformed] = READER.decode(malformed).reason == "存档无法读取"
	var missing := READER.decode("[opening]\nnode=\"D01\"")
	checks["missing_position"] = state.config_unavailable_reason(missing.config) == "存档位置无效"
	checks["invalid_utf8"] = not READER._valid_utf8(PackedByteArray([0xff])) and not READER._valid_utf8(PackedByteArray([0xed, 0xa0, 0x80])) and not READER._valid_utf8(PackedByteArray([0xf4, 0x90, 0x80, 0x80]))
	checks["valid_utf8"] = READER._valid_utf8("中文".to_utf8_buffer())
	state.free()
	return checks
