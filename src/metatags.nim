# Thin wrapper around [taglib](https://taglib.org)
# Requires the library to be installed with include files available
#
# based on https://github.com/alex-laskin/nim-taglib
{.experimental.}
{.deadCodeElim: on.}

{.passl: "-ltag_c".}
{.passc: "-ltag_c".}

import math, strformat

type
  FileType {.size: sizeof(cint).} = enum
    MPEG, OggVorbis, FLAC, MPC,
    OggFlac, WavPack, Speex,
    TrueAudio, MP4, ASF

type
  CFile = pointer
  CTag = pointer
  CAudioProperties = pointer

{.push importc.}
{.push cdecl.}
proc taglib_set_strings_unicode(unicode: cint)

proc taglib_file_new_type(filename: cstring; `type`: FileType): CFile
proc taglib_file_free(file: CFile)
proc taglib_file_is_valid(file: CFile): cint
proc taglib_file_tag(file: CFile): CTag
proc taglib_file_audioproperties(file: CFile): CAudioProperties

proc taglib_tag_title(tag: CTag): cstring
proc taglib_tag_artist(tag: CTag): cstring
proc taglib_tag_album(tag: CTag): cstring
proc taglib_tag_comment(tag: CTag): cstring
proc taglib_tag_genre(tag: CTag): cstring
proc taglib_tag_year(tag: CTag): cuint
proc taglib_tag_track(tag: CTag): cuint
proc taglib_tag_free_strings()

proc taglib_audioproperties_length(audioProperties: CAudioProperties): cint
proc taglib_audioproperties_bitrate(audioProperties: CAudioProperties): cint
proc taglib_audioproperties_samplerate(audioProperties: CAudioProperties): cint
proc taglib_audioproperties_channels(audioProperties: CAudioProperties): cint
{.pop.} # cdecl
{.pop.} # importc

taglib_set_strings_unicode(1)

type
  File = object
    path: string
    cfile: CFile
    tag: CTag
    ap: CAudioProperties
  InvalidFileError = object of IOError

proc init_file(path: string; cfile: CFile): File =
  if isNil(cfile):
    raise newException(IOError, "File could not be read.")
  if taglib_file_is_valid(cfile) > 0:
    let tag = taglib_file_tag(cfile)
    let ap = taglib_file_audioproperties(cfile)
    result = File(path: path, cfile: cfile, tag: tag, ap: ap)
  else:
    taglib_file_free(cfile)
    raise newException(InvalidFileError, "Provided file is invalid. Try to select FileType manually.")

proc open(path: string): File =
  for i in FileType.low .. FileType.high:
    try:
      let cfile = taglib_file_new_type(path, FileType(i))
      return init_file(path, cfile)
    except:
      discard

  raise newException(InvalidFileError, "Provided file is invalid, or file type not supported.")

proc close(file: var File) =
  taglib_tag_free_strings()
  taglib_file_free(file.cfile)
  file.cfile = cast[CFile](0)
  file.tag = cast[CTag](0)
  file.ap = cast[CAudioProperties](0)

type Metatags* = object
  length*: int
  bitrate*: int
  samplerate*: int
  channels*: int
  title*: string
  artist*: string
  album*: string
  comment*: string
  genre*: string
  year*: uint
  track*: uint

proc duration*(metas: Metatags): string =
  let minutes = int(floor(metas.length / 60))
  let seconds = int(floorMod(metas.length, 60))
  &"{minutes}:{seconds}"

proc readMetatags*(filename: string): Metatags =
  var file = open(filename)

  let metas = Metatags(
    length: taglib_audioproperties_length(file.ap),
    bitrate: taglib_audioproperties_bitrate(file.ap),
    samplerate: taglib_audioproperties_samplerate(file.ap),
    channels: taglib_audioproperties_channels(file.ap),
    title: $taglib_tag_title(file.tag),
    artist: $taglib_tag_artist(file.tag),
    album: $taglib_tag_album(file.tag),
    comment: $taglib_tag_comment(file.tag),
    genre: $taglib_tag_genre(file.tag),
    year: uint(taglib_tag_year(file.tag)),
    track: uint(taglib_tag_track(file.tag)),
  )

  close(file)
  return metas

proc `$`*(metas: Metatags): string =
  &"{metas.artist} - {metas.title} [{metas.duration}]"
