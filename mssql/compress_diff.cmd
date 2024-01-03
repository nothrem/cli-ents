@echo off

REM @param %1 = BAK file to compress to 7zip
REM @param %* = Additional file names to process

set /p db=What is the name of the database? (e.g. MyDB01):
set /p day=What is the day of files? (e.g. 2024-01-01):

:start
title Compressing file %~n1...
echo Compressing file %~n1...

IF NOT EXIST "C:\Program Files\WinRAR\Rar.exe" echo Could not find WinRAR compressor. Please install WinRAR to C:\Program Files\WinRar!
rem  a    = add new files if archive exists
rem -dw   = securely erase original file
rem -ep1  = do not include base path to the compressed file names (i.e. extract in current folder)
rem -mtX  = run with X threads
rem -m5   = use best compression
rem -md1g = use dictionary of size up to 1GB
rem -ri1  = use lowest priority (do not block other processes)
rem -s    = create solid archive (sort files by type and compress similar files together)
rem -t    = test file when finished
rem -tl   = update archive time by the last file time
rem -y    = answer YES to all (automatically confirm overwriting)
IF EXIST "C:\Program Files\WinRAR\Rar.exe" "C:\Program Files\WinRAR\Rar.exe" a -m5 -mt8 -md1g -ri1 -s -t -tl -dw -y "%~dp1%db%_%day%_diff.rar" "%~dpnx1"

if [] == [%2] goto done
shift
goto start

:done
echo Done
echo.
echo.
echo ------------------------------------------------------
echo.
pause >NUL
