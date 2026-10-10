extends Node
## Actual GLoot bag and slot; save history is a stable-ID projection, never a second live bag.
signal changed
const PROTOSET = preload("res://data/item_protoset.json")
const IDS = ["sword", "bow", "lamp", "healing", "lifeflame"]
var state: Node
var bag: Inventory
var equipment: ItemSlot

func _ready() -> void:
	name = "ProductInventory"
	bag = Inventory.new()
	bag.name = "Backpack"
	bag.protoset = PROTOSET
	var limit = ItemCountConstraint.new()
	limit.capacity = 12
	bag.add_child(limit)
	add_child(bag)
	equipment = ItemSlot.new()
	equipment.name = "Equipment"
	equipment.protoset = PROTOSET
	add_child(equipment)

static func valid_history(history: Dictionary) -> bool:
	if history.size() > 5: return false
	for id in history:
		if id not in IDS or not history[id] is int or history[id] <= 0: return false
		if history[id] > (9 if id == "healing" else (5 if id == "lifeflame" else 1)): return false
	return true

func restore() -> void:
	if bag == null: return
	if equipment.get_item(): equipment.clear()
	bag.clear()
	if not valid_history(state.bag_history):
		state.persistence_error = "背包记录无效"
		return
	for id in state.bag_history: accept(id, state.bag_history[id])
	ensure_equipment()
	select_equipment(state.selected_equipment)
	changed.emit()

func ensure_equipment() -> void:
	for pair in [["sword",state.sword_owned],["bow",state.bow_owned],["lamp",state.lamp_owned]]:
		if pair[1] and count(pair[0]) == 0: accept(pair[0], 1)

func count(id: String) -> int:
	var total = 0
	for item in bag.get_items():
		if item.get_prototype().get_prototype_id() == id: total += item.get_stack_size()
	var equipped = equipment.get_item()
	if equipped and equipped.get_prototype().get_prototype_id() == id: total += equipped.get_stack_size()
	return total

func snapshot() -> Dictionary:
	var result = {}
	for id in IDS:
		var amount = count(id)
		if amount > 0: result[id] = amount
	return result

func accept(id: String, amount: int) -> bool:
	if id not in IDS or amount <= 0: return false
	var max_count = 9 if id == "healing" else (5 if id == "lifeflame" else 1)
	var existing = bag.get_item_with_prototype_id(id)
	if count(id) + amount > max_count: return false
	if existing:
		if not existing.set_stack_size(existing.get_stack_size() + amount): return false
	else:
		if bag.get_item_count() >= 12: return false
		var item = bag.create_item(id)
		if item == null: return false
		if not item.set_stack_size(amount) or not bag.add_item(item): return false
	changed.emit()
	return true

func select_equipment(id: String) -> bool:
	if id not in ["unarmed","sword","bow","lamp"]: return false
	var old = equipment.get_item()
	if old and old.get_prototype().get_prototype_id() == id: return true
	var item = bag.get_item_with_prototype_id(id) if id != "unarmed" else null
	if id != "unarmed" and item == null: return false
	# Preserve the item on failed transfer; stock clear deletes its old contents.
	if old:
		if not equipment._inventory.remove_item(old): return false
		if not bag.add_item(old):
			equipment._inventory.add_item(old)
			return false
	if item and not equipment.equip(item):
		if old: equipment.equip(old)
		return false
	changed.emit()
	return true

func use_item(id: String) -> bool:
	var item = bag.get_item_with_prototype_id(id)
	if item == null or state.health <= 0 or state.recovery_pending: return false
	if id == "healing":
		if state.health >= 100: return false
		state.health = minf(100, state.health + 30)
	elif id == "lifeflame":
		if state.lives >= 5: return false
		state.lives += 1
	else: return false
	if item.get_stack_size() == 1: bag.remove_item(item)
	else: item.set_stack_size(item.get_stack_size() - 1)
	changed.emit()
	return true

func _mcp_state() -> Dictionary:
	return {"contents":snapshot(), "bag_items":bag.get_item_count(), "equipped":equipment.get_item().get_title() if equipment.get_item() else "空", "quick_item":state.quick_item}

# Branch supplies settle against the same health/ammunition authority as items.
# This is called only by DialogueState's eligible, unclaimed interaction.
func settle_bridge_supply() -> Dictionary:
	var before_health: float = state.health
	var before_arrows: int = state.arrows
	state.health = minf(100, state.health + 30)
	if state.bow_owned: state.arrows = mini(12, state.arrows + 4)
	changed.emit()
	return {"health":state.health - before_health, "arrows":state.arrows - before_arrows}

# Fixed E02 recovery is not a bag item or an enemy XP reward.
func settle_recovery_supply(amount: float) -> Dictionary:
	if state.health <= 0 or state.recovery_pending or state.health >= 100: return {}
	var before: float = state.health
	state.health = minf(100, state.health + amount)
	changed.emit()
	return {"health":state.health - before}
