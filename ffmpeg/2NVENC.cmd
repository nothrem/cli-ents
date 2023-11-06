@echo off
chcp 1250

rem TODO: improve contrast: -vf "eq=contrast=1.2:brightness=-0.1:saturation=1.2"

title Video conversion to HEVC
echo.
echo                            Video conversion to HEVC
echo.

rem Check that FFMPEG exist in this folder
set HEVC_process_app=%~dp0ffmpeg.exe
set AAC_process_app=%~dp0neroAacEnc.exe
if EXIST "%~dp0bin\ffmpeg.exe" set HEVC_process_app=%~dp0bin\ffmpeg.exe
if NOT EXIST "%HEVC_process_app%" goto error_ffmpeg

set log=%~dp0HEVC.log

set VIDEO_FILTER=
set END_CONFIG=
set HD_reduce_bitrate=0
set ENCDATA=hevc_nvenc -profile:v main10 -tier main -pix_fmt p010le
set ENCNAME=HEVC10
set HEVC_quality=30
set HEVC_quality_max=99
set HEVC_quality_min=1
set HEVC_bitrate=10M
set HEVC_preset=p5
set GOP_size=250
set HEVC_BFRAMES=4
set HEVC_BF_REF=1
set HEVC_lookahead=25
set HEVC_multipass=1
set WEIGHTED_PREDICTION=
set AUDIO_CONFIG=
set AUDIO_QUALITY=
set AUDIO_INFO=Copy
set VF_enabled=0
set VF_CROP=
set VF_SCALE=
set VF_PAD=
set VF_YADIF=
set VF_HDR=
set TUNE=
set MAP=-map 0
set SPATIAL_QUALITY=8
set TEMPORAL_QUALITY=1
set UNPACK=0
set USE_NERO_AAC=0
set AUDIO_INPUT=
set VF_SUB_TYPE=
set VF_SUB_FILE=
set PREPROCESS_RUTINE=
set HEVC_GPU=any

if not [] == [%1] goto config

:no_param
echo No parameter was detected, in this mode the script can process all files in a folder.
echo To continue please fill path to a folder and a mask for files (e.g. c:\*.wav).
echo.
set filepath=
set /P filepath=Please fill path to files you want to process:

if not "" == "%filepath%" if exist "%filepath%" goto config

echo No file found for "%filepath%". Please check the path.
echo.
goto no_param

:process_path
set total=0
for %%f in (%filepath%) do call :count_files %%f
echo.
echo Found %total% files in %filepath%
echo.
for %%f in (%filepath%) do call :after_count %%~f
goto end_path

:count_files
if exist %1 set /A total=%total% + 1
exit /b

:config
echo Please fill in a name of folder where to store the output files
echo Tips:
echo       * You can drag and drop the folder here.
echo       * You can press TAB to complete a name of an existing folder.
echo       * Keep the input empty to store files in their original folder.
echo.
set /p HEVC_output_folder="Output folder: "
if not "" == "%HEVC_output_folder%" set HEVC_output_folder=%HEVC_output_folder%\

:gpu
rem skip SLI selection since 30x0 cards does not support SLI anymore
goto select_video

echo.
echo Please select a GPU that will encode the video.
echo 0 = Primary GPU
echo 1 - 9 = Additional SLI GPUs
set /p HEVC_GPU="Select GPU for encoding [0-9] (leave empty to select first available GPU): "
if "" == "%HEVC_GPU%" set HEVC_GPU=any
set DECODE=-hwaccel nvdec -hwaccel_device %HEVC_GPU% -vsync 0
rem This is faster for AVC source videos but results in bad output in most cases
rem set DECODE=-hwaccel nvdec -hwaccel_device %HEVC_GPU% -vsync 0 -c:v h264_cuvid

:select_video
cls
echo Selected destination folder: %HEVC_output_folder%
echo.
echo Please select aproximate resolution of the video:            [reduced]
echo 1 = Xvid (Very low quality source in 240p): Bitrate ~ 512kbps 380kbps
echo 2 = TV  (Bad quality source in 360p):       Bitrate ~  1Mbps  768kbps
echo 3 = DVD (Good quality source in 480p/576i): Bitrate ~  2Mbps  1.5Mbps
echo 4 = HD (Good quality source in 720p):       Bitrate ~  3Mbps  2.5Mbps
echo 5 = Full HD (Good quality source in 1080p): Bitrate ~  5Mbps    4Mbps
echo 6 = 4K (UHD source in 2160p):               Bitrate ~ 10Mbps    8Mbps
echo.
echo Please select desired quality the video:
echo 0 = Automatic quality (determined from bitrate)
echo 7 = Better quality : Quality: 28 (3D movie)
echo 8 = Average quality: Quality: 30 (Feature movie)
echo 9 = Worse quality:   Quality: 32 (Animated movie)
echo.
echo Or manually setup the video conversion:
echo avc / hevc / hevc10 = Set encoder to hardware H264, H265 or H265 with 10bit pixel format respectively (default: hevc10)
echo swh / swa = Set encoder to software (CPU computed) HEVC or AVC respectively
echo dec / dhevc / davc = Set decoder to general hardware acceleration or Nvidia decoder for HEVC or AVC respectively.
echo avc2hevc / hevc2avc / hevc2hevc (h2h) = Use CUDA hardware acceleration to quickly change codec or quality. Filter are supported but slow!!!
echo avc2hevc10 / a10 = Use CUDA hardware to convert AVC into HEVC10. This is slower, because video from be transferred from HW decoder to SW filter.
echo d = Completely disable hardware decoding (recommended for DivX, Xvid, etc.)
echo b = Set bitrate
echo q = Set Constant quality (CRF) value [0 - 51]
echo m = Set minimum quatification value [0 - 51]
echo x = Set maximum quantification value [0 - 51]
if "" == "%WEIGHTED_PREDICTION%" echo w = Enable weighted prediction - detection of Fade In/Out (Experimental, fails on videos with B-frames!)
if not "" == "%WEIGHTED_PREDICTION%" echo w = Disable weighted prediction - detection of Fade In/Out (Experimental, fails on videos with B-frames!)
echo u = Unpack DivX video (DivX in AVI file may fail to process in FFMPEG, to convert the video correctly use this!)
rem Spatial AQ is supported only in ConstQP mode!
echo s = Enable Spatial AQ (Better quality for darker parts of a frame; not recommented for movies with Grain)
rem Temporal AQ is not supported by GeForce 1080 (Pascal)
echo e = Enable Temporal AQ (Better quality for low motion parts of a frame; not recommented for movies with Grain)
echo.
echo Additional options:
echo f = Set video filter (crop, scale, padding, deinterlace)
echo a = Change settings for audio (all stream at once)
echo.
echo Other options (select them before selecting quality settings):
echo r = Use reduced bitrate, recommended for resolutions 21:9 or 4:3 (e.g. 1920x800 or 640x480)
echo i = Return bitrate back to orignal value for 16:9 (e.g. 1920x1080)
echo g = Consider grain in old or low quality movies to improve overall visual quality
rem Tune animation not supported by HEVC
echo h = Consider animated content to improve overall visual quality
echo slow = Switch to Slow and quality processing (recommended, default)
echo fast = Switch to Fast processing for preview
echo t = Create test version (only first 5 minutes on fast preset)
echo.
echo. Leave the input empty and press Enter to start conversion with selection options

:select_preset
echo.
echo Decoder: %DECODE%
echo Encoder: %ENCDATA%, QP=%HEVC_quality% [%HEVC_quality_min% - %HEVC_quality_max%], GOP=%GOP_size%f, B-frames=%HEVC_BFRAMES%f, Multipass=%HEVC_multipass%, Look-ahead=%HEVC_lookahead%f
if not "" == "%AUDIO_CONFIG%" echo Audio quality is set to %AUDIO_CONFIG%
echo.
set preset=
set /p preset="Input the number of your selected settings: "

if "0" == "%preset%" goto preset_auto
if "1" == "%preset%" goto preset_low
if "2" == "%preset%" goto preset_tv
if "3" == "%preset%" goto preset_dvd
if "4" == "%preset%" goto preset_hd
if "5" == "%preset%" goto preset_fhd
if "6" == "%preset%" goto preset_4k
if "7" == "%preset%" goto preset_good
if "8" == "%preset%" goto preset_average
if "9" == "%preset%" goto preset_worse
if "b" == "%preset%" goto set_bitrate
if "q" == "%preset%" goto set_cq
if "m" == "%preset%" goto set_qmin
if "x" == "%preset%" goto set_qmax
if "w" == "%preset%" goto set_wpred
if "d" == "%preset%" goto set_hwaccell
if "u" == "%preset%" goto set_unpack
if "s" == "%preset%" goto set_saq
if "e" == "%preset%" goto set_taq
if "g" == "%preset%" goto set_grain
if "h" == "%preset%" goto set_anim
if "i" == "%preset%" goto switch_hd
if "r" == "%preset%" goto reduce_bitrate
if "slow" == "%preset%" goto switch_slow
if "slowest" == "%preset%" goto switch_slowest
if "fast" == "%preset%" goto switch_fast
if "t" == "%preset%" goto switch_end
if "ss" == "%preset%" goto switch_start
if "f" == "%preset%" goto switch_filter
if "a" == "%preset%" goto switch_audio
if "avc" == "%preset%" goto encode_avc
if "hevc" == "%preset%" goto encode_hevc
if "hevc10" == "%preset%" goto encode_hevc10
if "swh" == "%preset%" goto encode_swhevc
if "swa" == "%preset%" goto encode_swavc
if "dec" == "%preset%" goto set_hwaccel_dec
if "dhevc" == "%preset%" goto set_hwaccel_hevc
if "davc" == "%preset%" goto set_hwaccel_avc
if "avc2hevc" == "%preset%" goto set_hwaccel_avc2hevc
if "avc2hevc10" == "%preset%" goto set_hwaccel_avc2hevc10
if "a10" == "%preset%" goto set_hwaccel_avc2hevc10
if "hevc2avc" == "%preset%" goto set_hwaccel_hevc2avc
if "hevc2hevc" == "%preset%" goto set_hwaccel_hevc2hevc
if "h2h" == "%preset%" goto set_hwaccel_hevc2hevc

if "tv" == "%preset%" goto preset_tvac3
if "xavc" == "%preset%" goto preset_xavc
if "xhd" == "%preset%" goto preset_xhd
if "xvid" == "%preset%" goto preset_xvid
if "tit" == "%preset%" goto preset_tit
if "xanim" == "%preset%" goto preset_xanim


if "" == "%preset%" goto start

echo.
echo "Selected option is not valid, please select again!"
echo.
goto select_preset

:switch_filter
cls
:select_filter
echo f = Force 16:9 scale (convert to 16:9 by stretching the video and reenconding pixels)
echo p = Add padding (black borders) to convert video resolution from 4:3 (e.g. 720x576) to 16:9
echo c = Crop video to selected resolution (SW process after loading)
echo k = Crop input video to selected resolution (done BEFORE other filters) Works only with hardware decoder. Changing decoder will reset this!
echo s = Scale (resize) video to selected resolution (done AFTER crop if both are used)
echo r = Resize input video to selected resolution (done BEFORE other filters) Works only with hardware decoder. Changing decoder will reset this!
echo d = Deinterlace video to remove motion errors (for videos recorded from TV in 480i, 720i or 1080i)
echo t = Hard-code SRT or SUB subtitles into view stream
echo a = Hard-code ASS subtitles into video stream
echo h = Convert HDR video into SDR (Standard) using faster zScale method (may fail on older HDR movies)
echo l = Convert HDR video into SDR (Standard) using LUT3D (slower but always works)

:preset_filter
echo.
set preset_filter=
set /p preset_filter="Input the number of a filter: "

if "f" == "%preset_filter%" goto set_vf_force
if "p" == "%preset_filter%" goto set_vf_pad
if "c" == "%preset_filter%" goto set_vf_crop
if "k" == "%preset_filter%" goto set_vf_crop_hw
if "s" == "%preset_filter%" goto set_vf_scale
if "r" == "%preset_filter%" goto set_vf_resize
if "d" == "%preset_filter%" goto set_vf_yadif
if "t" == "%preset_filter%" goto set_vf_srt
if "a" == "%preset_filter%" goto set_vf_ass
if "h" == "%preset_filter%" goto set_vf_hdr
if "l" == "%preset_filter%" goto set_vf_lut

if "" == "%preset_filter%" goto select_video

echo.
echo "Selected option is not valid, please select again!"
echo.
goto preset_filter

:switch_audio
cls
:select_audio
echo Select preferred audio settings (for all audio streams):
echo 0 = Just copy audio as is (default). Use this to reset removed streams (option 'x').
echo 1 = Convert audio to constant bitrate AAC (2.0/5.1)
echo 2 = Convert audio to automatic AAC (target quality)
echo 3 = Convert audio to Dolby Digital (2.0/5.1)
echo 4 = Convert audio to variable bitrate MP3 (Joint Stereo)
echo f = Keep only first video and audio stream - removes all other video, audio and subtitle streams
echo x = Remove all audio and subtitle streams, keep only video - for 4K BluRay remux with lots of streams or Non-monotonous DTS error
echo Leave input empty to return back to video settings

:preset_audio
set preset_audio=
set /P preset_audio="Input the number of selected preset: "

if "0" == "%preset_audio%" goto audio_reset
if "1" == "%preset_audio%" goto audio_cbr
if "2" == "%preset_audio%" goto audio_aac
if "3" == "%preset_audio%" goto audio_ac3
if "4" == "%preset_audio%" goto audio_vbr
if "f" == "%preset_audio%" goto audio_first
if "x" == "%preset_audio%" goto audio_map

if "" == "%preset_audio%" goto select_video

echo.
echo "Selected option is not valid, please select again!"
echo.
goto preset_audio

:preset_special
cls
echo These are preset settings for specific type of movie or TV series:
echo.
echo xavc = Quickly convert video back from HEVC to AVC; copy only first audio track
echo tv = Encode TVrip (Source: 1080i + AC3) to HEVC
echo xvid = Encode Xvid/DivX video to HEVC and MP3 audio to AAC; convert 4:3 to 16:9; append SRT or SUB if available
echo xhd = Same as "xvid" but with video already in AVC; also uses better AAC quality
echo tit = Encode AVC to HEVC; convert 4:3 to 16:9; append SRT or SUB if available
echo xanim = Animated Xvid or DivX video with MP3 sound (480p, 720p)
echo
goto select_preset

:encode_hevc
set ENCDATA=hevc_nvenc -profile:v main
set ENCNAME=HEVC
echo Encode changed to HEVC (h.265)
goto select_preset

:encode_hevc10
set ENCDATA=hevc_nvenc -profile:v main10 -tier main -pix_fmt p010le
set ENCNAME=HEVC10
echo Encode changed to HEVC (h.265) with 10bit pixel format
goto select_preset

:encode_avc
set ENCDATA=h264_nvenc -profile:v main
set ENCNAME=AVC
echo Encode changed to AVC (h.264)
goto select_preset

:encode_swhevc
set ENCDATA=libx265
set ENCNAME=SWHEVC
echo Encode changed to HEVC (h.265) using CPU
goto select_preset

:encode_swavc
set ENCDATA=h264
set ENCNAME=SWAVC
echo Encode changed to AVC (h.264) using CPU
goto select_preset

:preset_low
set HEVC_bitrate=512k
if "1" == "%HD_reduce_bitrate%" set HEVC_bitrate=380k
goto select_preset

:preset_tv
set HEVC_bitrate=1M
if "1" == "%HD_reduce_bitrate%" set HEVC_bitrate=768k
goto select_preset

:preset_dvd
set HEVC_bitrate=2M
if "1" == "%HD_reduce_bitrate%" set HEVC_bitrate=1500k
goto select_preset

:preset_hd
set HEVC_bitrate=3M
if "1" == "%HD_reduce_bitrate%" set HEVC_bitrate=2500k
goto select_preset

:preset_fhd
set HEVC_bitrate=5M
if "1" == "%HD_reduce_bitrate%" set HEVC_bitrate=4M
goto select_preset

:preset_4k
set HEVC_bitrate=10M
if "1" == "%HD_reduce_bitrate%" set HEVC_bitrate=8M
goto select_preset

:preset_auto
set HEVC_quality=0
goto select_preset
:preset_good
set HEVC_quality=28
goto select_preset
:preset_average
set HEVC_quality=30
goto select_preset
:preset_worse
set HEVC_quality=32
goto select_preset

:preset_xvid
set DECODE=
rem for AVC 4:3 video:
set DECODE=-vsync 0 -c:v:0 h264_cuvid
set XVID_AAC_QUALITY=0.33
set XVID_AAC_QUALITY=0.55
set VF_enabled=1
set VF_PAD=setsar=1,pad=ih/9*16:ih:(ow-iw)/2,setdar=16/9

rem Jump to this block before converting each file (will prepare audio and subtitles)
set PREPROCESS_RUTINE=prepare_xvid

goto start

:preset_xvid
set DECODE=
rem for AVC 4:3 video:
set DECODE=-vsync 0 -c:v:0 h264_cuvid
set XVID_AAC_QUALITY=0.33
set XVID_AAC_QUALITY=0.55
set VF_enabled=1
set VF_PAD=setsar=1,pad=ih/9*16:ih:(ow-iw)/2,setdar=16/9

rem Jump to this block before converting each file (will prepare audio and subtitles)
set PREPROCESS_RUTINE=prepare_xvid

goto start

:preset_tit
set HEVC_quality=30
set HEVC_bitrate=10M
set DECODE=-vsync 0 -c:v:0 h264_cuvid

set VF_enabled=1
set VF_PAD=setsar=1,pad=ih/9*16:ih:(ow-iw)/2,setdar=16/9

rem Jump to this block before converting each file (will prepare audio and subtitles)
set PREPROCESS_RUTINE=prepare_tit

goto start

:preset_xanim
set HEVC_quality=32
set HEVC_bitrate=4M
set USE_NERO_AAC=1
set AUDIO_QUALITY=33
set AUDIO_CONFIG=
set AUDIO_INFO=AAC @ %AUDIO_QUALITY%%%
set TUNE=-tune animation
goto start

:preset_tvac3
set HEVC_quality=30
set HEVC_bitrate=5M
set WEIGHTED_PREDICTION=-bf 0 -weighted_pred 1
set DECODE=
set VF_enabled=1
set VF_YADIF=yadif
goto start

:preset_xavc
rem for HEVC video already encoded in 10bit pixel format we must convert it back to 4:2:0 color space (YUV)
set ENCDATA=h264_nvenc -profile:v main -pix_fmt yuv420p
set ENCNAME=AVC
set HEVC_quality=25
set HEVC_bitrate=10M
set HD_RESIZE_ROWS=1080
set /P HD_RESIZE_ROWS="Insert height of the resulting HD video [default: %HD_RESIZE_ROWS%]: "
set DECODE=-vsync 0 -c:v:0 hevc_cuvid -resize 1920x%HD_RESIZE_ROWS%
set MAP=-map 0:v:0 -map 0:a:0 -map 0:s?
goto start

:preset_xhd
rem Decode from AVC
set DECODE=-vsync 0 -c:v:0 h264_cuvid

rem Encode to AVC (with lower quality)
set HEVC_quality=32
set HEVC_bitrate=5M

rem Add pads to force 16:9
set VF_enabled=1
set VF_PAD=setsar=1,pad=ih/9*16:ih:(ow-iw)/2,setdar=16/9

rem Convert audio to AAC
rem set XVID_AAC_QUALITY=0.55
rem set PREPROCESS_RUTINE=prepare_xvid

goto start

:set_bitrate
set /p HEVC_bitrate="Set recommended bitrate (in kbps) [e.g. 1000 = 1Mbps]: "
set HEVC_bitrate=%HEVC_bitrate%k
echo.
echo Recommended bitrate is set to %HEVC_bitrate%
echo.
goto select_preset

:set_cq
set /p HEVC_quality="Set desired Constant Quality value [recommended: 23 for AVC, 28 for HEVC]: "
echo.
echo Constant quality is set to %HEVC_quality%
echo.
goto select_preset

:set_qmin
set /p HEVC_quality_min="Set minimum (best) quantification value [recommended: 15]: "
echo.
echo Minimum quantification is set to %HEVC_quality_max%
echo.
goto select_preset

:set_qmax
set /p HEVC_quality_max="Set maximum (worst) quantification value [recommended: 51]: "
echo.
echo Maximum quantification is set to %HEVC_quality_min%
echo.
goto select_preset

:set_wpred
rem Weighted prediction is disable when variable is empty but setting it empty would trigger the next condition so we first set it to 0 as disabled and later clear the zero value
if not "" == "%WEIGHTED_PREDICTION%" set WEIGHTED_PREDICTION=0
if "" == "%WEIGHTED_PREDICTION%" set WEIGHTED_PREDICTION=-bf 0 -weighted_pred 1
if "0" == "%WEIGHTED_PREDICTION%" set WEIGHTED_PREDICTION=
echo.
if "" == "%WEIGHTED_PREDICTION%" echo Weighted predition is disabled.
if not "" == "%WEIGHTED_PREDICTION%" echo Weighted predition is enabled.
echo.
goto select_preset

:set_hwaccell
set DECODE=
echo.
echo Hardware decoding is disabled.
echo.
goto select_preset

:set_hwaccel_dec
set DECODE=-hwaccel nvdec -hwaccel_device %HEVC_GPU% -vsync 0

echo.
echo Hardware decoding is enabled.
echo.
goto select_preset

:set_hwaccel_hevc
set DECODE=-hwaccel nvdec -vsync 0 -c:v:0 hevc_cuvid
echo.
echo Hardware decoding is set to HEVC.
echo.
goto select_preset

:set_hwaccel_avc
set DECODE=-vsync 0 -hwaccel nvdec -c:v:0 h264_cuvid
echo.
echo Hardware decoding is set to AVC.
echo.
goto select_preset

:set_hwaccel_avc2hevc10
set DECODE=-vsync 0 -hwaccel cuda -hwaccel_output_format cuda -c:v:0 h264_cuvid
set ENCDATA=hevc_nvenc -profile:v main10 -tier main -pix_fmt p010le
set TO_10bit=1
set VF_enabled=1
set ENCNAME=HEVC10
echo.
echo WARNING: this will configure hardware decoder and encoder with incompatible settings!
echo          To be able to use these settings you must enable at least one software filter.
echo.
goto select_preset

:set_hwaccel_avc2hevc
set DECODE=-vsync 0 -hwaccel cuda -hwaccel_output_format cuda -c:v:0 h264_cuvid
set ENCDATA=hevc_nvenc -profile:v main -tier main
set ENCNAME=HEVC
echo.
echo Hardware set to direct conversion from AVC to HEVC.
echo.
goto select_preset

:set_hwaccel_hevc2avc
set DECODE=-vsync 0 -hwaccel cuda -hwaccel_output_format cuda -c:v:0 hevc_cuvid
set FROM_10bit=1
set VF_enabled=1
set ENCDATA=h264_nvenc -pix_fmt yuv420p
set ENCNAME=AVC
echo.
echo Hardware set to direct conversion from HEVC to AVC.
echo WARNING: You cannot convert 10bit HEVC to AVC by this!!!
echo.
goto select_preset

:set_hwaccel_hevc2hevc
set DECODE=-vsync 0 -hwaccel cuda -hwaccel_output_format cuda -c:v:0 hevc_cuvid
set ENCDATA=hevc_nvenc -profile:v main10 -tier main
set ENCNAME=HEVC
echo.
echo Hardware set to quick re-encode of HEVC.
echo.
goto select_preset

:set_unpack
set UNPACK=1
set DECODE=
set WEIGHTED_PREDICTION=
echo.
echo Video will be unpacked first. Note that this will need to copy the original video into output folder.
echo.
goto select_preset

:set_saq
set SPATIAL_QUALITY=
set /P SPATIAL_QUALITY="Set strength of the Spatial AQ [0 = disabled, 1 = low; 15 = high; 8 = default]: "
if "" == "%SPATIAL_QUALITY%" set SPATIAL_QUALITY=8
echo.
if "0" == "%SPATIAL_QUALITY%" echo Spatial AQ is disabled
if not "0" == "%SPATIAL_QUALITY%" echo Spacial AQ set to %SPATIAL_QUALITY%.
echo.
goto select_preset

:set_taq
set TEMPORAL_QUALITY=1
echo.
echo Temporal AQ is enabled.
echo.
goto select_preset

:set_vf_crop
set /p VF_CROP_WIDTH="Set new width of the video after crop: "
set /p VF_CROP_HEIGHT="Set new height of the video after crop: "
set VF_enabled=1
set VF_CROP=crop=%VF_CROP_WIDTH%:%VF_CROP_HEIGHT%
echo.
echo Output video will be cropped to %VF_CROP_WIDTH%x%VF_CROP_HEIGHT%
echo.
goto preset_filter

:set_vf_crop_hw
set /p VF_CROP_WIDTH="Set new width of the video after crop: "
set /p VF_CROP_HEIGHT="Set new height of the video after crop: "
set VF_CROP_ORIG_WIDTH=3840
set VF_CROP_ORIG_HEIGHT=2160
if %VF_CROP_WIDTH% leq 1920 set VF_CROP_ORIG_WIDTH=1920
if %VF_CROP_HEIGHT% leq 1080 set VF_CROP_ORIG_HEIGHT=1080

set /p VF_CROP_ORIG_WIDTH="Set original width of the video [estimated: %VF_CROP_ORIG_WIDTH%]: "
set /p VF_CROP_ORIG_HEIGHT="Set original height of the video [estimated: %VF_CROP_ORIG_HEIGHT%]: "

set /a VF_CROP_X=(%VF_CROP_ORIG_WIDTH% - %VF_CROP_WIDTH%) / 2
set /a VF_CROP_Y=(%VF_CROP_ORIG_HEIGHT% - %VF_CROP_HEIGHT%) / 2
set DECODE=%DECODE% -crop %VF_CROP_Y%x%VF_CROP_Y%x%VF_CROP_X%x%VF_CROP_X%

echo.
echo Output video will be cropped from %VF_CROP_ORIG_WIDTH%x%VF_CROP_ORIG_HEIGHT% to %VF_CROP_WIDTH%x%VF_CROP_HEIGHT% by cropping %VF_CROP_Y%x%VF_CROP_Y%x%VF_CROP_X%x%VF_CROP_X%
echo.
goto preset_filter


:set_vf_force
set VF_enabled=1
set VF_PAD=setsar=1,setdar=16/9
echo.
echo Output video will be converted to 16:9 by stretching
echo.
goto preset_filter

:set_vf_pad
set VF_enabled=1
set VF_PAD=setsar=1,pad=ih/9*16:ih:(ow-iw)/2,setdar=16/9
echo.
echo Output video will be converted to 16:9 by adding black borders
echo.
goto preset_filter

:set_vf_scale
set /p VF_SCALE_WIDTH="Set new width of the video after resize: "
set /p VF_SCALE_HEIGHT="Set new height of the video after resize: "
set VF_enabled=1
set VF_SCALE=scale=%VF_SCALE_WIDTH%:%VF_SCALE_HEIGHT%:flags=lanczos
echo.
echo Output video will be resized to %VF_SCALE_WIDTH%x%VF_SCALE_HEIGHT%
echo.
goto preset_filter

:set_vf_resize
set /p VF_SCALE_WIDTH="Set new width of the video after resize: "
set /p VF_SCALE_HEIGHT="Set new height of the video after resize: "
set DECODE=%DECODE% -resize %VF_SCALE_WIDTH%x%VF_SCALE_HEIGHT%
echo.
echo Output video will be resized to %VF_SCALE_WIDTH%x%VF_SCALE_HEIGHT%
echo.
goto preset_filter

:set_vf_yadif
set VF_enabled=1
set VF_YADIF=yadif
echo.
echo Output video will be deinterlaced.
echo.
goto preset_filter

:set_vf_srt
set VF_enabled=1
set VF_SUB_TYPE=subtitles
set /p VF_SUB_FILE="Insert name of the subtitle file (for best results place the subtitle into same folder as the source video): "
echo.
echo Subtitles %VF_SUB_FILE% will be encoded into the video.
echo.
goto preset_filter

:set_vf_ass
set VF_enabled=1
set VF_SUB_TYPE=ass
set /p VF_SUB_FILE="Insert name of the subtitle file (for best results place the subtitle into same folder as the source video): "
echo.
echo Subtitles %VF_SUB_FILE% will be encoded into the video.
echo.
goto preset_filter

:set_vf_hdr
set VF_enabled=1
set VF_HDR=scale=-1:-1,zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p
echo.
echo Output video will converted from HDR source using zScale tonemapping.
echo.
goto preset_filter

:set_vf_lut
set VF_enabled=1
rem filter does not allow to use path for filename so we much switch to source path first
cd /d %~dp0
set VF_HDR=scale=-1:-1:in_color_matrix=bt2020,format=rgb48,lut3d=HDR_to_SDR.cube,scale=-1:-1:out_color_matrix=bt709
echo.
echo Output video will converted from HDR source using LUT3D Cube.
echo.
goto preset_filter

:set_grain
set TUNE=-tune grain
rem These options are not good for grain movies:
set SPATIAL_QUALITY=0
set TEMPORAL_QUALITY=0
echo.
echo Output video will be compressed with grain optimalization
echo.
goto select_preset

:set_anim
rem set TUNE=-tune animation
set GOP_size=500
echo.
echo Output video will be compressed as animated movie
echo.
goto select_preset


:switch_hd
echo.
set HD_reduce_bitrate=0
echo Conversion will use predefined bitrate
goto select_preset

:reduce_bitrate
echo.
set HD_reduce_bitrate=1
echo Conversion will use reduced bitrate
goto select_preset

:switch_slowest
rem Slowest preset, lookahead 5 seconds (25fps), full multipass, best B-frames
set HEVC_preset=p7
set HEVC_lookahead=128
set HEVC_multipass=2
set HEVC_BFRAMES=4
set HEVC_BF_REF=2
goto select_preset

:switch_slow
rem Slow preset, lookahead 5 seconds (25fps), full multipass, best B-frames
set HEVC_preset=p5
set HEVC_lookahead=54
set HEVC_multipass=2
set HEVC_BFRAMES=4
set HEVC_BF_REF=2
goto select_preset

:switch_fast
rem Fastest preset, lookahead 1 seconds (25fps), no multipass, default B-frames
set HEVC_preset=p1
set HEVC_lookahead=25
set HEVC_multipass=0
set HEVC_BFRAMES=2
set HEVC_BF_REF=0
goto select_preset

:switch_end
set end_time=5:00
set /P end_time="How much you want any save? Use format (minutes):(seconds).(milliseconds) [default: %end_time%] "
set END_CONFIG=-t %end_time%
goto select_preset

:switch_start
set start_time=0
echo.
echo Tip: to find exact time, you can open the video in Media Player Classic and play to the time you want.
echo Then you can pause with SPACE and use CTRL + array left/right to find correct frame (black, new scene, etc.)
echo To get the exact time of the frame, select File - Save picture (ALT+I) and copy the time from the file name (last value).
echo.
set /P start_time="How much you want to skip from beginning? Use format (minutes):(seconds).(milliseconds) [default: %start_time%] "
set END_CONFIG=-ss %start_time%
echo.
goto select_preset

:audio_reset
set AUDIO_CONFIG=
set MAP=-map 0
echo.
echo Audio conversion has been reset to default options.
echo.
goto preset_audio

:audio_cbr
echo Note: AAC quality 96kbps equals to 128kbps MP3 and 192kbps MP2. AAC quality 128kbps equals to 256kbps MP3 and 320kbps MP2. AAC 192kbps equals to 320kbps MP3.
set /p AUDIO_QUALITY="Select bitrate for the audio [Stereo: 64, 96, 128, 192, 256; default: 192]:"
if "" == "%AUDIO_QUALITY%" set AUDIO_QUALITY=192
set AUDIO_CONFIG=-c:a aac -b:a %AUDIO_QUALITY%k
set AUDIO_INFO=AAC @ %AUDIO_QUALITY%kbps
echo.
echo Audio set to AAC %AUDIO_QUALITY%kbps
echo.
goto preset_audio

:audio_vbr
set /p AUDIO_QUALITY="Select quality for the audio [0 = Best (~256kbps), 3 = average (~192kbps), 5 = low (~128kbps), 9 = lowest (~64kbps); default: 3]:"
if "" == "%AUDIO_QUALITY%" set AUDIO_QUALITY=3
set AUDIO_CONFIG=-c:a libmp3lame -q:a %AUDIO_QUALITY%
set AUDIO_INFO=MP3 VBR @%AUDIO_QUALITY%
echo.
echo Audio set to MP3 VBR with quality %AUDIO_QUALITY%
echo.
goto preset_audio

:audio_ac3
set /p AUDIO_QUALITY="Please select the AC3 quality [recommended for stereo: 128, 192, 256, 320; for 5.1: 384, 448, 640; default: 640]: "
if "" == "%AUDIO_QUALITY%" set AUDIO_QUALITY=640
set AUDIO_CONFIG=-c:a ac3 -b:a %AUDIO_QUALITY%k
set AUDIO_INFO=AC3 @ %AUDIO_QUALITY%kbps
echo.
echo Audio set to AC3 %AUDIO_QUALITY%kbps
echo.
goto preset_audio

:audio_aac
set USE_NERO_AAC=1
echo.
echo    33  = ~  96kbps per channel
echo    40  = ~ 128kbps per channel
echo    55  = ~ 192kbps per channel
echo    80  = ~ 320kbps per channel
echo   100  = ~ 420kbps per channel
set /p AUDIO_QUALITY="Please select the AAC quality [10 - 100; default = 50]: "
if "" == "%AUDIO_QUALITY%" set AUDIO_QUALITY=50
set AUDIO_CONFIG=
set AUDIO_INFO=AAC @ %AUDIO_QUALITY%%%
echo.
echo Audio set to AAC %AUDIO_QUALITY%%%
echo.
goto preset_audio

:audio_map
set MAP=-map 0:0
echo.
echo All streams except video will be removed.
echo.
goto preset_audio

:audio_first
set MAP=-map 0:v:0 -map 0:a:0 -map 0:s?
echo.
echo Only first video and audio (and all subtitles) will be kept Rest will be removed.
echo.
goto preset_audio





:start
rem cls

set processed=1

if exist %filepath% goto process_path

rem Count how many files we need to process
call :count_params %*
goto :after_count
:count_params
set total=0
:count_continue
set /A total=%total% + 1
shift
if not [] == [%1] goto :count_continue
exit /b
:after_count
rem END of count parameters

if "" == "%HEVC_bitrate%" goto select_video
if "" == "%HEVC_quality%" goto select_video

rem if "HEVC10" == "%ENCNAME%" set VF_enabled=1

if not "1" == "%VF_enabled%" goto param
set VIDEO_FILTER=-vf "

if "1" == "%TO_10bit%" set VIDEO_FILTER=%VIDEO_FILTER%hwdownload,format=nv12
if "1" == "%FROM_10bit%" set VIDEO_FILTER=%VIDEO_FILTER%hwdownload,format=p010le

rem TODO add 'hwdownload,format=nv12' to the beginning  when -hwaccel cuvid is enabled
rem TODO add 'hwupload_cuda' to the end and add option -hwaccel_output_format cuda to improve hardware encoding

rem Conditions must be sorted in order in which they are added into parameters
if "1" == "%TO_10bit%" goto add_filter
if "1" == "%FROM_10bit%" goto add_filter
goto create_filter

:add_filter
if not "%VF_SUB_TYPE%" == "" goto add_sub
if not "%VF_HDR%" == "" goto add_hdr
if not "%VF_YADIF%" == "" goto add_yadif
if not "%VF_CROP%" == "" goto add_crop
if not "%VF_SCALE%" == "" goto add_scale
if not "%VF_PAD%" == "" goto add_pad

:create_filter
if not "%VF_SUB_TYPE%" == "" goto create_sub
if not "%VF_HDR%" == "" goto create_hdr
if not "%VF_YADIF%" == "" goto create_yadif
if not "%VF_CROP%" == "" goto create_crop
if not "%VF_SCALE%" == "" goto create_scale
if not "%VF_PAD%" == "" goto create_pad
echo Unknown video filter - ignoring
if "1" == "%TO_10bit%" goto finish_filter
if "1" == "%FROM_10bit%" goto finish_filter
goto param

:create_sub
if "1" == "%TO_10bit%" set VIDEO_FILTER=%VIDEO_FILTER%,
if "1" == "%FROM_10bit%" set VIDEO_FILTER=%VIDEO_FILTER%,
set VIDEO_FILTER=%VIDEO_FILTER%%VF_SUB_TYPE%=%VF_SUB_FILE%
if not "%VF_HDR%" == "" goto add_hdr
if not "%VF_YADIF%" == "" goto add_yadif
if not "%VF_CROP%" == "" goto add_crop
if not "%VF_SCALE%" == "" goto add_scale
if not "%VF_PAD%" == "" goto add_pad
goto finish_filter

:add_hdr
set VIDEO_FILTER=%VIDEO_FILTER%,
:create_hdr
set VIDEO_FILTER=%VIDEO_FILTER%%VF_HDR%
if not "%VF_YADIF%" == "" goto add_yadif
if not "%VF_CROP%" == "" goto add_crop
if not "%VF_SCALE%" == "" goto add_scale
if not "%VF_PAD%" == "" goto add_pad
goto finish_filter

:add_yadif
set VIDEO_FILTER=%VIDEO_FILTER%,
:create_yadif
set VIDEO_FILTER=%VIDEO_FILTER%%VF_YADIF%
if not "%VF_CROP%" == "" goto add_crop
if not "%VF_SCALE%" == "" goto add_scale
if not "%VF_PAD%" == "" goto add_pad
goto finish_filter

:add_crop
set VIDEO_FILTER=%VIDEO_FILTER%,
:create_crop
set VIDEO_FILTER=%VIDEO_FILTER%%VF_CROP%
if not "%VF_SCALE%" == "" goto add_scale
if not "%VF_PAD%" == "" goto add_pad
goto finish_filter

:add_scale
set VIDEO_FILTER=%VIDEO_FILTER%,
:create_scale
set VIDEO_FILTER=%VIDEO_FILTER%%VF_SCALE%
if not "%VF_PAD%" == "" goto add_pad
goto finish_filter

:add_pad
set VIDEO_FILTER=%VIDEO_FILTER%,
:create_pad
set VIDEO_FILTER=%VIDEO_FILTER%%VF_PAD%
goto finish_filter

:finish_filter
echo Filter done.
set VIDEO_FILTER=%VIDEO_FILTER%"

:param
set AQ=
set HEVC_quality_AQ=
if not "0" == "%SPATIAL_QUALITY%" set AQ=%AQ% -spatial-aq 1 -aq-strength %SPATIAL_QUALITY%
if not "0" == "%TEMPORAL_QUALITY%" set AQ=%AQ% -temporal-aq 1
if not "" == "%AQ%" set HEVC_quality_AQ=AQ

set HEVC_filename=%~n1
set HEVC_input_ext=%~x1
set HEVC_input_folder=%~dp1
if "" == "%HEVC_filename%" goto end

if not [] == [%PREPROCESS_RUTINE%] goto %PREPROCESS_RUTINE%

:param_set
set title=[%processed%/%total%] Converting "%HEVC_filename%" to HEVC with CQ %HEVC_quality% [%HEVC_quality_min% - %HEVC_quality_max%] and bitrate %HEVC_bitrate%b/s on GPU %HEVC_GPU%...
title %title%...
echo.
echo %title%...
echo.

set HEVC_output_filename=%HEVC_filename%
if "" == "%HEVC_output_folder%" set HEVC_output_filename=%~dpn1

if not "" == "%VF_HDR%" set HEVC_output_filename=%HEVC_output_filename:.HDR.=.%
if not "" == "%VF_YADIF%" set HEVC_output_filename=%HEVC_output_filename:1080i=1080p%
if not "" == "%VF_YADIF%" set HEVC_output_filename=%HEVC_output_filename:720i=720p%

if "1" == "%USE_NERO_AAC%" goto prepare_aac
:continue_aac

rem Options description:
rem                 rc:vbr_hq            = Enable CRF (Constant Quality aka VBR) mode
rem                 -g 300               = Defines size of GOP and maximum interval between I-frames (aka Keyframes); recommended 250; less for action movies, more for static movies
rem                 -bf 4                = Sets how many B-frames (aka bi-directional) can be inserted in sequence - improves compression of moving objects; max 4 for NVenc; 2 is recommended; 0 for Weighted prediction
rem                 -b_ref_mode 1        = How B-frames can be referenced from other B-frames; 1 = each, 2 = only half of them; 0 = none (i.e. only reference P-frames); not supported by AVC
rem                 -nonref_p 1          = Enable non-reference P-frames (i.e. Key frames inside GOP)
rem                 rc-lookahead         = Number of future pictures to consider in VBR mode (32 is max for GeForce 1080; MAXINT for 3090)
rem                 b-adapt              = Enable/disable adaptive B-frames (incompatible with lookahead)
rem                 no-scenecut          = Do not insert keyframe just before new scene (lookahead required)
rem                 -2pass               = Process each frame in 2 passes [DEFAULT FOR SLOW PRESET]
rem                 -multipass           = 0 = Single pass; 1 = first pass with 1/4 resolution; 2 = first pass with full resolution
rem                 bluray-compat        = Create HEVC in Bluray compatible mode
rem                 weighted_pred        = Improve QP during fade In/Out or flashing lights; incompatible with B-frames; recommended only for movies with flashing lights where normal B-frames are not efficient
rem                 spatial-aq           = Use different (adaptive) quantifier for a selected part of a picture
rem                 aq-strength          = How much the AQ should be used (1 = rarely, 15 = very often, 8 = default)
rem                 temporal-aq          = Adaptive quantizier is based on how a part of the picture changes in time
rem                 pix_fmt=p010le       = use 10bit pixels instead of 16bit/24bit which allows to achieve smaller file size
rem                 pix_fmt=yuv444p16    = use 10bit pixels in 4:4:4 color space - a bit faster than p010 but creates slightly larger file
rem                 pix_fmt=nv12         = use native nVidia format for faster processing [DEFAULT]
rem                 -vf hwdownload,format=nv12    = download frame from HW memory to allow filters

rem set VIDEO_CONFIG=-c:v %ENCNAME% -rc:v vbr_hq -rc-lookahead 128 -b_adapt 0 -no-scenecut 1 -2pass 1 -bluray-compat 0 %WEIGHTED_PREDICTION% -temporal-aq 1 -spatial-aq 1 -aq-strength 9 -cq:v %HEVC_quality% -qmin %HEVC_quality_min% -qmax %HEVC_quality_max% -b:v %HEVC_bitrate% -preset %HEVC_preset% %TUNE% -maxrate:v 10M -gpu %HEVC_GPU% -pix_fmt p010le
rem set VIDEO_CONFIG=-c:v %ENCNAME% -profile:v main10 -rc:v vbr_hq -rc-lookahead 32 %WEIGHTED_PREDICTION%%AQ% -no-scenecut 1 -bluray-compat 0 -cq %HEVC_quality% -qmin %HEVC_quality_min% -qmax %HEVC_quality_max% -b:v %HEVC_bitrate% -preset %HEVC_preset% %TUNE% -maxrate:v 20M -gpu %HEVC_GPU% -pix_fmt p010le
if "HEVC" == "%ENCNAME%" set VIDEO_CONFIG=-c:v:0 %ENCDATA% -rc:v:0 vbr -tune hq -preset %HEVC_preset% -multipass %HEVC_multipass% -g %GOP_size% -bf %HEVC_BFRAMES% -b_ref_mode 1 -rc-lookahead %HEVC_lookahead% %WEIGHTED_PREDICTION%%AQ% -cq %HEVC_quality% -qmin %HEVC_quality_min% -qmax %HEVC_quality_max% -b:v:0 %HEVC_bitrate% -nonref_p 1 -bluray-compat 0
if "HEVC10" == "%ENCNAME%" set VIDEO_CONFIG=-c:v:0 %ENCDATA% -rc:v:0 vbr -tune hq -preset %HEVC_preset% -multipass %HEVC_multipass% -g %GOP_size% -bf %HEVC_BFRAMES% -b_ref_mode 1 -rc-lookahead %HEVC_lookahead% %WEIGHTED_PREDICTION%%AQ% -cq %HEVC_quality% -qmin %HEVC_quality_min% -qmax %HEVC_quality_max% -b:v:0 %HEVC_bitrate% -nonref_p 1 -bluray-compat 0
if "AVC" == "%ENCNAME%" set VIDEO_CONFIG=-c:v:0 %ENCDATA% -rc:v:0 vbr -tune hq -preset %HEVC_preset% -multipass %HEVC_multipass% -g %GOP_size% -bf %HEVC_BFRAMES% -rc-lookahead %HEVC_lookahead% %WEIGHTED_PREDICTION%%AQ% -cq %HEVC_quality% -qmin %HEVC_quality_min% -qmax %HEVC_quality_max% -b:v:0 %HEVC_bitrate% -nonref_p 1 -bluray-compat 0
if "SWHEVC" == "%ENCNAME%" set VIDEO_CONFIG=-c:v:0 %ENCDATA% -rc-lookahead 32 %WEIGHTED_PREDICTION%%AQ% -no-scenecut 1 -bluray-compat 0 -crf %HEVC_quality% -qmin %HEVC_quality_min% -qmax %HEVC_quality_max% -b:v:0 %HEVC_bitrate% -preset %HEVC_preset% %TUNE% -maxrate:v:0 20M
if "SWAVC" == "%ENCNAME%" set VIDEO_CONFIG=-c:v:0 %ENCDATA% -rc-lookahead 32 %WEIGHTED_PREDICTION%%AQ% -no-scenecut 1 -bluray-compat 0 -crf %HEVC_quality% -qmin %HEVC_quality_min% -qmax %HEVC_quality_max% -b:v:0 %HEVC_bitrate% -preset %HEVC_preset% %TUNE% -maxrate:v:0 20M


echo Converting "%HEVC_input_folder%%HEVC_filename%%HEVC_input_ext%" to "%HEVC_output_folder%%HEVC_output_filename%.%ENCNAME%~%HEVC_quality%%HEVC_quality_AQ%.mkv"
echo Converting "%HEVC_input_folder%%HEVC_filename%%HEVC_input_ext%" to "%HEVC_output_folder%%HEVC_output_filename%.%ENCNAME%~%HEVC_quality%%HEVC_quality_AQ%.mkv @%HEVC_bitrate%">> %log%
echo %HEVC_process_app% -y -hide_banner %DECODE% -i "%HEVC_input_folder%%HEVC_filename%%HEVC_input_ext%" %AUDIO_INPUT% %VIDEO_FILTER% %MAP% -c copy %AUDIO_CONFIG% %VIDEO_CONFIG% -max_muxing_queue_size 1024 %END_CONFIG% "%HEVC_output_folder%%HEVC_output_filename%.%ENCNAME%~%HEVC_quality%%HEVC_quality_AQ%.mkv"
     %HEVC_process_app% -y -hide_banner %DECODE% -i "%HEVC_input_folder%%HEVC_filename%%HEVC_input_ext%" %AUDIO_INPUT% %VIDEO_FILTER% %MAP% -c copy %AUDIO_CONFIG% %VIDEO_CONFIG% -max_muxing_queue_size 1024 %END_CONFIG% "%HEVC_output_folder%%HEVC_output_filename%.%ENCNAME%~%HEVC_quality%%HEVC_quality_AQ%.mkv"

echo.
if "0" == "%ERRORLEVEL%" echo Done converting %HEVC_output_filename%!
if "0" == "%ERRORLEVEL%" echo Done converting "%HEVC_output_folder%%HEVC_output_filename%.%ENCNAME%~%HEVC_quality%@%HEVC_bitrate%.mkv" >> %log%
if "1" == "%ERRORLEVEL%" echo Failed to convert %HEVC_output_filename%!
if "1" == "%ERRORLEVEL%" echo Failed to convert "%HEVC_output_folder%%HEVC_output_filename%.%ENCNAME%~%HEVC_quality%@%HEVC_bitrate%.mkv" >> %log%
echo.
if "0" == "%ERRORLEVEL%" if "1" == "%USE_NERO_AAC%" del "%HEVC_output_folder%%HEVC_output_filename%.aac"
set /A processed=%processed% + 1
shift
echo.
echo ---------------------------------------------------------------------
goto param

:prepare_aac
set AUDIO_INPUT=%HEVC_output_folder%%HEVC_output_filename%.aac

if exist "%AUDIO_INPUT%" echo Audio file "%AUDIO_INPUT%" already exists, will use it to mix with video...
if exist "%AUDIO_INPUT%" goto skip_aac

echo Quality %AUDIO_QUALITY%
set AACQ=0.%AUDIO_QUALITY%
if "0.100" == "%AACQ%" set AACQ=1.0
echo Q set to %AACQ%

echo Exporting audio of "%HEVC_input_folder%%HEVC_filename%%HEVC_input_ext%" to "%AUDIO_INPUT%"
echo Exporting audio of "%HEVC_input_folder%%HEVC_filename%%HEVC_input_ext%" to "%AUDIO_INPUT%">> %log%
echo %HEVC_process_app% -y -hide_banner -i "%HEVC_input_folder%%HEVC_filename%%HEVC_input_ext%" -vn -af "aresample=async=1" %END_CONFIG% "%HEVC_output_folder%%HEVC_output_filename%.wav"
%HEVC_process_app% -y -hide_banner -i "%HEVC_input_folder%%HEVC_filename%%HEVC_input_ext%" -vn -af "aresample=async=1" %END_CONFIG% -f wav - | %AAC_process_app% -q %AACQ% -ignorelength -if - -of "%AUDIO_INPUT%"
rem no goto, continue with skip_aac

:skip_aac
set AUDIO_INPUT=-i "%AUDIO_INPUT%"
set MAP=-map 0:v -map 1:a
goto continue_aac

:prepare_xvid
echo.
if exist "%HEVC_output_folder%%HEVC_filename%.1.aac" echo Audio file "%HEVC_output_folder%%HEVC_filename%.1.aac" found in target folder. Will be used for muxing...
if not exist "%HEVC_output_folder%%HEVC_filename%.1.aac" echo %HEVC_process_app% -y -hide_banner -i "%HEVC_input_folder%%HEVC_filename%%HEVC_input_ext%" -map 0:a:0 -vn -af "aresample=async=1" -f wav - ^| %AAC_process_app% -q %XVID_AAC_QUALITY% -ignorelength -if - -of "%HEVC_output_folder%%HEVC_filename%.1.aac"
if not exist "%HEVC_output_folder%%HEVC_filename%.1.aac" %HEVC_process_app% -y -hide_banner -i "%HEVC_input_folder%%HEVC_filename%%HEVC_input_ext%" -map 0:a:0 -vn -af "aresample=async=1" -f wav - | %AAC_process_app% -q %XVID_AAC_QUALITY% -ignorelength -if - -of "%HEVC_output_folder%%HEVC_filename%.1.aac"
echo.
if exist "%HEVC_output_folder%%HEVC_filename%.2.aac" echo Audio file "%HEVC_output_folder%%HEVC_filename%.2.aac" found in target folder. Will be used for muxing...
if not exist "%HEVC_output_folder%%HEVC_filename%.2.aac" echo %HEVC_process_app% -y -hide_banner -i "%HEVC_input_folder%%HEVC_filename%%HEVC_input_ext%" -map 0:a:1 -vn -af "aresample=async=1" -f wav - ^| %AAC_process_app% -q %XVID_AAC_QUALITY% -ignorelength -if - -of "%HEVC_output_folder%%HEVC_filename%.2.aac"
if not exist "%HEVC_output_folder%%HEVC_filename%.2.aac" %HEVC_process_app% -y -hide_banner -i "%HEVC_input_folder%%HEVC_filename%%HEVC_input_ext%" -map 0:a:1 -vn -af "aresample=async=1" -f wav - | %AAC_process_app% -q %XVID_AAC_QUALITY% -ignorelength -if - -of "%HEVC_output_folder%%HEVC_filename%.2.aac"

set MAP=-map 0:v:0 -map 1:a -metadata:s:a:0 language=cze
set AUDIO_INPUT=-i "%HEVC_output_folder%%HEVC_filename%.1.aac"
set SUBS_POS=2

if exist "%HEVC_output_folder%%HEVC_filename%.2.aac" set MAP=%MAP% -map 2:a -metadata:s:a:1 language=eng
if exist "%HEVC_output_folder%%HEVC_filename%.2.aac" set AUDIO_INPUT=%AUDIO_INPUT% -i "%HEVC_output_folder%%HEVC_filename%.2.aac"
if exist "%HEVC_output_folder%%HEVC_filename%.2.aac" set SUBS_POS=3

if exist "%HEVC_input_folder%%HEVC_filename%.srt" set MAP=%MAP% -map %SUBS_POS%:s -metadata:s:s:0 language=cze -disposition:s:0 forced
if exist "%HEVC_input_folder%%HEVC_filename%.srt" set AUDIO_INPUT=%AUDIO_INPUT%  -sub_charenc cp1250 -i "%HEVC_input_folder%%HEVC_filename%.srt"
if exist "%HEVC_input_folder%%HEVC_filename%.srt" set END_CONFIG=%END_CONFIG%

if exist "%HEVC_input_folder%%HEVC_filename%.sub" set MAP=%MAP% -map %SUBS_POS%:s -metadata:s:s:0 language=cze -disposition:s:0 forced
if exist "%HEVC_input_folder%%HEVC_filename%.sub" set AUDIO_INPUT=%AUDIO_INPUT%  -sub_charenc cp1250 -i "%HEVC_input_folder%%HEVC_filename%.sub"
if exist "%HEVC_input_folder%%HEVC_filename%.sub" set END_CONFIG=%END_CONFIG%

goto param_set

:prepare_tit
%HEVC_process_app% -y -hide_banner -i "%HEVC_input_folder%%HEVC_filename%%HEVC_input_ext%" -map 0:a:0 -vn -af "aresample=async=1" %END_CONFIG% -f wav - | %AAC_process_app% -q 0.55 -ignorelength -if - -of "%HEVC_output_folder%%HEVC_filename%.1.aac"

set MAP=-map 0:v:0 -map 1:a -metadata:s:a:0 language=cze
set AUDIO_INPUT=-i "%HEVC_output_folder%%HEVC_filename%.1.aac"

goto param_set

:error_ffmpeg
echo.
echo.
echo Could not find the FFMPEG program. Please move in into folder:
cd
echo The start this script again.
echo.
goto end

:error_param
echo.
echo.
echo No parameter given. To convert a video (or more videos at once)
echo please drag and drop them on the icon of this script.
echo.
goto end


:end
if exist %filepath% exit /b

:end_path
echo.
echo.
echo.
title Conversion DONE!
pause
