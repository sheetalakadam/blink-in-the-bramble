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
var _pending_skill = null # Skill awaiting target selection
var _pending_action: String = "" # "attack" or "skill" awaiting target

# Boon state
var _active_boon_effect: String = ""
var _auto_revive_available: bool = false
var _extra_turn_available: bool = false
var _bond_strike_available: bool = false

# Boss encounter
var _boss_controller: BossController = BossController.new()

@onready var action_menu: Control = $UI/ActionMenu
@onready var skill_menu: Control = $UI/SkillMenu
@onready var stance_menu: Control = $UI/StanceMenu
@onready var turn_queue_display: HBoxContainer = $UI/TurnQueue
@onready var combat_log: RichTextLabel = $UI/CombatLog
@onready var target_menu: Control = $UI/TargetMenu
@onready var party_display: VBoxContainer = $UI/PartyDisplay
@onready var enemy_display: VBoxContainer = $UI/EnemyDisplay
@onready var enemy_intent_label: Label = $UI/EnemyIntent

func _ready() -> void:
	action_menu.visible = false
	skill_menu.visible = false
	stance_menu.visible = false
	target_menu.visible = false
	CombatManager.turn_started.connect(_on_turn_started)

func start(party_data: Array[Dictionary], enemy_data: Array[Dictionary]) -> void:
	party = party_data
	enemies = enemy_data
	all_combatants = party + enemies
	_update_displays()
	_log("Battle begins!")
	CombatManager.start_combat(all_combatants)


func apply_boon(effect: String) -> void:
	_active_boon_effect = effect
	match effect:
		"reveal_armor":
			for enemy in enemies:
				_log("[Auryn's Sight] %s armor: %s" % [enemy.name, enemy.get("armor_type", "Unknown")])
		"auto_revive":
			_auto_revive_available = true
			_log("[Morrael's Grace] One party member will be revived if fallen.")
		"surge_extend":
			MomentumSystem.set_surge_protection(true)
			_log("[Varek's Fire] Surge damage taken reduced by 20%%.")
		"extra_turn":
			_extra_turn_available = true
			_log("[Lyenne's Gift] One extra turn available.")
		"bond_strike":
			_bond_strike_available = true
			_log("[Thessia's Bond] Bond Strike available this battle.")

# --- Turn flow ---

func _on_turn_started(entity: Dictionary) -> void:
	# Clear defend flag at the START of this entity's turn (not end of previous)
	entity.erase("defending")
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
	var attack_label: String = entity.get("_current_attack_name", "attacks")
	if entity.get("is_boss", false):
		_log("%s uses %s!" % [entity.name, attack_label])
	else:
		_log("%s attacks!" % entity.name)
	await get_tree().create_timer(0.5).timeout

	# Pick random alive party member
	var alive = party.filter(func(p): return p.hp > 0)
	if alive.is_empty():
		_check_end_conditions()
		return
	var target = alive[randi() % alive.size()]

	var target_defense: int = target.get("defense", 0)
	if target.get("defending", false):
		target_defense *= 2
	var damage = maxi(1, entity.attack - target_defense)
	target.hp -= damage
	MomentumSystem.add_momentum(-5.0)
	_log("%s hits %s for %d damage!" % [entity.name, target.name, damage])

	# Auto-revive check (Morrael boon)
	if target.hp <= 0 and _auto_revive_available:
		target.hp = maxi(1, int(target.max_hp * 0.3))
		_auto_revive_available = false
		_log("[Morrael's Grace] %s is revived!" % target.name)

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

	# Add boon buttons dynamically
	var boon_container = action_menu.get_node_or_null("BoonButtons")
	if boon_container == null:
		boon_container = VBoxContainer.new()
		boon_container.name = "BoonButtons"
		action_menu.get_node("VBoxContainer").add_child(boon_container)
	for child in boon_container.get_children():
		child.queue_free()

	if _extra_turn_available:
		var btn = Button.new()
		btn.text = "Time (Lyenne)"
		btn.pressed.connect(_on_extra_turn_pressed)
		boon_container.add_child(btn)

	if _bond_strike_available:
		var btn = Button.new()
		btn.text = "Bond Strike (Thessia)"
		btn.pressed.connect(_on_bond_strike_pressed)
		boon_container.add_child(btn)

func on_attack_pressed() -> void:
	if not waiting_for_input:
		return
	action_menu.visible = false
	_pending_action = "attack"
	_pending_skill = null
	_show_target_menu()

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
		var sign_str = "+" if skill.momentum_change >= 0 else ""
		btn.text = "%s (M: %s%d)" % [skill.name, sign_str, int(skill.momentum_change)]
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
	_pending_action = "skill"
	_pending_skill = skill
	_show_target_menu()

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

# --- Boon actions ---

func _on_extra_turn_pressed() -> void:
	if not waiting_for_input or not _extra_turn_available:
		return
	_extra_turn_available = false
	_log("[Lyenne's Gift] %s gains an extra turn!" % current_entity.name)
	# Don't end the turn — just hide the menu and show it again
	action_menu.visible = false
	_show_action_menu(current_entity)

func _on_bond_strike_pressed() -> void:
	if not waiting_for_input or not _bond_strike_available:
		return
	_bond_strike_available = false
	action_menu.visible = false
	var target = _pick_enemy_target()
	if target.is_empty():
		return
	waiting_for_input = false
	var partner = AffinityManager.get_highest_affinity_pair()
	var base_atk: int = current_entity.get("attack", 10)
	var raw_damage = base_atk * 1.5
	var defense: int = target.get("defense", 0)
	var final_damage = maxi(1, int(raw_damage) - defense)
	target.hp -= final_damage
	_log("[Thessia's Bond] %s and %s strike together for %d damage!" % [current_entity.name, partner, final_damage])
	_update_displays()
	if not _check_end_conditions():
		_end_player_turn()

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

	# Auto-revive check (Morrael boon)
	if target.hp <= 0 and not target.get("is_enemy", false) and _auto_revive_available:
		target.hp = maxi(1, int(target.max_hp * 0.3))
		_auto_revive_available = false
		_log("[Morrael's Grace] %s is revived!" % target.name)

	var msg = "%s uses %s on %s for %d damage!" % [attacker.name, skill_name, target.name, final_damage]
	if stance_mult > 1.0:
		msg += " (Stance advantage!)"
	_log(msg)

	# Boss phase transition check
	if target.get("is_boss", false) and target.hp > 0:
		if _boss_controller.check_phase_transition(target):
			var phase_idx: int = target.get("_current_phase_index", 0)
			var transition_msg = BossController.get_phase_transition_message(target, phase_idx)
			_log(transition_msg)
			# Optionally trigger dialogue on phase change
			var boss_data = target.get("boss_data") as BossData
			if boss_data and boss_data.dialogue_on_phase_change != "":
				if DialogueManager:
					DialogueManager.start_dialogue(boss_data.dialogue_on_phase_change)

	CombatVFXManager.trigger_hit_stop(0.08)
	_update_displays()

	if not _check_end_conditions():
		_end_player_turn()

func _end_player_turn() -> void:
	_telegraph_enemy_intent()
	await get_tree().create_timer(0.3).timeout
	# Defend flag is now cleared in _on_turn_started so it persists through enemy turns
	CombatManager.advance_turn()

# --- Target selection menu ---

func _show_target_menu() -> void:
	for child in target_menu.get_node("List").get_children():
		child.queue_free()

	var alive = enemies.filter(func(e): return e.hp > 0)
	if alive.size() == 1:
		# Only one target — skip the menu
		_on_target_selected(alive[0])
		return

	for enemy in alive:
		var btn = Button.new()
		btn.text = "%s (HP: %d/%d)" % [enemy.name, maxi(0, enemy.hp), enemy.max_hp]
		btn.pressed.connect(_on_target_selected.bind(enemy))
		target_menu.get_node("List").add_child(btn)

	var back = Button.new()
	back.text = "Back"
	back.pressed.connect(func():
		target_menu.visible = false
		action_menu.visible = true
		_pending_action = ""
		_pending_skill = null
	)
	target_menu.get_node("List").add_child(back)

	target_menu.visible = true

func _on_target_selected(target: Dictionary) -> void:
	target_menu.visible = false
	_execute_attack(current_entity, target, _pending_skill)
	_pending_action = ""
	_pending_skill = null

# --- Targeting (fallback for enemy AI) ---

func _pick_enemy_target() -> Dictionary:
	var alive = enemies.filter(func(e): return e.hp > 0)
	if alive.is_empty():
		return {}
	return alive[0]

# --- Enemy intent ---

func _telegraph_enemy_intent() -> void:
	var next_enemies = all_combatants.filter(func(e): return e.get("is_enemy", false) and e.hp > 0)
	if next_enemies.is_empty():
		enemy_intent_label.text = ""
		return
	var next = next_enemies[0]
	if next.get("is_boss", false):
		enemy_intent_label.text = _boss_controller.get_boss_telegraph(next)
	else:
		enemy_intent_label.text = "%s: preparing Attack" % next.name

# --- Win/loss ---

func _check_end_conditions() -> bool:
	var alive_enemies = enemies.filter(func(e): return e.hp > 0)
	var alive_party = party.filter(func(p): return p.hp > 0)

	if alive_enemies.is_empty():
		_log("Victory!")
		# Grant milestone for any defeated bosses
		for enemy in enemies:
			if enemy.get("is_boss", false):
				var boss_data = enemy.get("boss_data") as BossData
				if boss_data:
					_boss_controller.on_boss_defeated(boss_data)
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
		if i == 0:
			# Highlight current turn entity
			lbl.text = "> " + entity.get("name", "?")
			lbl.modulate = Color(1.0, 1.0, 0.3)
		else:
			lbl.text = entity.get("name", "?")
			if entity.get("is_enemy", false):
				lbl.modulate = Color(1.0, 0.4, 0.4)
		turn_queue_display.add_child(lbl)

func _log(msg: String) -> void:
	print("[Combat] ", msg)
	if combat_log:
		combat_log.append_text(msg + "\n")
		# Auto-scroll to bottom
		await get_tree().process_frame
		combat_log.scroll_to_line(combat_log.get_line_count())
