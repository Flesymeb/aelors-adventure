@tool
class_name Pool
extends Resource

@export var rolls: int = 1 # TODO: IntProvider
@export var rolls_mult_ctx_id: String = ""
@export var entries: Array[PoolEntry] = []
@export var ctx_ops: Array[LTContextOperation] = []

# Optional per-reward RNG. Default callers keep the upstream random source.
# Do not reseed this per frame or per selection.
var rng: RandomNumberGenerator

func _init(rolls: int = 1, entries: Array[PoolEntry] = []):
	self.rolls = rolls
	self.entries = entries

func roll(ctx: Dictionary = {}) -> Array[Resource]:
	ctx = ctx.duplicate(true)
	for op in ctx_ops:
		if op == null:
			return []
		ctx = op.apply(ctx)
	
	var roll_ct := rolls
	if rolls_mult_ctx_id != null && !rolls_mult_ctx_id.is_empty():
		var multiplier := LTContextOperation.get_float_or_default(ctx, rolls_mult_ctx_id, 1.0)
		if not is_finite(multiplier) or multiplier < 0.0:
			return []
		var effective_rolls := float(roll_ct) * multiplier
		if not is_finite(effective_rolls) or effective_rolls < 0.0 or effective_rolls > 1024.0:
			return []
		roll_ct = int(floor(effective_rolls))
	if roll_ct < 0 or roll_ct > 1024:
		return []
	
	return _do_rolls(roll_ct, ctx)

func _do_rolls(roll_ct: int, ctx: Dictionary = {}) -> Array[Resource]:
	var res: Array[Resource] = []
	for r in range(roll_ct):
		var ent: PoolEntry = _roll_entry(_entries(), ctx)
		if ent != null:
			res.append_array(ent.roll(ctx))
	return res

# (in case I want to make this dynamic later)
func _entries() -> Array[PoolEntry]:
	return entries

func _roll_entry(ents: Array[PoolEntry], ctx: Dictionary) -> PoolEntry:
	if ents.is_empty():
		return null
	
	# Context operations may alter weights. Evaluate exactly once per entry and
	# use those same intervals for the draw. Zero weights never select, including
	# at a random draw of zero. Invalid tables fail closed rather than biasing loot.
	var weights := PackedFloat64Array()
	var total_weight: float = 0.0
	for e in ents:
		if e == null:
			return null
		var effective_weight: float = e.calc_weight(ctx.duplicate(true))
		if not is_finite(effective_weight) or effective_weight < 0.0:
			return null
		weights.append(effective_weight)
		total_weight += effective_weight
	if not is_finite(total_weight) or total_weight <= 0.0:
		return null
	var unit: float = rng.randf() if rng != null else randf()
	var threshold := unit * total_weight
	var last_positive: PoolEntry = null
	for i in ents.size():
		if weights[i] <= 0.0:
			continue
		last_positive = ents[i]
		if threshold < weights[i]:
			return ents[i]
		threshold -= weights[i]
	# randf can return 1.0; rounding at the upper endpoint still selects a
	# positive entry, never an appended zero-weight entry.
	return last_positive

func title() -> String:
	return "Pool"

func display_string(str_fn: Callable) -> String:
	var res := " OR ".join(entries.map(func(e: PoolEntry):
		if entries.size() > 1:
			return "%s [%sw]" % [e.display_string(str_fn), str(snapped(e.weight, 0.01))]
		
		return e.display_string(str_fn)
	))
	
	if entries.is_empty():
		return "nothing"
	
	if entries.size() > 1:
		res = "(%s)" % res
	
	if rolls != 1:
		res = "%dx %s" % [rolls, res]
	
	return res
