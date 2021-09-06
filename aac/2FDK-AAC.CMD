@echo off
title Convert sound to AAC using Fraunhofer FDK library

rem Script may save temporary large files into TEMP folder. If this folder is too small, set this to 0 to rather use output folder for temporary files.
set use_temp=1

rem By default script will convert first audio track (index 0) from the container. You can change this to convert other audio tracks.
rem Note that this will move the converted track to the first place when merged back.
rem To convert all tracks in container set this number to the last audio track index and then convert file so many times how many tracks are in the file.
set track=0

rem For parameter -p (profile) used below following values can be used:
rem    2 is standard AAC-LC    (highest compatibility for old TVs/BD-players, etc.; not recommended for home usage)
rem    5 enables SBR (HE-AAC)  (recommended for movie sound; 5.1, 7.1 etc.)
rem   29 enables PS (HEv2 AAC) (recommended for music and other stereo sources; supported only for 2-channel source)
rem   23 and 39 enables LD or ELD (respectively) which are used for VoIP and other real-time communication (i.e. not suitable for music or movies).

:quality_set

echo.
echo Fraunhofer FDK can use constant (CBR) or variable (VBR) bitrate.
echo     This script uses CBR method but is some cases FDK may automatically switch to variable bitrate when more suitable
echo     (usually when source uses variable or much higher bitrate).
echo.
echo Recommended (total) bitrates (note that HE-AAC may use lower and higher bitrate as needed):
echo    32kbps  = mono, low quality (max. 9kHz) (e.g. chat recording)
echo    96kbps  = mono with high quality (up to 15kHz) or stereo with low quality; (recommended for 128kbps MP3 source)
echo    192kbps = stereo with high quality (17+kHz) (recommended for 320kbps/V0 MP3 or stereo AC3)
echo    224kbps = 5.1 with low quality (recommended for AC3 below 367kbps)
echo    448kbps = 5.1 with high quality (recommended for AC3 up to 640kbps, DTS, etc.)
echo    720kbps = 5.1 DTS or FLAC (when maximum quality is required)
echo.
echo HE-AAC improves sound quality for lower bitrate AAC, however may produce slightly larger file than AAC LC with same quality settings.
echo    On the contrary, HE-AAC improves compression for high bitrate AAC and will produce smaller file than AAC LC.
echo.
echo HE-AAC also ensures bitrate is not wasted on "empty" data which means it will never use higher bitrate than needed and will
echo    produce file with highest meaningful bitrate based on the source quality (instead of using maximum bitrate).
echo.

set AAC_bitrate=96
set /p AAC_bitrate="Choose target bitrate [32, 64, 96, 128, 192, 224, 448, etc.; default 96kbps]:"

rem Path to FDK-AAC
set AAC=%~dp0fdkaac.exe
if exist %~dp0bin/fdkaac.exe set AAC=%~dp0bin/fdkaac.exe
rem Path to FFMPEG
set FFMPEG=%~dp0ffmpeg.exe
if exist %~dp0bin/ffmpeg.exe set FFMPEG=%~dp0bin/ffmpeg.exe

if NOT exist "%AAC%" goto error_AAC

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
set processed=0
rem END of count parameters


:param
set inputname=%~n1
set fileext=%~x1
set inputdir=%~dp1

if not "" == "%inputname%" goto test_ext
goto end

:test_ext
set /A processed=%processed% + 1
set title=[%processed%/%total%] Converting "%inputname%" to HE-AAC with quality %AAC_bitrate%kbps...
title %title%...
echo.
echo %title%...
echo.

set delete_wav=0
if exist "%inputdir%%inputname%.wav" set filename=%inputdir%%inputname%.wav
if exist "%inputdir%%inputname%.wave" set filename=%inputdir%%inputname%.wave
if exist "%filename%" goto do_wav
goto error_filename

:do_wav
echo.
echo.

rem This is for debugging of other parts of the script to skip the conversion
rem if exist "%inputdir%%inputname%.HEv2~%AAC_bitrate%kbps.m4a" goto done_wav
rem if exist "%inputdir%%inputname%.HE~%AAC_bitrate%kbps.m4a" goto done_wav

echo Converting "%filename%" to HE-AAC...
echo.
set command=%AAC% -p29 -I -m0 -b%AAC_bitrate% -o "%inputdir%%inputname%.HEv2~%AAC_bitrate%kbps.m4a" "%filename%"
echo %command%
%command%

if [2] == [%ERRORLEVEL%] goto do_wav_fallback
goto done_wav

:do_wav_fallback
echo.
echo HE-AAC v2 (aka Parametric Stereo) is supported only for 2-channel input. Fallbacking to HE-AAC...
echo.
set command=%AAC% -p5 -I -m0 -b%AAC_bitrate% -o "%inputdir%%inputname%.HE~%AAC_bitrate%kbps.m4a" "%filename%"
echo %command%
%command%

:done_wav
if "1" == "%delete_wav%" del "%filename%"
if "1" == "%merge_back%" goto merge_back
if "1" == "%copy_meta%" goto copy_meta

shift

goto param

:prepare_wav
set delete_wav=1
set filename=%inputname%.wav
if "1" == "%use_temp%" set filename=%tmp%\%filename%
set copy_meta=0
if ".mp3"=="%fileext%" set copy_meta=1
if ".fla"=="%fileext%" set copy_meta=1
if ".flac"=="%fileext%" set copy_meta=1

if not "" == "%merge_back%" goto prepare_continue
if ".mkv" == "%fileext%" goto prepare_video
if ".avi" == "%fileext%" goto prepare_video
if ".mp4" == "%fileext%" goto prepare_video
if ".webm" == "%fileext%" goto prepare_video

:prepare_continue
echo.
echo.
echo Extracting WAV from "%filename%"...
echo.
rem Note: FFMPEG automatically selects format based on WAV extension so we don't need -c:a parameter
rem Note: WAV have constant bitrate based on number of channels (8bit 768kbps, 16bit 1536kbps, etc.) so not need to specify -b:a parameter
set command=%FFMPEG% -hide_banner -y -i "%inputdir%%inputname%%fileext%" -map 0:a:%track% "%filename%"
echo %command%
%command%
goto do_wav

:copy_meta

echo.
echo Copying Metadata from MP3/FLAC into M4A...
rem From original MP3 we will copy metadata and also all streams (video, pictures, text, etc.) except audio and then add audio from second (AAC) file. This way we will copy ID3 and Cover Art into new file.
set tags="%inputdir%%inputname%%fileext%"
if exist "%inputdir%..\%inputname%.mp3" set tags="%inputdir%..\%inputname%.mp3"
set audio=%inputname%.HE~%AAC_bitrate%kbps.m4a
if exist "%inputdir%%inputname%.HEv2~%AAC_bitrate%kbps.m4a" set audio=%inputname%.HEv2~%AAC_bitrate%kbps.m4a
set command=%FFMPEG% -hide_banner -y -i %tags% -i "%inputdir%%audio%" -c copy -map 0 -map -0:a -map 1:a -map_metadata 0 "%inputname%.HE~%AAC_bitrate%.tmp.m4a"
echo %command%
%command%
rem FFMPEG cannot edit existing files so we must first same new file into TMP, delete original and rename TMP to original name
del "%inputdir%%audio%"
ren "%inputname%.HE~%AAC_bitrate%.tmp.m4a" "%audio%"

shift

goto param

:merge_back
echo.
echo.
echo Merging video and new audio...
echo.

echo Exporting original video streams...
set TMP_VIDEO="%inputdir%%inputname%.video.tmp.%fileext%"
if "1" == "%use_temp%" set TMP_VIDEO=%tmp%\%inputname%.video.tmp.%fileext%
set command=%FFMPEG% -hide_banner -y -i "%inputdir%%inputname%%fileext%" -map 0:v -c copy "%TMP_VIDEO%"
echo %command%
%command%

echo.
set TMP_OTHER="%inputdir%%inputname%.other.tmp.%fileext%"
if "1" == "%use_temp%" set TMP_OTHER=%tmp%\%inputname%.other.tmp.%fileext%
echo Exporting additional streams...  (note: this may throw error, which is OK if the file contains only video stream(s) and one audio stream)
set command=%FFMPEG% -hide_banner -y -i "%inputdir%%inputname%%fileext%" -map 0 -map -0:v -map -0:a:%track% -c copy "%TMP_OTHER%"
echo %command%
%command%

rem Prepare merge command based on what files are available
set command=%FFMPEG% -hide_banner -y -i "%inputdir%%inputname%%fileext%"
set command=%command% -i "%TMP_VIDEO%"
if exist "%inputdir%%inputname%.HEv2~%AAC_bitrate%kbps.m4a" set command=%command% -i "%inputdir%%inputname%.HEv2~%AAC_bitrate%kbps.m4a"
if exist "%inputdir%%inputname%.HE~%AAC_bitrate%kbps.m4a"   set command=%command% -i "%inputdir%%inputname%.HE~%AAC_bitrate%kbps.m4a"
if exist "%TMP_OTHER%" set command=%command% -i "%TMP_OTHER%"
set command=%command% -map 1 -map 2:a
if exist "%TMP_OTHER%" set command=%command% -map 3
set command=%command% -map_metadata 0 -c copy
if exist "%inputdir%%inputname%.HEv2~%AAC_bitrate%kbps.m4a" set command=%command% "%inputdir%%inputname%.HEv2~%AAC_bitrate%kbps%fileext%"
if exist "%inputdir%%inputname%.HE~%AAC_bitrate%kbps.m4a"   set command=%command% "%inputdir%%inputname%.HE~%AAC_bitrate%kbps%fileext%"

echo.
echo Creating final file...
echo %command%
%command%

rem Comment these lines for debugging to see what files are created during conversion
if exist "%inputdir%%inputname%.HEv2~%AAC_bitrate%kbps.m4a" del "%inputdir%%inputname%.HEv2~%AAC_bitrate%kbps.m4a"
if exist "%inputdir%%inputname%.HE~%AAC_bitrate%kbps.m4a" del "%inputdir%%inputname%.HE~%AAC_bitrate%kbps.m4a"
del "%TMP_VIDEO%"
del "%TMP_OTHER%"

shift
goto param


:prepare_video
set merge_back=0
choice /C ny /T 10 /D n /N /M "This file is probably a video. Do you want to merge the video with the new AAC audio? [y = Yes / n = No]"
if 2 == %ERRORLEVEL%  set merge_back=1
goto prepare_continue

:error_filename
if exist %FFMPEG% goto prepare_wav
echo.
echo.
echo.
echo To convert the audio you either must have WAV file
echo or place FFMPEG executable into same folder as the script!
echo.
goto end


:end
set title=[%processed%/%total%] DONE!
title %title%...
echo.
echo %title%...
echo.

pause

:clear_mem
rem clear all used properties for use in Batch
set filename=
set AAC_bitrate=
