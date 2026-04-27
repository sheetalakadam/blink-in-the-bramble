# GEMINI.md - Development Mandates

These rules are foundational and take precedence over all other instructions for this project.

## Workflow Rules
1. **Branching:** All development must occur on feature branches (`feat/...` or `fix/...`).
2. **Local Testing:** After any code modification, provide specific instructions for the user to test the change in Godot.
3. **No Blind PRs:** Never create a Pull Request or merge into `main` without explicit user approval after their local test.
4. **Snappy PRs:** Keep implementation cycles small. Ensure the game is always in a "runnable" state before requesting verification.
5. **Logging:** Maintain meaningful debug logging in all core systems (prefixed with `[SystemName]`) for easier user troubleshooting.

## Technical Standards
- **Godot Version:** 4.3+ (Forward Plus/Mobile renderer).
- **Tile Size:** 32x32.
- **Resolution:** 640x360 (Pixel-perfect scaling).
- **Architecture:** Resource-driven (`.tres`) for data, Autoload singletons for managers.
- **Visuals:** High-contrast "Divine Teal" UI, Eastward-style 2D lighting.
