# Reverse Engineering SQLite3 Databases with ERD Concepts

Reverse engineering of database schema is an important technique for understanding the backend data model and potential limitations/issues of legacy databases and databases where graphical representations of the schema is not available. While the reverse engineering process may quite complex, aiming for a variety database aspects, my particular interest is development of a graphical representation of the schema focused on understanding the relationship between the tables defined by foreign key constraints. Another important consideration is the type of the database. My sole interest is on local serverless SQLite3 databases. For such databases, database communication and analysis is very efficient (no server/network limitations).

[ERD Concepts](https://erdconcepts.com) is a powerful professional  database designer software with a broad spectrum of features/functionality. While it has been discontinued in 2018, it is perfectly suitable for working with very conservative SQLite3 databases. Its final release (October 2018 / 8.0.4) is available on the official website under the MIT license license free of charge. Additionally, the vendor also released a number of auxiliary database-related tools (such as `Data Generator` and ADO `Connection String Checker`) also [available for downloading](https://erdconcepts.com/dbtoolbox.html). Here, I would like to go over the workflow for creating schema diagrams for existing SQLite3 databases.

## Prerequisite

A common way to access SQLite3 databases on Windows is via the ADO library using an ODBC driver. Windows ships with a copy of the SQLite3 library providing the C-API interface, but does not include higher-level drivers, so one needs to be installed. A common open source driver is the [SQLite ODBC Driver](http://ch-werner.de/sqliteodbc) (custom MSYS2/MinGW build scripts are also available from the [SQLite ICU MinGW project](https://pchemguy.github.io/SQLite-ICU-MinGW/odbc)).

Relevant installation artifacts:
- File system:
    - Program files in
        - `%ProgramFiles%\SQLite ODBC Driver`
        - `%ProgramFiles(x86)%\SQLite ODBC Driver`
    - `sqlite3odbc.dll` in
        - `%SystemRoot%\System32` (64-bit)
        - `%SystemRoot%\SysWOW64` (32-bit)

 - Registry:

```
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\ODBC\ODBCINST.INI\SQLite3 ODBC Driver]
"Driver"="C:\\Windows\\system32\\sqlite3odbc.dll"
"Setup"="C:\\Windows\\system32\\sqlite3odbc.dll"

[HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\ODBC\ODBCINST.INI\SQLite3 ODBC Driver]
"Driver"="C:\\Windows\\system32\\sqlite3odbc.dll"
"Setup"="C:\\Windows\\system32\\sqlite3odbc.dll"

; ------------------------------------------------------------------

[HKEY_LOCAL_MACHINE\SOFTWARE\ODBC\ODBC.INI\ODBC Data Sources]
"SQLite3 Datasource"="SQLite3 ODBC Driver"

[HKEY_LOCAL_MACHINE\SOFTWARE\ODBC\ODBC.INI\SQLite3 Datasource]
"Driver"="C:\\Windows\\system32\\sqlite3odbc.dll"
"Database"=""

[HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\ODBC\ODBC.INI\ODBC Data Sources]
"SQLite3 Datasource"="SQLite3 ODBC Driver"

[HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\ODBC\ODBC.INI\SQLite3 Datasource]
"Driver"="C:\\Windows\\system32\\sqlite3odbc.dll"
"Database"=""
```

## Portable Installation

ERD Concepts installers refuse to install without administrative privileges, even though such privileges are only necessary when installing in privileged locations, such as the standard `%ProgramFiles%`.  In fact, `ERD Concepts` software can be installed and used in a pseudo-portable fashion. While ERD installers do not provide an obvious standard means to perform portable installation, they are created using [InnoSetup](https://jrsoftware.org/isinfo.php) and can be simply unpacked using [InnoExtract](https://constexpr.org/innoextract/).

The contents of the unpacked installer (`erdconcepts804_x64_reg.exe`) includes two directories:

```
|
|-- app
     |-- ERDConcepts8.exe
     ~
|
|-- commonappdata
        |-- ERD Concepts
                |-- 8.0
                     |-- Report
                     |-- Schema
                     |-- Template
```

The `app` directory can be renamed as `ERDConcepts`, and the contents of `commonappdata/ERD Concepts/8.0` can be placed in `ERDConcepts/COMMON_DATA`, yielding directory structure:

```
ERDConcepts
    |-- ERDConcepts8.exe
    ~
    |
    |-- COMMON_DATA
            |-- Report
            |-- Schema
            |-- Template
```

After the program is started, go to `Tools -> Options -> Folders` and strip curly braces from `{COMMON_DATA}`. This way the variable placeholder `{COMMON_DATA}` is turned into a plain directory named, which is correctly resolved relative to the executable. Note that the `folders` settings includes another location prefix `{USER_DATA}`, which can be changed, by analogy, to `USER_DATA`, placing user files under `ERDConcepts/USER_DATA`. Note, if permissions are properly managed, the subtree `ERDConcepts` should generally provide read-only access for the standard Windows `Users` group. The `ERDConcepts/USER_DATA` subtree should be additionally granted full access Windows `Users`.

`ERD Concepts` stores settings under `%APPDATA%/ERD Concepts 8` and does not use registry. While this behavior cannot be altered via program settings, there is a fairly robust pattern for keeping settings inside the program directory as if it was portable.
1) A new subdirectory, for example, `ERDConcepts/Settings` is created and granted full access for Windows `Users`. 
2) The contents of `%APPDATA%/ERD Concepts 8` is moved to `ERDConcepts/Settings/APPDATA/ERD Concepts 8`
3) An empty file flag `configdir` is created under `Settings` (this is optional and is not discussed further here; this flag indicates to a separate permissions resetting script that the subtree starting from the directory containing this flag should be granted full access to Windows `users`).
4) A script `links.bat` is also placed under `Settings`:

```
@echo off

setlocal EnableExtensions EnableDelayedExpansion

for /D %%D in ("%~dp0APPDATA\*") do (
    set "SRC=%%~D"
    set "DST=%APPDATA%\%%~nD"
    if exist "!DST!" (cmd /c rmdir "!DST!" /S /Q)
    mklink /j "!DST!" "!SRC!"
)

endlocal
```

The final layout:

```
ERDConcepts
    |-- ERDConcepts8.exe
    ~
    |
    |-- USER_DATA
            |
            ~
    |
    |-- COMMON_DATA
            |-- Report
            |-- Schema
            |-- Template
    |
    |-- Settings
            |-- links.bat
            |-- configdir
            |-- APPDATA
                   |
                   ~
```

When executed, this script for each subdirectory under "APPDATA" creates a directory junction under "%APPDATA%". If the program directory is moved (or copied to the computer for the first time), `links.bat` needs to be executed once to set or adjust associated directory junctions. Other than this extra one-time execution of `links.bat` and creation of associated directory junctions, the program will behave as if it was portable.

## Database Analysis Workflow

1) Start `ERD Concepts` and create a *New* file based on *SQLite 3* template.
2) `Database -> Connect to Database -> New`
3) Select *Connection name*, for example, "WordNet Database"
4) Select *Database*: **SQLite 3.x**
5) *Connection string*
   If you can provide ADO connection string directly, that would be the quickest route, e.g.:
```
DRIVER=SQLite3 ODBC Driver;Timeout=1000;NoTXN=0;SyncPragma=NORMAL;StepAPI=1;FKSupport=1;NoCreat=0;Database=C:\Users\evgeny\Downloads\wn.db;
```

Assuming you have properly installed `SQLite3 ODBC Driver` referenced above, this connection string may be use as a template, with the only necessary change being correctly specifying database path instead of `C:\Users\evgeny\Downloads\wn.db`.

Alternatively, connection string can be saved as a data source. Because a complete valid connection string must include SQLite database path either directly or provided via a saved data source file, a generic data source for an SQLite database can only be configured with an empty database and permission to create a new database. If such a data source is selected, a new blank database will be created when initiating a connection. To connect to an existing database file via a data source file, the actual path to the database must be saved in the database-specific data source. Such a data source can be created, if desired via
 - click `Configure`, select `Microsoft OLE DB Provider for ODBC Driver`;
 - go to `Connection` tab;
 - `1. Specify the source of data`;
 - select `Use data source name` if using previously created data source;
 - select `Use connection string` for a new database connection;
 - click `Build`
 - stay on the `File Data Source` tab and click `New`
 - select `SQLite ODBC Driver` (could be a different driver, if installed)
 - click `Next`, select name and location of the new data source file, then `Finish`;
 - at this point the connection string dialog should popup (at least if `SQLite ODBC Driver` is used) that can be used to select options for the connection string.
   Note that `SQLite ODBC Driver` is not developed very actively, so some of the options included may be obsolete, while missing on newer options.
- Finally, accept the constructed connection string.
Click connect to establish connection using either directly provided or constructed connection string.
Note, if database creation option is selected in the connection string, SQLite generally would silently create a new database, if it cannot connect to the specified database file. While the result will be a successful connection with no error, such a setup will useless if the goal is to analyze the structure of an existing database.

Go to `Database -> Reverse Engineering... -> Next`. If the database connection was actually properly configured and matched the location of the database file, the Wizard should successfully extract database tables and show a list. An empty list would suggest a misconfigured connection string that resulted in a connection to a new empty database. On success, click `Start -> Accept`. It is possible to unselect tables before the final `Accept`, but table objects can also be removed from the chart after the chart is created.

Once the chart is created, move table object around to minimize relation intersections, consider if there are table objects that may not be necessary. It is a good idea to save a copy of this `*.ecm` file before deleting table objects, though the analysis process can be repeated from scratch, if necessary.
