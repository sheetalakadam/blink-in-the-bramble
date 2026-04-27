# UI/UX Design & Aesthetic Specification

## Background & Motivation
The user interface of *Blink in the Bramble* must reinforce the game's core themes: subtext, memory loss, and the tension between the mortal and divine. The UI is designed to be highly stylized, taking inspiration from *Persona 5* for its dynamic overlays, while maintaining a stark, melancholic "Divine Teal" color palette.

## Scope & Impact
This specification covers the design language and technical implementation of the three primary UI systems: The Dialogue Box (and Inner Monologue), The Journal (Memory Redaction), and the Combat HUD (Momentum Gauge).

## Proposed Solution: High-Contrast, Thematic Interfaces

### 1. The Color Palette & Typography
*   **Base:** Deep Charcoal/Off-Black (`#1A1C1E`) for backgrounds and boxes.
*   **Accent:** **Divine Teal** (`#00E5FF`). Used for highlights, the Momentum Gauge `SURGE` state, and divine UI elements. It represents the cold, precise power of the gods.
*   **Typography:**
    *   *Primary (Spoken/UI):* A clean, sans-serif or slightly condensed pixel font (e.g., *Silver* or *Munro*).
    *   *Secondary (Inner Monologue):* A distinct, slanted, handwritten-style font that feels raw and personal.

### 2. Dialogue: The Persona-Style Thought Overlay
Zi's inner thoughts are the emotional core of the game. They must feel intrusive and distinct from spoken words.

*   **Implementation (`DialogueBox.tscn`):**
    *   The main spoken text appears in the standard dialogue box at the bottom.
    *   When a `monologue` field is present in the JSON, a separate `RichTextLabel` node is dynamically instanced.
    *   **Animation:** This thought overlay instantly "slams" onto the screen beside Zi's portrait, slightly angled (like a physical stamp or a *Persona* cut-in), using the secondary handwritten font. It does not use a slow typewriter effect; it appears as a complete, sudden thought.
    *   The text color is a stark white against the dark background, cutting through the scene.

### 3. The Journal: Government Blackout Redaction
When a god exacts a `MEMORY` cost, the player's journal is permanently altered.

*   **Implementation (`JournalUI.tscn`):**
    *   The Journal renders text using a `RichTextLabel` with BBCode enabled.
    *   When `SaveManager` flags an entry as redacted, a custom Godot `RichTextEffect` (e.g., `[redact]...[/redact]`) is applied to the specific lines in the `journal_entries.json`.
    *   **Visuals:** The `[redact]` tag replaces the text with solid, uneven black blocks, mimicking heavily censored, declassified government documents. The player can clearly see *how much* text was lost, but cannot read it.

### 4. Combat: The Vertical Spine Momentum Gauge
The Momentum Gauge is the central tactical resource and requires constant player attention without obscuring the combat arena.

*   **Implementation (`CombatHUD.tscn`):**
    *   A thin, vertical `ProgressBar` anchored to the absolute left edge of the screen.
    *   **The Scale:** Fills from bottom (`-100`, Grounded) to top (`100`, Surge), with `0` (Balanced) clearly marked in the exact middle.
    *   **Dynamic Visuals:**
        *   *Grounded (Bottom 25%):* The bar turns a dull, heavy gray. The UI frame feels weighed down.
        *   *Balanced (Middle 50%):* Standard white/neutral color.
        *   *Surge (Top 25%):* The bar turns the blinding **Divine Teal** accent color. The entire spine pulses or emits subtle Godot particle effects (sparks/light) to indicate high risk/high reward.

## Verification
*   **Overlay Legibility:** Ensure the slanted, sudden "Thought Overlay" does not overlap critical UI elements or the spoken text box, regardless of screen resolution.
*   **BBCode Redaction:** Verify that the custom `RichTextEffect` for the blackout block correctly recalculates its width based on the hidden characters so the paragraph formatting doesn't collapse.
*   **HUD Anchoring:** Confirm the Vertical Spine is anchored using Godot's layout anchors (Left, Top-to-Bottom) so it scales perfectly on 16:9, 16:10, and Ultrawide displays without floating into the center.

## Alternatives Considered
*   **Glitch/Erased Text for Journal:** Considered making the text disappear entirely. Rejected because the stark, solid black "redaction" block fits the specific narrative theme of General Vaera's military bureaucracy and the gods' deliberate intervention better than a "magical glitch."
