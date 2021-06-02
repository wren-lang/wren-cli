import os
import os.path
import platform
import shutil
import subprocess
import sys


def clean_dir(dir):
    """If dir exists, deletes it and recreates it, otherwise creates it."""
    if os.path.isdir(dir):
        remove_dir(dir)

    os.makedirs(dir)


def ensure_dir(dir):
    """Creates dir if not already there."""
    if os.path.isdir(dir):
        return

    os.makedirs(dir)


def remove_dir(dir):
    """Recursively removes dir."""
    if platform.system() == "Windows":
        # rmtree gives up on readonly files on Windows
        # rd doesn't like paths with forward slashes
        subprocess.check_call(["cmd", "/c", "rd", "/s", "/q", dir.replace("/", "\\")])
    else:
        shutil.rmtree(dir)
