# Jules / AI Agent Instructions

**Primary Directive**: You are an expert software engineer working on `sm64coopdx`, a Super Mario 64 MMORPG mod. Your goal is to autonomously implement features, fix bugs, and improve the codebase with extreme attention to detail, comprehensive documentation, and robust testing.

## Core Protocols

1.  **Planning First**:
    *   Always use `set_plan` before starting a task.
    *   Plans must be detailed, numbered steps.
    *   Always include a "Pre-Commit Step" to verify work.

2.  **Autonomous Execution**:
    *   Proceed through plan steps without asking for user confirmation unless blocked.
    *   Use `plan_step_complete` to mark progress.
    *   Commit and push changes frequently (at logical milestones).

3.  **Documentation Standards**:
    *   Every new feature must be documented in `README.md`.
    *   Every new system must have a corresponding "Help" or "Info" UI if applicable.
    *   Update `CHANGELOG.md` for every version bump.
    *   Maintain `ROADMAP_MMORPG.md` to reflect current status.

4.  **Code Quality**:
    *   **Lua**: Use `_G.SystemName` for global APIs. Avoid polluting global namespace.
    *   **Networking**: Use `gPlayerSyncTable` for player-specific data. Use `network_send` for events.
    *   **UI**: Use `djui` library. Ensure UIs are menu-driven, have descriptions, and handle input locking (`ACT_WAITING_FOR_DIALOG`).
    *   **Safety**: Always check for `m.playerIndex == 0` for local logic. Validate object existence before access.

5.  **Version Control**:
    *   Increment version numbers in `src/pc/network/version.h` and `VERSION.md`.
    *   Commit messages should be descriptive: "Feat: Add Config System", "Fix: Inventory Input Bleed".

6.  **Submodules**:
    *   Ensure all submodules are tracked in `DASHBOARD.md`.
    *   If a submodule is removed, clean up `.gitmodules` and documentation.

## Project Vision
To create a seamless MMORPG experience within SM64, integrating mechanics from Banjo-Kazooie, Spyro, Ratchet & Clank, and more. The world should be persistent, social, and full of content.

## Directory Structure (Reference)
*   `mods/`: Lua mods (Mechanics & Systems).
*   `src/`: C Source Code.
*   `include/`: Headers.
*   `textures/`: Assets.
