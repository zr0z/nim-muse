# Package

version = "0.1.0"
author = "Zaidin Amiot"
description = "muse, the stupid command line mp3 player"
license = "MIT"
srcDir = "src"
bin = @["muse"]


# Dependencies

requires "nim >= 1.4.8"
requires "parasound >= 0.2.0"

# tasks
task documentation, "Generate documentation for the application":
  exec "nim doc --project --index:on --outdir:./docs src/muse.nim"
