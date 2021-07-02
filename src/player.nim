#
# muse
# (c) 2021 - Zaidin Amiot
#
# See the file "UNLICENCE", included in this
# distribution, for details about the copyright.
#

## This module provides th main entrypoint to [miniaudio](https://miniaud.io/)
## through its wrapper [parasound](https://github.com/paranim/parasound).
##
## .. code-block::
##   import player
##
##   play(FILENAME)
import os
import strformat
import times
{.warning[UnusedImport]: off.}
import parasound/miniaudio
# Needs to be imported or the C library is not found
import parasound/dr_wav

import metatags

type
  PlaybackError* = object of IOError ## `IOError` thrown if playback fails.

proc play*(filename: string) =
  ## Plays `filename` if the file is a valid mp3 track.
  var
    decoder = newSeq[uint8](ma_decoder_size())
    decoderAddr = cast[ptr ma_decoder](decoder[0].addr)
    deviceConfig = newSeq[uint8](ma_device_config_size())
    deviceConfigAddr = cast[ptr ma_device_config](deviceConfig[0].addr)
    device = newSeq[uint8](ma_device_size())
    deviceAddr = cast[ptr ma_device](device[0].addr)
  if ma_decoder_init_file_mp3(filename, nil, decoderAddr) != MA_SUCCESS:
    raise newException(PlaybackError, &"Failed to decode file named '{filename}'.")

  # Read and display metatags
  var metas = try:
      readMetatags(filename)
    except InvalidFileError as e:
      raise newException(PlaybackError, e.msg)

  echo metas

  # Duration in seconds can also be calculated using `frameCount` and `frameRate`
  #
  # let frameCount = ma_decoder_get_length_in_pcm_frames(decoderAddr)
  # let duration = float(frameCount) / frameRate
  # echo(fmt"{int(floor(duration / 60))}:{int(floorMod(duration, 60))}")

  proc data_callback(pDevice: ptr ma_device; pOutput: pointer; pInput: pointer;
                     frameCount: ma_uint32) {.cdecl.} =
    let decoderAddr = ma_device_get_decoder(pDevice)
    discard ma_decoder_read_pcm_frames(decoderAddr, pOutput, frameCount)

  ma_device_config_init_with_decoder(deviceConfigAddr, ma_device_type_playback,
                                     decoderAddr, data_callback)

  defer:
    discard ma_decoder_uninit(decoderAddr)

  if ma_device_init(nil, deviceConfigAddr, deviceAddr) != MA_SUCCESS:
    raise newException(PlaybackError, "Failed to open playback device.")

  defer:
    discard ma_device_stop(deviceAddr)
    ma_device_uninit(deviceAddr)

  if ma_device_start(deviceAddr) != MA_SUCCESS:
    raise newException(PlaybackError, "Failed to start playback device.")

  sleep(metas.length * 1000)
