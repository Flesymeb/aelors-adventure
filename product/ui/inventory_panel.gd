extends "res://ui/menu_foundation/main_menu.gd"
const FOCUS_HELPER := preload("res://ui/menu_foundation/capture_focus.gd")
var world: Node3D
var suspended = false
var bag_list: CtrlInventory
var status: Label
var equipped: Label
var use_button: Button
var quick_button: Button
var return_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$BackgroundTextureRect.hide()
	%MenuContainer.hide()
	var column = create_page(self,"行路背包",true)
	equipped = paragraph(column,"")
	bag_list = CtrlInventory.new()
	bag_list.icon_mode = ItemList.ICON_MODE_TOP
	bag_list.fixed_icon_size = Vector2i(64,64)
	bag_list.fixed_column_width = 120
	bag_list.max_columns = 4
	bag_list.same_column_width = true
	bag_list.max_text_lines = 2
	bag_list.inventory = state.inventory.bag
	bag_list.custom_minimum_size = Vector2(0,220)
	bag_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(bag_list)
	bag_list.inventory_item_selected.connect(func(_item): refresh())
	bag_list.inventory_item_activated.connect(func(_item): use_selected())
	var row = HBoxContainer.new()
	column.add_child(row)
	use_button = button(row,"使用 / 装备",use_selected)
	quick_button = button(row,"设为物品快捷栏 [6]",assign_selected)
	button(row,"收起装备",unequip)
	status = paragraph(column,"选择背包中的真实物品，再使用或装备。疗伤药恢复 30 生命；命火最多 5。")
	return_button = button(get_meta("footer_column"),"返回 [I / Esc]",close_panel)
	state.inventory.changed.connect(refresh)
	refresh()

func refresh() -> void:
	if equipped == null: return
	var item = state.inventory.equipment.get_item()
	equipped.text = "当前装备：%s · 箭 %d / 12\n物品快捷栏 [6]：%s ×%d" % [item.get_title() if item else "空",state.arrows,"疗伤药" if state.quick_item == "healing" else "命火",state.inventory.count(state.quick_item)]
	var selected = bag_list.get_selected_inventory_item()
	var focused := get_viewport().gui_get_focus_owner()
	use_button.disabled = selected == null
	quick_button.disabled = selected == null or selected.get_prototype().get_prototype_id() not in ["healing","lifeflame"]
	# An empty/nonselectable grid must not trap keyboard navigation.
	bag_list.focus_mode = Control.FOCUS_ALL if FOCUS_HELPER.selectable_item(bag_list) >= 0 else Control.FOCUS_NONE
	if is_visible_in_tree() and return_button and (focused == bag_list and bag_list.focus_mode == Control.FOCUS_NONE or focused == use_button and use_button.disabled or focused == quick_button and quick_button.disabled):
		return_button.grab_focus.call_deferred()
	reflow(self)

func use_selected() -> void:
	var item = bag_list.get_selected_inventory_item()
	if item == null: return
	var id = item.get_prototype().get_prototype_id()
	if id in ["sword","bow","lamp"]:
		close_panel()
		world.player.request_weapon(id)
	else:
		if state.inventory.use_item(id): world.training.commit(); status.text = "物品已使用"
		else: status.text = "当前无需使用，物品未消耗"
	refresh()

func assign_selected() -> void:
	var item = bag_list.get_selected_inventory_item()
	if item == null: return
	var id = item.get_prototype().get_prototype_id()
	if id not in ["healing","lifeflame"]: return
	state.quick_item = id
	world.training.commit()
	refresh()

func unequip() -> void:
	close_panel()
	world.player.request_weapon("unarmed")

func open_panel() -> void:
	world._set_pause_owner("bag",true)
	show()
	refresh()
	_restore_bag_focus.call_deferred()

func _restore_bag_focus() -> void:
	if not is_visible_in_tree() or suspended: return
	var index := FOCUS_HELPER.selectable_item(bag_list)
	if index >= 0:
		bag_list.select(index)
		bag_list.grab_focus()
	else:
		return_button.grab_focus()
	# ItemList.select does not emit item_selected; synchronize actions explicitly.
	refresh()

func close_panel() -> void:
	suspended = false
	hide()
	world._set_pause_owner("bag",false)
	audio.play_cue("back")

func suspend_for_menu() -> void:
	suspended = true
	hide()

func resume_from_menu() -> void:
	suspended = false
	show()
	refresh()
	_restore_bag_focus.call_deferred()

func _input(_event: InputEvent) -> void: pass
func _unhandled_input(_event: InputEvent) -> void: pass

func _mcp_state() -> Dictionary:
	var focus := get_viewport().gui_get_focus_owner()
	return {"visible":visible,"suspended":suspended,"contents":state.inventory.snapshot(),"item_count":bag_list.item_count,"selected_indices":Array(bag_list.get_selected_items()),"selected":bag_list.get_selected_inventory_item().get_title() if bag_list.get_selected_inventory_item() else "","focus_owner":str(focus.get_path()) if focus else "","use_disabled":use_button.disabled,"quick_disabled":quick_button.disabled,"return_focused":return_button.has_focus(),"status":status.text}
