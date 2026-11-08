# Build Results & Automated Benchmarks

## 1. Engine Compilation
- **Platform**: Linux (x86_64 Ubuntu Noble)
- **Target**: `make HEADLESS=1 -j$(nproc)`
- **Binary**: `build/us_pc/sm64coopdx` (Successfully built and verified)
- **Dependencies**: `libsdl2-dev`, `libcurl4-openssl-dev`, `bsdmainutils`, `lua5.3`, `pystray`, `pillow`

## 2. Test Suites
- **Lua Syntax Validation**: `luac5.3 -p` across all mods in `mods/` (100% Passed)
- **Headless MMO Tests**:
  - `tests/test_connections.lua`: Passed
  - `tests/test_economy_security.lua`: Passed
  - `tests/test_knockback.lua`: Passed
  - `tests/test_mmo_systems.lua`: Passed
  - `tests/test_party_trading.lua`: Passed

## 3. Concurrency & Network Load Benchmarks
Automated concurrency simulation via `tests/benchmark_concurrency_load.py` evaluates server packet compression under multi-player load (30Hz tick rate):
- **16 Concurrent Players (480 packets/sec)**: Level 1 adaptive compression saves ~2.1 ms CPU time per second over legacy Level 9.
- **32 Concurrent Players (960 packets/sec)**: Level 1 adaptive compression saves ~2.8 ms CPU time per second over legacy Level 9.
- **64 Concurrent Players (1,920 packets/sec)**: Level 1 adaptive compression delivers consistent deflate throughput with zero wire-protocol regressions.
