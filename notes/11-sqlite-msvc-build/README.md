---
urls:
  - https://chatgpt.com/c/6a648dd8-677c-83eb-ae07-14535c01617c
  - https://chatgpt.com/c/6b06fe46-69fc-83ea-ac08-dfcb73d17b8b
---

# Integrating Ordinary Loadable Extensions into the Amalgamation as Auto-Extensions

## Summary

This note documents a Windows/MSVC build pipeline for integrating selected ordinary SQLite loadable extensions from `ext/misc` directly into the SQLite amalgamation and registering them as auto-extensions. An application linked to the resulting library can use their SQL functions, collations and virtual table modules as soon as it opens a connection.

Three parts of the build connect the extension sources to each new database connection.

- `EXTRA_SRC` supplies additional sources to the amalgamation workflow.
- `SQLITE_EXTRA_AUTOEXT` adds a generated aggregate initializer to `sqlite3BuiltinExtensions`.
- Module-specific `SQLITE_ENABLE_*` definitions control which prepared extensions are registered.

Two Tcl utilities prepare the selected extension sources.

- `patch_sqlite_misc_autoext.tcl` converts loadable-extension entry points into core-callable initializers, preserves non-core loadable-extension wrappers, avoids symbol collisions with shell-integrated copies, and generates the aggregate `sqlite3ExtraAutoExtInit()` dispatcher.
- `bundle_extra_src.tcl` recursively expands local header and C-source dependencies so each extra source is self-contained when appended to the amalgamation.

The maintained MSVC batch script obtains SQLite, builds or reuses ZLIB, stages ICU from an active Conda environment, and prepares both stock and project extensions. It builds from a separate directory and collects the executable, libraries, headers and runtime DLLs. The primary source for the script and its prerequisites is the [Windows/MSVC build guide][build-guide]. For a worked extension with SQL and C API tests, see [SQLiteExtensionTemplate][template].

These scripts are an experimental use of SQLite's build internals. Their compatibility depends on the SQLite source version being built. The note is intended both as implementation documentation and as a basis for technical review of the use of `SQLITE_EXTRA_AUTOEXT`, the source transformations, and the interaction between modules compiled into both `sqlite3.c` and `shell.c`.

---

A few years ago, I experimented with a customized SQLite build process for integrating selected ordinary loadable extensions from `ext/misc` directly into the amalgamation and registering them as auto-extensions.

My primary target is the native Windows/MSVC build, although I have also used the same general approach with MinGW/MSYS2.

The original process required patching extension sources such as `ext/misc/csv.c`, patching `main.c`, and modifying parts of the build system, including `Makefile.msc` and `mksqlite3c.tcl`. It worked, but maintaining those changes across SQLite updates was unnecessarily cumbersome.

After revisiting the current source tree and build machinery, it appears that the integration can now be performed without modifying SQLite core sources or build files.

Three facilities in the SQLite source tree make this possible.

1. The `sqlite3.c` rule in `Makefile.msc` passes `$(EXTRA_SRC)` to the amalgamation generator after its regular arguments. [Makefile.msc][makefile]
2. `mksqlite3c.tcl` processes its stock source list and then appends the extra files in argument order. Its `copy_file_verbatim` routine trims trailing whitespace and emits file-boundary comments. It leaves C include directives for the compiler. [Amalgamation generator][amalgamator]
3. When `SQLITE_EXTRA_AUTOEXT` is defined, `main.c` declares `int SQLITE_EXTRA_AUTOEXT(sqlite3*)`. The `sqlite3BuiltinExtensions` array uses that same macro as a function name. [Connection initialization][main-c]

```c
#ifdef SQLITE_EXTRA_AUTOEXT
  SQLITE_EXTRA_AUTOEXT,
#endif
```

The build supplies the function name on the compiler command line.

```text
-DSQLITE_EXTRA_AUTOEXT=sqlite3ExtraAutoExtInit
```

With that definition, the array entry names `sqlite3ExtraAutoExtInit`. Its implementation is supplied through an extra source file, `misc_ext_init.c`. During `openDatabase()`, SQLite passes the new `sqlite3 *db` to each initializer in the array while the return code is `SQLITE_OK`. This is why the extension registers separately on each connection.

This reduces the required customization to preparation of the extension sources themselves. The remainder of the integration can be controlled through the build command line. The original discussion of Windows exports and `EXTRA_SRC` gives some background. [SQLite forum discussion][forum]

## Why the extension sources need preparation

`mksqlite3c.tcl` appends extra sources to the amalgamation after the SQLite core source.

An ordinary `ext/misc` loadable extension is generally written for a different compilation model.

* It includes `sqlite3ext.h`.
* It uses `SQLITE_EXTENSION_INIT1` and `SQLITE_EXTENSION_INIT2` to access the host's SQLite API table.
* It exports an entry point such as `sqlite3_csv_init()`.
* It may include private headers or auxiliary C sources.
* It may also be compiled separately into `shell.c`, creating the possibility of duplicate internal initializer names.

The extension sources therefore need to be adapted before they are passed through `EXTRA_SRC`.

I use two Tcl scripts for this preparation.

1. [`patch_sqlite_misc_autoext.tcl`][patcher] adapts the entry points and writes the dispatcher.
2. [`bundle_extra_src.tcl`][bundler] expands local header and C-source dependencies in the staged files.

My earlier workflow patched the original files under `ext/misc` in the SQLite source checkout. The current harness first runs NMake's `.target_source` target from `out\build`. It then copies the selected modules from `out\sqlite\ext\misc` into `out\build\tsrc` and runs both helpers there with SQLite's `out\build\jimsh0.exe`. The original files in the SQLite checkout are available for comparison with each transformation below. [MSVC build script][build-script]

## `patch_sqlite_misc_autoext.tcl`

The first script converts ordinary loadable-extension entry points into initializers that can be called from the built-in auto-extension registry.

It performs the following operations for each selected module.

### Conditional public-header setup

The patcher recognizes the usual loadable-extension prologue with either a quoted or an angle-bracket include. The quoted form reads as follows.

```c
#include "sqlite3ext.h"
SQLITE_EXTENSION_INIT1
```

The replacement selects the public header for the compilation mode.

```c
#ifndef SQLITE_CORE
  #include "sqlite3ext.h"
  SQLITE_EXTENSION_INIT1
#else
  #include "sqlite3.h"
#endif
```

When the source is incorporated into `sqlite3.c`, the extension uses the core SQLite declarations.

When it is compiled as a loadable extension, `SQLITE_EXTENSION_INIT1` declares the module's API-table pointer. The exported wrapper initializes it from the host's `pApi` argument before any registration calls. [SQLite extension API header][ext-header]

### Static initializer conversion

The CSV module has the conventional three-argument loadable-extension entry point. [Upstream CSV source][csv-source]

```c
int sqlite3_csv_init(
  sqlite3 *db,
  char **pzErrMsg,
  const sqlite3_api_routines *pApi
)
```

The patcher gives the registration body the one-argument signature expected by the built-in registry.

```c
int sqlite3CsvInit(sqlite3 *db)
```

The script removes the dynamic-loading setup that is no longer applicable inside the amalgamation, including `SQLITE_EXTENSION_INIT2(pApi)`. Calls in the body, such as `sqlite3_create_module(db, "csv", ...)`, still register against the supplied connection. Here “static” describes how the module is linked. The C function itself has external linkage.

The script also recognizes modules that already provide an initializer in the `sqlite3<Name>Init()` form. Such modules can be registered without converting an exported `sqlite3_<name>_init()` entry point.

### Preservation of loadable-extension support

For converted modules, the script appends a non-core wrapper that restores the conventional exported entry point.

```c
#ifndef SQLITE_CORE
#ifdef _WIN32
__declspec(dllexport)
#endif
int sqlite3_csv_init(
  sqlite3 *db,
  char **pzErrMsg,
  const sqlite3_api_routines *pApi
){
  (void)pzErrMsg;
  SQLITE_EXTENSION_INIT2(pApi);
  return sqlite3CsvInit(db);
}
#endif
```

At this stage the patched CSV source can still be built as an ordinary loadable extension against SQLite's public headers. On Windows the wrapper carries `__declspec(dllexport)`. The separate bundling step below prepares the copy for inclusion in `sqlite3.c` and removes its public-header includes. Use the header-bearing copy for a standalone build.

### Avoiding collisions between `sqlite3.c` and `shell.c`

Some modules may be incorporated into both the SQLite amalgamation and the shell build.

To prevent a non-core copy from defining the same internal initializer as the copy already present in `sqlite3.c`, the script inserts a conditional alias immediately before the initializer.

```c
#ifndef SQLITE_CORE
# define sqlite3CsvInit sqlite3CsvInit_Standalone
#endif
```

The initializer keeps its normal name when compiled as part of the SQLite core. A separately compiled copy receives a distinct symbol name.

This is relevant because `SQLITE_CORE` is defined while building the SQLite library core, but is not generally defined merely because a source is being compiled into the shell.

### Dispatcher generation

After processing the requested modules, the script generates `misc_ext_init.c`.

For each selected module it emits a guarded forward declaration. Here is the declaration for CSV.

```c
#ifdef SQLITE_ENABLE_CSV
int sqlite3CsvInit(sqlite3*);
#endif
```

It then emits the dispatcher referenced through `SQLITE_EXTRA_AUTOEXT`. With just CSV and Series in the registry, its body is as follows.

```c
int sqlite3ExtraAutoExtInit(sqlite3 *db){
  int rc = SQLITE_OK;

#ifdef SQLITE_ENABLE_CSV
  if( rc==SQLITE_OK ) rc = sqlite3CsvInit(db);
#endif

#ifdef SQLITE_ENABLE_SERIES
  if( rc==SQLITE_OK ) rc = sqlite3SeriesInit(db);
#endif

  return rc;
}
```

The generated guards follow the `SQLITE_ENABLE_<NAME>` convention. For a dynamic entry point such as `sqlite3_csv_init`, the guard is derived from `csv`. When only a core initializer is available, the patcher splits its CamelCase name. For example, `sqlite3StmtVtabInit` yields `SQLITE_ENABLE_STMT_VTAB`. These names come from the initializer. In the stock build, the file `rot13.c` uses `SQLITE_ENABLE_ROT`.

This allows the same prepared source set to be used with different build-time module selections. Omitting `SQLITE_ENABLE_CSV` skips its registration even when `csv.c` was appended to the amalgamation. With both guards defined, CSV runs first. If it returns an error, the dispatcher skips Series and returns that error to SQLite's connection-opening code.

### Idempotence

The patching operation is intended to be idempotent. On a second pass the patcher recognizes the converted initializer, conditional header block and collision alias. It reuses the existing wrapper.

The dispatcher also supports successive calls on different groups of files. The patcher reads the forward declarations in the existing `misc_ext_init.c`, merges registrations by initializer name and writes the declarations and calls in sorted order. A second pass for Series therefore retains a prior CSV registration. Repeating either pass gives the same dispatcher contents. When changing the module selection between configurations, use a fresh staging tree so the new selection starts with an empty registry. [Patcher implementation][patcher]

### Usage

Run the patcher with `tsrc` as its working directory and pass the staged source filenames. It writes `misc_ext_init.c` in that directory. For example, after the stock sources have been copied, run these commands from the harness root.

```cmd
cd /d out\build\tsrc
..\jimsh0.exe ..\..\..\tool\patch_sqlite_misc_autoext.tcl csv.c series.c
```

The patcher reports a missing file or an unrecognized initializer and skips that input. Inspect the generated declarations when adding a module with a different entry-point convention.

## `bundle_extra_src.tcl`

The second script prepares sources that depend on local headers or auxiliary C files.

Extra sources are inserted into the amalgamation as individual source bodies. A module may still contain local includes of this form.

```c
#include "decimal.h"
#include "some_internal_helper.c"
```

Those files must be available when the compiler reaches the appended source. An extension may also depend on the order in which their declarations and definitions become visible.

`bundle_extra_src.tcl` recursively expands such local includes in place. Run it from the same `tsrc` directory after patching. For the two modules above, the invocation is `..\jimsh0.exe ..\..\..\tool\bundle_extra_src.tcl csv.c series.c`.

### Complete include-graph validation

Before changing any file, the script scans the complete reachable local include graph.

* Each command-line target must be a bare `.c` or `.h` filename directly in `tsrc`. Discovered dependencies may be in subdirectories.
* Both `#include "name"` and `#include <name>` resolve relative to the root of `tsrc`, including directives inside nested headers. The bundler expands existing local files at each include site. A valid relative name absent from the staging tree passes through to the compiler. For example, `<unicode/ucol.h>` reaches the ICU include path.
* Absolute include paths and paths that escape the source tree through `..` or a resolved link are rejected.
* The local include graph must be acyclic. On a cycle the diagnostic identifies the chain of files involved.

The scanner recognizes literal include directives across backslash-newline splices, accounts for comments and quoted literals, and scans all conditional branches. Macro-based includes are left for the C preprocessor. A validation error stops the run before the first file is rewritten. [Bundler implementation][bundler]

### Dependency-first expansion

The discovered graph is ordered with dependencies before their includers.

Each included file is therefore fully expanded before its contents are substituted into a parent file.

For example, suppose the staged files contain these directives.

| File | Contents | Processing order |
| --- | --- | ---: |
| `module.c` | `#include "module.h"` | 3 |
| `module.h` | `#include "helper.h"` | 2 |
| `helper.h` | Contains the leaf definitions | 1 |

When `module.h` is inserted into `module.c`, it already contains the expanded contents of `helper.h`. PackedBlob is a practical example. Its hook copies the FP16 include tree into `tsrc` so the bundler can follow includes such as `<fp16/fp16.h>`. [PackedBlob build hook][pblob-hook]

### SQLite public headers

Two bare SQLite public-header names receive special treatment, including when those headers are present in `tsrc`.

```c
#include "sqlite3.h"
#include "sqlite3ext.h"
```

They are replaced with the comment `/* bundle_extra_src: sqlite public header already supplied */`. By the time a staged extension is appended to `sqlite3.c`, SQLite has already supplied the declarations needed in the core build.

### Section boundaries

Expanded files are surrounded by amalgamator-style comments.

```c
/************** Begin file helper.h ******************************************/
/* contents */
/************** End of helper.h **********************************************/
```

This preserves some visibility into the original source structure when inspecting the generated amalgamation. A literal `#pragma once` becomes a comment in the embedded copy. The source header keeps its own pragma.

### File preservation and replacement

The script preserves bytes outside the replaced directives, including mixed line endings and the final-newline state. Lines inserted at an include site use that directive's line ending.

Only files whose contents change are rewritten. For each one, the script writes and closes a temporary sibling before installing it. Under Jim Tcl on Windows it first moves the original to a backup. If installation fails, it tries to restore the original and reports the backup path if restoration also fails. Other supported environments use a forced rename of the staged file. The complete graph is validated up front, but installation proceeds one file at a time. Tracing goes to stderr by default. Set `BUNDLE_EXTRA_SRC_TRACE=0` to suppress it. The scanned and patched counts go to stdout.

## Combined source-preparation sequence

For the modules I currently integrate, the order is significant.

1. Run NMake's `.target_source` target from the build directory. Copy the selected `ext/misc` files into `tsrc` with SQLite's `tool/cp.tcl`. Stage any local headers and helper sources under the names used by their include directives.
2. Run `patch_sqlite_misc_autoext.tcl` on the staged extension entry points. This must happen while the original header prologues are still available to the patcher.
3. Run `bundle_extra_src.tcl` on the staged sources to inline their local dependencies.
4. Add the prepared module sources and the generated `misc_ext_init.c` to `EXTRA_SRC`. Define `SQLITE_EXTRA_AUTOEXT=sqlite3ExtraAutoExtInit` and the matching `SQLITE_ENABLE_*` guards in `OPT_XTRA`.
5. Run enabled project hooks against the same staging directory and dispatcher, then pass the complete `EXTRA_SRC` list to NMake.

The order of files in `EXTRA_SRC` controls which C definitions a later file can see. For example, `regexpmatches.c` uses the compiler and internal types from the stock `regexp.c`. The stock source must precede it in `sqlite3.c`. Both modules register their own SQL functions. The dispatcher can precede a project extension in the file list because it uses forward declarations. [RegexpMatches integration][regexp-integration]

### Adding a project extension

The stock stage (`SQLITE_EXTRA=1`) installs the dispatcher in `EXTRA_SRC` and sets `SQLITE_EXTRA_AUTOEXT`. The project stage (`USE_EXTRAS=1`) calls the sibling `sqlite_ext_*` scripts with no arguments. A hook stages its extension and headers, invokes the helpers, and appends its source and definitions to the caller's `EXTRA_SRC` and `OPT_XTRA`. The stock and project stages share the dispatcher, so leave both switches enabled for SQL registration of the three extensions in the full build. [Project extension hooks][hooks]

For a new extension, the template's alphabet hook shows how to register `alpha_string()`. Its CTD hook shows how to include plain C routines for direct tests. The template's single `sqlite_msbuild_extra.bat` preset exposes the C test APIs with the stock stage disabled. Its full-suite build enables the stock stage as well, so pytest can exercise both those exports through CFFI and the SQL function through Python's `sqlite3` module. [Alphabet hook][alphabet-hook] · [CTD hook][ctd-hook] · [Full-suite build instructions][template-build]

## Example MSVC build pipeline

The maintained `sqlite_msbuild.bat` demonstrates the complete integration in a Windows/MSVC build. Its paths are relative to the directory containing the script. [MSVC build script][build-script] · [Build guide][build-guide]

1. Select the build switches and verify the MSVC toolchain and Windows SDK. The helper can activate an installed x64 toolchain. For x86, start in an initialized x86 Native Tools prompt.
2. Download or reuse the SQLite source snapshot in `out\cache` and extract it into `out\sqlite`. When ZLIB is enabled, the harness builds or reuses it under `out\sqlite\compat\zlib`. The stock extension stage enables ZLIB for modules such as SQLAR.
3. When ICU is enabled, stage its headers, import libraries and runtime DLLs from an active Conda installation matching the target architecture. The MSVC harness uses that installation as its ICU provider.
4. Generate `tsrc`, select the stock modules and their compile definitions, and run the patcher and bundler. Run the project hooks after the stock stage. Both use SQLite's generated Jim Tcl interpreter.
5. Build the initial `sqlite3.def` and its prerequisite static library in `out\build`. The harness rebuilds the export definition from `dumpbin /linkermember:2 libsqlite3.lib`, then invokes NMake with the assembled sources and requested target. It regenerates the DLL import library with `lib.exe` for the target architecture. [Exports and import library][exports]
6. Collect the shell, SQLite DLL and enabled runtime DLLs in `out\bin`, the generated headers in `out\include`, `sqlite3.def` and the import library `sqlite3.lib` in `out\lib\import`, and the static library `libsqlite3.lib` in `out\lib\static`. [Packaged artifacts][artifacts]

The following four-module example shows how the build variables fit together inside the harness. It uses the harness's existing paths after `.target_source` has run. The production script specifies the full stock list, checks each helper's exit status and runs the project hooks before the final NMake build.

```cmd
set "MISC_EXT=csv.c decimal.c regexp.c series.c"
set OPT_XTRA=%OPT_XTRA% ^
    -DSQLITE_EXTRA_AUTOEXT=sqlite3ExtraAutoExtInit ^
    -DSQLITE_ENABLE_CSV ^
    -DSQLITE_ENABLE_DECIMAL ^
    -DSQLITE_ENABLE_REGEXP ^
    -DSQLITE_ENABLE_SERIES

cd /d "%SQLITEDIR%\ext\misc"
"%TCLSH_CMD%" "%SQLITEDIR%\tool\cp.tcl" %MISC_EXT% "%TSRC%"

cd /d "%TSRC%"
"%TCLSH_CMD%" "%TOOLDIR%\patch_sqlite_misc_autoext.tcl" %MISC_EXT%
"%TCLSH_CMD%" "%TOOLDIR%\bundle_extra_src.tcl" %MISC_EXT%

set EXTRA_SRC=%EXTRA_SRC% ^
    ""%TSRC%\csv.c"" ^
    ""%TSRC%\decimal.c"" ^
    ""%TSRC%\regexp.c"" ^
    ""%TSRC%\series.c"" ^
    ""%TSRC%\misc_ext_init.c""

cd /d "%BUILDDIR%"
nmake /nologo "EXTRA_SRC=%EXTRA_SRC%" "TOP=%SQLITEDIR%" /f "%SQLITE_MAKEFILE%"
```

The full script also configures ordinary SQLite facilities independently of the registration mechanism, including `SESSION=1`, `RBU=1` and `API_ARMOR=1`. The build guide lists the stock modules and the precise guard for each. [SQLite build settings and stock extensions][stock]

### Build and verify on Windows

From a `cmd.exe` prompt, open `SQLite-ICU-MinGW\Current\MSVC` in a checkout path without spaces. For the default build, activate a Conda environment containing ICU for the target architecture. Use a separate build base for each architecture or feature configuration. Build the shell and query all three project extensions on a fresh connection.

```cmd
cmd /d /c sqlite_msbuild.bat
out\bin\sqlite3.exe -list -noheader :memory: "SELECT str_casefold('ABC'), length(pblob_pack('[1,2]', '<f4')), regexp_matches('[0-9]+', 'a12b3');"
```

Expected output from the full build is one row.

```text
abc|12|["12","3"]
```

The middle value counts eight bytes for the two binary32 elements and four bytes for the PackedBlob trailer. To check an application's linkage and registrations, run the same query through a connection opened by that application. [MSVC registration checks][registration]

To exercise the two stock initializers in the dispatcher example, run the following statements on the same connection. The CSV module supplies the columns `c0` and `c1`. The Series module supplies the two values used in the join.

```sql
CREATE VIRTUAL TABLE temp.sample USING csv(data='alpha,42');
SELECT c0, c1, value
FROM sample CROSS JOIN generate_series(1, 2, 1)
ORDER BY value;
```

| c0 | c1 | value |
| --- | --- | ---: |
| alpha | 42 | 1 |
| alpha | 42 | 2 |

## Project family

| Project | What it provides |
| --- | --- |
| [SQLite-ICU-MinGW / Current][current] | Platform-specific SQLite builds, including [Windows/MSVC][msvc] and [Linux/GCC][gcc]. The full MSVC build combines stock `ext/misc` modules with the three extensions below. |
| [SQLiteExtensionTemplate][template] | A worked extension and test project. The alphabet example registers `alpha_string()`. Its pytest suites exercise SQL through Python's `sqlite3` module and call C routines through CFFI. |
| [SQLitePackedBlob][pblob] | `pblob_pack()` and `pblob_unpack()` convert between one-dimensional numeric JSON arrays and packed IEEE binary16 or binary32 BLOBs in either byte order. Uses SQLite's internal JSON routines and FP16 headers. |
| [SQLiteICUex][icuex] | Adds the `UTF_CI` and `UTF_CI_AI` collations, `str_casefold()` and `str_normalize()`. Uses public SQLite and ICU APIs and supports both built-in and loadable builds. |
| [SQLiteRegexpMatches][regexpmatches] | `regexp_matches()` and `regexpi_matches()` return successive non-overlapping matches as a JSON array. The module uses SQLite's JSON internals and the stock `ext/misc/regexp.c` compiler in the same translation unit. |

## Scripts

- [`sqlite_msbuild.bat`][build-script]
- [`patch_sqlite_misc_autoext.tcl`][patcher]
- [`bundle_extra_src.tcl`][bundler]

[current]: https://github.com/pchemguy/SQLite-ICU-MinGW/tree/master/Current/
[msvc]: https://github.com/pchemguy/SQLite-ICU-MinGW/tree/master/Current/MSVC
[gcc]: https://github.com/pchemguy/SQLite-ICU-MinGW/tree/master/Current/GCC
[template]: https://github.com/pchemguy/SQLiteExtensionTemplate
[pblob]: https://github.com/pchemguy/SQLitePackedBlob
[icuex]: https://github.com/pchemguy/SQLiteICUex
[regexpmatches]: https://github.com/pchemguy/SQLiteRegexpMatches
[makefile]: https://github.com/sqlite/sqlite/blob/master/Makefile.msc
[amalgamator]: https://github.com/sqlite/sqlite/blob/master/tool/mksqlite3c.tcl
[main-c]: https://github.com/sqlite/sqlite/blob/master/src/main.c
[regexp-integration]: https://github.com/pchemguy/SQLiteRegexpMatches#integration
[build-script]: https://github.com/pchemguy/SQLite-ICU-MinGW/blob/master/Current/MSVC/sqlite_msbuild.bat
[patcher]: https://github.com/pchemguy/SQLite-ICU-MinGW/blob/master/Current/MSVC/tool/patch_sqlite_misc_autoext.tcl
[bundler]: https://github.com/pchemguy/SQLite-ICU-MinGW/blob/master/Current/MSVC/tool/bundle_extra_src.tcl
[hooks]: https://github.com/pchemguy/SQLite-ICU-MinGW/blob/master/Current/MSVC/README.md#project-extension-hooks
[alphabet-hook]: https://github.com/pchemguy/SQLiteExtensionTemplate/blob/main/sqlite_ext_alphabet.bat
[ctd-hook]: https://github.com/pchemguy/SQLiteExtensionTemplate/blob/main/sqlite_ext_ctd.bat
[template-build]: https://github.com/pchemguy/SQLiteExtensionTemplate/blob/main/sqlite_msbuild.md#build-for-the-full-test-suite
[build-guide]: https://github.com/pchemguy/SQLite-ICU-MinGW/blob/master/Current/MSVC/README.md
[artifacts]: https://github.com/pchemguy/SQLite-ICU-MinGW/blob/master/Current/MSVC/README.md#packaged-artifacts
[forum]: https://sqlite.org/forum/info/903f721f3e7c0d25
[ext-header]: https://github.com/sqlite/sqlite/blob/master/src/sqlite3ext.h
[csv-source]: https://github.com/sqlite/sqlite/blob/master/ext/misc/csv.c
[pblob-hook]: https://github.com/pchemguy/SQLite-ICU-MinGW/blob/master/Current/MSVC/sqlite_ext_pblob.bat
[exports]: https://github.com/pchemguy/SQLite-ICU-MinGW/blob/master/Current/MSVC/README.md#exports-and-import-library
[stock]: https://github.com/pchemguy/SQLite-ICU-MinGW/blob/master/Current/MSVC/README.md#sqlite-build-settings-and-stock-extensions
[registration]: https://github.com/pchemguy/SQLite-ICU-MinGW/blob/master/Current/MSVC/README.md#post-build-registration-checks
