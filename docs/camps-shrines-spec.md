# Base Camps & Shrines Specification

## Background & Motivation
In *Blink in the Bramble*, the passage of time and the weight of decisions are central themes. Base Camps are safe havens where relationships (Affinity) and equipment (Forge) are developed over time. Shrines are specific locations where the player interacts with the gods. Since the gods operate on outdated 300-year-old information, their help (Boons) always comes with a narrative or mechanical cost (e.g., losing a memory, draining affinity, or taking HP).

## Scope & Impact
This specification covers the technical architecture of the `CampScene.tscn` modular hub and the `ShrineNode.tscn` interaction system. It defines how the God Boons system hooks into the `SaveManager` and the `DialogueManager` to permanently alter the game state.

## Proposed Solution: Modular Hubs & The Cost Mechanic

### 1. The Base Camp Architecture (`CampScene.tscn`)
Base Camps are distinct scenes loaded when Zi interacts with a camp point on the world map. They are built modularly so features can unlock progressively.

*   **Node Hierarchy:**
    *   `CampScene (Node2D)`
        *   `Environment (TileMap/Lighting)`
        *   `Interactables (Node2D)`
            *   `Campfire (Area2D)`: Restores HP/MP, triggers save.
            *   `Forge (Area2D)`: Opens weapon/armor upgrade UI.
            *   `Sanctum (Area2D)`: Unlocks later; allows remote God interactions.
        *   `Companions (Node2D)`
            *   `Caelan_NPC (CharacterBody2D/Area2D)`
            *   `Suri_NPC (CharacterBody2D/Area2D)`

*   **Camp Logic (`CampManager.gd`):**
    *   On `_ready()`, queries the `AffinityManager` (`unlocked_scenes` array).
    *   If a character has an unlocked scene, an `InteractionIndicator` (e.g., a floating ellipsis bubble) is spawned above their head.
    *   Interacting with them calls `DialogueManager.start_dialogue(scene_id)` and, upon completion, moves the scene ID to `completed_scenes`.

### 2. Shrines & God Interactions (`ShrineNode.tscn`)
Shrines are found in the overworld. Interacting with them brings up a specialized, screen-dominating God UI (e.g., Auryn's face and dialogue).

*   **Data Structure (`GodBoonData.tres`):**
    *   `god_id: String` (e.g., "Auryn")
    *   `boon_name: String` (e.g., "Reveal Armor")
    *   `cost_type: String` (Enum: `MEMORY`, `AFFINITY`, `HP`, `ITEM`)
    *   `cost_amount: int`
    *   `target_id: String` (Used if the cost targets a specific companion's affinity)

*   **The Cost Execution Flow:**
    When the player selects a Boon in the UI:
    1.  **Validation:** The system checks if the cost can be paid (e.g., if `cost_type == AFFINITY`, is Zi's affinity with the `target_id` high enough?).
    2.  **Execution (`ShrineManager.gd`):**
        *   If `MEMORY`: Deletes or redacts a specific lore entry in the player's Journal UI. This is purely narrative but highly impactful.
        *   If `AFFINITY`: Calls `AffinityManager.modify_affinity(target_id, -cost_amount)`.
        *   If `HP`: Deducts from Zi's current HP.
    3.  **Reward:** A global flag is set (e.g., `SaveManager.story_flags["auryn_boon_active"] = true`), which the Combat Engine checks at the start of the next battle to apply the buff.

### 3. The Journal System (`JournalUI.tscn`)
The Journal is where Zi records her thoughts. It is the primary target for the `MEMORY` cost type.

*   **Mechanics:**
    *   The Journal reads from a `journal_entries.json` array.
    *   When a God "takes a memory", `SaveManager` adds that entry's ID to a `redacted_memories` array.
    *   The `JournalUI` applies a Godot RichText effect (like a black highlight or blurred font) over redacted entries, visually representing the cost of divine intervention.

## Verification
*   **Scene Transitions:** Ensure that entering and exiting the `CampScene` correctly stores and restores Zi's position on the overworld map via the `SaveManager`.
*   **UI State:** Verify that `InteractionIndicators` instantly update if affinity thresholds are crossed *during* a camp dialogue scene, preventing the need to reload the camp to see the next available conversation.
*   **Boon Tracking:** Confirm that active God Boons are cleared after their intended duration (e.g., after one battle).

## Alternatives Considered
*   **Boons as Inventory Items:** Considered granting physical "Boon Items" that the player equips. Rejected because the GDD emphasizes the transactional, immediate nature of interacting with the gods. Paying a cost at a shrine for an immediate, ethereal buff fits the narrative better.
