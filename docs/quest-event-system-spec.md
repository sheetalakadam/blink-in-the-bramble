# Quest & Event System Specification

## Background & Motivation
In *Blink in the Bramble*, the story is linear but deeply branching in its emotional and conversational details. The world must react to Zi's past choices, her current party composition, and specific narrative milestones. A robust Quest and Event System is required to track these global flags, manage active objectives, and dynamically alter NPC dialogue or world obstacles (like the expanding Corrupted Zones).

## Scope & Impact
This specification introduces the `QuestManager.gd` Autoload, the `QuestData.tres` resource schema, and the `GlobalFlags.gd` system. It defines how the world state is tracked, saved, and queried by other systems (specifically the `DialogueManager` and `WorldManager`).

## Proposed Solution: Global Flags & Objective Trees

### 1. The Global Flag System (`GlobalFlags.gd`)
A centralized dictionary that stores the exact state of the world and player decisions.

*   **Data Structure:**
    *   `flags: Dictionary` (e.g., `{"met_caelan": true, "suri_secret_revealed": false, "valdrihn_border_open": false}`)
    *   `integers: Dictionary` (e.g., `{"corrupted_zones_cleared": 2}`)
*   **Integration with SaveManager:**
    *   The `flags` and `integers` dictionaries are fully serialized into the `SaveData.res` file when the player rests at a camp.
*   **Querying:**
    *   NPCs and trigger zones use `GlobalFlags.has_flag("flag_name")` to determine which dialogue script to load or whether to block a path.

### 2. Quest Resources (`QuestData.tres`)
Quests are defined as Godot Resources, allowing for easy creation and modification in the inspector.

*   **Schema (`QuestData.gd` -> extends Resource):**
    *   `id: String` (e.g., `mq_01_the_fall`)
    *   `title: String`
    *   `description: String` (Updates based on the current stage)
    *   `type: QuestType` (Enum: `MAIN`, `COMPANION`, `WORLD`)
    *   `stages: Array[QuestStage]`

*   **Sub-Schema (`QuestStage.gd` -> extends Resource):**
    *   `stage_id: int`
    *   `objective_text: String`
    *   `required_flags: Array[String]` (Flags that must be true to advance to the next stage)
    *   `on_start_events: Array[String]` (Signals to emit when this stage begins)

### 3. The Quest Manager (`QuestManager.gd`)
This Autoload tracks active, completed, and failed quests.

*   **Variables:**
    *   `active_quests: Dictionary` (Key: Quest ID, Value: Current Stage ID)
    *   `completed_quests: Array[String]`

*   **Mechanics:**
    *   **Function:** `func advance_quest(quest_id: String)`
        *   Checks the active quest's current stage.
        *   Evaluates if the `required_flags` for the *next* stage are met in `GlobalFlags`.
        *   If met, increments the stage, updates the Journal UI, and emits `quest_updated`.
        *   If it was the final stage, moves the quest to `completed_quests` and grants rewards (e.g., a Milestone Level up via `PartyManager`).

### 4. Dialogue Integration
The `DialogueManager` must be able to alter its flow based on quests and flags.

*   **JSON Schema Addition:**
    *   Dialogue Nodes will now support a `conditions` array.
    ```json
    "branch_secret": {
      "conditions": [
        {"type": "flag", "key": "suri_secret_known", "value": true},
        {"type": "quest_stage", "key": "mq_02_solenne", "value": 3}
      ],
      "lines": [ ... ]
    }
    ```
    *   When the parser reaches a branch, it evaluates the conditions. If they fail, it falls back to a default `next_node`.

## Verification
*   **Flag Persistence:** Ensure that modifying a flag, saving, and reloading correctly restores the flag state and immediately updates any dependent visual elements (like removing a blockade sprite).
*   **Quest Advancements:** Verify that completing the final stage of a quest correctly triggers the `PartyManager.trigger_milestone()` function without infinite looping.
*   **Dialogue Fallbacks:** Confirm that if a dialogue node's conditions fail, the system gracefully routes the player to generic/fallback dialogue instead of crashing.

## Alternatives Considered
*   **Script-Heavy Quest Logic:** Considered writing custom GDScript for every single quest (e.g., `Quest_MQ01.gd`). Rejected because it scales poorly and is hard for writers to edit. A data-driven Resource approach (`QuestData.tres`) is much more robust and manageable for an RPG.
