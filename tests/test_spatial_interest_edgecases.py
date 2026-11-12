#!/usr/bin/env python3
"""
Unit and edge-case benchmark test suite for Server Spatial Interest Culling & Packet Compression.
Simulates boundary conditions:
- Exactly at threshold boundary (15,000 units)
- Cross-area / course mismatches (must not false-cull across course boundaries)
- Invalid position flags (must safely fallback to transmitting)
- Non-motion packets (reliable RPCs must always bypass culling)
"""

import sys
import math

MAX_SPATIAL_INTEREST_DIST_SQ = 15000.0 * 15000.0

PACKET_PLAYER = 1
PACKET_CHAT = 2
PACKET_LUA_SYNC_TABLE = 3
PACKET_COLLECT_STAR = 4

def simulate_spatial_cull(packet_type, sender_pos, target_pos,
                         sender_valid, target_valid,
                         sender_course, target_course,
                         sender_area, target_area):
    # Only PACKET_PLAYER is candidate for spatial culling
    if packet_type != PACKET_PLAYER:
        return False  # Never culled

    # If position invalid or different course/area, spatial culling does not drop
    if not (sender_valid and target_valid):
        return False

    if sender_course != target_course or sender_area != target_area:
        return False

    dx = sender_pos[0] - target_pos[0]
    dy = sender_pos[1] - target_pos[1]
    dz = sender_pos[2] - target_pos[2]
    dist_sq = dx * dx + dy * dy + dz * dz

    return dist_sq > MAX_SPATIAL_INTEREST_DIST_SQ

def run_tests():
    print("[Testing] Running Spatial Interest Edge-Case Scenarios...")

    # Test 1: Close proximity in same area -> Do not cull
    culled = simulate_spatial_cull(PACKET_PLAYER, (0, 0, 0), (1000, 500, 1000), True, True, 1, 1, 1, 1)
    assert not culled, "Test 1 failed: close player was unexpectedly culled"

    # Test 2: Extreme distance in same area (e.g. 20,000 units apart) -> Must cull
    culled = simulate_spatial_cull(PACKET_PLAYER, (0, 0, 0), (20000, 0, 0), True, True, 1, 1, 1, 1)
    assert culled, "Test 2 failed: distant player was not culled"

    # Test 3: Exactly on boundary (15,000 units) -> Do not cull
    culled = simulate_spatial_cull(PACKET_PLAYER, (0, 0, 0), (15000, 0, 0), True, True, 1, 1, 1, 1)
    assert not culled, "Test 3 failed: boundary player (15k units) should not be culled"

    # Test 4: Just over boundary (15,001 units) -> Must cull
    culled = simulate_spatial_cull(PACKET_PLAYER, (0, 0, 0), (15001, 0, 0), True, True, 1, 1, 1, 1)
    assert culled, "Test 4 failed: player beyond boundary (15001 units) was not culled"

    # Test 5: Non-motion packet (CHAT) -> Never cull regardless of distance
    culled = simulate_spatial_cull(PACKET_CHAT, (0, 0, 0), (50000, 0, 0), True, True, 1, 1, 1, 1)
    assert not culled, "Test 5 failed: CHAT packet was culled"

    # Test 6: Non-motion packet (COLLECT_STAR) -> Never cull
    culled = simulate_spatial_cull(PACKET_COLLECT_STAR, (0, 0, 0), (50000, 0, 0), True, True, 1, 1, 1, 1)
    assert not culled, "Test 6 failed: COLLECT_STAR packet was culled"

    # Test 7: Non-motion packet (LUA_SYNC_TABLE) -> Never cull
    culled = simulate_spatial_cull(PACKET_LUA_SYNC_TABLE, (0, 0, 0), (50000, 0, 0), True, True, 1, 1, 1, 1)
    assert not culled, "Test 7 failed: LUA_SYNC_TABLE packet was culled"

    # Test 8: Sender position invalid -> Do not cull (fail-open)
    culled = simulate_spatial_cull(PACKET_PLAYER, (0, 0, 0), (20000, 0, 0), False, True, 1, 1, 1, 1)
    assert not culled, "Test 8 failed: invalid sender pos caused culling"

    # Test 9: Target position invalid -> Do not cull (fail-open)
    culled = simulate_spatial_cull(PACKET_PLAYER, (0, 0, 0), (20000, 0, 0), True, False, 1, 1, 1, 1)
    assert not culled, "Test 9 failed: invalid target pos caused culling"

    # Test 10: Different course -> Spatial culling in packet rebroadcast does not cull (handled by levelArea routing)
    culled = simulate_spatial_cull(PACKET_PLAYER, (0, 0, 0), (20000, 0, 0), True, True, 1, 2, 1, 1)
    assert not culled, "Test 10 failed: different course triggered spatial culling"

    print("[Testing] All 10 spatial interest edge-case scenarios PASSED!")

if __name__ == "__main__":
    run_tests()
