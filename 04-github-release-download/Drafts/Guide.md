# Downloading the latest GitHub release - annotated walkthrough

**Purpose:** detailed, structured guide for the `GitHubRelease.bat` toolkit for a power user/admin to quickly get the full picture, follow the details, and extend or troubleshoot the script. This text is written as a technical Field Notes post for _power users_ familiar with Windows batch scripting and GitHub; advanced bits (GitHub API parsing, `curl` options, escape patterns, extraction behavior) are explained in depth.

**Tested platform:** **Windows 10 LTSC 2021** (this is the environment the script was written / tested for).

## Quick summary

`GitHubRelease.bat` is a small, pragmatic Windows batch utility to **fetch and cache the latest GitHub release asset** for a repository. It supports two modes: _direct_ downloads (construct a known `download` URL) and _indirect_ downloads (query the GitHub Releases API, parse JSON, locate the desired asset URL by suffix matching, then download). The script expects `curl.exe` and `tar.exe` to be available and uses a local cache directory to avoid repeated downloads. It also optionally downloads and uses `jq.exe` (if not already present) to parse release metadata.

## Table of contents

1. Goals & design assumptions    
2. Prerequisites and environment
3. Primary modes: DIRECT vs INDIRECT (how the script decides what to do)
4. Important variables (what you set and what the script computes)
5. Control flow (high-level flowchart + step-by-step)
6. Key functions and implementation notes
    - `:CACHE_DIR`
    - `:JQ_DOWNLOAD`
    - `:ASSET_DOWNLOAD`
    - `:RETRIEVE_ASSET_URL` (jq + findstr fallback)
    - Extraction & rename behavior
7. Examples (how to use it for `jq`, `micromamba`, `libjpeg-turbo`)
8. Error handling, exit codes & common failures
9. Security, reliability & improvement ideas
10. Appendix: variable reference & sample invocations

---

# 1. Goals & design assumptions

- The script is **not** a generic release automation tool. It’s a local _cached downloader_ for the **latest** binary release from GitHub.
    
- Target audience: power users / system administrators who run Windows batch scripts and want a small, portable way to retrieve release assets for later scripting (installers, portable `.exe`, archive assets).
    
- It prefers **tools available on modern Windows** (e.g., `curl` bundled with newer Windows or installed manually) and uses `tar` for archive extraction. `jq` is used to parse JSON metadata and is downloaded into the cache if missing.
    
- Caching is important: this reduces bandwidth and avoids repeated API calls.
    

---

# 2. Prerequisites & environment

- **Windows 10 LTSC 2021** (tested). Behavior on other Windows versions may vary.
    
- **Required utilities on PATH:**
    
    - `curl.exe` — used for both metadata (API) fetch and asset downloads. The script uses `curl --fail --retry 3 --retry-delay 2 -L -o ...` for downloads.
        
    - `tar.exe` — used to extract archive assets (the script uses `tar -xf`). On Windows, `tar` can be the native one shipped with modern Windows or a shipped GNU/bsdtar.
        
- **Optional:** `jq.exe` — used to parse GitHub release JSON. If not found, the script attempts to fetch and cache the latest `jq.exe` itself. There is a fallback parser using `FINDSTR` if `jq` extraction fails.
    
- Environment variables (see next section) must be set before invoking the script (the script deliberately does not provide a command-line interface). Example usage: set variables in caller script or interactive session, then `call "GitHubRelease.bat"`.
    

---

# 3. PRIMARY MODES: DIRECT vs INDIRECT

The script supports two download methods:

**DIRECT** (simple, predictable URL construction)

- If `ASSET_URL_SUFFIX` is **unset**, the script constructs a direct download URL of the form:
    
    ```
    https://github.com/<owner>/<repo>/releases/latest/download/<RELEASE_URL_SUFFIX>
    ```
    
- This is the simplest path — you provide the exact uploaded asset filename as `RELEASE_URL_SUFFIX`, e.g. `jq-win64.exe`.
    

**INDIRECT** (query the GitHub Releases API & parse assets)

- If `ASSET_URL_SUFFIX` is **set**, the script:
    
    1. Fetches `https://api.github.com/repos/<owner>/<repo>/releases/latest` into a JSON file (`%META_FILE%`).
        
    2. Uses `jq` to find an asset whose `browser_download_url` matches a pattern (suffix matching on `ASSET_URL_SUFFIX`) and writes that `browser_download_url` to a temporary file.
        
    3. Reads that URL into `%ASSET_URL%` and downloads it with `curl`.
        
- This mode is useful when release asset names encode platform/arch metadata and you only know a suffix pattern (e.g., `-win64.zip` or `vc-x64.exe`), or when you want to select among multiple assets automatically.
    

> Important: The script has both a `jq`-based extractor and a `FINDSTR` fallback. The `jq` approach is robust (proper JSON parsing). The `FINDSTR` path is less robust but useful on systems where `jq` cannot be used.

---

# 4. Important variables (what you set; examples)

> You should set variables before `call "GitHubRelease.bat"` (or within wrapper scripts).

Core variables:

- `REPO_NAME` — GitHub repository in `owner/repo` form.  
    Example:
    
    ```bat
    set "REPO_NAME=jqlang/jq"
    ```
    
- `ASSET_URL_SUFFIX` — (optional) suffix to match in `browser_download_url` (regex-like). If set, script uses indirect mode.  
    Example:
    
    ```bat
    set "ASSET_URL_SUFFIX=x64.exe"
    ```
    
- `RELEASE_URL_SUFFIX` — filename used for direct downloads (used to build the `/download/<filename>` URL or to name the local download). Example:
    
    ```bat
    set "RELEASE_URL_SUFFIX=jq-win64.exe"
    ```
    
- `COMMON_NAME` — short label used for logging / cache folder name. Example `JQ`.
    
- `CANONICAL_NAME` — final filename you want in the cache/target path (e.g., `jq.exe`). When set, the script will attempt to rename the downloaded/extracted file to that canonical name.
    
- `SPECIFIC_NAME` — if the asset contains a platform-specific name inside an archive and you need to identify it for renaming. If unset, the script guesses based on download filename.
    

Other computed vars:

- `CACHE` — path to the cache dir (computed by `:CACHE_DIR` if not provided). The script tries several locations and falls back to `%TEMP%`.
    
- `PREFIX` — `"%CACHE%\%COMMON_NAME%"` (per-target cache folder).
    
- `DOWNLOAD_FILE` — final name of the downloaded asset on disk (often `RELEASE_URL_SUFFIX` plus any `DOWNLOAD_EXT`).
    

---

# 5. Control flow — high-level

1. **Preflight**: Ensure `curl.exe` and `tar.exe` are available (script exits if missing).
    
2. **Cache resolution**: `:CACHE_DIR` determines a cache folder (tries `CACHE` if set, or local project `CACHE` directories, Downloads, then `%TEMP%`). `PREFIX = %CACHE%\%COMMON_NAME%`.
    
3. **jq availability**: If `JQ` is not set, call `:JQ_DOWNLOAD` to fetch and cache `jq.exe` (used for JSON parsing).
    
4. **Check cache**: If target executable `EXE_NAME` already exists in cache, script prints “Cached” and exits.
    
5. **Download**:
    
    - If `ASSET_URL_SUFFIX` is **not defined** ⇒ **DIRECT**: build `ASSET_URL` from `RELEASE_URL_SUFFIX` and `REPO_NAME` and `curl` to download to `%PREFIX%\%DOWNLOAD_FILE%`.
        
    - If `ASSET_URL_SUFFIX` **is defined** ⇒ **INDIRECT**: call `:RETRIEVE_ASSET_URL` to fetch release metadata and extract the exact `browser_download_url` to `ASSET_URL`, then `curl` it.
        
6. **Extraction** (if archive): `tar -xf "%DOWNLOAD_FILE%"` is used to extract the contents into `PREFIX` (the script detects zip-like extensions and extracts; if the asset is not an archive, skip extraction).
    
7. **Rename**: If `CANONICAL_NAME` is set, attempt to rename downloaded/extracted binary to `%EXE_NAME%`.
    
8. **Finalize**: report success / store exit code.
    

---

# 6. Key functions & implementation details

### 6.1 `:CACHE_DIR`

- Purpose: choose a sensible cache location with preference order:
    
    1. `%CACHE%` if already defined and exists.
        
    2. A `%~d0\CACHE` (drive root) if present.
        
    3. `%~dp0CACHE` (script folder) if present.
        
    4. `%USERPROFILE%\Downloads\CACHE` or `%USERPROFILE%\Downloads`.
        
    5. Falls back to `%TEMP%`.
        
- Outputs the chosen cache directory in `CACHE` and prints `%INFO% CACHE directory: "!CACHE!"`.
    

### 6.2 `:JQ_DOWNLOAD`

- If the script does not detect `jq` on the system, it will:
    
    1. Set `COMMON_NAME=JQ` and prepare a direct download of `jq-win64.exe` (example from `jqlang/jq`).
        
    2. Call `:ASSET_DOWNLOAD` to download and cache `jq.exe` in `%CACHE%\JQ\jq.exe`.
        
- After successful download, `JQ` is set (path to cached `jq.exe`) for subsequent use.
    

**Why `jq`?** The GitHub Releases API returns JSON; `jq` makes robust, clear selection of the correct asset (`.assets[] | select(... ) | .browser_download_url`). Using `jq` avoids fragile string parsing.

### 6.3 `:ASSET_DOWNLOAD` (main workhorse)

- Creates `%PREFIX%` (`%CACHE%\%COMMON_NAME%`) if missing.
    
- If a cached download file `%PREFIX%\%DOWNLOAD_FILE%` exists, skip GitHub download.
    
- **DIRECT MODE**: construct `ASSET_URL` directly:
    
    ```
    set "ASSET_URL=https://github.com/%REPO_NAME%/releases/latest/download/%RELEASE_URL_SUFFIX%"
    ```
    
    Then `curl --fail --retry 3 --retry-delay 2 -L -o "%PREFIX%\%DOWNLOAD_FILE%" "%ASSET_URL%"`.
    
- **INDIRECT MODE**: call `:RETRIEVE_ASSET_URL` to obtain `ASSET_URL` by parsing GitHub release metadata; the metadata is written to `%META_FILE%` then parsed.
    
- After download, `tar -xf "%DOWNLOAD_FILE%"` is used to extract the archive (if present); success/failure handled via `%ERRORLEVEL%`.
    
- If `CANONICAL_NAME` is set, the script attempts to locate and `move` the downloaded or extracted file to the canonical name.
    

**Notes on curl flags used:**

- `--fail` => return non-zero on HTTP errors (no HTML error page saved).
    
- `--retry 3 --retry-delay 2` => retry transient failures.
    
- `-L` => follow redirects (important; GitHub release download URLs often redirect).
    

### 6.4 `:RETRIEVE_ASSET_URL`

- Fetches the release metadata JSON:
    
    ```
    set "META_URL=https://api.github.com/repos/%REPO_NAME%/releases/latest"
    curl --fail --retry 3 --retry-delay 2 -s "%META_URL%" >"%META_FILE%"
    ```
    
- If `jq` is present, it builds a `jq` expression pattern to select the `browser_download_url` whose string `test()` matches the escaped `ASSET_URL_SUFFIX`.
    
    - Example `jq` pattern:
        
        ```
        .assets[] | select(.browser_download_url | test("vc\-x64\.exe")) | .browser_download_url
        ```
        
        (periods escaped; script transforms `.` → `\.` and uses `test`).
        
- Writes the matched URL into a temp file and reads it into `%ASSET_URL%`.
    
- **Fallback**: If `jq` fails, the script attempts a `FINDSTR`-based regex across the JSON file to locate a line with `.browser_download_url: https://...-<suffix>`, then extracts the URL.
    

**Important detail:** The script escapes `.` in `ASSET_URL_SUFFIX` differently depending on whether it will be embedded into a `jq` pattern (needs `\\.` in batch string to become `\.` in `jq`) or into a `FINDSTR` regex (a single `\.`). The script does that with variable transformations:

- `set "_ASSET_URL_SUFFIX=%ASSET_URL_SUFFIX:.=\\.%$"` (for `jq`)
    
- `set "_ASSET_URL_SUFFIX=%ASSET_URL_SUFFIX:.=\.%$"` (for `FINDSTR`)
    

### 6.5 Fallbacks and robustness

- If `jq` extraction fails, script prints a message and tries `FINDSTR`. If both fail, it exits with an error and descriptive message.
    
- The script carefully sets `%EXIT_STATUS%` after each operation and bubbles up errors to the caller.
    

---

# 7. Example use cases & snippets

### Example: fetch the `jq` Windows binary (direct)

```bat
set "COMMON_NAME=JQ"
set "REPO_NAME=jqlang/jq"
set "RELEASE_URL_SUFFIX=jq-win64.exe"
set "CANONICAL_NAME=jq.exe"
call "GitHubRelease.bat"
```

This constructs the direct URL:

```
https://github.com/jqlang/jq/releases/latest/download/jq-win64.exe
```

downloads it to `%CACHE%\JQ\jq-win64.exe`, and then renames it to `jq.exe` if `CANONICAL_NAME` is set.

### Example: fetch libjpeg-turbo vc x64 installer (indirect)

```bat
set "COMMON_NAME=libjpeg-turbo"
set "REPO_NAME=libjpeg-turbo/libjpeg-turbo"
set "ASSET_URL_SUFFIX=vc-x64.exe"
set "RELEASE_URL_SUFFIX=libjpeg-turbo-vc-x64.exe"  :: fallback local name
set "CANONICAL_NAME=libjpeg-turbo-vc-x64.exe"
call "GitHubRelease.bat"
```

Here, the script will fetch the release metadata and _search assets_ for a `browser_download_url` matching `vc-x64.exe`. If found, that exact URL is used.

---

# 8. Error handling, exit codes & common failures

The script uses `%EXIT_STATUS%` to report success/failure and exits with that code.

**Common errors & fixes:**

- **`"curl.exe" not found`** — the script exits immediately. Install `curl` or put it in PATH, or use the Windows bundled `curl` (Windows 10/11 includes one).
    
- **`"tar.exe" not found`** — script requires `tar` for archive extraction. Ensure the Windows tar or a compatible `tar` (e.g., bsdtar, GNU tar) is in PATH.
    
- **`jq` not found** — script will attempt to download `jq` into the cache. If that fails (network issue or insufficient privileges), the script will try `FINDSTR` fallback but that is more fragile.
    
- **Extraction failure (`tar -xf` fails)** — either `tar` doesn't understand the archive format (e.g., a `.zip` that tar cannot handle on that system) or the archive is corrupted. Consider using `Expand-Archive` (PowerShell) or `7z` as alternative extractors.
    
- **`ASSET_URL` not found from metadata** — check the `ASSET_URL_SUFFIX` you provided: it is used as a `test()` regex so be careful with dots (`.`) and other regex metacharacters. The script escapes `.` into `\.` but other characters may need handling. For debugging, open `%META_FILE%` in an editor and inspect `.assets[]` list.
    

**Debugging tips:**

- Inspect `%CACHE%\%COMMON_NAME%\*.json` (the metadata file) to see the GitHub API response.
    
- Print `ASSET_URL` after `:RETRIEVE_ASSET_URL` to confirm the matching result.
    
- Temporarily run `curl` commands from the command line manually to verify network/redirect behavior.
    

---

# 9. Security, reliability & improvement suggestions

**Security:**

- **No checksum verification:** The script does not verify checksums or GPG signatures. Consider adding a step to compare downloaded file hash with a signed checksum file or a release `sha256sum` asset when available.
    
- **GitHub API rate limits:** The script uses unauthenticated API calls; heavy usage can hit rate limits. If you need many requests, consider passing a `GITHUB_TOKEN` header (personal access token) to `curl`:
    
    ```bat
    curl -H "Authorization: Bearer %GITHUB_TOKEN%" ...
    ```
    
    Implementing token support requires storing token securely and possibly prompting for it.
    

**Reliability:**

- **Extraction fallbacks:** `tar` might not extract `.zip` on all Windows. Add `powershell -Command "Expand-Archive -Path 'file.zip' -DestinationPath 'dest' -Force"` as a fallback when `tar -xf` fails or when the download file extension is `.zip`.
    
- **7-Zip support:** Add `7z.exe` fallback if installed for robust extraction of many archive formats.
    
- **Better CLI interface:** Currently variables must be set in the environment or caller. A small CLI parser would make usage friendlier (`GitHubRelease.bat -r owner/repo -a vc-x64.exe -n libjpeg`).
    
- **Logging levels:** Add `VERBOSE`/`QUIET` toggles; currently the script prints informational messages.
    
- **Windows compatibility:** Test on older Windows where bundled `curl`/`tar` may be absent. Consider embedding small helpers or providing instructions for installing required tools.
    

**Maintainability:**

- Add comments and group related functionality into separate labels that return consistently documented exit codes.
    
- Consider porting the script to PowerShell if you want richer JSON handling without shipping `jq` (PowerShell has native JSON parsing via `ConvertFrom-Json`).
    

---

# 10. Appendix — variable reference & sample invocations

### Minimal direct download example

```bat
rem Example: download a release asset with known filename
set "COMMON_NAME=QS_TOOL"
set "REPO_NAME=owner/repo"
set "RELEASE_URL_SUFFIX=tool-win64.zip"
set "CANONICAL_NAME=tool.exe"
call "GitHubRelease.bat"
```

### Minimal indirect download example

```bat
rem Example: find the asset whose browser_download_url ends with "-win64.zip"
set "COMMON_NAME=MYAPP"
set "REPO_NAME=someorg/myapp"
set "ASSET_URL_SUFFIX=-win64.zip"
set "CANONICAL_NAME=myapp.exe"
call "GitHubRelease.bat"
```

### Key internal variable names (computed)

- `CACHE` — path to cache root (computed)
    
- `PREFIX` — `%CACHE%\%COMMON_NAME%`
    
- `META_FILE` — `%PREFIX%\%COMMON_NAME%.json` (metadata)
    
- `DOWNLOAD_FILE` — `%RELEASE_URL_SUFFIX%%DOWNLOAD_EXT%` (asset filename)
    
- `EXE_NAME` — `%PREFIX%\%CANONICAL_NAME%` (final expected exe path)
    

---

# Final notes & checklist (for your Field Notes)

-  Script enforces `curl` and `tar` presence at start — check your system PATH.
    
-  `jq` is fetched automatically if missing (but you should consider using PowerShell as an alternative for JSON parsing to avoid shipping additional binaries).
    
-  For robust production usage, add checksum verification and consider authenticated GitHub API requests to avoid rate limiting.
    
-  If you encounter a failed extraction for `.zip`, add a `PowerShell` `Expand-Archive` fallback or use `7z` if installed.
    

---

If you want, I can:

- produce a **compact README.md** (Markdown) ready to paste into your `Field Notes` repo that includes the usage examples above and a short `how to install prerequisites` section, **or**
    
- convert the `tar -xf` extraction step to a more robust extractor with `Expand-Archive` & `7z` fallbacks and produce a patched `.bat` with comments and safer handling.
    

Which of those two would you like next?