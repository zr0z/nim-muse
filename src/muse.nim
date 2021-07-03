#
# muse
# (c) 2021 - Zaidin Amiot
#
# See the file "UNLICENCE", included in this
# distribution, for details about the copyright.
#

import os
import player
import parseopt

const USAGE = "Usage: muse PATH_TO_FILE.mp3"

type Exit = enum
  regular, invalid, error

when isMainModule:
  for kind, key, _ in getOpt():

    case kind
    of cmdLongOption, cmdShortOption:
      case key:
        of "help", "h":
          echo(USAGE)
          quit(ord(regular))

    of cmdArgument:
      case splitFile(key).ext:
        of ".mp3":
          try:
            play(key)
            quit(ord(regular))
          except PlaybackError:
            echo getCurrentExceptionMsg()
            quit(ord(error))

    of cmdEnd: discard

    echo("Invalid usage.")
    echo(USAGE)
    quit(ord(invalid))

