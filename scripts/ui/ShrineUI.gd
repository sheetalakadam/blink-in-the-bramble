extends CanvasLayer

## Popup UI for shrine boon selection.
## Shows god name, boon details, cost, and accept/decline buttons.

@onready var panel: PanelContainer = $Panel
@onready var god_label: Label = $Panel/VBox/GodName
@onready var boon_label: Label = $Panel/VBox/BoonName
@onready var desc_label: Label = $Panel/VBox/Description
@onready var cost_label: Label = $Panel/VBox/Cost
@onready var accept_btn: Button = $Panel/VBox/Buttons/Accept
@onready var decline_btn: Button = $Panel/VBox/Buttons/Decline

var _current_data: ShrineData = null


func _ready() -> void:
	accept_btn.pressed.connect(_on_accept)
	decline_btn.pressed.connect(_on_decline)
	visible = false


func show_boon(shrine_data: ShrineData) -> void:
	_current_data = shrine_data
	god_label.text = shrine_data.god_name
	boon_label.text = shrine_data.boon_name
	desc_label.text = shrine_data.boon_description
	cost_label.text = "%s: %d" % [shrine_data.cost_type.capitalize(), shrine_data.cost_amount]
	visible = true
	get_tree().paused = true


func _on_accept() -> void:
	if _current_data:
		var sm = get_node_or_null("/root/ShrineManager")
		if sm:
			var success = sm.activate_boon(_current_data)
			if not success:
				print("[ShrineUI] Cannot afford boon cost")
	_close()


func _on_decline() -> void:
	_close()


func _close() -> void:
	_current_data = null
	visible = false
	get_tree().paused = false
