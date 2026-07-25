# Integrating ordinary `ext/misc` loadable extensions into the amalgamation as auto-extensions

I have revisited an old custom SQLite build process that embeds selected ordinary loadable extensions from `ext/misc` directly into the amalgamation and registers them as auto-extensions. This pipeline (primarily implemented for MSVC, but also MinGW/MSYS2) relied on patching extension sources, `main.c`, `Makefile.msc`, and `mksqlite3c.tcl`.

With the current SQLite build machinery, the core and build-file patches no longer appear necessary:

1. `Makefile.msc` accepts additional sources through `EXTRA_SRC`.
2. `mksqlite3c.tcl` incorporates those sources into the amalgamation.
3. `sqlite3BuiltinExtensions` contains this hook:

```c
#ifdef SQLITE_EXTRA_AUTOEXT
  SQLITE_EXTRA_AUTOEXT,
#endif
```

The build can therefore define:

```text
-DSQLITE_EXTRA_AUTOEXT=sqlite3ExtraAutoExtInit
```

and provide `sqlite3ExtraAutoExtInit()` through an extra source file.

See also a related discussion of `EXTRA_SRC` is [here](https://sqlite.org/forum/info/903f721f3e7c0d25).

## Source preparation

Ordinary `ext/misc` modules are generally written as loadable extensions. They include `sqlite3ext.h`, use `SQLITE_EXTENSION_INIT1/2`, and export entry points such as `sqlite3_csv_init()`. I use two TCL scripts to prepare selected modules. The key script is `patch_sqlite_misc_autoext.tcl`.

### `patch_sqlite_misc_autoext.tcl`

For each selected module, this script:

* makes the `sqlite3ext.h` setup conditional on `SQLITE_CORE`;
* converts a dynamic entry point such as `sqlite3_csv_init()` into a core-callable initializer such as `sqlite3CsvInit(sqlite3*)`;
* retains a non-core wrapper so that the prepared source can still be built as a loadable extension;
* conditionally renames the non-core initializer to avoid collisions when the same module is present in both `sqlite3.c` and `shell.c`;
* recognizes modules that already provide a `sqlite3<Name>Init()` initializer;
* generates `misc_ext_init.c`, containing guarded declarations and the aggregate `sqlite3ExtraAutoExtInit()` dispatcher.

For example, the generated dispatcher contains code of this form:

```c
#ifdef SQLITE_ENABLE_CSV
int sqlite3CsvInit(sqlite3*);
#endif

int sqlite3ExtraAutoExtInit(sqlite3 *db){
  int rc = SQLITE_OK;

#ifdef SQLITE_ENABLE_CSV
  if( rc==SQLITE_OK ) rc = sqlite3CsvInit(db);
#endif

  return rc;
}
```

The source transformations are intended to be idempotent.

## Build sequence

The resulting build sequence is:

1. Run `patch_sqlite_misc_autoext.tcl` on the selected `ext/misc` sources.
2. Define the corresponding `SQLITE_ENABLE_*` macros.
3. Define `SQLITE_EXTRA_AUTOEXT=sqlite3ExtraAutoExtInit`.
4. Add the prepared sources and generated `misc_ext_init.c` to `EXTRA_SRC`.
5. Invoke the normal `Makefile.msc` build.

Conceptually:

```bat
set OPT_XTRA=%OPT_XTRA% ^
    -DSQLITE_EXTRA_AUTOEXT=sqlite3ExtraAutoExtInit ^
    -DSQLITE_ENABLE_CSV ^
    -DSQLITE_ENABLE_DECIMAL ^
    -DSQLITE_ENABLE_REGEXP ^
    -DSQLITE_ENABLE_SERIES

tclsh patch_sqlite_misc_autoext.tcl %MISC_EXT%

nmake /f Makefile.msc "TOP=%DISTRODIR%" "EXTRA_SRC=%EXTRA_SRC%"
```

I have also included a complete MSVC batch pipeline that downloads and builds SQLite, optionally builds ZLIB and ICU, prepares the selected modules, builds from a separate directory, and collects the resulting binaries.

The full explanation and all scripts are available [here](https://github.com/pchemguy/Field-Notes/blob/main/11-sqlite-msvc-build/README.md).
