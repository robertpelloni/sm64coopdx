# sm64coopdx: The MMORPG Project

![Logo](textures/segment2/custom_coopdx_logo.rgba32.png)

A massive multiplayer online modification for Super Mario 64, integrating mechanics from the history of 3D platformers into a cohesive world.

## Overview
This project transforms SM64 into an MMORPG with persistent inventory, quests, guilds, classes, and advanced movement mechanics. Join friends to explore, battle, and build your legacy.

## Getting Started
1.  **Join the Server**: Connect to a server running this mod.
2.  **Open the Menu**: Press `L + START` to access the Main Menu.
3.  **Choose a Class**: Use `/class [warrior|mage|rogue]` to select your role.
4.  **Start a Quest**: Visit the Quest Log in the Main Menu or use `/quest coin`.

## Controls & Mechanics

### Core Systems
*   **Main Menu**: `L + START` - Access Inventory, Quests, Guilds, and Options.
*   **Inventory**: Manage your items. Use `D-Pad` to navigate, `A` to use/equip.
*   **Weapon Wheel**: Hold `L Trigger` to quickly select equipped items/weapons.
*   **Quests**: Track your progress via the Quest Log in the Main Menu.
*   **Shop**: Interact with Toads (Press `B`) to buy items.

### Movement Abilities
*   **Sonic Boost**: While moving on ground, press `X`. Requires Boost Meter.
*   **Spyro Glide**: In air, hold `L + A` to glide.
*   **FLUDD**: Equip a nozzle (Hover, Rocket, Turbo) from Inventory.
    *   **Hover**: Press `R` in air.
    *   **Rocket**: Press `R` to launch.
    *   **Turbo**: Press `R` while moving to speed up.
*   **Hookshot**: Equip `Hookshot`. Press `Y` to fire at surfaces.
*   **Telekinesis**: Press `R` to grab objects (if no FLUDD nozzle equipped). Press `R` again to throw.
*   **Vehicle (Zoomer)**: Use `/vehicle` to toggle hover bike mode. Press `A` to accelerate.

### Classes & Combat
*   **Warrior**: High HP, Melee focus.
    *   *Ability 1 (Left D-Pad)*: Bash/Stun.
    *   *Ability 2 (Right D-Pad)*: Rage (Invulnerability).
*   **Mage**: Ranged magic.
    *   *Ability 1 (Left D-Pad)*: Fireball.
    *   *Ability 2 (Right D-Pad)*: Teleport.
*   **Rogue**: Stealth and Speed.
    *   *Ability 1 (Left D-Pad)*: Dash.
    *   *Ability 2 (Right D-Pad)*: Invisibility.

### Social
*   **Guilds**: Join forces with other players.
    *   `/guild create [name]`: Create a guild.
    *   `/guild join [name]`: Join a guild.
    *   `/g [message]`: Chat with guild members.
*   **Trading**: Use `/trade [player]` or interact with players to initiate a trade.

## Items & Economy
*   **Coins**: The primary currency. Collected in the world.
*   **Badges**: Equip badges from Inventory for passive bonuses (Speed, Health, etc.).
*   **Transformation Totems**: Use to transform into enemies (Goomba, Termite).

## Lua API
sm64coopdx is moddable via Lua. See `docs/lua/lua.md` for documentation.

## Credits
Based on sm64ex-coop. Developed by the Coop Deluxe Team.
