# Fallen Grace — Game Design Document

## Concept
A dark fantasy JRPG set in Tessavar, a world shattered when the divine realm broke apart 300 years ago.
Angels fell. Gods went silent. Now something is waking them again.

The story follows Sael, a mortal living in isolation, whose life is upended when a fallen angel named Kael
crashes into it. What begins as reluctant companionship becomes something neither expected.

Emotionally grounded. Quiet. Deeply personal. Epic world, intimate story.

---

## Tone & References
- **Gameplay**: Chained Echoes, Fire Emblem Three Houses, Hades
- **World**: Skyrim (environmental storytelling), AC Odyssey (mythological depth, romance freedom)
- **Emotional tone**: Ikoku Nikki — slow relationships, grief, found family, real feelings in extraordinary circumstances
- **Writing**: Inner monologue, journal entries, dialogue choices with weight

---

## The World: Tessavar

The Fracture happened 300 years ago. The Canopy (divine realm) tore apart.
Angels fell to the mortal world — some corrupted, some traumatized, some trying to rebuild.
The gods went silent. The mortal world warped, mixing with fragments of the divine realm.

Now: sky islands, corrupted zones, angelic ruins alongside living forests and plains.
People worship gods who don't answer. Study fallen angels like relics. Fight over divine power.

Something is shifting. Angels are waking. Gods are whispering again.

---

## The Gods (Occasional Helpers)

| God | Domain | Personality | How They Help | Hidden Agenda |
|-----|--------|-------------|---------------|---------------|
| Auryn | Light, Truth | Cold, precise | Reveals info, enemy weaknesses | Wants old divine order restored at any cost |
| Morrael | Death, Endings | Gentle, dark, honest | Revives fallen party members | Believes the mortal world should end — kindly |
| Thessia | Love, Memory | Warm, chaotic | Heals relationships, restores affinity | Collects emotions — takes something personal |
| Varek | War, Conflict | Blunt, loyal to strength | Combat boosts, breaks impossible fights | Help always costs something |
| Lyenne | Time, Forgetting | Melancholic, cryptic | Shows past visions, explains lore | Erasing herself — each intervention costs her existence |

Gods appear at divine shrines, in dreams, visions. You call on them — they always want something back.

---

## Characters

### Sael (Player Character)
- Mortal. Practical, dry humor, quietly carries grief
- Was living alone in the ruins zone before Kael arrived
- No magic. Fights with a blade. Gets things done.
- Arc: learning to let people in again

### Kael (First Companion — Fallen Angel)
- Doesn't remember The Fracture or who they were before
- Gentle, curious about mortal life, overwhelmed by feelings
- Powerful magic they can't fully control
- Carries a wound the gods recognize and fear
- Arc: figuring out who they are now, not who they were

### Riven (Second Companion — Deserter Soldier)
- Deserted their kingdom after witnessing something they won't discuss
- Sarcastic, protective, acts unbothered
- Has quietly searched for Fracture answers for years — knows more than they show
- Arc: confronting what they saw and why they ran

### Essa (Third Companion — Scholar, joins later)
- Obsessed with angelic lore. Enthusiastic, oblivious to danger
- Complicated relationship with the god Lyenne
- Brings warmth and chaos to the group
- Arc: reconciling academic understanding with meeting actual angels

---

## Core Systems

### 1. Exploration
- Top-down open world, 8-directional movement
- Enemies visible on map — contact triggers battle (no random encounters)
- Environmental storytelling: ruins, notes, journals, scattered lore

### 2. Combat (JRPG Turn-Based — Chained Echoes style)
- Party of 3-4 vs enemy group
- Menu-driven: Attack / Skills / Magic / Items / Defend
- Turn order based on Speed stat
- Each character has unique skill tree
- Failure has narrative acknowledgment

### 3. Base Camps
- Scattered across world, discovered through exploration
- Develop over time:
  - **Forge** — weapon/armor upgrades
  - **Sanctum** — magic research, god shrines
  - **Quarters** — relationship scenes, bonding moments
  - **Outpost** — fast travel, storage, map
- Rest at camp to save and recover

### 4. Relationships & Affinity
- Bond system per companion — builds through dialogue, camp scenes, gifts, shared meals
- Affinity levels unlock new story scenes and dialogue
- Romance available with multiple characters
- Hades-style: characters react to your progress and choices
- Inner monologue shows Sael's real thoughts vs what they say

### 5. Gods System
- Divine shrines scattered across world
- Call on a god → they help → they take something (HP, memory, affinity, items)
- Each god has 3-4 unique interventions
- Overusing one god has consequences

### 6. Journal
- Sael writes after major events — handwritten style, unfiltered thoughts
- Auto-updates with lore, character notes, world discoveries
- Player can read at any time

---

## Build Phases

| Phase | Focus |
|-------|-------|
| 0 | Repo, project setup, Godot project, tile size decision |
| 1 | Player movement (top-down), camera, basic tilemap |
| 2 | Dialogue system (text, portraits, choices, inner monologue) |
| 3 | Combat system (turn manager, menus, skills, enemy AI) |
| 4 | Party system (roster, stats, levels, classes) |
| 5 | World regions + enemy placement + battle triggers |
| 6 | Relationship/affinity system + camp scenes |
| 7 | Camp development + inventory + crafting |
| 8 | Gods system (shrines, interventions, costs) |
| 9 | Story, routes, side quests, journal |
| 10 | Polish, audio, UI, balancing |

---

## Open Questions (to decide before Phase 1)
- [ ] Tile size: 16x16 or 32x32?
- [ ] Combat turn order: speed-based or fixed?
- [ ] AP system or one action per turn?
- [ ] Dialogue: custom system or Dialogic plugin?
- [ ] Data format: JSON or Godot Resources?
- [ ] World structure: how many regions to start?
- [ ] Kael/Sael relationship: romance or found family (or player's choice)?
