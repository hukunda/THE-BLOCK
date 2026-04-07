# THE BLOCK

**Complete Game Design & Technical Specification**  
Cross-platform ASCII First-Person Game

---

## 1. PROJECT OVERVIEW

### 1.1 Title

**THE BLOCK**

### 1.2 Genre

- First-Person Shooter (FPS)
- Dungeon crawler
- Urban horror
- ASCII-rendered game

### 1.3 Target Experience

A slow-burn, atmospheric shooter focused on:

- exploration
- tension
- memory
- decay
- dark, dry humor

The game should feel like:

> “A console-era FPS trapped inside a broken building and rendered in ASCII.”

---

## 2. CORE DESIGN GOALS

- True cross-platform from day one
- ASCII as deliberate visual style, not novelty
- Controller, keyboard, and touch parity
- Strong sense of place and progression
- Replayable, modular structure
- Players feel nostalgia without explicit references
- Boss fights define each level

---

## 3. TARGET PLATFORMS (MANDATORY)

The game **MUST** be playable on:

- Windows
- macOS
- Linux
- Consoles (gamepad-first)
- Mobile phones and tablets (touch-first)

### 3.1 Cross-Platform Rules

The game **MUST NOT**:

- depend on terminal/console applications
- assume mouse movement
- assume fixed resolution
- assume physical keyboard presence

The game **MUST**:

- use a platform-agnostic rendering layer
- treat ASCII as a scalable graphical layer
- run from a single shared logic codebase

---

## 4. INPUT SYSTEM (CRITICAL)

### 4.1 Action-Based Input Architecture

All input is abstracted into **actions**, never keys:

- MoveForward
- MoveBackward
- StrafeLeft
- StrafeRight
- TurnLeft
- TurnRight
- Fire
- Interact
- UseItem
- Pause

### 4.2 Device Mapping

Each action must be mappable to:

- Keyboard keys
- Game controller buttons / sticks
- Touch areas (virtual joystick + buttons)

### 4.3 Touch Controls

Touch controls must:

- avoid precision gestures
- use large, forgiving input zones
- support one-handed play if possible

---

## 5. CAMERA & MOVEMENT

### 5.1 Camera

- First-person only
- No free look with mouse assumed
- Horizontal turning speed configurable

### 5.2 Movement

- Doom-style movement (fast strafing, responsive)
- No jumping required
- Verticality handled via level layout, not jumping

---

## 6. RENDERING SYSTEM

### 6.1 ASCII Rendering Model

- Fixed-width monospace grid
- Characters represent materials, depth, and light
- Rendering independent of actual screen resolution

**Minimum viewport:** 80 columns × 30 rows  
**Preferred viewport:** 100 × 35 or higher  

**Small screens:**

- Scale glyph size
- Reduce peripheral detail
- Keep center area readable

### 6.2 Pseudo-3D Perspective

- Forward-facing depth illusion
- Floor compression toward horizon
- Walls use density gradients
- No top-down or isometric view

### 6.3 Visual Language

**Materials**

- `░▒▓` – concrete, decay, walls
- `#|=` – metal, infrastructure
- `. -` – distance, floor
- `@O0` – humans
- `█` – bosses, mass, immovable objects

**Lighting**

- No real shadows
- Brightness via glyph density and color
- Flickering lights swap similar characters

---

## 7. GLITCH & DISTORTION SYSTEM

Glitch effects represent **reality corruption**, not visuals for fun. Used only when:

- boss fights occur
- network interference zones
- late-game floors

Effects may include:

- scrambled characters
- brief UI loss
- input delays (short, predictable)

**Never** permanent. **Never** constant.

---

## 8. GAME STRUCTURE

### 8.1 Overall Structure

- The building = vertical progression
- Each floor = one level
- Each level ends with a boss
- **Total floors: 10**

---

## 9. LEVEL DESIGN (DETAILED)

Each floor contains:

- exploration phase
- enemy encounters
- optional NPCs
- environmental storytelling
- a sealed boss arena

### Floor Breakdown

**FLOOR 1 – THE LOBBY**  
Purpose: tutorial | Enemies: slow residents | Boss: **The Doorman**  
Teaching: movement, aiming, interaction

**FLOOR 2 – THE STAIRWELL**  
Theme: transition | Enemies: ambush types | Boss: **The Fall**  
Teaching: vertical awareness, knockback danger

**FLOOR 3 – THE VIDEO STORE**  
Theme: media decay | Enemies: fast, fragile | Boss: **The Late Fee**  
Focus: pressure, aggressive play

**FLOOR 4 – THE ARCADE**  
Theme: broken entertainment | Enemies: unpredictable | Boss: **Player One**  
Teaching: pattern recognition, adaptive combat

**FLOOR 5 – COMPUTER ROOMS**  
Theme: early networking | Enemies: teleporting / lagging | Boss: **The Modem**  
Introducing: signal interference, rhythm disruption

**FLOOR 6 – THE SLEEPERS**  
Theme: homelessness | Enemies: morally ambiguous | Boss: **The One Who Remembers**  
Focus: emotional storytelling, non-linear encounters

**FLOOR 7 – NETWORK FLOOR**  
Theme: abstraction | Enemies: non-physical | Boss: **Ping**  
Teaching: movement timing, visibility constraints

**FLOOR 8 – EMPTY APARTMENTS**  
Theme: absence | Enemies: reflections | Boss: **The Tenant**  
Mechanic: mirrors player behavior

**FLOOR 9 – THE ELEVATOR**  
Theme: control | Enemies: environment itself | Boss: **The Caretaker**  
Mechanic: environment manipulation

**FLOOR 10 – THE ROOF**  
Theme: confrontation | Boss: **The Block**  
Multi-phase fight where architecture attacks, UI is stripped away, rules break intentionally

---

## 10. ENEMY DESIGN

### Enemy Principles

- Few archetypes
- Clear silhouettes
- Predictable patterns that evolve

### Enemy Types

- Residents
- Drop-Outs
- Floor Sleepers
- Holdovers
- Glitch Entities

Enemies are not “evil”; they are left behind.

---

## 11. BOSSES

Bosses are **ideas**, not just enemies.

**Rules:**

- Occupy ≥ ⅓ of screen
- Alter space, rules, or UI
- Introduce unique mechanic
- Communicate indirectly

Each boss represents: control, delay, stagnation, memory.

---

## 12. COMBAT SYSTEM

- Hitscan or simple projectile combat
- Limited ammo
- No reloading animations
- Visual hit feedback via ASCII distortion

**Difficulty ramps by:**

- enemy behavior
- environmental pressure
- rule changes

---

## 13. PROGRESSION SYSTEM

- Player power remains limited
- No RPG stats
- Improvements come from knowledge, pattern recognition, equipment variations
- **No skill trees.**

---

## 14. USER INTERFACE (UI)

**HUD example:**

```text
HP [||||||     ]   AMMO 12   SIGNAL ?
> You hear something inside the walls.
```

**Rules:**

- readable on small screens
- ASCII only
- no modern UI metaphors
- no minimaps

---

## 15. AUDIO DESIGN

### Music

- PC speaker-style tones
- MIDI loops
- simple repetitive patterns

### Sound

- CRT hum
- electrical buzz
- static
- minimal impact sounds

**Silence is intentional.**

---

## 16. HUMOR & WRITING

**Tone:** dry, cynical, adult, subtle

**Examples:**

- “Connection lost. Continue anyway.”
- Achievement: You Shouldn’t Be Here

**No** memes. **No** pop-culture references. **No** explicit years.

---

## 17. STORY & LORE

- No cutscenes.
- No narration.

**Story told through:** architecture, NPC comments, system messages, inconsistencies.

**Central theme:** Buildings remember even when people leave.

---

## 18. ENDINGS

- Leave
- Shut Down
- Stay (NG+ latent ending)

No perfect outcome.

---

## 19. TECHNICAL DEVELOPMENT RULES

Cursor / development must:

- separate logic from rendering
- keep systems deterministic
- design floors as modular units
- allow future content expansion
- never optimize at cost of clarity

---

## 20. DEFINITION OF DONE

The project is successful when:

- playable on keyboard, controller, touch
- readable on phone screens
- each floor feels distinct
- bosses are memorable
- ASCII feels essential, not gimmicky

---

## 21. BRAND

### 21.1 Title

**THE BLOCK** — Short, aggressive, architectural. Works globally, no translation needed.

### 21.2 Core Brand Keywords

Concrete · Noise · Memory · Utility · Abandonment · Infrastructure · Signal · Late 90s / early 00s

Everything visual or audible must align with these.

---

## 22. LOGO DESIGN (OFFICIAL)

### 22.1 Logo Philosophy

The logo must look like:

- A building label
- A utility sign
- A network node name
- Something painted, printed, or bolted onto concrete

It should **not**:

- look like a modern indie logo
- use gradients
- use stylized typography
- reference specific countries or cultures

### 22.2 Primary ASCII Logo (OFFICIAL)

Canonical logo — title screen, splash, marketing ASCII renders, readme files:

```text
████████╗ ██╗  ██╗ ███████╗
╚══██╔══╝ ██║  ██║ ██╔════╝
   ██║    ███████║ █████╗
   ██║    ██╔══██║ ██╔══╝
   ██║    ██║  ██║ ███████╗
   ╚═╝    ╚═╝  ╚═╝ ╚══════╝

██████╗  ██╗      ██████╗  ██████╗ ██╗  ██╗
██╔══██╗ ██║     ██╔═══██╗ ██╔════╝ ██║ ██╔╝
██████╔╝ ██║     ██║   ██║ ██║      █████╔╝
██╔══██╗ ██║     ██║   ██║ ██║      ██╔═██╗
██████╔╝ ███████╗╚██████╔╝ ╚██████╗ ██║  ██╗
╚═════╝  ╚══════╝ ╚═════╝   ╚═════╝ ╚═╝  ╚═╝
```

**Optional subtitle (contextual):**  
`>An ASCII urban nightmare (1995–2004)`

### 22.3 Minimal Logo (HUD / Mobile / Menu)

When space is limited:

```text
[ THE BLOCK ]
```

or

```text
### THE BLOCK ###
```

### 22.4 Non-ASCII Logo Rules (If Needed)

If a graphical logo is ever made:

- use only blocky sans-serif
- pretend it was made in 1998
- flat colors only
- no glow, no gradients

ASCII version remains the source of truth.

---

## 23. TITLE SCREEN (OFFICIAL)

### 23.1 Layout

```text
████████████████████████████████████████
              THE BLOCK

        An ASCII urban nightmare
                1995–2004

           > PRESS ANY KEY <

████████████████████████████████████████
```

### 23.2 Audio on Title Screen

- Single short PC-speaker-style beep
- Then low background hum
- No melody
- Silence is acceptable

---

## 24. MUSIC DIRECTION (CRITICAL)

Music is **not** background decoration. It models the mental state of the building.

### 24.1 Musical Aesthetic

Primary inspirations (mentally, not legally): PC speaker tones, early Sound Blaster FM, DOS MIDI, tracker music, system beeps.

Music should feel: limited, repetitive, slightly broken, hypnotic, uncomfortable after long exposure.

### 24.2 What the Music MUST NOT Be

- No modern synthwave
- No lo-fi hip hop
- No orchestral scoring
- No emotional manipulation
- No long melodies

---

## 25. MUSIC IMPLEMENTATION RULES

### 25.1 Track Structure

- Tracks are short loops (20–60 seconds)
- Minimal harmony (1–2 notes preferred)
- Repetition is intentional
- Some floors may have no music at all

### 25.2 Dynamic Music Rules

Music **may**: drop out suddenly, distort during combat, desync briefly during glitches.

Music should **NEVER**: swell emotionally, “solve” tension, guide player feelings explicitly.

---

## 26. FLOOR-BY-FLOOR MUSIC SPEC

| Floor            | Style                                      |
| ---------------- | ------------------------------------------ |
| Lobby            | PC speaker beeps, low tempo                |
| Stairwell        | Slow ticking pulse                         |
| Video Store      | Simple MIDI melody fragment                |
| Arcade           | Faster MIDI loop, unstable rhythm          |
| Computer Rooms   | Modem-like tones, distortion               |
| Sleepers         | Almost silent, low drone                    |
| Network Floor    | Glitch pulses, packet noise                |
| Empty Apartments | No music, only ambience                    |
| Elevator         | Mechanical rhythm                          |
| Roof             | Abstract noise + silence                   |

---

## 27. BOSS FIGHT MUSIC

Boss music is **not** heroic.

**Rules:** Short loops, repetitive, increasing distortion, sometimes stops mid-fight.

**Example behaviors:**

- Player One mimics previous track
- The Modem cuts audio with “connection loss”
- The Block removes music entirely in final phase

---

## 28. SOUND EFFECTS (SFX)

### 28.1 Sound Philosophy

Sound effects are: dry, short, utilitarian, unpleasant up close. Think “system feedback”, not “cinematic sound”.

### 28.2 Required SFX Categories

- Movement (footsteps, scraping)
- Combat (minimalistic impacts)
- Doors (metal + failure)
- UI (beeps, clicks)
- Glitch (static, noise bursts)

### 28.3 Silence Policy

Some zones must include: no music, minimal SFX, long silence stretches. **Silence is a mechanic.**

---

## 29. AUDIO TOOLS (GUIDANCE, NOT REQUIREMENT)

Suggested tools compatible with style: Bosca Ceoil, LMMS, Furnace Tracker, Deflemask.

No real instruments required.

---

## 30. AUDIO FILE CONSTRAINTS

- Low sample rates acceptable
- Mono preferred for SFX
- Files must loop cleanly
- No reverb tails unless intentional

Audio should feel **small**.

---

## 31. FINAL BRAND CHECKLIST (MUST PASS)

The game is brand-complete if:

- Logo looks like part of a building
- Music feels intentionally constrained
- Silence is used deliberately
- ASCII visuals and audio reinforce each other
- Nothing feels “modern indie”
- Nothing breaks immersion with polish

---

*End of specification.*
