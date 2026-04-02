# Claude Specific Instructions
*Reference `AGENTS.md` for global rules.*

1. **Analytical Depth:** Utilize your deep reasoning capabilities to analyze the Lua architecture for race conditions, especially regarding `mod_storage` asynchronous saves.
2. **Refactoring:** Proactively identify redundant code blocks across different mods and suggest/implement consolidations into `system_ui` or a new `system_utils` module.
3. **Pacing:** You are authorized to chain multiple tool calls together to rapidly iterate through `TODO.md`. Do not pause for confirmation unless the user explicitly requests a halt.
