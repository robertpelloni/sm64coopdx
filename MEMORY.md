# Ongoing Memory & Codebase Observations

## Project State (v1.22)
*   **UI Architecture:** We have moved to a unified `UIToolkit` (`mods/system_ui/main.lua`). All menus MUST use `UIToolkit.draw_menu` and `UIToolkit.handle_input`. Hover-tooltip support is fully integrated.
*   **Data Persistence:** We rely heavily on `mod_storage` for systems like Mail, Auction House, Housing, and Inventory. String serialization must aggressively escape delimiters (`|`, `;`) to prevent injection/corruption.
*   **State Sync:** Short-term network sync uses `gPlayerSyncTable`. Nested tables are not supported; flatten keys (e.g., `inv_wood`).
*   **Input Handling:** Lua scripts are executed alphabetically. UI dependencies (like `_G.UIToolkit`) must be verified before use. Mod menus triggered from the Main Menu must debounce inputs using an `OPEN_TIMER` to prevent instant accidental selections.
*   **Security:** Command parsing (e.g., `/ah sell`, `/mail send`) MUST enforce positive integers for item counts and coin values to prevent severe integer underflow exploits.
*   **C-Engine vs Lua:** The project uses the sm64coopdx C engine. Custom C functions like `network_player_kick` are exposed to Lua. The Headless mode `--headless` relies on `src/pc/gfx/gfx_dummy.c`.
*   **Submodules:** The project currently does not use submodules (`bobcoin` was scrubbed). All custom logic resides in `mods/`.
A Persistent World Connections system (`mods/system_waypoints/connections.lua`) utilizes position-based triggers to warp players seamlessly between levels (e.g., walking from Bob-omb Battlefield into Whomp's Fortress) without needing to return to the Castle Hub, creating a contiguous MMORPG map layout.

The PvP and environmental knockback system relies on flattened sync keys such as `kb_immune` in `gPlayerSyncTable` (e.g., triggered by the Warrior's Rage ability) and core engine flags like `MARIO_METAL_CAP` to determine hit reactions. When testing network sync logic for combat, ensure that immunity correctly nullifies velocity changes without causing desynchronization across clients.

When integrating custom movement mechanics like Glide or Fludd Hover, always hook `HOOK_ON_SET_MARIO_ACTION` to manually clear active states (e.g., `is_gliding = false`) when Mario enters airborne knockback actions (`ACT_BACKWARD_AIR_KB`, `ACT_FORWARD_AIR_KB`) to prevent floating physics desyncs.
