#
# muse
# (c) 2021 - Zaidin Amiot
#
# See the file "UNLICENCE", included in this
# distribution, for details about the copyright.
#

import os
import player

when isMainModule:
  let params = commandLineParams()

  if params.len > 0:
    try:
      play(params[0])
    except PlaybackError:
      echo getCurrentExceptionMsg()
  else:
    echo "muse PATH_TO_FILE.mp3"
