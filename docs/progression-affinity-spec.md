# Progression & Affinity Specification

## Background & Motivation
Unlike traditional JRPGs, *Blink in the Bramble* does not rely on random encounters or grinding for progression. Leveling up is milestone-based, tied to story progression and boss defeats. The other major progression axis is **Affinity**, which tracks Zi's relationship with her companions and unlocks specific narrative scenes and combat synergies.

## Scope & Impact
This specification defines the `SaveManager.gd`, `AffinityManager.gd`, and `PartyManager.gd` singletons. It establishes the secure Godot binary format (`.res` or `.dat`) for saving the game state, ensuring it is robust against tampering and easy to manage during development.

## Proposed Solution: Centralized State Singletons & Resource Serialization

### 1. The Party Progression Manager (`PartyManager.gd`)
This Singleton manages the active roster, their current stats, and the milestone leveling logic.

*   **Variables:**
    *   `active_party: Array[CharacterData]` (Max 3 + Vyn)
    *   `reserve_party: Array[CharacterData]`
    *   `current_party_level: int = 1`

*   **Leveling Logic:**
    *   Instead of individual EXP, the party shares a milestone level.
    *   A predefined Resource (e.g., `LevelMilestones.tres`) maps Level IDs to stat increases and skill unlocks.
    *   **Function:** `func trigger_milestone(level_id: int)`
        *   Iterates through all party members (active and reserve).
        *   Applies stat modifiers from their respective `CharacterGrowthData` resources.
        *   Unlocks new skills in their `skills` array.
        *   Heals the party fully.

### 2. The Affinity System (`AffinityManager.gd`)
Tracks the numerical relationship scores and the specific boolean flags for unlocked dialogue scenes.

*   **Data Structure:**
    *   `affinity_scores: Dictionary` (e.g., `{"caelan": 15, "suri": 40, "rynn": 10, "lex": 5}`)
    *   `unlocked_scenes: Array[String]` (e.g., `["suri_camp_1", "lex_forest_chat"]`)
    *   `completed_scenes: Array[String]`

*   **Mechanics:**
    *   **Function:** `func modify_affinity(character_id: String, amount: int)`
        *   Adds or subtracts the amount.
        *   Checks a `SceneThresholds.json` or Resource dictionary to see if the new score crosses a threshold for a new scene.
        *   If a threshold is crossed, adds the scene ID to `unlocked_scenes`.
    *   Base Camps will query `unlocked_scenes` to display interaction icons above companions.

### 3. The Secure Save System (`SaveManager.gd`)
To prevent easy tampering and keep data tightly integrated with Godot, we use custom Resource serialization.

*   **The Save Data Object (`SaveData.gd` -> extends Resource):**
    *   A custom resource class that holds snapshot variables of the singletons:
        *   `@export var party_level: int`
        *   `@export var affinity_data: Dictionary`
        *   `@export var story_flags: Dictionary`
        *   `@export var current_map_chunk: Vector2i`
        *   `@export var player_position: Vector2`
        *   `@export var inventory: Array`

*   **Serialization Flow:**
    1.  **Save:** `SaveManager` creates a new instance of `SaveData`.
    2.  It copies current values from `PartyManager`, `AffinityManager`, and `WorldManager` into the `SaveData` instance.
    3.  It calls `ResourceSaver.save(save_data_instance, "user://save_slot_1.res")`.
    4.  **Load:** `ResourceLoader.load("user://save_slot_1.res")` retrieves the structured object.
    5.  `SaveManager` pushes the values back into the active Singletons.

## Verification
*   **Tamper Resistance:** Verify that the `user://save_slot_1.res` file is written in Godot's binary format (by default if no `ResourceFormatSaver` is specified to override it as text), making casual text-editor modifications difficult.
*   **State Consistency:** Ensure that loading a save file correctly updates the `WorldManager` chunk generation before yielding control back to the player, preventing out-of-bounds spawning.

## Alternatives Considered
*   **JSON Save Files:** Considered for ease of debugging. Rejected because the Godot binary `.res` format is much faster, natively supports strong typing (which prevents load-time cast errors), and offers a basic layer of tamper resistance out-of-the-box.
