@echo off

title Image conversion to AVIF
cls
echo.
echo                            Image conversion to AVIF
echo.

rem Check that AVIF exist in this folder
set process_app=%~dp0cavif.exe
if exist %~dp0bin/cavif.exe set process_app=%~dp0bin/cavif.exe
if NOT EXIST "%process_app%" goto error_app

set log=%~dp02AVIF.log

set QUALITY=80

if [] == [%1] goto error_param

echo   Please set quality you want to use for the pictures.
echo.
set /p QUALITY="100 = best lossy, 0 = smallest file. [Default: 80]: "


:start
rem cls

rem Count how many files we need to process
call :count_params %*
set processed=1
rem END of count parameters

:param
if [] == [%1] goto end

set filename=%~1
set output=%~dpn1.avif


:param_set
set title=[%processed%/%total%] Converting "%filename%" to AVIF with %QUALITY%%% quality ...
title %title%...
echo.
echo %title%...

set command=%process_app% --quality=%QUALITY% --speed=1 --overwrite -o %output% "%filename%"

echo %command%>> %log%
%command%

if "0" == "%ERRORLEVEL%" echo Done converting %output%!
if "0" == "%ERRORLEVEL%" echo Done converting "%output%" >> %log%
if "1" == "%ERRORLEVEL%" echo Failed to convert %filename%!
if "1" == "%ERRORLEVEL%" echo Failed to convert "%filename%" >> %log%
echo.
call :smaller %filename% %output%
if "0" == "%ERRORLEVEL%" echo File "%output%" is smaller >> %log%
if "1" == "%ERRORLEVEL%" echo Failed to get smaller version of "%filename%" >> %log%


set /A processed=%processed% + 1
shift
echo.
echo ---------------------------------------------------------------------
goto param

:error_app
echo.
echo.
echo Could not find the AVIF program. Please move "cavif.exe" into folder: %~dp0
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
echo  [X] AVIF is larger than original image. AVIF takes %diff%%% of original file.
exit /B 1

:is_smaller
set /A diff=%size1% - %size2%
set /A percent=%diff% * 100 / %size1%
set /A diff=%diff% / 1024
echo  [V] AVIF is smaller than original image. You saved %diff%kB (%percent%%%)
exit /B 0


:end
echo.
echo.
echo.
title [%processed%/%total%] Conversion DONE!
pause
