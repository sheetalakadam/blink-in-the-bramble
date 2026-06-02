extends Node2D

signal combat_won
signal combat_lost
signal rewards_acknowledged

# Combat participants
var party: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var all_combatants: Array[Dictionary] = []

# Turn state
var current_entity: Dictionary = {}
var stance_switched_this_turn: bool = false
var waiting_for_input: bool = false
var _pending_skill = null # Skill awaiting target selection
var _pending_action: String = "" # "attack", "skill", or "item" awaiting target
var _pending_item_path: String = "" # Item path awaiting ally target selection
var _last_ally_target: Dictionary = {} # Tracks last target a party member attacked (for Vyn's Pack Instinct)

# Boon state
var _active_boon_effect: String = ""
var _auto_revive_available: bool = false
var _extra_turn_available: bool = false
var _bond_strike_available: bool = false

# Boss encounter
var _boss_controller: BossController = BossController.new()

# Reward UI
var _reward_ui: Node = null

@onready var action_menu: Control = $UI/ActionMenu
@onready var skill_menu: Control = $UI/SkillMenu
@onready var stance_menu: Control = $UI/StanceMenu
@onready var turn_queue_display: HBoxContainer = $UI/TurnQueue
@onready var combat_log: RichTextLabel = $UI/CombatLog
@onready var target_menu: Control = $UI/TargetMenu
@onready var party_display: VBoxContainer = $UI/PartyDisplay
@onready var enemy_display: VBoxContainer = $UI/EnemyDisplay
@onready var enemy_intent_label: Label = $UI/EnemyIntent
@onready var item_menu: Control = $UI/ItemMenu

func _ready() -> void:
	action_menu.visible = false
	skill_menu.visible = false
	stance_menu.visible = false
	target_menu.visible = false
	item_menu.visible = false
	CombatManager.turn_started.connect(_on_turn_started)

func start(party_data: Array[Dictionary], enemy_data: Array[Dictionary]) -> void:
	party = party_data
	enemies = enemy_data
	all_combatants = party + enemies
	ComboSystem.reset()
	StatusEffectSystem.reset()
	_update_displays()
	_log("Battle begins!")

	# Apply passive combo bonuses at battle start
	var passive_bonus := ComboSystem.get_passive_bonus(party, enemies)
	if passive_bonus > 0.0:
		_log("[Combo] Caelan and Lex — Spirit Hunters! +%d%% damage to spirits" % int(passive_bonus * 100))

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

	# Process status effects at turn start
	var effect_msgs := StatusEffectSystem.process_turn_start(entity)
	for msg in effect_msgs:
		_log(msg)

	# Skip turn if rooted
	if StatusEffectSystem.has_effect(entity, "rooted"):
		StatusEffectSystem.process_turn_end(entity)
		_update_displays()
		if not _check_end_conditions():
			await get_tree().create_timer(0.3).timeout
			CombatManager.advance_turn()
		return

	if entity.get("is_enemy", false):
		_enemy_turn(entity)
	elif entity.get("name", "") == "Vyn":
		_vyn_turn(entity)
	else:
		_player_turn(entity)

func _player_turn(entity: Dictionary) -> void:
	_log("%s's turn" % entity.name)

	# Check for available combo
	var next_idx = (CombatManager.active_entity_index + 1) % CombatManager.turn_queue.size()
	var next_entity = CombatManager.turn_queue[next_idx] if CombatManager.turn_queue.size() > 1 else {}
	var combo = ComboSystem.check_combo(entity, "", next_entity, all_combatants)
	if combo.active:
		_log(combo.message)

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

	# Mark this enemy as having attacked last turn (for Vyn's Root AI)
	entity["attacked_last_turn"] = true

	# Auto-revive check (Morrael boon)
	if target.hp <= 0 and _auto_revive_available:
		target.hp = maxi(1, int(target.max_hp * 0.3))
		_auto_revive_available = false
		_log("[Morrael's Grace] %s is revived!" % target.name)

	# Vyn passive intercept: if any party member dropped below 25% HP
	_vyn_passive_intercept(entity, target, damage)

	CombatVFXManager.trigger_screen_shake(3.0, 0.15)
	# Play hit SFX for enemy attacks
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("hit")
	_update_displays()

	if _check_end_conditions():
		return

	StatusEffectSystem.process_turn_end(entity)
	_telegraph_enemy_intent()
	await get_tree().create_timer(0.3).timeout
	CombatManager.advance_turn()

# --- Vyn semi-autonomous turn ---

func _vyn_turn(entity: Dictionary) -> void:
	_log("Vyn acts on instinct...")
	await get_tree().create_timer(0.3).timeout

	var alive_enemies = enemies.filter(func(e): return e.get("hp", 0) > 0)
	if alive_enemies.is_empty():
		_check_end_conditions()
		return

	var decision = VynCombatAI.choose_action(entity, party, enemies, _last_ally_target)
	var target = decision.target
	var action = decision.action
	var damage_mult = VynCombatAI.get_damage_multiplier(entity, party)

	var base_atk: int = entity.get("attack", 10)
	var defense: int = target.get("defense", 0)
	if target.get("defending", false):
		defense *= 2

	match action:
		"wild_strike":
			var variance = VynCombatAI.calculate_wild_strike_variance()
			var raw_damage = base_atk * variance * damage_mult
			var final_damage = maxi(1, int(raw_damage) - defense)
			target.hp -= final_damage
			MomentumSystem.add_momentum(5.0)
			_log("[Vyn] Wild Strike! %d damage to %s!" % [final_damage, target.name])

		"root":
			var raw_damage = base_atk * 0.5 * damage_mult
			var final_damage = maxi(1, int(raw_damage) - defense)
			target.hp -= final_damage
			StatusEffectSystem.apply_effect(target, "rooted", 2, 0)
			MomentumSystem.add_momentum(3.0)
			_log("[Vyn] Root! %s is rooted for 2 turns! %d damage." % [target.name, final_damage])

		"pack_instinct":
			var raw_damage = base_atk * 0.7 * damage_mult  # Each hit of double-hit
			var hit1 = maxi(1, int(raw_damage) - defense)
			var hit2 = maxi(1, int(raw_damage) - defense)
			target.hp -= (hit1 + hit2)
			MomentumSystem.add_momentum(8.0)
			_log("[Vyn] Pack Instinct! Double hit on %s for %d + %d damage!" % [target.name, hit1, hit2])

	# Clear attacked_last_turn flags after Vyn acts
	for enemy in enemies:
		enemy.erase("attacked_last_turn")

	_update_displays()
	if not _check_end_conditions():
		_telegraph_enemy_intent()
		await get_tree().create_timer(0.3).timeout
		CombatManager.advance_turn()


func _vyn_passive_intercept(attacker: Dictionary, target: Dictionary, damage_dealt: int) -> void:
	# Check if any party member dropped below 25% HP
	if target.hp > 0 and float(target.hp) / float(target.max_hp) >= 0.25:
		return

	# Find Vyn in party
	var vyn: Dictionary = {}
	for member in party:
		if member.get("name", "") == "Vyn" and member.get("hp", 0) > 0:
			vyn = member
			break

	if vyn.is_empty():
		return

	# Vyn intercepts: takes 30% of damage dealt
	var intercept_damage = int(damage_dealt * 0.3)
	vyn.hp -= intercept_damage
	_log("[Vyn] intercepts! Takes %d damage protecting %s!" % [intercept_damage, target.name])

	# Vyn retaliates for 50% of his attack
	var retaliation = int(vyn.get("attack", 10) * 0.5)
	var attacker_defense = attacker.get("defense", 0)
	var retaliation_damage = maxi(1, retaliation - attacker_defense)
	attacker.hp -= retaliation_damage
	_log("[Vyn] retaliates for %d damage!" % retaliation_damage)


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
		action_menu.get_node("List").add_child(boon_container)
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

func on_item_pressed() -> void:
	if not waiting_for_input:
		return
	action_menu.visible = false
	_show_item_menu()

# --- Item sub-menu ---

func _show_item_menu() -> void:
	for child in item_menu.get_node("List").get_children():
		child.queue_free()

	var consumables = InventoryManager.get_consumables()
	if consumables.is_empty():
		var lbl = Label.new()
		lbl.text = "No items"
		item_menu.get_node("List").add_child(lbl)
	else:
		for entry in consumables:
			var item: ItemData = entry["item"]
			var btn = Button.new()
			btn.text = "%s x%d" % [item.name, entry["count"]]
			btn.pressed.connect(_on_item_selected.bind(entry["path"]))
			item_menu.get_node("List").add_child(btn)

	var back = Button.new()
	back.text = "Back"
	back.pressed.connect(func(): item_menu.visible = false; action_menu.visible = true)
	item_menu.get_node("List").add_child(back)

	item_menu.visible = true

func _on_item_selected(item_path: String) -> void:
	item_menu.visible = false
	_pending_item_path = item_path
	_pending_action = "item"
	_show_ally_target_menu()

func _show_ally_target_menu() -> void:
	for child in target_menu.get_node("List").get_children():
		child.queue_free()

	var alive = party.filter(func(p): return p.hp > 0)
	for member in alive:
		var btn = Button.new()
		btn.text = "%s (HP: %d/%d)" % [member.name, maxi(0, member.hp), member.max_hp]
		btn.pressed.connect(_on_ally_target_selected.bind(member))
		target_menu.get_node("List").add_child(btn)

	var back = Button.new()
	back.text = "Back"
	back.pressed.connect(func():
		target_menu.visible = false
		_pending_action = ""
		_pending_item_path = ""
		action_menu.visible = true
	)
	target_menu.get_node("List").add_child(back)

	target_menu.visible = true

func _on_ally_target_selected(target: Dictionary) -> void:
	target_menu.visible = false
	waiting_for_input = false
	var success = InventoryManager.use_item(_pending_item_path, target)
	if success:
		var item_res = load(_pending_item_path) as ItemData
		var item_name = item_res.name if item_res else _pending_item_path
		_log("%s uses %s on %s!" % [current_entity.name, item_name, target.name])
		# Play heal SFX for item use on allies
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("heal")
	else:
		_log("Could not use item.")
	_pending_item_path = ""
	_pending_action = ""
	_update_displays()
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
	# Track last ally target for Vyn's Pack Instinct
	if not attacker.get("is_enemy", false):
		_last_ally_target = target

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

	# Equipment stance bonus
	var equip_list = attacker.get("equipment", [])
	if equip_list is Array and not equip_list.is_empty():
		var typed_equip: Array[EquipmentData] = []
		for e in equip_list:
			if e is EquipmentData:
				typed_equip.append(e)
		stance_mult += EquipmentManager.get_stance_bonus(typed_equip, attacker.get("active_stance", ""))

	var momentum_mult = MomentumSystem.get_damage_multiplier()
	var defense: int = target.get("defense", 0)
	if target.get("defending", false):
		defense *= 2

	# Combo bonus
	var combo_mult: float = 1.0
	var next_idx = (CombatManager.active_entity_index + 1) % CombatManager.turn_queue.size()
	var next_entity = CombatManager.turn_queue[next_idx] if CombatManager.turn_queue.size() > 1 else {}
	var combo = ComboSystem.check_combo(attacker, skill_name, next_entity, all_combatants)
	if combo.active:
		combo_mult += combo.bonus
		_log(combo.message)

	# Passive combo bonus (Caelan+Lex vs spirits)
	var passive_bonus := ComboSystem.get_passive_bonus(party, enemies)
	if passive_bonus > 0.0 and target.get("type", "") == "Spirit":
		combo_mult += passive_bonus

	# Marked bonus (from Suri's Setup Strike)
	var marked_bonus := StatusEffectSystem.consume_marked(target)
	if marked_bonus > 0.0:
		combo_mult += marked_bonus
		_log("[Marked] +%d%% bonus damage!" % int(marked_bonus * 100))

	var raw_damage = base_atk * skill_mult * stance_mult * momentum_mult * combo_mult
	var final_damage = maxi(1, int(raw_damage) - defense)

	target.hp -= final_damage
	MomentumSystem.add_momentum(momentum_change)

	# Record action for combo tracking
	ComboSystem.record_action(attacker.get("name", ""), skill_name)

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
	# Play hit SFX on damage
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("hit")
	_update_displays()

	if not _check_end_conditions():
		_end_player_turn()

func _end_player_turn() -> void:
	StatusEffectSystem.process_turn_end(current_entity)
	_telegraph_enemy_intent()
	await get_tree().create_timer(0.3).timeout
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
		_process_rewards()
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
		var effect_str := StatusEffectSystem.get_effect_display(enemy)
		lbl.text = "%s  HP: %d/%d  [%s]%s" % [
			enemy.name,
			maxi(0, enemy.hp),
			enemy.max_hp,
			enemy.get("armor_type", "?"),
			effect_str
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
		var next_idx = (idx + 1) % CombatManager.turn_queue.size()
		var next_entity_name: String = CombatManager.turn_queue[next_idx].get("name", "") if CombatManager.turn_queue.size() > 1 else ""
		var entity_name: String = entity.get("name", "?")
		var combo_indicator: String = ""
		if ComboSystem.has_combo_available(entity_name, next_entity_name):
			combo_indicator = " [!]"
		var lbl = Label.new()
		if i == 0:
			# Highlight current turn entity
			lbl.text = "> " + entity_name + combo_indicator
			lbl.modulate = Color(1.0, 1.0, 0.3)
		else:
			lbl.text = entity_name + combo_indicator
			if entity.get("is_enemy", false):
				lbl.modulate = Color(1.0, 0.4, 0.4)
		turn_queue_display.add_child(lbl)

func _process_rewards() -> void:
	var rewards := BattleRewards.calculate_rewards(party, enemies)

	# Apply affinity gains to AffinityManager
	var affinity_gains: Dictionary = rewards.get("affinity_gains", {})
	for character in affinity_gains:
		var gain: int = affinity_gains[character]
		if gain > 0:
			AffinityManager.add_affinity(character, gain)

	# Apply milestone XP to party members and check for level ups
	var leveled_up: bool = false
	var xp_gained: int = rewards.get("milestone_xp", 0)
	for member in party:
		if member.get("is_enemy", false):
			continue
		var old_xp: int = member.get("xp", 0)
		var new_xp: int = old_xp + xp_gained
		member["xp"] = new_xp
		if BattleRewards.check_level_up(old_xp, new_xp):
			leveled_up = true

	# Add loot to InventoryManager if it exists
	var loot: Array = rewards.get("loot", [])
	if not loot.is_empty():
		var inventory = Engine.get_singleton("InventoryManager") if Engine.has_singleton("InventoryManager") else null
		if inventory == null:
			# Try autoload path
			inventory = get_node_or_null("/root/InventoryManager")
		if inventory and inventory.has_method("add_item"):
			for item_path in loot:
				inventory.add_item(item_path)

	# Show reward UI
	_show_reward_ui(rewards, leveled_up)


func _show_reward_ui(rewards: Dictionary, leveled_up: bool) -> void:
	var reward_scene = load("res://scenes/ui/BattleRewardUI.tscn")
	if reward_scene:
		_reward_ui = reward_scene.instantiate()
		add_child(_reward_ui)
		_reward_ui.rewards_acknowledged.connect(_on_rewards_acknowledged)
		_reward_ui.show_rewards(rewards, leveled_up)
	else:
		# If scene can't load, just emit immediately
		rewards_acknowledged.emit()


func _on_rewards_acknowledged() -> void:
	if _reward_ui:
		_reward_ui.queue_free()
		_reward_ui = null
	rewards_acknowledged.emit()


func _log(msg: String) -> void:
	print("[Combat] ", msg)
	if combat_log:
		combat_log.append_text(msg + "\n")
		# Auto-scroll to bottom
		await get_tree().process_frame
		combat_log.scroll_to_line(combat_log.get_line_count())
