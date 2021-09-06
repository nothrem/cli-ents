# Convert audio to AAC

## Requirements:
* Nero AAC encoder (https://www.videohelp.com/software/Nero-AAC-Codec)
* FFMPEG to support other than WAV files (https://ffmpeg.org/download.html#build-windows)
  * _Note: you need to use the newest (2021+) build to support 8-channel source audio. Older builds support only 6-channel audio and will remove any excess channels._ 

* Fraunhofer FDK encoder (recommended to use https://github.com/kekyo/fdk-aac-win32-builder)
  * _Note that Fraunhofer licence does not allow distribution of EXE file, and you have to build it yourself!_

## Usage
* download selected *.cmd script
* download the tools  (for FDK see below)
* place the script and the tools into same folder (or place the tool inside `bin` sub-folder)
* Drag and drop selected MP3, AC3, DTS, AVI or MKV onto the script (or its LNK Shortcut).
* Write a number of quality you want to use. You can press Enter to use the default quality.
  * For supported video containers confirm if you want the AAC merged back into video
* Wait until all files are processed.

## What is AAC?

AAC (Advanced Audio Coding) is an audio coding standard for lossy digital audio compression. Designed to be the successor of the MP3 format, AAC generally achieves higher sound quality than MP3 at the same bit rate.
**from WIKIPEDIA**

AAC is part of MPEG standard as same as MP3, MPEG video, AVC and HEVC video codecs.
It has better quality than MP3 or vice-versa can use lower bitrate when converting from MP3
(e.g. you can convert 128kbps MP3 into 96kbps AAC with same quality).

AAC is used by audio (Spotify, iTunes) and video (Netflix) providers because
it can produce smaller file than AC3 and DTS used on physical media (DVD and BluRay) while
keeping same audio quality. AAC supports unlimited number of streams,
so it's compatible with 5.1, 7.1 and Atmos audio systems
(*however most encoders are limited to 6 or 8 channels, so they cannot correctly convert Atmos audio*). 

## Description of `2AAC`

This script **converts WAV file into AAC** with selected quality (produces M4A file).

The script **primarily creates AAC LC** but uses auto-detection and may produce HE-AAC
in case the source file has higher quality than what AAC LC supports. HE-AAC is backward
compatible with players that support only AAC LC.

**The script is intended for audio sources with lower quality, such as MP3 128kbps or lower
or for usages where compatibility with old or low-end devices must be ensured (e.g. internet streaming).**

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

HE-AAC uses half-frequency to encode the primary channel (AAC LC) and then uses the SBR to
compensate and reconstruct the data lost when the frequency was lowered (which means in the end no
data are actually lost and any HE-AAC-compatible device can play the audio with
the original frequency and quality while older AAC-compatible devices will play the audio only
with the lower frequency and lower quality).
e.g. 48kHz audio will be encoded as 24Khz AAC LC and the data above the 24kHz are stored as the SBR meta-data.

HE-AAC also contains better compression (that's why the name "High Efficiency") which means
for high-bitrate AAC it produces smaller file than AAC LC (up to 50% smaller for 100% quality).

Third improvement of HE-AAC is PS (Parametric stereo) which can be used for a stereo source
and which converts the audio into a 1-channel file (mono AAC LC) with second differential (hidden) track.
Any HEv2-compatible device will play the audio as stereo, but older HE-AAC or AAC-only devices
will play only the mono channel.
AAC with PS track is called HEv2; HE-AAC without PS is sometimes called HEv1 (or just HE).

The script always **creates HE-AAC**. First it tries to check if the source file
is 2-channel (stereo) and for such source it creates HEv2 (aka Parametric stereo).
For 1-channel (mono) or multi-channel (surround, 5.1, 7.1, etc.) source it creates
HE-AAC file. Please note that HE-AAC is still identified as "AAC LC" in some programs;
to recognize HE-AAC check additional flags "+ SBR" (i.e. HEv1) and/or "+ PS" (HEv2).

**The script is intended for audio sources with higher quality, such as MP3 320kbps/V0, multi-channel AC3, DTS, etc.**

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

## What is Fraunhofer FDK?

The Fraunhofer FDK library was originally written for Android OS and its main focus is to
produce very small audio files suitable for mobile devices and other hardware with limited storage.
Later the library was modified for WinAmp and other usages.
Versions for Linux and Windows console exists, but due to licensing of the original tool 
(because it contains some technologies that were licensed only for use on the Android OS
and the WinAmp application and their use in other environments/applications is not allowed by the license owners)
it is not recommended (possible) to distribute compiled binaries (EXE files for Windows).

To get EXE file needed for the scripts you either must compile the console tool
https://github.com/nu774/fdkaac and the FDK library https://github.com/mstorsjo/fdk-aac
or you can use a script prepared by Kouji Matsui (see below).

* *FDK-AAC* is a library (DLL in case of Windows) that contains the conversion algorithms
(encoder and decoder) and can be used in any application.
* `fdkaac` is a simple console tool (fdkaac.exe for Windows) that passes the parameters into the library
and prints its output into console. This tool **requires the library** (DLL) to be present into same folder.

The Fraunhofer FDK library is still in developement and contains newest error fixes and other
improvements that ensures the highest audio quality. This means the library is better than
the Nero AAC Encoded which has not been updated since 2010.

## Description of `2FDK-AAC`

This script **converts WAV file into HE-AAC** using Fraunhofer FDK library (produces M4A file).

The resulting file will contain HE-AAC (SBR) or HEv2 (SBR+PS) for stereo source. 
This script uses CBR mode (constant bitrate) however the FDK library may, in specific cases,
decide to use a variable bitrate instead. This usually happen when you select too high or too low
bitrate and the library will decide to use variable bitrate either not to waste bitrate on *empty* data
or will need to encode specific part of the input with higher bitrate to prevent large quality loss. 

**The script is intended for users who look for the highest quality audio encoded with the newest algorithms.**

--------

Apart from the above the usage and limitations of the 2FDK-AAC are as same as for 2HE-AAC. 

## Description of `2FDK-Auto`

This script **converts WAV file into HE-AAC** using Fraunhofer FDK library (produces M4A file).

The resulting file will contain HE-AAC (SBR) or HEv2 (SBR+PS) for stereo source. 
This script uses VBR (variable bitrate) mode which produces the smallest possible file size however
the VBR mode is not officially supported and may produce errors in the output sound or may fail
to convert the input completely. 

**The script is intended for users who look for the smallest possible file (and some quality limitations or errors are acceptable).**

**If you need to ensure the output has the highest quality without any errors you should use FDK CBR or Nero AAC Encoder instead!**

By default, the script uses "Filter 5" which produces the highest quality, but largest, file.
Such file is still 30% to 50% smaller than the best file produced by Nero AAC Encoder (with comparable settings).
If you aim to get even smaller file, you can set the variable `%filter%` inside the script to other value
(see the script for filter description).

Note that with "Filter 5" the audio quality is **limited to 112kbps** (mono or HEv2).
*For multi-channel input other limitations apply - see the "Filter" description inside the script. e.g. for standard 5.1 input (DD/DTS) maximum bitrate is 608kbps.*  

--------

Apart from the above the usage and limitations of the 2FDK-VBR are as same as for 2HE-AAC. 

## How to build Fraunhofer FDK library

(Steps for reference, always consult the README from step 1.)
1. Download the builder (e.g. go ot https://github.com/kekyo/fdk-aac-win32-builder, click "Code" button, select "Download ZIP" and extract it somewhere).
1. Download and install MSYS2 (go to https://www.msys2.org/ and click link in Step 1.) - during installation keep everything on default and just click Next in all steps.
   * Note: if you already have CygWin there is no need to uninstall it. Both CygWin and MSYS2 can run on same Windows because each is used for a different purpose.
1. Close all MSYS2, CygWin and MinGW windows
1. Open Start menu and...
   * to compile 32bit version usable on all Windows versions run "MSYS2 MinGW 32bit"
   * to compile 64bit version that can be used only on 64bit Windows run "MSYS2 MinGW 64bit"
1. On first run you must install packages needed to build the library:
   * inside MSYS2 MinGW 32bit run command `pacman -S mingw-w64-i686-gcc autoconf automake-wrapper make libtool`
   * inside MSYS2 MinGW 64bit run command `pacman -S mingw-w64-x86_64-gcc autoconf automake-wrapper make libtool`
1. run setup by command `./setup.sh`
1. build project by command `./build.sh`
1. run `./test.sh` to verify library and EXE were compiled correctly
1. go to "artifacts" folder (in the Builder folder) and from the sub-folder (not the one with "_test") copy EXE and all DLL files into `bin` folder of the AAC script.

### FDK AAC parameter description

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
