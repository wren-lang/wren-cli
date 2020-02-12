workspace "wren-cli"
  configurations { "Release", "Debug" }
  platforms { "64bit", "32bit" }
  defaultplatform "64bit"
  location ("../" .. _ACTION)

  filter "configurations:Debug"
    targetsuffix "_d"
    defines { "DEBUG" }
    symbols "On"

  filter "configurations:Release"
    defines { "NDEBUG" }
    optimize "Full"

  filter "platforms:32bit"
    architecture "x86"

  filter "platforms:64bit"
    architecture "x86_64"

  filter "system:windows"
    staticruntime "On"
    systemversion "latest"
    defines { "_CRT_SECURE_NO_WARNINGS" }
    flags { "MultiProcessorCompile" }

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

  filter "system:macosx"
    systemversion "10.12"
    defines { "_DARWIN_USE_64_BIT_INODE", "_DARWIN_UNLIMITED_SELECT" }
    links {
      "iconv", "z", "bz2",
      "Foundation.framework", "AppKit.framework",
      "Cocoa.framework", "Carbon.framework", "IOKit.framework",
      "ForceFeedback.framework", "CoreVideo.framework"
    }

  filter "system:linux"
    links { "pthread", "dl" }

  filter "system:windows"
    -- for some reason, OPT:REF makes a GetModuleHandleA fail
    -- in libuv, `advapi32_module = GetModuleHandleA("advapi32.dll");
    linkoptions { '/OPT:NOREF' }
    links { "imm32", "winmm", "version", "wldap32", "ws2_32", "psapi", "iphlpapi", "userenv" }
    files {
      "../../deps/libuv/src/win/*.h",
      "../../deps/libuv/src/win/*.c"
    }
