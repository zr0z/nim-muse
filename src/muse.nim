import os
import player

when isMainModule:
  let params = commandLineParams()
  if params.len > 0:
    play(params[0])
  else:
    echo "muse PATH_TO_FILE.mp3"
