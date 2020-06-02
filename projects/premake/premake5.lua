workspace "wren-cli"
  configurations { "Release", "Debug" }
  platforms { "64bit", "32bit", "64bit-no-nan-tagging" }
  defaultplatform "64bit"
  location ("../" .. _ACTION)

  filter "configurations:Debug"
    targetsuffix "_d"
    defines { "DEBUG" }
    symbols "On"

  filter "configurations:Release"
    defines { "NDEBUG" }
    optimize "Full"

  filter "platforms:64bit-no-nan-tagging"
    defines { "WREN_NAN_TAGGING=0" }

  filter "platforms:32bit"
    architecture "x86"

  filter "platforms:64bit"
    architecture "x86_64"

  filter "system:windows"
    staticruntime "On"
    systemversion "latest"
    defines { "_CRT_SECURE_NO_WARNINGS" }
    flags { "MultiProcessorCompile" }

  --the 'xcode4' and 'gmake2' folder names
  --are simply confusing, so, simplify then
  filter { "action:xcode4" }
    location ("../xcode")

  filter "action:gmake2"
    location ("../make")

  filter { "action:gmake2", "system:bsd" }
    location ("../make.bsd")

  filter { "action:gmake2", "system:macosx" }
    location ("../make.mac")

project "wren_cli"
  kind "ConsoleApp"
  language "C"
  cdialect "C99"
  targetdir "../../bin"

  files {
    "../../src/**.h",
    "../../src/**.c",
    "../../src/**.inc",
  }


  includedirs {
    "../../src/cli",
    "../../src/module",
  }

-- wren dependency

  files {
    "../../deps/wren/include/**.h",
    "../../deps/wren/src/**.c",
    "../../deps/wren/src/**.h"
  }

  includedirs {
    "../../deps/wren/include",
    "../../deps/wren/src/vm",
    "../../deps/wren/src/optional"
  }

-- libuv dependency

  includedirs {
    "../../deps/libuv/include",
    "../../deps/libuv/src"
  }

  files {
    "../../deps/libuv/include/**.h",
    "../../deps/libuv/src/*.c",
    "../../deps/libuv/src/*.h"
  }

  -- unix common files
  filter "system:not windows"
    files {
      "../../deps/libuv/src/unix/async.c",
      "../../deps/libuv/src/unix/atomic-ops.h",
      "../../deps/libuv/src/unix/core.c",
      "../../deps/libuv/src/unix/dl.c",
      "../../deps/libuv/src/unix/fs.c",
      "../../deps/libuv/src/unix/getaddrinfo.c",
      "../../deps/libuv/src/unix/getnameinfo.c",
      "../../deps/libuv/src/unix/internal.h",
      "../../deps/libuv/src/unix/loop-watcher.c",
      "../../deps/libuv/src/unix/loop.c",
      "../../deps/libuv/src/unix/pipe.c",
      "../../deps/libuv/src/unix/poll.c",
      "../../deps/libuv/src/unix/process.c",
      "../../deps/libuv/src/unix/random-devurandom.c",
      "../../deps/libuv/src/unix/signal.c",
      "../../deps/libuv/src/unix/spinlock.h",
      "../../deps/libuv/src/unix/stream.c",
      "../../deps/libuv/src/unix/tcp.c",
      "../../deps/libuv/src/unix/thread.c",
      "../../deps/libuv/src/unix/tty.c",
      "../../deps/libuv/src/unix/udp.c",
    }

  -- todo: this has to be tested
  filter "system:macosx"
    systemversion "10.12"
    defines { "_DARWIN_USE_64_BIT_INODE=1", "_DARWIN_UNLIMITED_SELECT=1" }
    files {
      "../../deps/libuv/src/unix/bsd-ifaddrs.c",
      "../../deps/libuv/src/unix/darwin.c",
      "../../deps/libuv/src/unix/darwin-proctitle.c",
      "../../deps/libuv/src/unix/fsevents.c",
      "../../deps/libuv/src/unix/kqueue.c",
      "../../deps/libuv/src/unix/proctitle.c",
      "../../deps/libuv/src/unix/random-getentropy.c",
    }

  filter "system:linux"
    links { "pthread", "dl", "m" }
    defines { "_GNU_SOURCE" }
    files {
      "../../deps/libuv/src/unix/linux-core.c",
      "../../deps/libuv/src/unix/linux-inotify.c",
      "../../deps/libuv/src/unix/linux-syscalls.c",
      "../../deps/libuv/src/unix/linux-syscalls.h",
      "../../deps/libuv/src/unix/procfs-exepath.c",
      "../../deps/libuv/src/unix/proctitle.c",
      "../../deps/libuv/src/unix/random-getrandom.c",
      "../../deps/libuv/src/unix/random-sysctl-linux.c",
      "../../deps/libuv/src/unix/sysinfo-loadavg.c"
    }

  filter "system:windows"
    -- for some reason, OPT:REF makes a GetModuleHandleA fail
    -- in libuv, `advapi32_module = GetModuleHandleA("advapi32.dll");
    linkoptions { '/OPT:NOREF' }
    links { "imm32", "winmm", "version", "wldap32", "ws2_32", "psapi", "iphlpapi", "userenv" }
    files {
      "../../deps/libuv/src/win/*.h",
      "../../deps/libuv/src/win/*.c"
    }
  
  filter "system:bsd"
    links { "pthread", "dl", "m" }
    files {
      "../../deps/libuv/src/unix/bsd-ifaddrs.c",
      "../../deps/libuv/src/unix/bsd-proctitle.c",
      "../../deps/libuv/src/unix/freebsd.c",
      "../../deps/libuv/src/unix/kqueue.c",
      "../../deps/libuv/src/unix/posix-hrtime.c",
      "../../deps/libuv/src/unix/random-getrandom.c",
    }
