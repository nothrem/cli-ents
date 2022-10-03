@echo off

title Image conversion to WEBP
cls
echo.
echo                            Image conversion to WEBP
echo.

rem Check that CWEBP exist in this folder
set process_app=%~dp0cwebp.exe
if exist %~dp0bin/cwebp.exe set process_app=%~dp0bin/cwebp.exe
if NOT EXIST "%process_app%" goto error_app

set log=%~dp02WEBP_auto.log

set QUALITY=75

if [] == [%1] goto error_param

echo   Please set base quality you want to use for the pictures.
echo   This script will try to find best quality that will produce smaller file than the original.
echo.
set /p QUALITY="100 = best quality, 0 = worst quality, smallest file. [Default: %QUALITY%]: "


:start
rem cls

rem Count how many files we need to process
call :count_params %*
set processed=0
rem END of count parameters

:param
if [] == [%1] goto end

set filename=%~1
set output=%~dpn1.webp
set outQ=%QUALITY%
set /A processed=%processed% + 1


:param_set
set title=[%processed%/%total%] Converting "%~nx1" to WEBP with %outQ%%% quality factor...
title %title%...
echo.
echo %title%...
echo.

rem if exist %output% echo File %output% already exist. Skipping.
rem if exist %output% echo File %output% already exist. Skipping. >> %LOG%
rem if exist %output% goto :check_smaller

set command=%process_app% -quiet -q %outQ% -preset photo -hint photo -m 6 -sharp_yuv -pass 10 -mt -af -alpha_filter best "%filename%" -o "%output%"

echo %command% >> %log%
%command%

echo.
if "0" == "%ERRORLEVEL%" echo Done converting %output%!
if "0" == "%ERRORLEVEL%" echo Done converting "%output%" >> %log%
if "1" == "%ERRORLEVEL%" echo Failed to convert %filename%!
if "1" == "%ERRORLEVEL%" echo Failed to convert "%filename%" >> %log%

:check_smaller
echo.
call :smaller %filename% %output%
if "0" == "%ERRORLEVEL%" echo File "%output%" is smaller >> %log%
if "0" == "%ERRORLEVEL%" goto next
if "1" == "%ERRORLEVEL%" echo Failed to get smaller version of "%filename%" >> %log%

if %outQ% LSS 10 goto next
set /A outQ=%outQ% - 10
goto :param_set


:next
shift
echo.
echo ---------------------------------------------------------------------
goto param

:error_app
echo.
echo.
echo Could not find the CWEBP program. Please move "cwebp.exe" or extract "libwebp-*.zip" into folder: %~dp0
echo Then start this script again.
echo.
goto end

:error_param
echo.
echo.
echo No parameter given. To convert an image (or more at once)
echo please drag and drop them on the icon of this script.
echo.
goto end

:count_params
set total=0
:count_continue
set /A total=%total% + 1
shift
if not [] == [%1] goto :count_continue
exit /b

:smaller
set size1=%~z1
set size2=%~z2

if %size2% LSS %size1% goto is_smaller

set /A diff=%size2% * 100 / %size1%
echo  [X] WEBP is larger than original image. WEBP takes %diff%%% of original file. WEBP will NOT be saved!
del %2
exit /B 1

:is_smaller
set /A diff=%size1% - %size2%
set /A percent=%diff% * 100 / %size1%
set /A diff=%diff% / 1024
if %diff% LSS 1024 if %percent% LSS 11 goto no_diff
echo  [V] WEBP is smaller than original image. WEBP saved %diff%kB (%percent%%%)
exit /B 0

:no_diff
set /A diff=%size1% - %size2%
echo  [-] WEBP is smaller by less than 1kB and less than 10%%. WEBP would save only %diff%B (%percent%%%). WEBP will NOT be saved!
del %2
exit /B 1


:end
echo.
echo.
echo.
title [%processed%/%total%] Conversion DONE!
pause
