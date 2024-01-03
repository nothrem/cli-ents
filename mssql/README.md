Microsoft SQL Express scheduled backup tool
===========================================

MSSQL Express is a free database server, which does not include the SQL Agent — a tool you can use to schedule backup and maintenance tasks on your database.

This command line script helps you with that.

## Requirements

* Installed MSSQL Express with Client SDK and setup for login using Windows Credentials.
* Setup PATH on the current version of Client SDK's `binn` folder (see below).
* Enough space on a disk connected to the server (local disk, network disk, etc.).
* Optionally, WinRAR compressor. You can download and install this tool from https://www.win-rar.com/ (download and install the EXE version for your CPU).
* Optionally, an external tool for off-site backup (you can use something like OneDrive or Synology Drive Client to upload the backups to a cloud or external server).

## Usage

Note: You must be logged in as a user that has access to the MSSQL database (usually the user who installed it).

### Setup PATH for MSSQL client.

* First you need to find where the file `sqlcmd.exe` is located on your disk. Most probably it will be `C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\<newest version>\Tools\Binn\`.
* Then you can search for "Edit Environment Variables" in the Start menu or open Control Panel - System - Advanced System settings - Advanced - Environment variables.
* Click `Path` under System variables and click Edit. Click New, then Browse... and navigate to the `binn` folder.
* Close all windows with OK and then close all opened CLI windows (Command, PS shell, Terminal, etc.).

### You can run the script manually by this command:
```> mssql_express_backup F MyServer\SQLEXPRESS MyDB1 MyDB2```
* In the first parameter `F` means to create full backup. The first time you need to always create a full backup. Then you can use `D` to create differential backup.
  * You must always store both the newest full backup and the newest differential backup (or keep multiple differential backups to be able to return the database to a specific point in time).
  * When creating the full backup, the script will also shrink the database files if there is more than 5% overhead of a free space.
* The second parameter is the name of the database. This is the same name you chose during installation and which you use in SQL Server Management Studio.
* The next parameters are any number of database names you want to back up.

### To setup automatic backup, you need to use the Windows Task Scheduler.

* Search for `Task Scheduler` in Start menu and open it.
* Click `Action` - `Create task`
* Define task name (e.g. `MSSQL Daily backup`)
* Under `Security` click "Run whenever user is logged on or not"
* Under `Triggers` click `New` and setup how often the backup should be done. For full backup is recommended Weekly or Daily, for differential is recommended Daily or "Repeat task every 1 hour" or more often. 
* Under `Actions` click `New`, select "Start a program".
    * Click `Browse` and select the backup script (e.g. `C:\Cli-ents\mssql\mssql_express_backup.cmd`).
    * Into `Add arguments` fill the parameters (e.g. `F MyServer\SQLEXPRESS MyDB1 MyDB2`)
    * Into `Start in` write the folder where you want to store your backup files (e.g. `C:\Backup` or `C:\Users\Administrator\Onedrive\Backup`). Make sure the Database process has access to this folder! 
* Under `Settings` check "Run task as soon as possible..." (this helps to make backup if the server is restarting when the backup should start).
* Click `OK` to create the task.

Repeat the steps to schedule Full and Differential backups as needed.

To see the output of the backup process, you need to change the command (see below). You can either define this in the Task Scheduler,
or you can create additional CMD file with your required parameters and log command. Then you need to run this new batch instead.

```cmd /C "backup.cmd F MyServer\SQLEXPRESS MyDB1 MyDB2" >> output.log 2>&1```

## How to restore backup

This is not handled by this script and you need Sql Server Management Studio (SSMS). 

If your backups are compressed, extract the Full and Differential file(s) into a folder accessible from the server.

* Open SSMS and log in to your server.
* Right-click on Databases and select Restore Database.
* Click Source - Device and then click "...".
* Select the Full and optionally one or more Differential backups from which you want to restore the database.
* Optionally, you can click Timeline and Specific date and time to select which differential backup will be actually used for restoration (useful if the latest backups may contain damaged data).
* Click OK to restore the database


## Helper tools

Helper tools `compress.cmd` and `compress_diff.cmd` are scripts that allows you to compress existing backups into the same format generated
by the main backup script. They are not needed for running the main script.
