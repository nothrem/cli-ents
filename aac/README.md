# Convert images to WEBP

## Requirements:
* Nero AAC encoder (https://www.videohelp.com/software/Nero-AAC-Codec)
* FFMPEG to support other than WAV files (https://ffmpeg.org/download.html#build-windows)

## Usage
* download selected *.cmd script
* download the tools
* place the script and the tools into same folder (or place the tool inside `bin` sub-folder)
* Drag and drop selected MP3, AC3, DTS, AVI or MKV onto the script (or its LNK Shortcut).
* Write a number of quality you want to use. You can press Enter to use the default quality.
  * For supported video containers confirm if you want the AAC merged back into video
* Wait until all files are processed.

## What is AAC?

AAC (Advanced Audio Coding) is an audio coding standard for lossy digital audio compression. Designed to be the successor of the MP3 format, AAC generally achieves higher sound quality than MP3 at the same bit rate.
**from WIKIPEDIA**

AAC is part of MPEG standard as same AS MP3, MPEG video, AVC and HEVC video codecs.
It has beter quality than MP3 or vice-versa can use lower bitrate when converting from MP3
(e.g. you can convert 128kbps MP3 into 96kbps AAC with same quality).

AAC is used by audio (Spotify, iTunes) and video (Netflix) providers because
it can produce smaller file than AC3 and DTS used on physical media (DVD and BluRay) while
keeping same audio quality. AAC supports unlimited number of streams so it's compatible with 5.1 and 7.1 system. 

## Description of `2AAC`

This script **converts WAV file into AAC** with selected quality (produces M4A file).

The script **primarily creates AAC LC** but uses auto-detection and may produce HE-AAC
in case the source file has higher quality than what AAC LC supports. HE-AAC is backward
compatible with players that support only AAC LC.

The script is intended for audio sources with lower quality, such as MP3 128kbps or lower.

--------

If other than WAV file is passed then the script will use FFMPEG to create WAV file.
Note that only first audio track is converted if the file contains more audio tracks.

If MKV, AVI, MP4 or WebM video file is passed the user has an option to either create
separate M4A file (option "N") or merge the video and new audio together 
(option "Y"; produces MKV file from first video and first audio track).
If user does not select either option in 10 seconds the script will produce M4A file. 

If MP3 or FLAC file is passed the script will also automatically copy ID3 tags and cover art
into the M4A file.

## Description of `2HE-AAC`

This script **converts WAV file into HE-AAC** with selected quality (produces M4A file).

HE-AAC extends AAC LC by adding additional data (SBR) which can be used to improve sound quality
in cases when higher-bitrate source is converted into lower-bitrate AAC (e.g. when
converting 128kbps MP3 into 80kbps AAC). This results in a slightly larger file.

HE-AAC also contains better compression (that's why the name "High Efficiency") which means
for high-bitrate AAC it produces smaller file than AAC LC (up to 50% smaller for 100% quality).

Third improvement of HE-AAC is PS (Parametric stereo) which can be used for a stereo source
and which converts AAC into a 1-channel file with second differential (hidden) track.
AAC with PS track is called HEv2; HE-AAC without PS is sometimes called HEv1 (or just HE).

The script always **creates HE-AAC**. First it tries to check if the source file
is 2-channel (stereo) and for such source creates HEv2 (aka Parametric stereo).
For 1-channel (mono) or multi-channel (surround, 5.1, 7.1, etc.) source creates
HE-AAC file. Please note that HE-AAC is still identified as "AAC LC" in some programs;
to recognize HE-AAC check additional flags "+ SBR" (i.e. HEv1) and/or "+ PS" (HEv2).

The script is intended for audio sources with higher quality, such as AC3, DTS or MP3 320kbps.

Note that the quality auto-detection (when you use 100% quality) may not work correctly
for some MP3 or AC3 sources and may produce AAC file that is larger than the original.

--------

If other than WAV file is passed then the script will use FFMPEG to create WAV file.
Note that only first audio track is converted if the file contains more audio tracks.

If MKV, AVI, MP4 or WebM video file is passed the user has an option to either create
separate M4A file (option "N") or merge the video and new audio together
(option "Y"; produces MKV file from first video and first audio track).
If user does not select either option in 10 seconds the script will produce M4A file.

If MP3 or FLAC file is passed the script will also automatically copy ID3 tags and cover art
into the M4A file.


## For developers
When you fork this repository, you can place the tool directly into you Working Copy. The GIT is configured to ignore EXE and LOG files.

You can change the AAC and FFMPEG variables if you want to use another tool with the script.

You can change the AAC_quality variable to set default quality.

You can add more options under `:test_ext` to support other than WAV and WAVE extensions (e.g. *.PCM).
You can add more options user `:prepare_wav` to detect other extensions as video or audio with ID3 tags.

## Planned improvements

* use temp dir for Metadata processing (MP3/FLAC)
* use temp dir for M4A when Merge is planned
* use `call` instead of `goto` for WAV and video processing
* use `smaller` script to display how much AAC saved
