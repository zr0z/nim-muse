# muse

muse is a stupid command line cross-platform mp3 player. It is built in nim and uses a few C library.
The only external dependency that needs to be installed is [TagLib](https://taglib.org).

The player uses [miniaudio](https://miniaud.io/) which is installed through its Nim wrapper
[parasound](https://github.com/paranim/parasound).

## Installation

```
# macos
$ brew install taglib

$ nimble install
```

## Usage

```
muse PATH_TO_FILE.mp3
```

2021 - muse is released under THE UNLICENSE.
