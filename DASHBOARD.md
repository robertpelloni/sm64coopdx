# Project Dashboard

## Project Directory Structure

The project structure is organized as follows:

-   **`src/`**: Contains the source code for the game.
    -   `src/pc/`: Platform-specific code (PC port).
    -   `src/game/`: Game logic and behaviors.
    -   `src/engine/`: Core engine components.
-   **`mods/`**: Contains Lua mods for gameplay mechanics and systems.
    -   `mods/mechanic_boost/`: Sonic Boost mechanic (Speed/Meter).
    -   `mods/mechanic_fludd/`: FLUDD mechanic (Hover/Rocket/Turbo).
    -   `mods/mechanic_glide/`: Spyro Glide mechanic.
    -   `mods/mechanic_gravity/`: Launch Star mechanic (Galaxy).
    -   `mods/mechanic_hookshot/`: Hookshot mechanic.
    -   `mods/mechanic_possession/`: Entity Possession mechanic.
    -   `mods/mechanic_telekinesis/`: Telekinesis mechanic (Psychonauts style).
    -   `mods/mechanic_transformation/`: Transformation API (Banjo style).
    -   `mods/mechanic_vehicle/`: Vehicle mechanic (Zoomer).
    -   `mods/system_achievements/`: Achievements and Titles system.
    -   `mods/system_classes/`: RPG Class system (Warrior/Mage/Rogue).
    -   `mods/system_guilds/`: Guild system, Chat, and Nametags.
    -   `mods/system_instancing/`: Instancing system (Dimensions).
    -   `mods/system_inventory/`: Universal Inventory system and Economy.
    -   `mods/system_optimization/`: Client-side interest management/culling.
    -   `mods/system_perks/`: Perks/Badges system.
    -   `mods/system_quests/`: Quest system API and tracker.
    -   `mods/system_shop/`: NPC Shop system.
    -   `mods/system_trading/`: Player Trading system.
    -   `mods/system_weapon_wheel/`: Weapon Wheel UI.
    -   `mods/system_world/`: Connected World (Portals).
-   **`include/`**: Header files.
-   **`levels/`**: Level data and scripts.
-   **`actors/`**: Actor data and models.
-   **`sound/`**: Sound data and sequences.
-   **`textures/`**: Texture assets.
-   **`tools/`**: Build tools and scripts.

## Submodules

There are no submodules configured in this repository.

## MMORPG Roadmap

See `ROADMAP_MMORPG.md` for the detailed plan and feature breakdown.

## Version Information

Current Version: `v1.7` (Internal Version: 44)
See `src/pc/network/version.h`.
