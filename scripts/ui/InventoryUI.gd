extends CanvasLayer

## Inventory screen UI. Shows items, counts, and a Use button for consumables.
## Pauses the game while open.

signal item_used(item_path: String, target: Dictionary)

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBox/Title
@onready var item_list: VBoxContainer = $Panel/VBox/ScrollContainer/ItemList
@onready var detail_label: Label = $Panel/VBox/Detail
@onready var use_btn: Button = $Panel/VBox/Buttons/UseBtn
@onready var close_btn: Button = $Panel/VBox/Buttons/CloseBtn

var _selected_path: String = ""
var _filter_consumable_only: bool = false
## When set, the Use button applies the item to this target dict directly
var _use_target: Dictionary = {}


func _ready() -> void:
	use_btn.pressed.connect(_on_use_pressed)
	close_btn.pressed.connect(close)
	visible = false


func open(filter_consumable: bool = false, target: Dictionary = {}) -> void:
	_filter_consumable_only = filter_consumable
	_use_target = target
	_selected_path = ""
	_refresh()
	visible = true
	get_tree().paused = true


func close() -> void:
	_selected_path = ""
	_use_target = {}
	visible = false
	get_tree().paused = false


func _refresh() -> void:
	# Clear old entries
	for child in item_list.get_children():
		child.queue_free()

	var items: Array[Dictionary]
	if _filter_consumable_only:
		items = InventoryManager.get_consumables()
		title_label.text = "Items (Consumables)"
	else:
		items = InventoryManager.get_all_items()
		title_label.text = "Inventory"

	if items.is_empty():
		var lbl = Label.new()
		lbl.text = "No items."
		item_list.add_child(lbl)
		use_btn.disabled = true
		detail_label.text = ""
		return

	for entry in items:
		var item: ItemData = entry["item"]
		var btn = Button.new()
		btn.text = "%s  x%d" % [item.name, entry["count"]]
		btn.pressed.connect(_on_item_selected.bind(entry["path"]))
		item_list.add_child(btn)

	use_btn.disabled = true
	detail_label.text = "Select an item."


func _on_item_selected(path: String) -> void:
	_selected_path = path
	var entry: Dictionary = InventoryManager.inventory.get(path, {})
	if entry.is_empty():
		return
	var item: ItemData = entry["item"]
	detail_label.text = item.description
	use_btn.disabled = item.item_type != ItemData.ItemType.CONSUMABLE


func _on_use_pressed() -> void:
	if _selected_path == "":
		return
	var success = InventoryManager.use_item(_selected_path, _use_target)
	if success:
		item_used.emit(_selected_path, _use_target)
		if _use_target.is_empty():
			_refresh()
		else:
			# In combat context, close after using
			close()
	else:
		detail_label.text = "Cannot use this item."
