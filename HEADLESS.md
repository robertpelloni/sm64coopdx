# Headless Server Guide

The `sm64coopdx` engine supports a "Headless" mode, allowing you to run a dedicated server without a graphical window or audio output. This is essential for hosting 24/7 servers on Linux VPS or containerized environments.

## How to Run

Launch the executable with the `--headless` argument:

```bash
./sm64coopdx --headless --server [PORT] --savepath [PATH]
```

### Arguments

*   `--headless`: Disables graphics (window creation) and audio. The game loop runs in a console-only mode.
*   `--server [PORT]`: Starts the game immediately in Server mode on the specified port.
*   `--savepath [PATH]`: Specifies where save data and configuration should be stored (useful for containers).
*   `--configfile [FILE]`: Load a specific configuration file.

## Example Usage (Linux)

```bash
# Start a server on port 3000
./sm64coopdx --headless --server 3000 --savepath ./server_data
```

## Technical Details

In headless mode:
1.  **Graphics**: The `WAPI` (Window API) and `RAPI` (Rendering API) are replaced with "Dummy" implementations. `gfx_dummy.c` handles the game loop timing (`clock_gettime`) but discards all draw calls.
2.  **Audio**: The audio system is initialized with `audio_null`, processing no sound.
3.  **Input**: No keyboard/mouse input is processed. You must configure the server via `sm64config.txt` or CLI arguments.
4.  **Logging**: Output is directed to `stdout` (console).

## Configuration

Ensure your `sm64config.txt` (located in the save path) has the correct settings for your server:

```ini
network_system SOCKET
network_host_port 3000
network_player_name "Dedicated Server"
```
