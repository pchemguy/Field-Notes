---
urls:
  - https://chatgpt.com/c/6a648dd8-677c-83eb-ae07-14535c01617c
  - https://chatgpt.com/c/6b06fe46-69fc-83ea-ac08-dfcb73d17b8b
---

# Integrating Ordinary Loadable Extensions into the Amalgamation as Auto-Extensions

## Summary

An application linked to a customized SQLite library can use selected extensions as soon as it opens a connection. The build appends their C sources to `sqlite3.c` through `EXTRA_SRC`. SQLite then calls a single initializer, selected by `SQLITE_EXTRA_AUTOEXT`, to register their SQL functions, collations and virtual table modules on each connection.

For the maintained Windows build, its scripts and prerequisites, start with [SQLite-ICU-MinGW → Current/MSVC][msvc]. For a worked example of writing an extension and testing both its SQL interface and its C implementation, start with [SQLiteExtensionTemplate][template].

## 1. Project family

| Project | What it provides |
| --- | --- |
| [SQLite-ICU-MinGW / Current][current] | Platform-specific SQLite builds, including [Windows/MSVC][msvc] and [Linux/GCC][gcc]. The full MSVC build combines stock `ext/misc` modules with the three extensions below. |
| [SQLiteExtensionTemplate][template] | A development and test project. The `alphabet` example registers `alpha_string()`. Its pytest suite exercises SQL through Python’s `sqlite3` module and calls C routines directly through CFFI. |
| [SQLitePackedBlob][pblob] | `pblob_pack()` and `pblob_unpack()` convert between one-dimensional numeric JSON arrays and packed IEEE binary16 or binary32 BLOBs in either byte order. Uses SQLite’s internal JSON routines and FP16 headers. |
| [SQLiteICUex][icuex] | Adds the `UTF_CI` and `UTF_CI_AI` collations, `str_casefold()` and `str_normalize()`. Uses public SQLite and ICU APIs and supports both built-in and loadable builds. |
| [SQLiteRegexpMatches][regexpmatches] | `regexp_matches()` and `regexpi_matches()` return successive non-overlapping matches as a JSON array. The module uses SQLite’s JSON internals and the stock `ext/misc/regexp.c` compiler in the same translation unit. |

## 2. From C source to an open connection

My earlier MSVC build patched `main.c`, `Makefile.msc` and `mksqlite3c.tcl`. The current harness uses SQLite’s existing build files and connects the prepared extension sources to the database-open path in three steps.

1. **Append the sources.** `Makefile.msc` passes `EXTRA_SRC` to `mksqlite3c.tcl`. The generator appends those files in the supplied order after the core sources. It copies their bodies without processing their local includes. [Makefile.msc][makefile] · [Amalgamation generator][amalgamator]
2. **Connect the initializer.** The build defines `-DSQLITE_EXTRA_AUTOEXT=sqlite3ExtraAutoExtInit`. With that definition, `src/main.c` declares `int sqlite3ExtraAutoExtInit(sqlite3*)` and includes it in the `sqlite3BuiltinExtensions` array. SQLite calls it with the new database handle during connection initialization. [SQLite connection initialization][main-c]
3. **Select the registrations.** The generated `misc_ext_init.c` defines `sqlite3ExtraAutoExtInit()`. Each module has a `SQLITE_ENABLE_*` guard. The dispatcher starts with `SQLITE_OK`, calls the enabled initializers in sequence and returns the first error. For example, CSV contributes this branch to the dispatcher.

```c
#ifdef SQLITE_ENABLE_CSV
  if( rc==SQLITE_OK ) rc = sqlite3CsvInit(db);
#endif
```

Source order matters when one extension uses another module’s internal routines. For example, the stock `regexp.c` must precede `regexpmatches.c` in `sqlite3.c`. The two modules register different SQL functions. [RegexpMatches integration][regexp-integration]

## 3. Preparing stock modules and project extensions

The harness runs NMake’s `.target_source` target from `out\build`, then copies selected stock modules from `out\sqlite\ext\misc` into `out\build\tsrc`. All extension edits happen in the staging tree. The harness runs both Tcl helpers there with SQLite’s `out\build\jimsh0.exe`, passing the staged filenames. [MSVC build script][build-script]

**Adapt the initializer.** For a conventional entry point such as `sqlite3_csv_init(db, pzErrMsg, pApi)`, the patcher creates `sqlite3CsvInit(sqlite3 *db)` for the core. With `SQLITE_CORE` defined, the patched prologue includes `sqlite3.h`. The loadable build uses `sqlite3ext.h` and `SQLITE_EXTENSION_INIT1`. The non-core wrapper initializes the API table with `SQLITE_EXTENSION_INIT2(pApi)` and calls the same registration routine. A `_Standalone` alias gives a separately compiled non-core copy its own initializer symbol when a module appears in both the library and the shell. The patcher also recognizes existing core initializers. On successive runs it merges their declarations into `misc_ext_init.c`, so project hooks can extend the stock dispatcher. [`patch_sqlite_misc_autoext.tcl`][patcher] · [SQLite forum discussion of Windows exports and `EXTRA_SRC`][forum]

**Bundle local dependencies.** The bundler resolves quoted and angle-bracket literal includes from the root of `tsrc`, including those found in nested headers. It inlines existing local files, replaces bare `sqlite3.h` and `sqlite3ext.h` includes with comments, and leaves a valid relative include for the compiler when its target is absent from `tsrc` (for example, `<unicode/ucol.h>`). It checks the reachable graph for cycles and paths escaping `tsrc` before rewriting files in dependency order. This lets a module such as PackedBlob bring its nested FP16 headers into the amalgamation. [`bundle_extra_src.tcl`][bundler]

**Add project hooks.** `SQLITE_EXTRA=1` prepares the stock modules, adds `misc_ext_init.c` to `EXTRA_SRC` and sets `SQLITE_EXTRA_AUTOEXT`. `USE_EXTRAS=1` then runs the sibling `sqlite_ext_*` hooks. Each shipped extension hook stages its source and dependencies, updates the dispatcher, appends its C source to `EXTRA_SRC` and adds its feature definition to `OPT_XTRA`. Keep both switches enabled for the three project extensions in the full MSVC build. [Project extension hooks][hooks]

For a new extension, the template’s alphabet hook shows how to add a module with a SQL initializer. Its CTD hook shows how to include plain C routines for direct tests. The template’s single `sqlite_msbuild_extra.bat` preset exports the C APIs with the stock stage disabled. Use the template’s SQL-enabled build for the full pytest suite, including `alpha_string()` registration. [Alphabet hook][alphabet-hook] · [CTD hook][ctd-hook] · [Full-suite build instructions][template-build]

## 4. Build and verify on Windows

Install the MSVC C++ Build Tools and Windows SDK. Open `cmd.exe` in `SQLite-ICU-MinGW\Current\MSVC` using a checkout path without spaces, and activate a Conda environment with ICU for the target architecture. The harness can activate installed x64 tools. For x86, start in an initialized x86 Native Tools prompt with matching x86 ICU. Use a separate build base for each architecture or feature configuration. [MSVC build guide][build-guide]

With its default switches, the harness stages ICU from Conda and builds or reuses ZLIB for the stock extensions. Run the build, then query all three project extensions on a fresh connection in the packaged shell.

```cmd
cmd /d /c sqlite_msbuild.bat
out\bin\sqlite3.exe -list -noheader :memory: "SELECT str_casefold('ABC'), length(pblob_pack('[1,2]', '<f4')), regexp_matches('[0-9]+', 'a12b3');"
```

The full build returns the following row. The middle value counts eight bytes for two binary32 values and four bytes for the PackedBlob trailer.

```text
abc|12|["12","3"]
```

The shell and runtime DLLs go to `out\bin`, SQLite headers to `out\include`, the DLL import library to `out\lib\import` and the static library to `out\lib\static`. To verify registration in an application, run the same query through that application’s own SQLite connection. [Packaged artifacts][artifacts]

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
