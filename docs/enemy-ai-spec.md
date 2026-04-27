# Enemy AI & Behavior Tree Specification

## Background & Motivation
To support the highly tactical combat loop in *Blink in the Bramble*, enemies cannot simply attack at random. The player must be able to read their intentions, prepare counters, and manage the Momentum Gauge. The Enemy AI is designed to be fully transparent, tactically coordinated, and psychologically varied.

## Scope & Impact
This specification covers the `EnemyBrain.gd` component, which attaches to every enemy combatant in `CombatScene.tscn`. It dictates how enemies select actions, how they broadcast their "Intent" to the player, and how they react when losing a battle.

## Proposed Solution: State-Driven Action Selection

### 1. Intent & Telegraphing (Full Transparency)
Players are rewarded for planning ahead. Every enemy action is decided *at the end* of their previous turn, not the beginning of their current one.

*   **Mechanics:**
    *   Once an enemy finishes its turn, `EnemyBrain.evaluate_next_move()` runs immediately.
    *   The selected `ActionData` (Attack, Defend, Heal, Debuff) is stored in `queued_action`.
    *   The UI displays a corresponding "Intent Icon" directly above the enemy sprite (e.g., a cracked shield for an armor-breaking attack).
    *   If Zi uses her "Read" skill or Lex uses "Field Notes," the specific numbers (e.g., "Attack for 15 HP") and the target of the attack are also revealed.

### 2. Group Intelligence (Tactical Coordination)
Enemies do not fight selfishly. They evaluate the entire state of the board.

*   **The Scoring System:**
    *   `EnemyBrain.evaluate_next_move()` iterates through a list of possible actions and scores them based on the current situation:
        *   **Kill Priority:** If a party member is below 20% HP and the enemy's attack can kill them, score `+50`.
        *   **Protection Priority:** If an allied enemy is low on HP, a healing/buffing action scores `+40`.
        *   **Momentum Denial:** If the player is in `SURGE` state, actions that drain the Momentum Gauge score `+30`.
    *   The AI selects the action with the highest score, ensuring enemies always take the most dangerous path.

### 3. Morale & The "Fear" Mechanic
To make the world feel alive, enemies do not all fight mindlessly to the death. Each enemy archetype rolls for a "Morale Type" when the battle begins (or has one strictly assigned in their `EnemyData.tres`).

*   **The Morale States:**
    When an enemy drops below 25% HP, or when they are the last one standing against a full party, their Morale State triggers:
    *   **State 1 (Standard):** The enemy ignores the situation and fights to 0 HP (Typical of Corrupted Beasts or unfeeling golems).
    *   **State 2 (Fleeing):** The enemy's Intent Icon changes to "Escape." On their next turn, they attempt to run from the battle, depriving the player of EXP/loot if successful (Typical of scavengers or smart opportunists).
    *   **State 3 (Desperation/Last Stand):** The enemy visually enrages. They gain a permanent +30% damage buff but their defense drops to 0 (Typical of proud Valdrihn soldiers or cornered predators).

## Verification
*   **Intent Locking:** Ensure that if the player stuns or interrupts an enemy, the `queued_action` is cleared or delayed, and a new intent is rolled correctly.
*   **Tactical Override:** Verify that the "Kill Priority" scoring does not cause *every single enemy* to focus the same low-HP target if the first enemy's attack is already guaranteed to secure the kill. The AI should realize the target is already doomed and select the next best option.
*   **Morale Variance:** Ensure the randomized morale state (if not hardcoded) does not break specific boss encounters (e.g., General Vaera should never roll "Fleeing").

## Alternatives Considered
*   **Random Action Selection:** Considered for ease of development. Rejected because random attacks break the tactical puzzle of the Stance and Momentum systems, leading to frustrating deaths where the player could not have planned a counter.
