#!/usr/bin/env python

from argparse import ArgumentParser
import sys
from os import path
from subprocess import CalledProcessError, run
import shutil
import platform
from util import clean_dir, remove_dir

parser = ArgumentParser()
parser.add_argument("version", nargs="?")

args = parser.parse_args(sys.argv[1:])

libuv_version = args.version.strip("v")

DEPS_DIR = path.join(path.dirname(__file__), "../deps/")
LIBUV_DIR = path.join(DEPS_DIR, "libuv")


def move(item, src, dest):
    return shutil.move(path.join(src, item), path.join(dest, item))


def main(args):
    libuv_repo = path.join(DEPS_DIR, "libuv_" + libuv_version)

    print("Cloning libuv...")
    run(
        [
            "git",
            "clone",
            "--quiet",
            "--depth=1",
            "https://github.com/libuv/libuv.git",
            libuv_repo,
        ]
    )

    print("Getting tags...")
    run(["git", "fetch", "--quiet", "--depth=1", "--tags"], cwd=libuv_repo)

    print("Checking out libuv v" + libuv_version + "...")
    try:
        run(
            ["git", "checkout", "--quiet", "v" + libuv_version],
            cwd=libuv_repo,
            check=True,
        )
    except CalledProcessError:
        print("Failed to checkout libuv: v" + libuv_version)
        remove_dir(libuv_repo)
        exit(1)

    print("Copying header and source files...")
    clean_dir(LIBUV_DIR)
    move("src", libuv_repo, LIBUV_DIR)
    move("include", libuv_repo, LIBUV_DIR)
    remove_dir(libuv_repo)

    print("Storing version information...")
    with open(path.join(LIBUV_DIR, "version.md"), "w") as writer:
        writer.write(libuv_version + " release")


main(sys.argv)
