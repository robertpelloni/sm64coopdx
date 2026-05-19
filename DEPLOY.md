# Deployment Instructions
*Current Project Version: Reference VERSION.md for the single source of truth.*

## Prerequisites
*   A Linux environment (Debian/Ubuntu recommended) or MSYS2 for Windows.
*   GCC, Make, Python 3.
*   A base Super Mario 64 ROM (US version) for asset extraction (must be placed in the project root as `baserom.us.z64`).

## Building the Client
1. Clone the repository.
2. Ensure `baserom.us.z64` is in the root directory.
3. Run `make -j$(nproc)` to compile the standard client.
4. The executable will be located in `build/us_pc/sm64coopdx`.

## Building the Headless Server
To host a dedicated server without graphical overhead:
1. Run `make HEADLESS=1 -j$(nproc)`.
2. Launch the server using `./build/us_pc/sm64coopdx --headless --server <PORT>`.

## Updating the Server
1. Pull the latest `main` branch.
2. Run `make clean`.
3. Run `make HEADLESS=1 -j$(nproc)`.
4. Restart the server process.

## Mod Installation
All gameplay systems are implemented as Lua scripts within the `mods/` directory. They are loaded automatically on server start. Ensure `mods/` is present in the working directory when launching the server.
