## Design Principles

The script is designed to download the latest binary release from GitHub using repository name (e.g., `jqlang/jq`). The script is coded for `cmd.exe`, has been developed and tested on Windows 10 LTSC 2021. The script relies on stock tools only. It uses `curl` for downloading and `tar` for extracting zip archives. The script also has an optional soft dependency on `jq` for analyzing GitHub JSON release metadata. The script will use installed `jq`, if available. Otherwise, it will download `jq` from GitHub. In case of failure, the script falls back to using the Windows `findstr` tool for RegEx-based analysis.

The script aims to handle two types of repos. Some repos use robust release naming convention where version number is not included in the file name (URL suffix), but each target platform has a version independent platform-specific name. The latest release for such repos (assuming they follow established modern conventions) can be downloaded directly without any metadata analysis using a template `https://github.com/<user>/<repo>/releases/latest/download/<release_name>`.

If the repo's naming convention includes version number in the filename (in addition to platform suffix), JSON file containing release metadata needs to be obtained first via `https://api.github.com/repos/<user>/<repo>/releases/latest`. Assuming, the naming convention is still sufficiently robust, actual asset URL can the be extract from the `browser_download_url` using platform-specific suffix for matching.

The main script is structured as a modular code file following a pseudo-procedural organization. The first block of the script (`:HELP`) is the module's "docstring" that also serves as a help message printed to console, if requested via conventional command line argument (at presently, the help option is the only processed command line argument).

The second code block `:MAIN`, as the name suggests, orchestrates high-level workflows by calling subroutines implementing specific functionality. The subroutine blocks are placed after the main block, aiming to follow the single well-defined responsibility per routine design principle. The core routines include `:RETRIEVE_ASSET_URL` responsible for downloading release metadata and extracting specific asset URL. This routine is called by the primary download entry, `:ASSET_DOWNLOAD`, if necessary.

Two other small routines are responsible for setting cache directory (`:CACHE_DIR`) and console color scheme (`:ESCAPE_COLORS`).

The script is designed to be verbose for troubleshooting potential issues, and ANSI escape sequences are used to structure output with color code. To limit mixing escape sequences with batch code and allow for increased flexibility, `:ESCAPE_COLORS` sets environment variables, which are then used throughout the code. This approach also avoids another potential subtle pitfall - having the special `ESC`  character dispersed throughout the file. Because of its special nature, the `ESC` character may cause issues under specific condition, including complete loss. The script uses this character only twice within the dedicated `:ESCAPE_COLORS` routine, mitigating potential issues.

The code strives to perform careful explicit error checking for all critical operations, including file system and network operations, as well as utility use. The primary goal, as usual, is to identify a critical error as soon as possible and fail early with a clear and meaningful error message rather then letting the script proceed with normal logic after failed operations.

The script does not implement command line interface. All processing workflow is mediated via environment variables. While this approach breaks code block "encapsulation", complicating testability, the limited ability of `cmd.exe` environment supporting only positional parameters in calls makes variable-based approach convenient, though it should be used carefully.

Whenever possible, subroutine calls should be wrapped in `setlocal/endlocal` to avoid uncontrollable changes to the caller's environment. On the other hand, this sandbox also makes it problematic to return any output to the caller via environment variables. Still, there is a known `feature` of `cmd.exe` scripts: if `set` commands are stringed after the `endlocal` command, e.g.,

```batch
EndLocal & (set "JQ=%JQ%") & (set "CACHE=%CACHE%") & exit /b %EXIT_STATUS%
```
such variable values are actually preserved in the caller's environment.

The script uses several environment variables which should be set by the caller to identify the target release

| Variable             | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `COMMON_NAME`        | Short label used for caching/logging (e.g. `JQ`)                                                                                                                                                                                                                                                                                                                                                                                                                       |
| `REPO_NAME`          | GitHub repository in `owner/repo` form                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `RELEASE_URL_SUFFIX` | The last part of release URL acting as filename for direct mode                                                                                                                                                                                                                                                                                                                                                                                                        |
| `DOWNLOAD_EXT`       | File extension, e.g., `.zip`, that is not part of the download URL, but should be added to filename defined by `RELEASE_URL_SUFFIX`; must include the dot.                                                                                                                                                                                                                                                                                                             |
| `ASSET_URL_SUFFIX`   | Pattern used to match asset in indirect mode (string suffix, e.g. `x64.exe`)                                                                                                                                                                                                                                                                                                                                                                                           |
| `SPECIFIC_NAME`      | This name, if defined will be used as a source in rename operation. It may be necessary if release is provided as ZIP, which is extracted by the script, and the name of the extracted file does not match the name of the archive. (Alternatively, the script could also run `dir` command after extraction to identify extracted file name, but their might be more that one file in the archive, so this automatic renaming approach is not currently implemented). |
| `CANONICAL_NAME`     | Final name for the downloaded/extracted file (used to rename the downloaded file, which would normally be named as `%RELEASE_URL_SUFFIX%%DOWNLOAD_EXT%`)                                                                                                                                                                                                                                                                                                               |

The script produces several variables as output. Note that `CACHE` and `JQ` presently can be overridden, if set before calling the script.

| Variable   | Description                                  |
| ---------- | -------------------------------------------- |
| `CACHE`    | Optional override for cache directory        |
| `PREFIX`   | Computed: `%CACHE%\%COMMON_NAME%`            |
| `EXE_NAME` | Computed: `%PREFIX%\%CANONICAL_NAME%`        |
| `JQ`       | Computed: path to `jq.exe`, may be overriden |

Several other variables act as flags affecting produced console output:

| Variable               | Description                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------------ |
| `UPDATE_CACHE`         | if defined, existing cache is deleted (except for JQ)                                                        |
| `NO_TOP_BAR`           | if defined, skips top bar in console output                                                                  |
| `NO_BOTTOM_BAR`        | if defined, skips bottom bar in console output                                                               |
| `ESCAPE_COLORS_SILENT` | if defined, suppresses ESCAPE_COLORS confirmation                                                            |
| `BLOCK_TYPE`           | if defined, selects block label style: accepted values include `<undefined>`(i.e, unset), `ODD`, and `EVEN`. |
