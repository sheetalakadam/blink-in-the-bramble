extends CanvasLayer

var _is_open: bool = false

@onready var panel: PanelContainer = $Panel
@onready var menu_list: VBoxContainer = $Panel/VBox/MenuList


func _ready() -> void:
	panel.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _is_open:
			_close()
		else:
			_open()
		get_viewport().set_input_as_handled()


func _open() -> void:
	_is_open = true
	panel.visible = true
	get_tree().paused = true


func _close() -> void:
	_is_open = false
	panel.visible = false
	get_tree().paused = false


func _on_party_pressed() -> void:
	_close()
	var stats_scene = load("res://scenes/ui/PartyStatsUI.tscn")
	if stats_scene:
		var stats = stats_scene.instantiate()
		get_tree().root.add_child(stats)


func _on_inventory_pressed() -> void:
	_close()
	var inv_scene = load("res://scenes/ui/InventoryUI.tscn")
	if inv_scene:
		var inv = inv_scene.instantiate()
		get_tree().root.add_child(inv)
		inv.open()


func _on_journal_pressed() -> void:
	_close()
	var journal_scene = load("res://scenes/ui/JournalUI.tscn")
	if journal_scene:
		var journal = journal_scene.instantiate()
		get_tree().root.add_child(journal)
		journal.open()


func _on_save_pressed() -> void:
	_close()
	var save_scene = load("res://scenes/ui/SaveLoadUI.tscn")
	if save_scene:
		var save_ui = save_scene.instantiate()
		get_tree().root.add_child(save_ui)


func _on_return_title_pressed() -> void:
	_close()
	get_tree().change_scene_to_file("res://scenes/world/NaevoriaRuins.tscn")
