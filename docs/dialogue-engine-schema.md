# Dialogue Engine & JSON Schema Specification

## Background & Motivation
The narrative of *Blink in the Bramble* relies heavily on subtext, specifically the contrast between Zi's spoken words and her internal thoughts ("Inner Monologue"). Furthermore, characters possess "Domain Expertise" (e.g., Zi's tactical geometry, Suri's social economy) that shapes how they perceive and describe the world without them explicitly stating it. A standard dialogue system cannot handle this elegantly. We need a custom JSON-based schema to manage this multi-layered dialogue efficiently.

## Scope & Impact
This specification defines the exact structure of the `dialogue.json` files that power the custom Godot parser. It establishes how branches, choices, inner monologues, portrait states, and game events (signals) are declared and processed by `DialogueManager.gd`.

## Proposed Solution: The Multi-Layer JSON Schema

The dialogue will be structured as an array of JSON objects, where each object represents a single "Conversation Node" or "Block". A conversation can jump between nodes based on choices or linear progression.

### 1. The Root Structure
Each file represents a conversation (e.g., `scene_01_camp.json`).

```json
{
  "id": "scene_01_camp_main",
  "start_node": "intro_node",
  "nodes": {
    "intro_node": { ... },
    "branch_a": { ... },
    "branch_b": { ... }
  }
}
```

### 2. The Node Structure (The Heart of the System)
A node contains a sequence of lines to be displayed sequentially.

```json
"intro_node": {
  "lines": [
    {
      "speaker": "Zi",
      "text": "Fine.",
      "monologue": "I don't know what to do when people stay.",
      "portrait": "zi_neutral",
      "lens": "tactical",
      "events": ["fade_music_out"]
    },
    {
      "speaker": "Suri",
      "text": "Okay but what if we just asked nicely first?",
      "portrait": "suri_concerned",
      "lens": "social",
      "events": []
    }
  ],
  "choices": [
    {
      "label": "Agree with Suri",
      "next_node": "branch_a",
      "affinity_change": { "Suri": 5 }
    },
    {
      "label": "Ignore her",
      "next_node": "branch_b",
      "affinity_change": { "Suri": -2 }
    }
  ],
  "next_node": null 
}
```

### 3. Key Schema Definitions
*   **`speaker` (String):** The ID of the character speaking. Determines the nameplate and portrait directory.
*   **`text` (String):** The primary spoken dialogue displayed in the main text box.
*   **`monologue` (String, Optional):** Zi's internal thoughts. When present, the UI will spawn a secondary floating text node (perhaps in a handwritten font) overlapping or near her portrait while the spoken `text` is typed out.
*   **`portrait` (String):** The specific sprite animation state to play (e.g., `zi_angry`, `caelan_confused`).
*   **`lens` (String, Optional):** Defines the "Domain Expertise" filter for the line. For example, if `"lens": "tactical"` is used during a narration line, the UI might highlight specific words or subtly change the text box color to indicate Zi is analyzing the room rather than just observing it.
*   **`events` (Array of Strings, Optional):** Signals that the `DialogueManager` will emit when this line begins typing. Used to trigger animations, sound effects, or camera shakes (e.g., `"play_glass_shatter"`, `"shake_camera_light"`).
*   **`choices` (Array, Optional):** If present at the end of a node's lines, the UI pauses and displays buttons. Each choice dictates the `next_node` to load and can modify the central `AffinityManager`.
*   **`next_node` (String, Optional):** If no choices are present, the conversation automatically jumps to this node ID after the last line. If `null`, the conversation ends.

## The UI Implementation Strategy (`DialogueBox.tscn`)
1.  **Main Text Panel:** Standard typewriter effect (`visible_ratio` tween) for the `text` field.
2.  **Monologue Overlay:** A secondary `RichTextLabel` with a different font (e.g., a scratchy handwriting font) that appears *simultaneously* with the main text if the `monologue` field is populated. It fades in slightly slower than the spoken word.
3.  **Portrait Node:** An `AnimatedSprite2D` or `TextureRect` that dynamically swaps textures based on the `speaker` + `portrait` string combination.
4.  **Signal Bus:** The `DialogueManager` Autoload will have a generic signal: `signal dialogue_event(event_name: String)`. Other systems (Audio, Camera) connect to this to react when an event string is fired from the JSON.

## Verification
*   **Parsing:** Ensure the Godot `JSON.parse_string()` can successfully load complex scenes without stuttering.
*   **Timing:** Verify that the `monologue` text timing aligns comfortably with the spoken `text` so the player can read both without feeling rushed.
*   **State Management:** Confirm that `affinity_change` correctly updates the `SaveManager` state instantly upon selection.

## Alternatives Considered
*   **Using Resource (`.tres`) files instead of JSON:** While more "Godot-native", writing dense, branch-heavy dialogue in the Godot Inspector UI is highly inefficient compared to writing raw JSON in a text editor (or using a dedicated branching narrative tool like Twine/Yarn and exporting to JSON). JSON remains the superior authoring format for this scope.
