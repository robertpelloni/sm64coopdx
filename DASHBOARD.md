# Project Dashboard

## Project Directory Structure

The project structure is organized as follows:

-   **`src/`**: Contains the source code for the game.
    -   `src/pc/`: Platform-specific code (PC port).
    -   `src/game/`: Game logic and behaviors.
    -   `src/engine/`: Core engine components.
-   **`mods/`**: Contains Lua mods for gameplay mechanics and systems.
    -   `mods/mechanic_boost/`: Sonic Boost mechanic.
    -   `mods/mechanic_glide/`: Spyro Glide mechanic.
    -   `mods/mechanic_hookshot/`: Hookshot mechanic.
    -   `mods/mechanic_possession/`: Entity Possession mechanic.
    -   `mods/system_inventory/`: Universal Inventory system.
    -   `mods/system_perks/`: Perks/Badges system.
    -   `mods/system_weapon_wheel/`: Weapon Wheel UI.
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

Current Version: `v1.5` (Internal Version: 42)
See `src/pc/network/version.h`.
