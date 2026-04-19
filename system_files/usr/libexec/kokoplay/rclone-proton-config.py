#!/usr/bin/env python3

import pexpect
import subprocess
import os
import re
import sys

DB = os.path.expanduser("~/Passwords.kdbx")
ENTRY = "Proton Drive"
RCLONE_CONF = os.path.expanduser("~/.config/rclone/rclone.conf")
REMOTE = "proton"
MOUNT = os.path.expanduser("~/ProtonDrive")


# -------------------------
# HELPERS
# -------------------------

def run(cmd):
    return subprocess.check_output(cmd).decode().strip()

def remote_exists():
    if not os.path.exists(RCLONE_CONF):
        return False
    with open(RCLONE_CONF) as f:
        return re.search(rf"^\[{REMOTE}\]", f.read(), re.MULTILINE) is not None

def get_dbpass():
    return run(["secret-tool", "lookup", "app", "keepass", "db", "kokoplay"])

def kpxc(attr, dbpass):
    return run([
        "bash", "-c",
        f"printf %s \"{dbpass}\" | keepassxc-cli show -q --attributes {attr} \"{DB}\" \"{ENTRY}\""
    ])

def get_otp(dbpass):
    try:
        otp = subprocess.check_output(
            ["bash", "-c",
             f"printf %s \"{dbpass}\" | keepassxc-cli show -q -t \"{DB}\" \"{ENTRY}\" | tr -d '\\n'"]
        ).decode().strip()

        if otp == "":
            return None

        return otp

    except subprocess.CalledProcessError:
        return None

# -------------------------
# CONFIG CREATION
# -------------------------

def create_remote(dbpass):
    print("[+] Creating rclone remote")

    USER = kpxc("username", dbpass)
    PASS = kpxc("password", dbpass)
    OTP  = get_otp(dbpass)

    child = pexpect.spawn("rclone config", encoding="utf-8", timeout=60)
    child.logfile = open("/tmp/rclone_debug.log", "w")

    try:
        child.expect("n\\) New remote")
        child.sendline("n")

        child.expect("name>")
        child.sendline(REMOTE)

        child.expect("Storage>")
        child.sendline("48")

        child.expect("username")
        child.sendline(USER)

        child.expect("y/g>")
        child.sendline("y")

        child.expect(r"(?i)enter.*password")
        child.sendline(PASS)

        child.expect(r"password:")
        child.sendline(PASS)

        child.expect("2FA")
        child.expect("2FA")

        if OTP:
            print("[+] Using TOTP from KeePassXC")
            child.sendline(OTP)
        else:
            print("[=] No TOTP found → sending empty (default)")
            child.sendline("")   # ← just press Enter

        child.expect("otp_secret_key")
        child.sendline("n")

        child.expect("Edit advanced config")
        child.sendline("n")

        child.expect("y/e/d>")
        child.sendline("y")

        # back to main menu
        child.expect("e/n/d/r/c/s/q>")

        # set config password
        print("[+] Setting rclone config password")
        child.sendline("s")
        # handle BOTH states
        idx = child.expect([
            r"a/q>",
            r"c/r/q>",
            r"c/u/q>",
        ])

        if idx == 0:
            print("[+] Adding new config password")
            child.sendline("a")

            child.expect(r"(?i)new.*password|enter.*password")
            child.sendline(dbpass)

            child.expect(r"(?i)confirm.*password|repeat.*password")
            child.sendline(dbpass)

        elif idx == 1:
            print("[+] Changing existing config password")
            child.sendline("c")

            child.expect(r"(?i)new.*password|enter.*password")
            child.sendline(dbpass)

            child.expect(r"(?i)confirm.*password|repeat.*password")
            child.sendline(dbpass)

        elif idx == 2:
            print("[=] Config already encrypted → skipping password setup")
            child.sendline("q")
            return


        idx = child.expect([
            r"e/n/d/r/c/s/q>",
            r"c/u/q>",
     ])

        if idx == 0:
            # main menu
            child.sendline("q")

        elif idx == 1:
            # still inside encrypted submenu
            child.sendline("q")
            child.expect("e/n/d/r/c/s/q>")
            child.sendline("q")

        child.close()

        subprocess.run([
             "rclone", "lsd", "proton:",
             "--protondrive-app-version", "macos-drive@1.0.0-alpha.1"
    ])
        print("[+] Remote created successfully")

    except Exception as e:
        print("[!] Config failed, cleaning up broken config")
        child.close()

        # remove broken remote
        subprocess.run(["rclone", "config", "delete", REMOTE], stderr=subprocess.DEVNULL)
        raise e


# -------------------------
# MOUNT HANDLING
# -------------------------

def ensure_mount_point():
    if os.path.exists(MOUNT):
        if not os.path.isdir(MOUNT):
            print("[!] Fixing invalid mount path")
            os.remove(MOUNT)
            os.makedirs(MOUNT)
    else:
        os.makedirs(MOUNT)

def unmount_if_needed():
    subprocess.run(["fusermount", "-u", MOUNT],
                   stdout=subprocess.DEVNULL,
                   stderr=subprocess.DEVNULL)

def is_mounted():
    return subprocess.call(
        ["mountpoint", "-q", MOUNT],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    ) == 0


# -------------------------
# MAIN
# -------------------------

def main():
    dbpass = get_dbpass()

    # set rclone config password env
    os.environ["RCLONE_CONFIG_PASS"] = dbpass

    # create remote if missing
    if not remote_exists():
        create_remote(dbpass)
    else:
        print("[=] Remote exists → skipping config")

    # mount handling
    ensure_mount_point()

    if is_mounted():
        print("[=] Already mounted → exiting")
        return

    unmount_if_needed()

    print("[+] Mounting Proton Drive...")

    result = subprocess.run([
        "rclone", "mount", f"{REMOTE}:", "--protondrive-app-version", "macos-drive@1.0.0-alpha.1", MOUNT,
        "--vfs-cache-mode", "writes",
        "--daemon",
        "--log-level", "ERROR"
    ])

    if result.returncode != 0:
        print("[-] Mount failed")
        sys.exit(1)

    print("[+] Mounted successfully")


if __name__ == "__main__":
    main()
