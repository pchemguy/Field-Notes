<!--
https://gemini.google.com/app/538f45fab101cefe
-->

# A Robust Script for Managing GitHub Binary Releases

This document provides a detailed technical overview of [GitHubRelease.bat](https://github.com/pchemguy/Field-Notes/blob/main/04-github-release-download/GitHubRelease.bat), a command-line script for downloading and caching the latest binary releases from GitHub repositories. It is designed for `cmd.exe` (no PowerShell dependence) on Windows and relies on native or commonly available tools.

## Overview

`GitHubRelease.bat` automates the process of fetching the latest binary asset from a GitHub release. It is built to be robust, verbose, and configurable, serving as a reliable tool in larger automation workflows. The script handles caching to minimize redundant downloads, supports both direct and metadata-driven downloads, and can extract `.zip` archives automatically.

Its entire workflow is controlled via environment variables, making it easy to integrate into other scripts without a complex command-line interface. For troubleshooting, it produces detailed, color-coded console output using ANSI escape sequences.

## Features

- **Two Download Modes:**    
    - **Direct Download:** For repositories with version-independent release URLs (e.g., `/latest/download/app-windows.exe`).
    - **Indirect (Metadata) Download:** For repositories where release asset URLs include version numbers. The script fetches release metadata from the GitHub API and parses it to find the correct download URL.
- **Download Caching:** Downloads are stored in a local cache directory. The script checks for an existing file before initiating a new download. The cache can be forcefully updated via a flag.
- **Archive Handling:** Automatically detects and extracts `.zip` files using `tar.exe` after download.
- **Metadata Parsing:** Uses `jq.exe` to parse GitHub's JSON metadata for high accuracy. If `jq` is not available, it will first attempt to download it. As a final resort, it gracefully falls back to the native Windows `findstr.exe` utility for RegEx-based parsing.
- **Error Handling:** The script performs checks for all critical operations (dependency availability, network requests, file system actions) and exits early with a clear error message upon failure.
- **Configurability:** All behavior is controlled through a clear set of environment variables.
- **Included Testing:** The script includes internal routines for self-testing, which are executed if no external repository is specified. A companion [GitHubRelease_Test.bat](https://github.com/pchemguy/Field-Notes/blob/main/04-github-release-download/GitHubRelease_Test.bat) script provides more extensive test cases.

See sample log [screenshots](./Screenshots.md).
## Prerequisites

The script requires the following command-line utilities to be available in your system's `PATH`:
- `curl.exe`: Used for all network operations (downloading assets and metadata).
- `tar.exe`: Used for extracting `.zip` archives.

Windows 10 and later typically include both `curl.exe` and `tar.exe` by default.

## Usage

To use the script, you must first set a series of environment variables to define the target repository and the desired asset. Then, simply execute the script.

### Example: Downloading the latest `pixi` release

This example demonstrates how to download `pixi`, which is a zipped executable.

```batch
:: Set the variables to configure the download
set "COMMON_NAME=PIXI"
set "REPO_NAME=prefix-dev/pixi"
set "RELEASE_URL_SUFFIX=pixi-x86_64-pc-windows-msvc.zip"
set "CANONICAL_NAME=pixi.exe"
set "SPECIFIC_NAME=pixi.exe"

:: These are unset for this specific download type
set "ASSET_URL_SUFFIX="
set "DOWNLOAD_EXT="

:: Execute the script
call GitHubRelease.bat
```

## Configuration via Environment Variables

The script's behavior is entirely controlled by environment variables. They are categorized below as **Input Variables** (required for configuration), **Control Flags** (optional flags to modify behavior), and **Output Variables** (set by the script upon completion).

### Input Variables

| Variable             | Description                                                                                                                                                                                                                                                                                                             |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `COMMON_NAME`        | A short, descriptive name (e.g., "JQ"). Used for console logging and as the name of the cache subdirectory.                                                                                                                                                                                                             |
| `REPO_NAME`          | The target GitHub repository in `owner/repo` format (e.g., `jqlang/jq`).                                                                                                                                                                                                                                                |
| `RELEASE_URL_SUFFIX` | **Direct Mode:** The final part of the download URL (the asset's filename). **Indirect Mode:** The filename to save the downloaded asset as, since the remote name is not used directly.                                                                                                                                |
| `ASSET_URL_SUFFIX`   | **The key variable that controls the download mode.** If **unset**, the script attempts a **direct download**. If **set**, the script performs an **indirect download** by querying release metadata15. The value is a string used to match against the `browser_download_url` field in the metadata (e.g., `x64.exe`). |
| `DOWNLOAD_EXT`       | An optional file extension (including the dot) to append to the downloaded filename. Useful when the extension is not part of the `RELEASE_URL_SUFFIX`. For instance, if `RELEASE_URL_SUFFIX` is `my-app` and `DOWNLOAD_EXT` is `.zip`, the file is saved as `my-app.zip`.                                              |
| `CANONICAL_NAME`     | The final, desired name for the executable (e.g., `jq.exe`). If set, the script will rename the downloaded or extracted file to this name.                                                                                                                                                                              |
| `SPECIFIC_NAME`      | The name of the executable _inside_ a `.zip` archive. This is only needed if `CANONICAL_NAME` is set and the executable's name within the archive is different from what the script would guess. If not defined, the script guesses the name based on the archive name.                                                 |

### Control Flags

| Variable               | Description                                                                                                                                                                            |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `UPDATE_CACHE`         | If defined (e.g., `set "UPDATE_CACHE=1"`), the script will delete the existing cache directory for the `COMMON_NAME` before downloading. This does not apply to the `JQ` tool's cache. |
| `NO_TOP_BAR`           | If defined, suppresses the decorative top bar in the console output.                                                                                                                   |
| `NO_BOTTOM_BAR`        | If defined, suppresses the decorative bottom bar in the console output.                                                                                                                |
| `ESCAPE_COLORS_SILENT` | If defined, suppresses the initial confirmation message that ANSI color variables have been set.                                                                                       |
| `BLOCK_TYPE`           | Sets the background color style for the `COMMON_NAME` label in the output. Can be set to `ODD` or `EVEN` for different colors.                                                         |
   
### Output Variables

These variables are set by the script and will be available in the calling environment.

| Variable   | Description                                                                                            |
| ---------- | ------------------------------------------------------------------------------------------------------ |
| `EXE_NAME` | The final, absolute path to the ready-to-use executable file.                                          |
| `JQ`       | The absolute path to the `jq.exe` executable, whether it was pre-existing or downloaded by the script. |
| `CACHE`    | The absolute path to the main cache directory used by the script.                                      |

## Operational Modes Explained

The script's logic hinges on whether the `ASSET_URL_SUFFIX` variable is set.

### Direct Download Mode (`ASSET_URL_SUFFIX` is unset)

This is the simplest mode, used when a repository provides a predictable, version-agnostic URL for its latest release. The script constructs the download URL using the following template: `https://github.com/<REPO_NAME>/releases/latest/download/<RELEASE_URL_SUFFIX>`. This mode is fast and efficient as it avoids the overhead of an API call to GitHub.

### Indirect Download Mode (`ASSET_URL_SUFFIX` is set)

This mode is necessary when release asset filenames contain version numbers, making the direct URL unpredictable. The script follows a multi-step process:
1. **Fetch Metadata:** It makes an API call to `https://api.github.com/repos/<REPO_NAME>/releases/latest` to retrieve a JSON object containing details about the latest release. This metadata is cached as a `.json` file to avoid repeated API calls.
2. **Parse Metadata:** It searches the JSON for an asset where the `browser_download_url` field ends with the string specified in `ASSET_URL_SUFFIX`.
    - **JQ:** The preferred method uses `jq` to parse the JSON and extract the URL. The script escapes `.` characters in the suffix to ensure they are treated as literal characters in the regex.
    - **Findstr Fallback:** If `jq` fails or is not available, the script falls back to using `findstr` with a regular expression to find the matching URL line in the raw JSON file.
3. **Download Asset:** Once the URL is extracted, `curl` is used to download the asset33. The asset is saved locally with the filename provided in `RELEASE_URL_SUFFIX`, not the filename from the extracted URL.

## Code Structure & Design Philosophy

The script is written as a modular `cmd.exe` batch file, organized into pseudo-procedural routines marked by labels.

### Core Routines

- **:MAIN:** The top-level block that orchestrates the entire workflow. It checks for dependencies, initializes the cache directory, ensures `jq` is available, and then calls the main download routine. It also includes sections for self-testing if invoked without a `REPO_NAME`.
- **:ASSET_DOWNLOAD:** The primary workhorse routine38. It handles cache management (checking, creating, and clearing), determines the final executable path, invokes the download, and manages the subsequent extraction and renaming steps.
- **:RETRIEVE_ASSET_URL:** This routine implements the logic for the indirect download mode. It fetches and caches the release metadata and then attempts to parse it with `jq`, falling back to `findstr` on failure.
- **:CACHE_DIR:** A helper routine that determines the appropriate cache directory location by checking several standard locations (`%~dp0CACHE`, `%USERPROFILE%\Downloads`, etc.).
- **:ESCAPE_COLORS:** A dedicated setup routine that defines all ANSI escape sequence variables used for coloring the console output. This isolates the special `ESC` character and makes the main script logic cleaner.

### Technical Design Choices

- **Environment Variable Interface:** The script exclusively uses environment variables for configuration. While this can complicate testability, it is a convenient and straightforward approach within the limitations of `cmd.exe`, which only supports simple positional parameters.
- **Scope Management:** `setlocal` and `endlocal` are used within routines to prevent variables from polluting the global scope. To return values to the caller, the script uses a known `cmd.exe` feature where `set` commands chained after `endlocal` are executed in the caller's context:

```
endlocal & (set "JQ=%EXE_NAME%") & exit /b %EXIT_STATUS%
```

- **Early Failure:** The script diligently checks the `ERRORLEVEL` after every critical operation (`md`, `rmdir`, `curl`, `tar`, `move`). If an error is detected, it prints a specific message and exits immediately, preventing further issues down the line.

## Testing

The project includes [GitHubRelease_Test.bat](https://github.com/pchemguy/Field-Notes/blob/main/04-github-release-download/GitHubRelease_Test.bat), a companion script that serves as a test suite. It invokes `GitHubRelease.bat` multiple times with different configurations to validate its functionality and robustness across various scenarios, including:
- Successful direct and indirect downloads.
- Expected failures from bad repository names.
- Correct fallback from `jq` to `findstr`.
- Handling of malformed `.zip` files.
- Failure when the cache directory is read-only.
