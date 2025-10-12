
![](https://raw.githubusercontent.com/pchemguy/Field-Notes/refs/heads/main/assets/ghrelease.jpg)

# **Downloading Latest GitHub Release Assets on Windows**

## **Synopsis**

**Platform tested:** Windows 10 LTSC 2021  
**Main Script:** `GitHubRelease.bat`
**Test Script:** `GitHubRelease_Test.bat`

### **Purpose**

A compact Windows batch utility for **retrieving the latest GitHub release asset** from any public repository.  
Designed for reproducible setups and scripted environment bootstrapping where you need *the latest* version of a binary, installer, or archive.

This is not a release automation tool - it is a **client-side downloader** that uses the GitHub Releases API and minimal system dependencies.

### **Design Principles**

- Works **without PowerShell** or third-party installers.  
- Depends only on **stock Windows components**:  
    - `curl.exe` (bundled with modern Windows)  
    - `tar.exe` (bundled with modern Windows)  
    - **`jq.exe`** (for JSON parsing) is downloaded automatically if missing.  
- Fully self-contained; no external package managers.  
- Uses a **local cache** to avoid repeated downloads.  
- Operates in two modes:  
  1. **Direct** - download known filename (release file name does not include version number) from `/releases/latest/download/`  
  2. **Indirect** - query the API and select an asset by pattern

### **Typical Use Case**

You maintain local scripts that need a current binary (e.g., `jq`, `micromamba`, `libjpeg-turbo`).  
Instead of hardcoding version numbers or manually checking releases, this tool automates retrieval of the latest asset.

Example pattern:

```bat
set "COMMON_NAME=JQ"
set "REPO_NAME=jqlang/jq"
set "RELEASE_URL_SUFFIX=jq-win64.exe"
set "ASSET_URL_SUFFIX="
set "DOWNLOAD_EXT="
set "SPECIFIC_NAME="
set "CANONICAL_NAME=jq.exe"
call "GitHubRelease.bat"
```

Result:

```
https://github.com/jqlang/jq/releases/latest/download/jq-win64.exe
↓
%CACHE%\JQ\jq.exe
```

---

## **Modes of Operation**

### **1. Direct Mode**

Triggered when `ASSET_URL_SUFFIX` is not defined.

The download URL is built as:

```
https://github.com/<owner>/<repo>/releases/latest/download/<RELEASE_URL_SUFFIX>
```

Example:

```bat
set "REPO_NAME=jqlang/jq"
set "RELEASE_URL_SUFFIX=jq-win64.exe"
```

This is the simplest mode and suitable when you know the exact filename, particularly, when `<RELEASE_URL_SUFFIX>` (asset name) does not integrate version number ("jq-win64.exe" vs. "7z2501.exe").

### **2. Indirect Mode**

Triggered when `ASSET_URL_SUFFIX` is defined.

The script:

1. Fetches `https://api.github.com/repos/<owner>/<repo>/releases/latest`
2. Parses the JSON with `jq` to find an asset whose  
    `.browser_download_url` matches the provided suffix pattern.
3. Downloads the matched asset with `curl`.

Example:

```bat
set "COMMON_NAME=libjpeg-turbo"
set "REPO_NAME=libjpeg-turbo/libjpeg-turbo"
set "ASSET_URL_SUFFIX=vc-x64.exe"
set "RELEASE_URL_SUFFIX=libjpeg-turbo-vc-x64.exe"
set "DOWNLOAD_EXT="
set "CANONICAL_NAME="
set "SPECIFIC_NAME="
call "GitHubRelease.bat"
```

Here, the script locates the correct `*-vc-x64.exe` asset dynamically. This workflow is necessary, becuase "libjpeg-turbo-3.1.2-vc-x64.exe" includes release version number.

## **Cache Directory Resolution**

`GitHubRelease.bat` determines the cache path automatically in this order:

1. Existing `%CACHE%` variable (if defined)    
2. `CACHE` folder on current drive (`%~d0\CACHE`)
3. `CACHE` folder beside the script (`%~dp0CACHE`)
4. `%USERPROFILE%\Downloads\CACHE`
5. `%USERPROFILE%\Downloads`
6. `%TEMP%`

Each asset gets its own subfolder:

```
%CACHE%\JQ\
%CACHE%\MICROMAMBA\
...
```

This approach avoids name collisions and supports offline reuse.

## **Variable Reference**

| Variable             | Description                                                                  |
| -------------------- | ---------------------------------------------------------------------------- |
| `COMMON_NAME`        | Short label used for caching/logging (e.g. `JQ`)                             |
| `REPO_NAME`          | GitHub repository in `owner/repo` form                                       |
| `RELEASE_URL_SUFFIX` | Filename for direct mode                                                     |
| `ASSET_URL_SUFFIX`   | Pattern used to match asset in indirect mode (string suffix, e.g. `x64.exe`) |
| `CANONICAL_NAME`     | Final name for the downloaded/extracted file                                 |
| `CACHE`              | Optional override for cache directory                                        |
| `EXE_NAME`           | Computed: `%PREFIX%\%CANONICAL_NAME%`                                        |
| `PREFIX`             | Computed: `%CACHE%\%COMMON_NAME%`                                            |

## **Toolchain Behavior**

- **Download:** via `curl --fail --retry 3 --retry-delay 2 -L`
- **Extraction:** via `tar -xf`, only if archive detected
- **Renaming:** uses `CANONICAL_NAME` when defined
- **Error reporting:** via `%EXIT_STATUS%`

## **Error Recovery**

| Symptom              | Cause                    | Fix                                                       |
| -------------------- | ------------------------ | --------------------------------------------------------- |
| `curl.exe` not found | Missing system component | Ensure Windows build ≥ 1803                               |
| `tar.exe` not found  | Missing system component | Install optional Windows features (or copy from newer OS) |
| `jq` parsing fails   | Network/redirect issues  | Retry; JSON will be cached locally                        |
| Asset not found      | Wrong suffix or pattern  | Inspect metadata JSON under `%PREFIX%`                    |

## **Example Recipes**

### **1. jq binary**

```bat
set "COMMON_NAME=JQ"
set "REPO_NAME=jqlang/jq"
set "RELEASE_URL_SUFFIX=jq-win64.exe"
set "ASSET_URL_SUFFIX="
set "DOWNLOAD_EXT="
set "SPECIFIC_NAME="
set "CANONICAL_NAME=jq.exe"
call "GitHubRelease.bat"
```

### **2. micromamba binary**

```bat
set "COMMON_NAME=Micromamba"
set "REPO_NAME=mamba-org/micromamba-releases"
set "ASSET_URL_SUFFIX="
set "RELEASE_URL_SUFFIX=micromamba-win-64.exe"
set "DOWNLOAD_EXT="
set "CANONICAL_NAME=micromamba.exe"
set "SPECIFIC_NAME="
call "GitHubRelease.bat"
```

### **3. libjpeg-turbo installer**

```bat
set "COMMON_NAME=libjpeg-turbo"
set "REPO_NAME=libjpeg-turbo/libjpeg-turbo"
set "ASSET_URL_SUFFIX=vc-x64.exe"
set "RELEASE_URL_SUFFIX=libjpeg-turbo-vc-x64.exe"
set "DOWNLOAD_EXT="
set "CANONICAL_NAME="
set "SPECIFIC_NAME="
call "GitHubRelease.bat"
```

## **Implementation Highlights**

- Automatic download of `jq.exe` into cache if missing    
- Safe retry behavior with `curl`
- Controlled extraction with `tar`
- Simple and deterministic file structure
- Minimal dependencies - works on fresh LTSC installations

## **Notes for Future Maintenance**

- GitHub API is rate-limited for anonymous users.  
    If you make frequent API calls, consider adding  
    `-H "Authorization: Bearer <token>"` in the curl command.
- The script currently skips checksum verification;  
    for production, you may extend it to validate against a `.sha256` asset if present.
- Avoid adding PowerShell or 7-Zip dependencies -  they defeat the self-contained design philosophy.

## **Summary**

`GitHubRelease.bat` is a minimal yet flexible downloader for Windows power users.  
It encapsulates GitHub API queries, caching, and asset extraction in a single stock-Windows script - no external runtime, no package managers, and no PowerShell.
