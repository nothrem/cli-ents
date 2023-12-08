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
set now=%date%_%time:~0,2%-%time:~3,2%-%time:~6,2%
goto done
goto backup

:US_date
set now=%date:~6,4%-%date:~0,2%-%date:~3,2%_%time:~0,2%-%time:~3,2%-%time:~6,2%
goto backup

:ISO_date
set now=%date:~6,4%-%date:~3,2%-%date:~0,2%_%time:~0,2%-%time:~3,2%-%time:~6,2%
goto backup

goto backup

:backup
shift

IF NOT EXIST %backup% mkdir %backup%

echo Backing up database %1 on time %now%...

sqlcmd -S %server% -E -Q "BACKUP DATABASE %1 TO DISK = '%backup%\%1_%now%_%file%.bak' %type%"
echo.

IF NOT EXIST "C:\Program Files\7-zip\7z.exe" echo Could not find 7Zip compressor. Please install 7Zip to C:\Program Files\7-zip to automatically compress the backup.
IF EXIST "C:\Program Files\7-zip\7z.exe" "C:\Program Files\7-zip\7z.exe" a -mmt4 -mx9 -sdel -y %backup%\%1_%now%_%file%.7z %backup%\%1_%now%_%file%.bak

if [] == [%2] goto done
goto time

:no_cli
echo.
echo Cannot find MSSQL CLI client. Please check that your PATH include the path to the /binn folder of the SQL client.
echo (Example of instalation path: c:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\sqlcmd.exe)

:done
echo Done
