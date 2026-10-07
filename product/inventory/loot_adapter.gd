extends RefCounted
## The adopted Pool/SingleEntry units draw the reward payload once per death.
static func roll() -> Dictionary:
	var entries: Array[PoolEntry] = []
	for pair in [["healing",3.0],["lifeflame",1.0]]:
		var entry = SingleEntry.new()
		entry.weight = pair[1]
		var payload = Resource.new()
		payload.set_meta("item_id", pair[0])
		entry.resource = payload
		entries.append(entry)
	var pool = Pool.new(1, entries)
	var result = pool.roll({})
	return {"id":str(result[0].get_meta("item_id")), "quantity":1} if not result.is_empty() else {}
