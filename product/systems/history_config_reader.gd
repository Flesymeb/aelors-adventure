extends RefCounted
## Quiet, read-only decoding of the native ConfigFile history representation.
## ConfigFile remains the save/restore carrier; no writes or state restoration here.
var text := ""
var cursor := 0
var valid := true
const TYPES := {"bool": TYPE_BOOL, "int": TYPE_INT, "float": TYPE_FLOAT,
	"String": TYPE_STRING, "Vector2": TYPE_VECTOR2, "Vector2i": TYPE_VECTOR2I,
	"Vector3": TYPE_VECTOR3, "Vector3i": TYPE_VECTOR3I, "Vector4": TYPE_VECTOR4,
	"Vector4i": TYPE_VECTOR4I, "Color": TYPE_COLOR, "Dictionary": TYPE_DICTIONARY,
	"Array": TYPE_ARRAY, "StringName": TYPE_STRING_NAME, "NodePath": TYPE_NODE_PATH}
const NUMERIC_CONSTRUCTORS := {"Vector2": 2, "Vector2i": 2, "Vector3": 3,
	"Vector3i": 3, "Vector4": 4, "Vector4i": 4, "Rect2": 4, "Rect2i": 4,
	"Plane": 4, "Quaternion": 4, "Color": 4, "AABB": 6, "Basis": 9,
	"Transform2D": 6, "Transform3D": 12, "Projection": 16}
const PACKED_TYPES := {"PackedByteArray": TYPE_INT, "PackedInt32Array": TYPE_INT,
	"PackedInt64Array": TYPE_INT, "PackedFloat32Array": TYPE_FLOAT,
	"PackedFloat64Array": TYPE_FLOAT, "PackedStringArray": TYPE_STRING,
	"PackedVector2Array": TYPE_VECTOR2, "PackedVector3Array": TYPE_VECTOR3,
	"PackedColorArray": TYPE_COLOR, "PackedVector4Array": TYPE_VECTOR4}

static func read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"reason": "暂无存档"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {"reason": "存档无法读取"}
	var bytes := file.get_buffer(file.get_length())
	if file.get_error() not in [OK, ERR_FILE_EOF]: return {"reason": "存档无法读取"}
	# Decoding damaged UTF-8 through FileAccess.get_as_text logs engine errors.
	if not _valid_utf8(bytes): return {"reason": "存档无法读取"}
	return decode(bytes.get_string_from_utf8().trim_prefix(String.chr(0xfeff)))

static func _valid_utf8(bytes: PackedByteArray) -> bool:
	var index := 0
	while index < bytes.size():
		var first := int(bytes[index])
		index += 1
		if first == 0: return false
		if first < 0x80: continue
		var count := 1 if first >= 0xc2 and first < 0xe0 else (2 if first >= 0xe0 and first < 0xf0 else (3 if first >= 0xf0 and first < 0xf5 else -1))
		if count < 0 or index + count > bytes.size(): return false
		var codepoint := first & (0x7f >> (count + 1))
		for offset in count:
			var next := int(bytes[index + offset])
			if next < 0x80 or next > 0xbf: return false
			codepoint = (codepoint << 6) | (next & 0x3f)
		if codepoint < [0, 0x80, 0x800, 0x10000][count] or codepoint > 0x10ffff or (codepoint >= 0xd800 and codepoint < 0xe000): return false
		index += count
	return true

static func decode(data: String) -> Dictionary:
	var reader = load("res://systems/history_config_reader.gd").new()
	reader.text = data
	return reader._config()

func _config() -> Dictionary:
	var config := ConfigFile.new()
	var section := ""
	while valid:
		_space()
		if cursor == text.length(): return {"reason": "", "config": config}
		if _take("["):
			var end := text.find("]", cursor)
			if end == -1 or "\n" in text.substr(cursor, end - cursor): break
			section = text.substr(cursor, end - cursor).strip_edges()
			cursor = end + 1
		else:
			var start := cursor
			while cursor < text.length() and text[cursor] not in ["=", "\n", ";"]: cursor += 1
			var key := text.substr(start, cursor - start).strip_edges()
			if key.is_empty() or not _take("="): break
			var value: Variant = _value(0)
			if not valid: break
			config.set_value(section, key, value)
	return {"reason": "存档无法读取"}

func _space() -> void:
	while cursor < text.length():
		if text[cursor] in [" ", "\t", "\r", "\n"]: cursor += 1
		elif text[cursor] == ";":
			while cursor < text.length() and text[cursor] != "\n": cursor += 1
		else: break

func _take(token: String) -> bool:
	_space()
	if text.substr(cursor, token.length()) != token: return false
	cursor += token.length()
	return true

func _require(token: String) -> void:
	if not _take(token): valid = false

func _value(depth: int) -> Variant:
	_space()
	# Bound malformed nesting before it can exhaust the game stack.
	if depth > 64 or cursor >= text.length():
		valid = false
		return null
	if text[cursor] == '"': return _string()
	if _take("&"):
		if cursor >= text.length() or text[cursor] != '"':
			valid = false
			return null
		var name_value: Variant = _string()
		return StringName(name_value) if valid else null
	if _take("["): return _list("]", depth)
	if _take("{"):
		var result := {}
		if _take("}"): return result
		while valid:
			var key: Variant = _value(depth + 1)
			_require(":")
			var value: Variant = _value(depth + 1)
			if not valid: return null
			result[key] = value
			if _take("}"): return result
			_require(",")
			if _take("}"): return result
		return null
	var start := cursor
	while cursor < text.length() and text[cursor] not in [" ", "\t", "\r", "\n", ";", ",", ":", "[", "]", "{", "}", "(", ")"]: cursor += 1
	var atom := text.substr(start, cursor - start)
	if atom in ["null", "nil"]: return null
	if atom == "true": return true
	if atom == "false": return false
	if atom in ["inf", "+inf"]: return INF
	if atom in ["-inf", "inf_neg"]: return -INF
	if atom == "nan": return NAN
	if atom.is_valid_int(): return atom.to_int()
	if atom.is_valid_float(): return atom.to_float()
	if atom == "Array" or atom == "Dictionary":
		var type_id := TYPE_NIL
		var value_type := TYPE_NIL
		if _take("["):
			_space()
			start = cursor
			while cursor < text.length() and text[cursor] not in ["]", ","]: cursor += 1
			var type_name := text.substr(start, cursor - start).strip_edges()
			if not TYPES.has(type_name): valid = false
			else: type_id = TYPES[type_name]
			if atom == "Dictionary":
				_require(",")
				_space()
				start = cursor
				while cursor < text.length() and text[cursor] != "]": cursor += 1
				type_name = text.substr(start, cursor - start).strip_edges()
				if not TYPES.has(type_name): valid = false
				else: value_type = TYPES[type_name]
			_require("]")
		_require("(")
		var values: Variant = _value(depth + 1)
		_require(")")
		if (atom == "Array" and not values is Array) or (atom == "Dictionary" and not values is Dictionary): valid = false
		if not valid: return null
		if type_id == TYPE_NIL: return values
		for item in values:
			if typeof(item) != type_id or (atom == "Dictionary" and typeof(values[item]) != value_type):
				valid = false
				return null
		return Array(values, type_id, "", null) if atom == "Array" else Dictionary(values, type_id, "", null, value_type, "", null)
	if atom in ["StringName", "NodePath"]:
		_require("(")
		var value: Variant = _value(depth + 1)
		_require(")")
		if not value is String: valid = false
		if not valid: return null
		return StringName(value) if atom == "StringName" else NodePath(value)
	if NUMERIC_CONSTRUCTORS.has(atom) or PACKED_TYPES.has(atom):
		_require("(")
		var args := _list(")", depth)
		if NUMERIC_CONSTRUCTORS.has(atom) and args.size() != NUMERIC_CONSTRUCTORS[atom]: valid = false
		for arg in args:
			if NUMERIC_CONSTRUCTORS.has(atom):
				if not (arg is int or arg is float): valid = false
			elif atom in ["PackedVector2Array", "PackedVector3Array", "PackedVector4Array", "PackedColorArray"]:
				if not (arg is int or arg is float): valid = false
			elif typeof(arg) != PACKED_TYPES[atom] and not (PACKED_TYPES[atom] == TYPE_FLOAT and arg is int): valid = false
		if atom in ["PackedVector2Array", "PackedVector3Array", "PackedVector4Array", "PackedColorArray"]:
			var width := 2 if atom == "PackedVector2Array" else (3 if atom == "PackedVector3Array" else 4)
			if args.size() % width != 0: valid = false
			if valid:
				var grouped := []
				for offset in range(0, args.size(), width):
					if width == 2: grouped.append(Vector2(args[offset], args[offset + 1]))
					elif width == 3: grouped.append(Vector3(args[offset], args[offset + 1], args[offset + 2]))
					elif atom == "PackedColorArray": grouped.append(Color(args[offset], args[offset + 1], args[offset + 2], args[offset + 3]))
					else: grouped.append(Vector4(args[offset], args[offset + 1], args[offset + 2], args[offset + 3]))
				args = grouped
		if not valid: return null
		if NUMERIC_CONSTRUCTORS.has(atom):
			# Native Variant syntax has scalar constructors (e.g. Transform3D)
			# that differ from GDScript constructors. Only sanitized numeric values
			# with the exact native arity reach this parser, never file syntax.
			var literals := PackedStringArray()
			for arg in args: literals.append(var_to_str(arg))
			return str_to_var(atom + "(" + ",".join(literals) + ")")
		# Only a whitelisted native value constructor and decoded numeric literals
		# reach Expression. No identifiers, operators, objects or gameplay calls.
		var names := PackedStringArray()
		for index in args.size(): names.append("value%d" % index)
		var expression := Expression.new()
		var arguments := ",".join(names)
		var inputs := args
		if PACKED_TYPES.has(atom):
			names = PackedStringArray(["values"])
			arguments = "values"
			inputs = [args]
		if expression.parse(atom + "(" + arguments + ")", names) != OK:
			valid = false
			return null
		var value: Variant = expression.execute(inputs, null, false)
		if expression.has_execute_failed(): valid = false
		return value
	valid = false
	return null

func _list(end: String, depth: int) -> Array:
	var values := []
	if _take(end): return values
	while valid:
		values.append(_value(depth + 1))
		if _take(end): return values
		_require(",")
		if _take(end): return values
	return values

func _string() -> Variant:
	var start := cursor
	cursor += 1
	while cursor < text.length():
		var character := text[cursor]
		cursor += 1
		if character == "\\": cursor += 1
		elif character == '"':
			var json := JSON.new()
			if json.parse(text.substr(start, cursor - start)) == OK: return json.data
			break
	valid = false
	return null
