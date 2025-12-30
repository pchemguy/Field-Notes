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

The installation files (such as the 64-bit designer installer `erdconcepts804_x64_reg.exe`) require administrative privileges for installations even though these privileges are only necessary when installing in privileged locations, such as the standard `%ProgramFiles%`.  In fact, `ERD Concepts` can be installed and used in a pseudo-portable fashion.


```
DRIVER=SQLite3 ODBC Driver;Timeout=1000;NoTXN=0;SyncPragma=NORMAL;StepAPI=1;FKSupport=1;NoCreat=0;Database=C:\Users\evgeny\Downloads\wn.db;
```
