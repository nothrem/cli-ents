@echo off

REM @param %1 = F for full backup, D for differential backup
REM @param %2 = Server name to connect to (e.g. MyServer\SQLEXPRESS)
REM @param %3 = Database name to backup
REM @param %* = Additional names of databases to backup

REM test that MSSQL console command is in PATH
sqlcmd /? > NUL
if NOT 0 == %ERRORLEVEL% goto no_cli

set backup=%cd%
echo Files will be stored into folder %backup%.

if [F] == [%1] goto full
if [f] == [%1] goto full
if [D] == [%1] goto diff
if [d] == [%1] goto diff
echo First parameter must be either F for full backup or D for differential backup!
goto done

:full
set type=WITH CHECKSUM
set file=full
goto server

:diff
set type=WITH DIFFERENTIAL
set file=diff
goto server

:server
shift
set server=%1
goto time

:time
echo.

if [/] == [%date:~2,1%] goto US_date
if [.] == [%date:~2,1%] goto ISO_date
set today=%date%
set now=%time:~0,2%-%time:~3,2%-%time:~6,2%
goto shrink

:US_date
set today=%date:~6,4%-%date:~0,2%-%date:~3,2%
set now=%time:~0,2%-%time:~3,2%-%time:~6,2%
goto shrink

:ISO_date
set today=%date:~6,4%-%date:~3,2%-%date:~0,2%
set now=%time:~0,2%-%time:~3,2%-%time:~6,2%
goto shrink

:shrink
rem get name of first DB to process
shift
if [] == [%1] goto done

rem No shrinking for differential backup
IF [%file%] == [diff] goto backup

echo Shrinking database %1...

sqlcmd -S %server% -E -Q "DBCC SHRINKDATABASE ( %1, 5 )"
echo.


:backup
REM day or time in range 0 - 9 may start with a space, but we need zero to make it filename-compatible
set today=%today: =0%
set now=%now: =0%

IF NOT EXIST %backup% mkdir %backup%

echo Backing up database %1 on %today% %now%...

sqlcmd -S %server% -E -Q "BACKUP DATABASE %1 TO DISK = '%backup%\%1_%today%_%now%_%file%.bak' %type%"
echo.

IF NOT EXIST "C:\Program Files\WinRAR\Rar.exe" echo Could not find WinRAR compressor. Please install WinRAR to C:\Program Files\WinRar to automatically compress the backup.
IF NOT EXIST "C:\Program Files\WinRAR\Rar.exe" goto time
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
IF [%file%] == [full] "C:\Program Files\WinRAR\Rar.exe" a -m5 -mt8 -md1g -ri1 -s -ep1 -t -tl -dw -y %backup%\%1_%today%_%now%_%file%.rar %backup%\%1_%today%_%now%_%file%.bak
IF [%file%] == [diff] "C:\Program Files\WinRAR\Rar.exe" a -m5 -mt8 -md1g -ri1 -s -ep1 -t -tl -dw -y %backup%\%1_%today%_%file%.rar %backup%\%1_%today%_%now%_%file%.bak

goto time

:no_cli
echo.
echo Cannot find MSSQL CLI client. Please check that your PATH include the path to the /binn folder of the SQL client.
echo (Example of instalation path: c:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\sqlcmd.exe)

:done
echo Done
echo.
echo.
echo ------------------------------------------------------
echo.
