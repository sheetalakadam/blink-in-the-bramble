# Core Systems Architecture Plan

## Scope & Impact
This plan outlines the technical foundation for the four remaining major pillars of *Blink in the Bramble*: Dialogue & Story Engine, Turn-Based Combat Engine, Progression & Affinity, and Base Camps & Shrines. It establishes the class structures, data flows, and UI paradigms.

---

## Pillar 1: Dialogue & Story Engine
**Requirement:** Subtle, subtext-heavy dialogue with "Inner Monologue" overlays.
**Architecture:** Custom Godot Native Parser.

*   **Data Structure (`.json` or custom Godot Resources):**
    Dialogue will be stored as an array of JSON objects or Custom Resources containing:
    *   `speaker`: Character ID.
    *   `text`: The spoken dialogue.
    *   `monologue`: (Optional) Zi's internal thoughts displayed simultaneously in a different font/color or handwritten style overlay.
    *   `portrait_state`: Emotional state to load the correct sprite.
    *   `event_trigger`: Signals to fire (e.g., `Caelan_Memory_Fragment_1`).
*   **UI Implementation (`DialogueBox.tscn`):**
    *   Main text box at the bottom.
    *   Floating text node positioned near Zi's portrait for `monologue`.
    *   Typewriter effect using `RichTextLabel.visible_ratio`.
*   **Interaction:** Raycasts on NPCs/Objects trigger the `DialogueManager` Singleton, passing the specific script ID to load.

---

## Pillar 2: Turn-Based Combat Engine
**Requirement:** Momentum Gauge, Stance System, No purely passive characters.
**Architecture:** Modern Radial UI with Speed-based Queue.

*   **Turn Queue (`CombatManager.gd` Autoload):**
    *   Calculates initiative based on Character `speed` stat.
    *   Displays a scrolling timeline UI at the top of the screen showing the next 5-8 turns.
*   **Momentum Gauge (`MomentumSystem.gd`):**
    *   A shared global float variable (-100 to 100).
    *   States: Grounded (< -50), Balanced (-50 to 50), Surge (> 50).
    *   Emits signals when crossing state thresholds to instantly update UI visuals and character damage multipliers.
*   **Simple Vertical Menu UI (`ActionMenu.tscn`):**
    *   When a character's turn begins, a dark semi-transparent panel appears with vertical buttons: Attack, Skill, Stance, Defend.
    *   Sub-menus (skill list, stance selection) are also simple vertical lists. Clean and minimal.
*   **Stance System:**
    *   Each character has an active `Stance` enum/resource.
    *   Switching stances is a free action handled by a state machine pattern within `CharacterCombat.gd`.

---

## Pillar 3: Progression & Affinity
**Requirement:** Milestone leveling (no grinding), relationship tracking.
**Architecture:** Centralized Save State Manager.

*   **Progression (`PartyManager.gd` Singleton):**
    *   Tracks current party members (3 active + Vyn).
    *   `grant_experience()` is called only after major story events or boss defeats.
    *   Leveling up automatically updates base stats and unlocks skills based on predefined `LevelUpChart` resources.
*   **Affinity System (`AffinityManager.gd`):**
    *   A Dictionary tracking Zi's relationship score with each companion: `{"Caelan": 15, "Suri": 40, ...}`
    *   Increased via dialogue choices and camp interactions.
    *   Unlocks specific `CampScene` IDs when thresholds are met.
*   **Save System (`SaveManager.gd`):**
    *   Uses `FileAccess` to serialize the entire `PartyManager` and `AffinityManager` state, plus global flags (e.g., `has_met_auryn`), into a secure binary format (`.dat` or `.res`) using Godot's built-in `var_to_bytes()` and `bytes_to_var()` functions.

---

## Pillar 4: Base Camps & Shrines
**Requirement:** Resting, upgrading, God boons with narrative costs.
**Architecture:** Modular Hub Scenes and Event Listeners.

*   **Base Camps (`CampScene.tscn`):**
    *   Dedicated scenes accessed from specific world map points.
    *   Contains interactive nodes (Forge, Sanctum, Quarters).
    *   **Quarters Logic:** Checks `AffinityManager` for pending scenes. If an interaction point glows, clicking it loads a specific dialogue script.
*   **Shrines & God Boons (`ShrineNode.tscn`):**
    *   Interactive objects in the world.
    *   Opening a shrine pauses exploration and brings up the God UI (e.g., Auryn's face).
    *   **The Cost Mechanic:** Selecting a boon calls `SaveManager.apply_boon(god_id, cost_type)`. If the cost is "memory", a specific lore entry in the player's journal is permanently deleted or altered. If "affinity", it deducts from the `AffinityManager`.

---

## Next Steps for Implementation
1.  Begin drafting the `DialogueManager` Singleton and the `DialogueBox.tscn` UI.
2.  Design the JSON structure for dialogue scripts to ensure it supports the "Inner Monologue" feature cleanly before writing any story content.
