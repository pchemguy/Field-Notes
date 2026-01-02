# Reverse Engineering SQLite3 Databases with ERD Concepts

Reverse engineering a database schema is a critical technique for understanding backend data models, particularly for legacy systems or databases where graphical documentation is missing. While the process can be complex, my specific focus is generating a graphical representation of the schema to visualize table relationships defined by foreign key constraints.

My primary interest lies in local, serverless SQLite3 databases. Due to their file-based nature, communication and analysis are highly efficient, avoiding network latency and server throughput limitations.

## The Tool: ERD Concepts

[ERD Concepts](https://erdconcepts.com) is a professional-grade database design tool. Although discontinued in 2018, its final release (v8.0.4, October 2018) remains robust and perfectly suitable for stable, conservative database engines like SQLite3. It is available under the MIT license free of charge.

The vendor also provides potentially useful auxiliary tools, such as a Data Generator and an ADO Connection String Checker, available on their [toolbox page](https://erdconcepts.com/dbtoolbox.html).

## Prerequisite: SQLite ODBC Driver

Windows ships with the SQLite3 C-API library but lacks the high-level drivers required for ADO/ODBC connections. To interface with ERD Concepts, you must install a driver. The [SQLite ODBC Driver](http://ch-werner.de/sqliteodbc) by Christian Werner is the standard open-source solution.

**Relevant Installation Artifacts:**

* **File System:**
    * `%SystemRoot%\System32\sqlite3odbc.dll` (64-bit)
    * `%SystemRoot%\SysWOW64\sqlite3odbc.dll` (32-bit)


* **Registry Configuration:**

```registry
Windows Registry Editor Version 5.00

; --- Driver Registration ---
[HKEY_LOCAL_MACHINE\SOFTWARE\ODBC\ODBCINST.INI\SQLite3 ODBC Driver]
"Driver"="C:\\Windows\\system32\\sqlite3odbc.dll"
"Setup"="C:\\Windows\\system32\\sqlite3odbc.dll"

[HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\ODBC\ODBCINST.INI\SQLite3 ODBC Driver]
"Driver"="C:\\Windows\\system32\\sqlite3odbc.dll"
"Setup"="C:\\Windows\\system32\\sqlite3odbc.dll"

; --- Data Source Configuration ---
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

Note that both `WOW6432Node` and non-`WOW6432Node` reference the same 64-bit library under `System32` and neither refers to the 32-bit under `SysWOW64`, which might be a driver installer's mistake. However, I believe that I could connect to SQLite databases from both 32-bit and 64-bit applications (primarily MS Office).

## Portable Installation Strategy

The official installer requires administrative privileges solely to write to `%ProgramFiles%`. However, the software itself can be run in a pseudo-portable fashion by unpacking the installer and using directory junctions to handle AppData.

### 1. Extraction

The installer is built with [InnoSetup](https://jrsoftware.org/isinfo.php). Use [InnoExtract](https://constexpr.org/innoextract/) to unpack `erdconcepts804_x64_reg.exe`, yielding two folders: `app` and `commonappdata`.

### 2. Directory Restructuring

Rename `app` to `ERDConcepts`. Move the contents of `commonappdata/ERD Concepts/8.0` into a new subdirectory `ERDConcepts/COMMON_DATA`.

**Target Structure:**

```text
ERDConcepts
├── ERDConcepts8.exe
│   ~
├── COMMON_DATA  <-- Create this
│   ├── Report
│   ├── Schema
│   └── Template
└── USER_DATA  <-- Create this

```

### 3. Application Configuration

Launch the executable and navigate to `Tools -> Options -> Folders`.

* Remove the curly braces from `{COMMON_DATA}`. This edit forces the application to resolve the path relative to the executable.
* Change `{USER_DATA}` to `USER_DATA`.
* *Note:* The `ERDConcepts` root should generally be Read-Only for standard users (Windows `Users`), while `ERDConcepts/USER_DATA` requires Full Write access.

### 4. The AppData Junction Hack

ERD Concepts hardcodes settings storage to `%APPDATA%/ERD Concepts 8`. To keep these settings "portable" (contained within the program folder), we can use a batch script to create directory junctions.

1. Create a directory `ERDConcepts/Settings`.
2. Move any existing contents from `%APPDATA%/ERD Concepts 8` to `ERDConcepts/Settings/APPDATA/ERD Concepts 8`.
3. Create a script `links.bat` inside `ERDConcepts/Settings`:

```batch
@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: Loop through directories in local APPDATA folder
for /D %%D in ("%~dp0APPDATA\*") do (
    set "SRC=%%~D"
    set "DST=%APPDATA%\%%~nxD"
    
    :: Remove existing directory in real AppData if it exists
    if exist "!DST!" (cmd /c rmdir "!DST!" /S /Q)
    
    :: Create Junction pointing real AppData to our local folder
    mklink /j "!DST!" "!SRC!"
)
endlocal

```

**Final Layout** (only showing key directories and files):

```text
ERDConcepts
├── ERDConcepts8.exe
├── USER_DATA
├── COMMON_DATA
└── Settings
    ├── links.bat
    └── APPDATA
        └── ERD Concepts 8

```

*Usage:* When moving the tool to a new computer, run `links.bat` once. This script creates the necessary junctions, tricking the software into writing to your portable folder while it thinks it is writing to `%APPDATA%`.

## Database Analysis Workflow

### 1. Establish Connection

1. Start ERD Concepts and create a **New** file using the **SQLite 3** template.
2. Navigate to `Database -> Connect to Database -> New`.
3. Set **Database** to **SQLite 3.x**.

### 2. Configure Connection String

The most efficient method is to provide the ADO connection string directly.

**Template:**

```text
DRIVER=SQLite3 ODBC Driver;Timeout=1000;NoTXN=0;SyncPragma=NORMAL;StepAPI=1;FKSupport=1;NoCreat=1;Database=C:\Path\To\Your\Database.db;
```

> **Warning:** Ensure the `Database` path is correct. If the path is incorrect and the driver defaults are used, SQLite may silently create a new, empty database. The connection will succeed, but the reverse engineering wizard will find zero tables.

**Alternative (Wizard Method):**
If you prefer the GUI construction:

1. Click `Configure` -> `Microsoft OLE DB Provider for ODBC Driver` -> `Next`.
2. Select `Use connection string` -> `Build`.
3. In the **File Data Source** tab, click `New` -> `SQLite ODBC Driver`.
4. Follow the prompts to save a `.dsn` file.
5. When the driver configuration dialog appears, map it to your target database.

### 3. Reverse Engineering

1. Go to `Database -> Reverse Engineering... -> Next`.
2. If the connection is valid, the Wizard will display a list of detected tables.
3. Click `Start` -> `Accept`.

### 4. Refinement

Once the chart is generated, arrange the table objects to minimize crossing relationship lines. You can delete unnecessary tables from the view now, but it is recommended to save the raw `*.ecm` file before performing destructive edits.
