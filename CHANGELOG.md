# Changelog

All notable changes to this project will be documented in this file.

## [v1.23] - Latest
### Added
- **Equipment Manager:** Added `system_equipment` to visually manage and unequip weapons and badges via the Main Menu.
- **Daily Quests:** Added repeatable procedural daily tasks to `system_quests`.

### Fixed
- Fixed Quest namespace reference bug in the Main Menu.

## [v1.22] - Previous
### Added
- **Global `UIToolkit` Overhaul:** All menus now support descriptive labels, text wrapping, and hover-tooltips.
- **In-Game Encyclopedia:** Added `system_help` providing an exhaustive manual directly inside the game.
- **Weapon System:** Implemented `mechanic_weapons` featuring equippable swords and hammers with durability, hitboxes, and inventory UI integration.
- **Documentation Suite:** Rebuilt `VISION.md`, `MEMORY.md`, `DEPLOY.md`, `ROADMAP_MMORPG.md`, `TODO.md`, `HANDOFF.md`, and `DASHBOARD.md`.
- **AI Agent Directives:** Created `AGENTS.md` and model-specific instruction files (`CLAUDE.md`, `GEMINI.md`, etc.).
- **Unified Versioning:** Created `VERSION.md` as the single source of truth, with a python script (`build_version.py`) to inject it into the C engine.

### Fixed
- Fixed fatal Lua load crash in `system_quests` caused by incorrect table initialization.
- Fixed critical integer underflow exploits in `system_auction_house` and `system_mail` commands that allowed infinite coin generation.

## [v1.21] - Previous
- Implemented `system_housing` (Instanced Player Houses & Guild Halls).
- Implemented `system_auction_house` (Global Asynchronous Marketplace).
- Implemented `system_mail` (Persistent Item Transfer).
- Removed the deprecated `bobcoin` submodule entirely.
