# World Architecture & Map Implementation Plan

## Background & Motivation
The world of Tessavar in *Blink in the Bramble* requires a seamless, open-world feel with a dark fantasy, melancholic atmosphere. The goal is to achieve a premium, modern pixel-art aesthetic (similar to *Eastward* or *Chained Echoes*) while maintaining a highly efficient, budget-friendly pure 2D development pipeline.

## Scope & Impact
This plan covers the technical foundation for the game's overworld and exploration systems. It establishes how maps are built, loaded, and visually presented. It impacts the `scenes/world/` directory and introduces background loading systems.

## Proposed Solution: The "Premium 2D" Chunking System

1.  **Pure 2D Engine with Modern Lighting:**
    *   Utilize Godot 4's 2D engine (`TileMap`, `CharacterBody2D`) for straightforward math, collision, and asset pipeline.
    *   Apply `CanvasModulate` for global ambient darkness/mood.
    *   Use `PointLight2D` with textures for campfires, glowing magic (Velundrath bioluminescence), and environmental highlights.
    *   Add a `WorldEnvironment` node to the main scene to apply global Bloom (glow) and subtle color correction.

2.  **Seamless Map Chunking:**
    *   Divide the world into discrete, manageable "Chunk" scenes (e.g., 64x64 tiles each).
    *   Implement a `WorldManager` script that tracks the player's position.
    *   Use Godot's `ResourceLoader.load_threaded_request()` to asynchronously load adjacent chunks before the player reaches the edge of their current chunk, unloading distant ones to maintain performance.

3.  **TileMap Layering Standard:**
    *   Every chunk will adhere to a strict layer hierarchy:
        *   `Layer 0 (Ground)`: Base terrain (grass, stone).
        *   `Layer 1 (Pathways)`: Dirt paths, floor details.
        *   `Layer 2 (Y-Sort/Objects)`: Trees, buildings, characters (things Zi can walk in front of or behind).
        *   `Layer 3 (Foreground/Canopy)`: Leaves, mist, or structures that block the camera, rendered partially transparent when the player is underneath.

4.  **Camera & Enemies:**
    *   `Camera2D` with position smoothing attached to the player.
    *   Enemies are placed directly into chunk scenes as `CharacterBody2D` nodes. Their AI process is paused when they are off-screen to save resources. Contact triggers the combat scene.

## Alternatives Considered
*   **HD-2D (Octopath Traveler style):** Considered placing 2D sprites in a 3D Godot environment. Rejected because it significantly increases development complexity (3D math, physics, sprite sorting, asset conversion) and goes against the requirement for an easier, faster pipeline.
*   **Massive Single TileMap:** Rejected due to memory constraints and load times. A single huge map is not viable for an open-world JRPG structure.

## Implementation Plan

### Phase 1: World Manager & Chunking Setup
1.  Create a base `MapChunk.tscn` with the standardized `TileMap` layers.
2.  Implement `WorldManager.gd` as an Autoload (Singleton) to handle the grid logic and tracking player coordinates.
3.  Write the async loading/unloading logic in `WorldManager.gd` using `ResourceLoader`.

### Phase 2: Visual Polish Pipeline (The "Eastward" Look)
1.  Add a `WorldEnvironment` to the root scene with Glow/Bloom enabled.
2.  Create standard reusable light prefabs (e.g., `CampfireLight.tscn`, `MagicGlow.tscn`).
3.  Implement a foreground/canopy fading script (dims `Layer 3` of the TileMap when the player enters a specific `Area2D`).

### Phase 3: Enemy Overworld Entities
1.  Create a base `OverworldEnemy.tscn`.
2.  Implement simple roaming AI using Godot's `NavigationRegion2D` within the chunks.
3.  Add collision detection to trigger a scene transition to the (yet-to-be-built) Combat Scene.

## Verification
*   **Performance:** Verify that crossing chunk boundaries does not cause frame drops or stuttering.
*   **Visuals:** Ensure characters properly sort behind/in front of `Layer 2` objects (Y-sorting).
*   **Memory:** Monitor memory usage while running in a straight line across multiple chunks to ensure old chunks are properly freed.

## Migration & Rollback
Since this establishes the foundational architecture, rollback would involve reverting to the single `NaevoriaRuins.tscn` test scene created earlier. No existing complex systems are being replaced.
