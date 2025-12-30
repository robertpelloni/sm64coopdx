# Roadmap to MMORPG: The Definitive 3D Platformer Collection

## Vision
The ultimate goal of `sm64coopdx` is to evolve into a massive multiplayer online world ("MMORPG") that integrates the best mechanics from the entire history of 3D platformers. This document outlines the definitive list of inspirations and the roadmap to achieve feature parity with them, leading up to the technical overhaul required for thousands of players.

---

## Part 1: The Definitive List & Feature Gap Analysis

### Generation 5: The Foundations (N64 / PS1)
*The era of defining movement in 3D space.*

| Game | Notable Features | Current SM64CoopDX Status | Implementation Strategy |
| :--- | :--- | :--- | :--- |
| **Super Mario 64** | Core movement (Triple jump, long jump, wall kick). | **Complete** (Base Game). | Maintenance. |
| **Banjo-Kazooie** | **Transformation:** Turning into objects. | **Implemented.** | `mods/mechanic_transformation` |
| **Spyro the Dragon** | **Gliding:** Horizontal traversal. | **Implemented.** | `mods/mechanic_glide` |
| **Ape Escape** | **Gadgets:** Net, Sling, RC Car. | **Implemented.** | `mods/system_inventory` & `mods/system_weapon_wheel` |

### Generation 6: Refinement & Expansion (GC / PS2 / Xbox)
*The era of tools, weapons, and connected worlds.*

| Game | Notable Features | Current SM64CoopDX Status | Implementation Strategy |
| :--- | :--- | :--- | :--- |
| **Super Mario Sunshine** | **FLUDD:** Hover, Turbo, Rocket nozzles. | **Implemented.** | `mods/mechanic_fludd`. Integrated with Inventory. |
| **Jak and Daxter** | **Vehicles:** Zoomer bikes. | **Implemented.** | `mods/mechanic_vehicle` |
| **Ratchet & Clank** | **Weapon Wheel:** Selecting/leveling guns. | **Implemented.** | `mods/system_weapon_wheel` |
| **Psychonauts** | **PSI Powers:** Telekinesis. | **Implemented.** | `mods/mechanic_telekinesis` |

### Generation 7: Experimentation (Wii / PS3)
*The era of gravity and physics gimmicks.*

| Game | Notable Features | Current SM64CoopDX Status | Implementation Strategy |
| :--- | :--- | :--- | :--- |
| **Super Mario Galaxy** | **Gravity:** Launch Stars, Planetoids. | **Implemented (Launch Star).** | `mods/mechanic_gravity` implements Launch Stars. Full spherical gravity requires engine rewrite. |
| **Sonic Generations** | **Boost:** Instant high-speed state. | **Implemented.** | `mods/mechanic_boost` |

### Generation 8/9: Mastery (Switch / PS5)
*The era of fluid control and possession.*

| Game | Notable Features | Current SM64CoopDX Status | Implementation Strategy |
| :--- | :--- | :--- | :--- |
| **Super Mario Odyssey** | **Possession:** Controlling enemies. | **Implemented.** | `mods/mechanic_possession` |
| **A Hat in Time** | **Badges & Hookshot.** | **Implemented.** | `mods/system_perks` & `mods/mechanic_hookshot` |

---

## Part 2: The MMORPG Roadmap

### Phase 1: Gameplay Feature Parity
*Status: **Complete**.*
All mechanics from Generations 5-9 have been implemented as pilot mods.

### Phase 2: World & Progression
*Status: **Complete**.*
Inventory, Economy, Social (Guilds/Trading), and Save Data are active.

### Phase 3: The MMO Tech Stack
*Status: **Partial / In Progress**.*
1.  **Interest Management:** **Implemented (Client-Side).**
2.  **Dedicated Server Architecture:** **Pending.** Requires C Engine rewrite.
3.  **Instancing:** **Implemented (Client-Side).**

### Phase 4: Content Depth
*Status: **Complete**.*
1.  **Raid Bosses:** King Whomp.
2.  **Dungeons:** Crypt of the Vanished (Mob Tracking).
3.  **Classes:** Warrior, Mage, Rogue (Active Abilities).

---

## Current Status: Feature Complete (Alpha)
The project has reached feature parity with the target list. The next major step is the C Engine rewrite for Dedicated Server support.
