# Menu System & Interactive Flow Specification

## Background & Motivation
The user interface and menu flow in *Blink in the Bramble* must immediately establish the game's tone of isolation, tactical precision, and emotional grounding. The menus are not just functional; they are extensions of the world's cultures (like Valdrihn efficiency) and the game's core themes of memory and accessibility.

## Scope & Impact
This specification covers the technical implementation and visual design of the `TitleScreen.tscn`, the `SaveLoadUI.tscn`, and the global `SettingsManager.gd` Autoload, with a specific focus on the "Input Pacing" accessibility feature.

## Proposed Solution: Thematic & Accessible Interfaces

### 1. The Title Screen ("The Intimate Ruin")
The first impression of the game is quiet and melancholic, contrasting with the high-stakes narrative to come.

*   **Visual Design (`TitleScreen.tscn`):**
    *   A static, high-quality pixel art background of Zi's isolated camp at night. Vyn is curled up sleeping near a small campfire.
    *   The menu options (New Game, Continue, Settings, Exit) use the clean, primary sans-serif font aligned to the bottom right, away from the focal point.
*   **Idle Animation Logic:**
    *   A `Timer` node tracks the player's inactivity on the title screen.
    *   As time passes (e.g., after 30 seconds), the `PointLight2D` representing the campfire slowly dims via a `Tween`, and the ambient wind audio grows slightly louder, emphasizing the isolation and the passage of time before the player even begins.

### 2. Save/Load Interface ("The Military Ledger")
Reflecting Zi's Valdrihn background, the save system eschews flowery language or memory-heavy visuals for stark, efficient data.

*   **Visual Design (`SaveLoadUI.tscn`):**
    *   A clean, grid-based ledger interface utilizing the high-contrast `Divine Teal` and deep charcoal palette. No thumbnails or location screenshots.
*   **Data Display:**
    *   Each save slot displays only raw, critical data parsed from the `SaveData.res` file:
        *   `Slot Number` & `Timestamp` (Real-world time).
        *   `Playtime` (Format: HH:MM).
        *   `Current Location Name` (e.g., "Naevoria Ruins - Depths").
        *   `Active Party Roster` (Small pixel icons of the characters currently in the active 3-person lineup).
        *   `Milestone Level`.

### 3. Accessibility: "Input Pacing" Setting
The GDD explicitly calls for accommodating neurodivergence and ensuring the tactical combat is cerebral, not twitch-based.

*   **Mechanic (`SettingsManager.gd`):**
    *   A global boolean variable: `is_input_pacing_enabled: bool = false`.
    *   Toggled via the Options Menu.
*   **Combat Impact:**
    *   When enabled, the `CombatVFXManager` bypasses the `trigger_hit_stop()` function. This removes the 0.1s game freeze and severe screen shakes, which can be overstimulating or visually disruptive for some players.
    *   The Radial Menu animations play 50% faster, or snap open instantly, reducing the visual "noise" of UI transitions.
    *   The Combat timeline (Turn Queue) strictly locks in place while the player is selecting an action, ensuring there is zero perceived time pressure during decision-making.

## Verification
*   **Ledger Parsing:** Verify that the `SaveLoadUI` can parse the raw data variables (Playtime, Location) from a `.res` file *without* loading the entire heavy Resource or the associated map chunk into memory, ensuring the save menu opens instantly.
*   **Idle State Reset:** Ensure that any mouse movement or keyboard input resets the `Timer` on the Title Screen, restoring the campfire's brightness.
*   **Settings Persistence:** Confirm that the `is_input_pacing_enabled` flag is saved to a separate `user://settings.cfg` file, so the accessibility preference persists across all save files and new games.

## Alternatives Considered
*   **God-Blink Title Screen:** Considered a flashing, high-contrast title screen showing the Fracture. Rejected because starting the game with a quiet, intimate moment of isolation provides a stronger emotional contrast when Caelan abruptly crashes into the camp during the Cold Open.