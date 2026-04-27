# Combat Engine Specification

## Background & Motivation
The combat in *Blink in the Bramble* must be highly tactical, eliminating purely passive turns while demanding constant adaptation from the player. This is achieved through two core systems: the **Momentum Gauge** (a shared risk/reward resource) and the **Stance System** (a rock-paper-scissors mechanic that requires free action switching). This document outlines the mathematical and architectural foundations for these systems.

## Scope & Impact
This specification defines the data structures and core singletons required for the Turn-Based Combat Engine. It will dictate how `CombatManager.gd`, `MomentumSystem.gd`, and `CharacterCombat.gd` interact during an encounter.

## Proposed Solution: State Machines & Global Resources

### 1. The Momentum Gauge (`MomentumSystem.gd`)
The Momentum Gauge is a shared resource for the entire party, represented as a global float value from `-100.0` to `100.0`. It dictates the current combat state and applies multipliers.

*   **Variables:**
    *   `current_momentum: float = 0.0`
    *   `state: MomentumState` (Enum: `GROUNDED`, `BALANCED`, `SURGE`)

*   **State Thresholds & Multipliers:**
    *   **`GROUNDED` (-100 to -50):** 
        *   Player Damage Output: `-20%` (0.8x multiplier)
        *   Skill Stamina Cost: `-50%` (0.5x multiplier)
        *   Enemy Speed: `-10%` (0.9x multiplier)
    *   **`BALANCED` (-49 to 49):** 
        *   Player Damage Output: `100%` (1.0x multiplier)
        *   Normal costs and speeds.
    *   **`SURGE` (50 to 100):**
        *   Player Damage Output: `+40%` (1.4x multiplier)
        *   Player Damage Taken: `+30%` (1.3x multiplier)

*   **Mechanics:**
    *   Attacking, critting, and Vyn's passive attacks add positive momentum.
    *   Taking damage, defending, or using specific utility skills drains momentum (moves it towards -100).
    *   The `MomentumSystem.gd` Autoload will emit signals (e.g., `state_changed(new_state)`) whenever thresholds are crossed, prompting UI and particle effect updates.

### 2. The Stance System (`CharacterCombat.gd`)
Every character possesses three unique stances. Stances define elemental/type advantages against specific enemy armors.

*   **Data Structure (`StanceData.tres`):**
    *   `id: String` (e.g., "Soldier's Edge")
    *   `advantage_against: String` (e.g., "Heavy")
    *   `disadvantage_against: String` (e.g., "Agile")
    *   `passive_buff: Dictionary` (Optional stat tweaks while active)

*   **The State Machine:**
    *   `CharacterCombat.gd` runs a simple State Machine.
    *   Switching stances is a **Free Action** (can be done once per turn before the main action).
    *   When an attack lands, the combat engine compares the attacker's active `Stance.advantage_against` to the defender's `armor_type`.
    *   **Multipliers:**
        *   Advantage: `130%` damage (1.3x)
        *   Neutral: `100%` damage (1.0x)
        *   Disadvantage: `60%` damage (0.6x)

### 3. The Turn Queue (`CombatManager.gd`)
The system must telegraph enemy intent one turn in advance, requiring a deterministic timeline.

*   **Data Structure:**
    *   An Array of Dictionaries or custom Objects representing the timeline: `[{entity: EntityNode, action: ActionData, speed_value: int}, ...]`
*   **Sorting Logic:**
    *   At the start of a round, all combatants roll for initiative based on their base `speed` stat + a small random variance (`randf_range(0.9, 1.1)`).
    *   The queue is sorted descending by the final speed value.
    *   Enemy AI determines its `action` for its *next* turn immediately after its current turn ends, allowing the UI to display "Intent Icons" (Attack, Buff, Defend) above their heads or in the timeline UI.

## The Action Resolution Flow
When a player selects "Strike" via the Radial Menu:
1.  **Selection:** Player picks Target.
2.  **Calculation:** Base Damage * Skill Multiplier * Stance Multiplier * Momentum Multiplier.
3.  **Execution:** Play animation -> Emit `damage_dealt(amount)`.
4.  **Momentum Update:** `MomentumSystem.add(SkillData.momentum_change)`.
5.  **Queue Advance:** Active character is moved to the end of the queue or next round; next entity begins turn.

## Verification
*   **Multiplier Stacking:** Ensure multipliers (Stance + Momentum) stack additively or multiplicatively as designed (e.g., Surge + Advantage = 1.4 * 1.3 = 1.82x damage) without causing integer overflow.
*   **Free Actions:** Verify the Stance swap state machine strictly limits swaps to once per turn.

## Alternatives Considered
*   **Active Time Battle (ATB):** Considered a constantly filling bar system (like older Final Fantasy games). Rejected because the Momentum and Stance systems require highly calculated, deliberate choices. A strict queue provides better tactical readability.