import os
import times
{.warning[UnusedImport]: off.}
import parasound/miniaudio
# Needs to be imported or the C library is not found
import parasound/dr_wav

import metatags

proc play*(data: string) =
  var
    decoder = newSeq[uint8](ma_decoder_size())
    decoderAddr = cast[ptr ma_decoder](decoder[0].addr)
    deviceConfig = newSeq[uint8](ma_device_config_size())
    deviceConfigAddr = cast[ptr ma_device_config](deviceConfig[0].addr)
    device = newSeq[uint8](ma_device_size())
    deviceAddr = cast[ptr ma_device](device[0].addr)
  doAssert MA_SUCCESS == ma_decoder_init_file_mp3(data, nil, decoderAddr)

  let metas = readMetatags(data)
  echo metas

  #
  # let frameCount = ma_decoder_get_length_in_pcm_frames(decoderAddr)
  # let duration = float(frameCount) / 44100
  # echo(fmt"{int(floor(duration / 60))}:{int(floorMod(duration, 60))}")

  proc data_callback(pDevice: ptr ma_device; pOutput: pointer; pInput: pointer;
                     frameCount: ma_uint32) {.cdecl.} =
    let decoderAddr = ma_device_get_decoder(pDevice)
    discard ma_decoder_read_pcm_frames(decoderAddr, pOutput, frameCount)

  ma_device_config_init_with_decoder(deviceConfigAddr, ma_device_type_playback,
                                     decoderAddr, data_callback)

  if ma_device_init(nil, deviceConfigAddr, deviceAddr) != MA_SUCCESS:
    discard ma_decoder_uninit(decoderAddr)
    quit("Failed to open playback device.")

  if ma_device_start(deviceAddr) != MA_SUCCESS:
    ma_device_uninit(deviceAddr)
    discard ma_decoder_uninit(decoderAddr)
    quit("Failed to start playback device.")

  sleep(metas.length * 1000)

  discard ma_device_stop(deviceAddr)
  ma_device_uninit(deviceAddr)
  discard ma_decoder_uninit(decoderAddr)
  quit(0)
