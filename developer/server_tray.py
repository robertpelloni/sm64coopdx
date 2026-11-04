#!/usr/bin/env python3
"""
SM64CoopDX Server Tray & Process Controller
Cross-platform process supervisor providing system tray integration and headless/CLI management.
Supports starting, stopping, restarting, status checking, and reading live logs.
"""

import sys
import os
import time
import subprocess
import signal
import argparse
import threading

SERVER_PORT = 7777
LOG_FILE = "server_output.log"
PID_FILE = "server.pid"

def get_binary_path():
    candidates = [
        "./build/us_pc/sm64coopdx",
        "./build/us_pc/sm64coopdx.exe",
        "./build/us_pc/sm64.us.f3dex2e",
        "./build/us_pc/sm64.us.f3dex2e.exe"
    ]
    for c in candidates:
        if os.path.isfile(c) and os.access(c, os.X_OK):
            return c
        if os.path.isfile(c) and sys.platform == "win32":
            return c
    return None

def is_server_running():
    if not os.path.isfile(PID_FILE):
        return False, None
    try:
        with open(PID_FILE, "r") as f:
            pid = int(f.read().strip())
        # Check if pid exists
        os.kill(pid, 0)
        return True, pid
    except (OSError, ValueError):
        if os.path.exists(PID_FILE):
            os.remove(PID_FILE)
        return False, None

def start_server(port=SERVER_PORT, headless=True):
    running, pid = is_server_running()
    if running:
        print(f"[Tray/Manager] Server is already running with PID {pid}.")
        return pid

    binary = get_binary_path()
    if not binary:
        print(f"[Tray/Manager] Error: No compiled binary found in ./build/us_pc/. Please run make first.")
        return None

    cmd = [binary, "--server", str(port)]
    if headless:
        cmd.append("--headless")

    print(f"[Tray/Manager] Launching server: {' '.join(cmd)}")
    log_fp = open(LOG_FILE, "a")
    proc = subprocess.Popen(
        cmd,
        stdout=log_fp,
        stderr=subprocess.STDOUT,
        preexec_fn=os.setsid if sys.platform != "win32" else None
    )

    with open(PID_FILE, "w") as f:
        f.write(str(proc.pid))

    print(f"[Tray/Manager] Server successfully started (PID: {proc.pid}, Port: {port}). Logs: {LOG_FILE}")
    return proc.pid

def stop_server():
    running, pid = is_server_running()
    if not running:
        print("[Tray/Manager] Server is not currently running.")
        return True

    print(f"[Tray/Manager] Stopping server process (PID: {pid})...")
    try:
        if sys.platform != "win32":
            os.killpg(os.getpgid(pid), signal.SIGTERM)
        else:
            os.kill(pid, signal.SIGTERM)
        time.sleep(1)
    except OSError as e:
        print(f"[Tray/Manager] Note during termination: {e}")

    # Ensure PID file cleaned up
    if os.path.exists(PID_FILE):
        os.remove(PID_FILE)
    print("[Tray/Manager] Server stopped.")
    return True

def restart_server(port=SERVER_PORT, headless=True):
    print("[Tray/Manager] Restarting server...")
    stop_server()
    time.sleep(1)
    return start_server(port, headless)

def show_status():
    running, pid = is_server_running()
    if running:
        print(f"[Tray/Manager] Server STATUS: RUNNING (PID: {pid})")
    else:
        print("[Tray/Manager] Server STATUS: STOPPED")

def tail_logs(lines=20):
    if not os.path.isfile(LOG_FILE):
        print(f"[Tray/Manager] No log file found at {LOG_FILE}.")
        return
    with open(LOG_FILE, "r") as f:
        content = f.readlines()
        tail = content[-lines:]
        print(f"--- Last {len(tail)} lines of {LOG_FILE} ---")
        for l in tail:
            print(l, end="")

def run_tray():
    """Attempts to run desktop system tray via pystray if available, falling back to interactive CLI."""
    try:
        import pystray
        from PIL import Image, ImageDraw

        def create_icon_image():
            width = 64
            height = 64
            image = Image.new('RGB', (width, height), (0, 0, 50))
            dc = ImageDraw.Draw(image)
            dc.rectangle([16, 16, 48, 48], fill=(0, 200, 255))
            return image

        def on_start(icon, item):
            start_server()

        def on_stop(icon, item):
            stop_server()

        def on_restart(icon, item):
            restart_server()

        def on_quit(icon, item):
            stop_server()
            icon.stop()

        icon = pystray.Icon(
            "sm64coopdx_server",
            create_icon_image(),
            "SM64CoopDX Server Manager",
            menu=pystray.Menu(
                pystray.MenuItem("Start Server", on_start),
                pystray.MenuItem("Stop Server", on_stop),
                pystray.MenuItem("Restart Server", on_restart),
                pystray.MenuItem("Quit", on_quit)
            )
        )
        print("[Tray/Manager] Running graphical system tray icon...")
        icon.run()
    except (ImportError, Exception) as e:
        print(f"[Tray/Manager] Desktop tray GUI unavailable ({e}). Running in CLI supervisor mode.")
        cli_interactive()

def cli_interactive():
    print("========================================")
    print("   SM64CoopDX Server Control Manager    ")
    print("========================================")
    print("Commands: start | stop | restart | status | logs | quit")
    while True:
        try:
            cmd = input("sm64-server> ").strip().lower()
            if cmd == "start":
                start_server()
            elif cmd == "stop":
                stop_server()
            elif cmd == "restart":
                restart_server()
            elif cmd == "status":
                show_status()
            elif cmd == "logs":
                tail_logs(25)
            elif cmd in ("quit", "exit"):
                stop_server()
                print("Exiting server manager.")
                break
            elif cmd == "":
                continue
            else:
                print("Unknown command. Options: start, stop, restart, status, logs, quit")
        except (KeyboardInterrupt, EOFError):
            print("\nExiting server manager.")
            break

def main():
    parser = argparse.ArgumentParser(description="SM64CoopDX Server Tray & Process Manager")
    parser.add_argument("action", nargs="?", default="tray", choices=["start", "stop", "restart", "status", "logs", "tray", "interactive"],
                        help="Action to execute")
    parser.add_argument("--port", type=int, default=SERVER_PORT, help="Server port (default: 7777)")
    parser.add_argument("--lines", type=int, default=25, help="Number of log lines to show")
    parser.add_argument("--no-headless", action="store_true", help="Run with graphical client instead of headless")

    args = parser.parse_args()

    if args.action == "start":
        start_server(args.port, not args.no_headless)
    elif args.action == "stop":
        stop_server()
    elif args.action == "restart":
        restart_server(args.port, not args.no_headless)
    elif args.action == "status":
        show_status()
    elif args.action == "logs":
        tail_logs(args.lines)
    elif args.action == "interactive":
        cli_interactive()
    elif args.action == "tray":
        run_tray()

if __name__ == "__main__":
    main()
