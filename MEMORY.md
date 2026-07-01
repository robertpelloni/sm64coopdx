# Ongoing Memory & Codebase Observations

## Project State (v1.22)
*   **UI Architecture:** We have moved to a unified `UIToolkit` (`mods/system_ui/main.lua`). All menus MUST use `UIToolkit.draw_menu` and `UIToolkit.handle_input`. Hover-tooltip support is fully integrated.
*   **Data Persistence:** We rely heavily on `mod_storage` for systems like Mail, Auction House, Housing, and Inventory. String serialization must aggressively escape delimiters (`|`, `;`) to prevent injection/corruption.
*   **State Sync:** Short-term network sync uses `gPlayerSyncTable`. Nested tables are not supported; flatten keys (e.g., `inv_wood`).
*   **Input Handling:** Lua scripts are executed alphabetically. UI dependencies (like `_G.UIToolkit`) must be verified before use. Mod menus triggered from the Main Menu must debounce inputs using an `OPEN_TIMER` to prevent instant accidental selections.
*   **Security:** Command parsing (e.g., `/ah sell`, `/mail send`) MUST enforce positive integers for item counts and coin values to prevent severe integer underflow exploits.
*   **C-Engine vs Lua:** The project uses the sm64coopdx C engine. Custom C functions like `network_player_kick` are exposed to Lua. The Headless mode `--headless` relies on `src/pc/gfx/gfx_dummy.c`.
*   **Submodules:** The project currently does not use submodules (`bobcoin` was scrubbed). All custom logic resides in `mods/`.

## Implementation: Persistent World Connections & Fast Travel
*   **Waypoints System:** Created `mods/system_waypoints/` to manage fast travel discovery and dynamic boundary wrapping (`connections.lua`).
*   **Persistence:** Discoveries are saved to `waypoints_unlocked` via `mod_storage` using proper string serialization (joining via `|`).
*   **UI Integration:** Waypoints list correctly utilizes the `UIToolkit`, supports item debouncing, properly disables logic for undiscovered locked (`???`) locations, and is integrated directly into the `system_menu`.
