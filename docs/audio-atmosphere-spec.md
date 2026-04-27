# Audio & Atmosphere Specification

## Background & Motivation
In *Blink in the Bramble*, the audio is as crucial as the visuals for establishing the melancholic, vast, and intimate tone of Tessavar. Rather than relying on full voice acting, the game emphasizes strong, layered environmental audio and distinct "character blips" to convey personality. The music must transition cleanly to maintain immersion during the shift from exploration to tactical combat.

## Scope & Impact
This specification covers the `AudioManager.gd` Autoload, which governs music crossfading, environmental ambient layers (specifically the "moods" of the world), and the dialogue blip system tied to the `DialogueManager`.

## Proposed Solution: Layered Audio & Dynamic Mixing

### 1. Dynamic Music Transitions (Classic Crossfade)
The transition between exploration and combat must be distinct but not jarring.

*   **Mechanics (`AudioManager.gd`):**
    *   Two dedicated `AudioStreamPlayer` nodes: `MusicPlayer_Exploration` and `MusicPlayer_Combat`.
    *   When combat is triggered, `AudioManager.transition_to_combat(track_id)` is called.
    *   A Godot `Tween` animates the `volume_db` of `MusicPlayer_Exploration` from `0dB` to `-80dB` over 1.5 seconds.
    *   Simultaneously, `MusicPlayer_Combat` starts playing and its volume is tweened from `-80dB` to `0dB`.
    *   Upon combat victory, the reverse crossfade occurs, returning the player to the ambient exploration track.

### 2. Ambient Forest "Moods" (Creature Layers)
The world of Tessavar reacts to the spread of the Corrupted Zones. The audio environment must reflect the "health" of the current region.

*   **Data Structure (`AmbientData.tres`):**
    *   `region_id: String` (e.g., "ereivyn_forest")
    *   `base_layer: AudioStream` (e.g., wind in the leaves)
    *   `healthy_layer: AudioStream` (e.g., birdsong, rustling animals)
    *   `distressed_layer: AudioStream` (e.g., deep resonant hums, unsettling silence, distant cracking)

*   **Mechanics (`EnvironmentAudio.gd`):**
    *   Attached to the `MapChunk` or a global trigger area.
    *   Queries `GlobalFlags.get_integer("ereivyn_health_state")` (values e.g., 0 for distressed, 100 for healthy).
    *   Dynamically adjusts the `volume_db` of the `healthy_layer` and `distressed_layer` based on this integer. A fully distressed forest mutes the birdsong entirely and raises the volume of the unsettling resonant hums, fundamentally altering the "mood" of the area without changing the base wind track.

### 3. Character Voices (Classic Blips)
Dialogue uses short, repeating audio samples (blips) synchronized with the text typewriter effect to convey personality without full voice acting.

*   **Data Structure (in `CharacterData.gd` or a linked `VoiceData.tres`):**
    *   `voice_blip: AudioStream` (A short, 0.05s sound file)
    *   `base_pitch: float` (e.g., 0.8 for Zi, 1.2 for Suri, 1.5 with reverb for Caelan)
    *   `pitch_variance: float` (e.g., 0.1 to allow slight modulation so it doesn't sound completely robotic)

*   **Mechanics (Integrated into `DialogueBox.tscn`):**
    *   An `AudioStreamPlayer` is dedicated to dialogue blips.
    *   As the `RichTextLabel` reveals characters (`visible_characters += 1`), the system checks if the new character is a letter (ignoring spaces and punctuation).
    *   If it is a letter, it plays the `voice_blip` with a randomized pitch: `base_pitch + randf_range(-pitch_variance, pitch_variance)`.
    *   **Pacing:** The blip does not play on every single frame/letter to avoid audio clipping; it plays on every 2nd or 3rd character, creating a rhythmic, pleasant "speaking" sound.

## Verification
*   **Crossfade Overlap:** Ensure that the `Tween` for the crossfade does not cause a momentary spike in master volume if both tracks hit peak amplitude simultaneously. Using a logarithmic volume curve for the tween is recommended over a linear one.
*   **Ambient Loop:** Verify that the ambient layers (`base_layer`, `healthy_layer`, `distressed_layer`) are perfectly seamless loops to prevent noticeable "pops" when the track restarts.
*   **Blip Fatigue:** Playtest the dialogue blip frequency. Ensure the `pitch_variance` and skip-character logic prevent the sound from becoming grating during long monologue sequences.

## Alternatives Considered
*   **Full Voice Acting:** Rejected due to budget constraints and the GDD's explicit preference for an atmosphere-heavy, subtext-driven presentation where the player imagines the exact inflection.
*   **Horizontal Re-sequencing for Music:** Considered adding combat drum layers over the exploration track. Rejected in favor of a hard crossfade to create a sharper emotional contrast between the safety/melancholy of exploration and the danger of combat.
