extends Node2D

signal combat_won
signal combat_lost

# Combat participants
var party: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var all_combatants: Array[Dictionary] = []

# Turn state
var current_entity: Dictionary = {}
var stance_switched_this_turn: bool = false
var waiting_for_input: bool = false

@onready var action_menu: Control = $UI/ActionMenu
@onready var skill_menu: Control = $UI/SkillMenu
@onready var stance_menu: Control = $UI/StanceMenu
@onready var turn_queue_display: HBoxContainer = $UI/TurnQueue
@onready var combat_log: Label = $UI/CombatLog
@onready var party_display: VBoxContainer = $UI/PartyDisplay
@onready var enemy_display: VBoxContainer = $UI/EnemyDisplay
@onready var enemy_intent_label: Label = $UI/EnemyIntent

func _ready() -> void:
	action_menu.visible = false
	skill_menu.visible = false
	stance_menu.visible = false
	CombatManager.turn_started.connect(_on_turn_started)

func start(party_data: Array[Dictionary], enemy_data: Array[Dictionary]) -> void:
	party = party_data
	enemies = enemy_data
	all_combatants = party + enemies
	_update_displays()
	_log("Battle begins!")
	CombatManager.start_combat(all_combatants)

# --- Turn flow ---

func _on_turn_started(entity: Dictionary) -> void:
	current_entity = entity
	stance_switched_this_turn = false
	_update_displays()
	_update_turn_queue()

	if entity.get("is_enemy", false):
		_enemy_turn(entity)
	else:
		_player_turn(entity)

func _player_turn(entity: Dictionary) -> void:
	_log("%s's turn" % entity.name)
	waiting_for_input = true
	_show_action_menu(entity)

func _enemy_turn(entity: Dictionary) -> void:
	_log("%s attacks!" % entity.name)
	await get_tree().create_timer(0.5).timeout

	# Pick random alive party member
	var alive = party.filter(func(p): return p.hp > 0)
	if alive.is_empty():
		_check_end_conditions()
		return
	var target = alive[randi() % alive.size()]

	var damage = maxi(1, entity.attack - target.get("defense", 0))
	target.hp -= damage
	MomentumSystem.add_momentum(-5.0)
	_log("%s hits %s for %d damage!" % [entity.name, target.name, damage])

	CombatVFXManager.trigger_screen_shake(3.0, 0.15)
	_update_displays()

	if _check_end_conditions():
		return

	# Telegraph next attack
	_telegraph_enemy_intent()
	await get_tree().create_timer(0.3).timeout
	CombatManager.advance_turn()

# --- Action menu ---

func _show_action_menu(entity: Dictionary) -> void:
	action_menu.visible = true
	skill_menu.visible = false
	stance_menu.visible = false

func on_attack_pressed() -> void:
	if not waiting_for_input:
		return
	action_menu.visible = false
	_execute_attack(current_entity, _pick_enemy_target(), null)

func on_skill_pressed() -> void:
	if not waiting_for_input:
		return
	action_menu.visible = false
	_show_skill_menu()

func on_stance_pressed() -> void:
	if not waiting_for_input or stance_switched_this_turn:
		return
	action_menu.visible = false
	_show_stance_menu()

func on_defend_pressed() -> void:
	if not waiting_for_input:
		return
	action_menu.visible = false
	waiting_for_input = false
	MomentumSystem.add_momentum(-10.0)
	current_entity["defending"] = true
	_log("%s defends." % current_entity.name)
	_end_player_turn()

# --- Skill sub-menu ---

func _show_skill_menu() -> void:
	# Clear old buttons
	for child in skill_menu.get_node("List").get_children():
		child.queue_free()

	var skills: Array = current_entity.get("skills", [])
	for skill in skills:
		var btn = Button.new()
		btn.text = skill.name
		btn.pressed.connect(_on_skill_selected.bind(skill))
		skill_menu.get_node("List").add_child(btn)

	# Back button
	var back = Button.new()
	back.text = "Back"
	back.pressed.connect(func(): skill_menu.visible = false; action_menu.visible = true)
	skill_menu.get_node("List").add_child(back)

	skill_menu.visible = true

func _on_skill_selected(skill: SkillData) -> void:
	skill_menu.visible = false
	_execute_attack(current_entity, _pick_enemy_target(), skill)

# --- Stance sub-menu ---

func _show_stance_menu() -> void:
	for child in stance_menu.get_node("List").get_children():
		child.queue_free()

	var stances: Array = current_entity.get("stances", [])
	for stance_name in stances:
		var btn = Button.new()
		var prefix = ">> " if stance_name == current_entity.get("active_stance", "") else ""
		btn.text = prefix + stance_name
		btn.pressed.connect(_on_stance_selected.bind(stance_name))
		stance_menu.get_node("List").add_child(btn)

	var back = Button.new()
	back.text = "Back"
	back.pressed.connect(func(): stance_menu.visible = false; action_menu.visible = true)
	stance_menu.get_node("List").add_child(back)

	stance_menu.visible = true

func _on_stance_selected(stance_name: String) -> void:
	stance_menu.visible = false
	current_entity["active_stance"] = stance_name
	stance_switched_this_turn = true
	_log("%s switches to %s" % [current_entity.name, stance_name])
	# Return to action menu — stance switch is free
	action_menu.visible = true

# --- Damage resolution ---

func _execute_attack(attacker: Dictionary, target: Dictionary, skill) -> void:
	waiting_for_input = false

	var base_atk: int = attacker.get("attack", 10)
	var skill_mult: float = 1.0
	var momentum_change: float = 5.0
	var skill_name: String = "Attack"

	if skill != null:
		skill_mult = skill.damage_multiplier
		momentum_change = skill.momentum_change
		skill_name = skill.name

	var stance_mult = StanceSystem.get_multiplier(
		attacker.get("active_stance", ""),
		target.get("armor_type", "")
	)
	var momentum_mult = MomentumSystem.get_damage_multiplier()
	var defense: int = target.get("defense", 0)
	if target.get("defending", false):
		defense *= 2

	var raw_damage = base_atk * skill_mult * stance_mult * momentum_mult
	var final_damage = maxi(1, int(raw_damage) - defense)

	target.hp -= final_damage
	MomentumSystem.add_momentum(momentum_change)

	var msg = "%s uses %s on %s for %d damage!" % [attacker.name, skill_name, target.name, final_damage]
	if stance_mult > 1.0:
		msg += " (Stance advantage!)"
	_log(msg)

	CombatVFXManager.trigger_hit_stop(0.08)
	_update_displays()

	if not _check_end_conditions():
		_end_player_turn()

func _end_player_turn() -> void:
	_telegraph_enemy_intent()
	await get_tree().create_timer(0.3).timeout
	# Clear defend flag
	current_entity.erase("defending")
	CombatManager.advance_turn()

# --- Targeting ---

func _pick_enemy_target() -> Dictionary:
	var alive = enemies.filter(func(e): return e.hp > 0)
	if alive.is_empty():
		return {}
	return alive[0] # Auto-target first alive enemy for MVP

# --- Enemy intent ---

func _telegraph_enemy_intent() -> void:
	var next_enemies = all_combatants.filter(func(e): return e.get("is_enemy", false) and e.hp > 0)
	if next_enemies.is_empty():
		enemy_intent_label.text = ""
		return
	var next = next_enemies[0]
	enemy_intent_label.text = "%s: preparing Attack" % next.name

# --- Win/loss ---

func _check_end_conditions() -> bool:
	var alive_enemies = enemies.filter(func(e): return e.hp > 0)
	var alive_party = party.filter(func(p): return p.hp > 0)

	if alive_enemies.is_empty():
		_log("Victory!")
		combat_won.emit()
		return true
	if alive_party.is_empty():
		_log("Defeat...")
		combat_lost.emit()
		return true
	return false

# --- Display updates ---

func _update_displays() -> void:
	# Party HP
	for child in party_display.get_children():
		child.queue_free()
	for member in party:
		var lbl = Label.new()
		lbl.text = "%s  HP: %d/%d  [%s]" % [
			member.name,
			maxi(0, member.hp),
			member.max_hp,
			member.get("active_stance", "—")
		]
		if member.hp <= 0:
			lbl.modulate = Color(0.5, 0.5, 0.5)
		party_display.add_child(lbl)

	# Enemies
	for child in enemy_display.get_children():
		child.queue_free()
	for enemy in enemies:
		var lbl = Label.new()
		lbl.text = "%s  HP: %d/%d  [%s]" % [
			enemy.name,
			maxi(0, enemy.hp),
			enemy.max_hp,
			enemy.get("armor_type", "?")
		]
		if enemy.hp <= 0:
			lbl.modulate = Color(0.5, 0.5, 0.5)
		enemy_display.add_child(lbl)

func _update_turn_queue() -> void:
	for child in turn_queue_display.get_children():
		child.queue_free()
	for i in mini(5, CombatManager.turn_queue.size()):
		var idx = (CombatManager.active_entity_index + i) % CombatManager.turn_queue.size()
		var entity = CombatManager.turn_queue[idx]
		var lbl = Label.new()
		lbl.text = entity.get("name", "?")
		if entity.get("is_enemy", false):
			lbl.modulate = Color(1.0, 0.4, 0.4)
		turn_queue_display.add_child(lbl)

func _log(msg: String) -> void:
	print("[Combat] ", msg)
	if combat_log:
		combat_log.text = msg
