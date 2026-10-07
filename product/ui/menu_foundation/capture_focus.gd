extends Control
## Node that captures UI focus when switching menus.
##
## This script assists with capturing UI focus when
## opening, closing, or switching between menus.
## When attached to a node, it will check if it was changed to visible
## and if it should grab focus. If both are true, it will capture focus
## on the first eligible node in its scene tree.

## Hierarchical depth to search in the scene tree for a focusable control node.
@export var search_depth : int = 1
## If true, always capture focus when made visible.
@export var enabled : bool = false
## If true, capture focus if nothing currently is in focus.
@export var null_focus_enabled : bool = true
## If true, capture focus if there is a joypad detected.
@export var joypad_enabled : bool = true
## If true, capture focus if the mouse is hidden.
@export var mouse_hidden_enabled : bool = true

## Locks focus
@export var lock : bool = false :
	set(value):
		var value_changed : bool = lock != value
		lock = value
		if value_changed and not lock:
			update_focus()

static func selectable_item(control_node: ItemList) -> int:
	# Retain a real selection when returning from a submenu.
	for index in control_node.get_selected_items():
		if index < control_node.item_count and control_node.is_item_selectable(index) and not control_node.is_item_disabled(index):
			return index
	for index in range(control_node.item_count):
		if control_node.is_item_selectable(index) and not control_node.is_item_disabled(index):
			return index
	return -1

func _focus_first_search(control_node : Node, levels : int = 1) -> bool:
	if not control_node is Control or !control_node.is_visible_in_tree():
		return false
	if control_node.focus_mode == FOCUS_ALL and not (control_node is BaseButton and control_node.disabled):
		if control_node is ItemList:
			var index := selectable_item(control_node)
			if index >= 0:
				control_node.select(index)
				control_node.grab_focus()
				return true
		else:
			control_node.grab_focus()
			return true
	if levels < 1:
		return false
	var children = control_node.get_children()
	for child in children:
		if _focus_first_search(child, levels - 1):
			return true
	return false

func focus_first() -> void:
	_focus_first_search(self, search_depth)

func update_focus() -> void:
	if lock : return
	if _is_visible_and_should_capture():
		focus_first()

func _should_capture_focus() -> bool:
	var _null_focus := get_viewport().gui_get_focus_owner() == null and null_focus_enabled
	var _joypad_detected := Input.get_connected_joypads().size() > 0 and joypad_enabled
	var _mouse_hidden := Input.mouse_mode not in [Input.MOUSE_MODE_VISIBLE, Input.MOUSE_MODE_CONFINED] and mouse_hidden_enabled
	return enabled or _null_focus or _joypad_detected or _mouse_hidden

func _is_visible_and_should_capture() -> bool:
	return is_visible_in_tree() and _should_capture_focus()

func _on_visibility_changed() -> void:
	call_deferred("update_focus")

func _ready() -> void:
	if is_inside_tree():
		update_focus()
		connect("visibility_changed", _on_visibility_changed)
