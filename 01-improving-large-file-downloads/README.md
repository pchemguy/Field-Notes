# Resuming Large File Downloads with Dynamic Links

## 1. The Problem

Modern web browsers, despite network improvements, often fail to robustly download large files (e.g., OS images, CAD software) over unreliable or slow connection. There are two primary reasons for this problem:

1. **Limited Resume Capabilities:** Standard browser downloaders often cannot properly resume a download that fails midway through, deleting the partial file and forcing a restart.
2. **Dynamic & Expiring Links:** Many services no longer provide simple, direct download links. Instead, a browser must first "negotiate" a real link by following HTTP redirects. This negotiated link is often dynamic and temporary, may contain a short-lived token (a common practice on GitHub for asset downloads) or be guarded by a required captcha-like challenge. If the connection drops due to expired token, the browser's attempt to resume from the now-invalid URL will fail permanently.

The lack of robust built-in general-purpose browser download manager resulted in an odd trend where even major software vendors replace direct download links with small, single-purpose "stub" downloaders (e.g., think of how the Google Chrome browser has been distributed for years). The most widely used general solution for robust downloading of large files is the peer-to-peer Torrent protocol, but its adoption remains limited, with truly general-purpose widely adopted solution lacking.

## 2. The Solution

The most reliable solution for conventional HTTP downloads is, perhaps, to use a command-line tool like **`wget`** in a script that can handle resuming downloads and can be re-run to get a fresh download link when needed.

This approach involves two key steps:

- **Aligning with the Browser Request:** To continue the download session initiated in the browser, the script configures `wget` to use the same HTTP headers. This includes the `User-Agent` and any necessary session cookies. By providing this context, the server recognizes the `wget` request as a valid continuation of the user's activity.
- **External Retry Loop:** The `wget` command is wrapped in an external batch loop. If `wget` fails because a temporary link has expired, the loop simply re-runs the entire command, which uses the _original_ URL to negotiate a _new_, valid download link and then resumes the download from where it left off, if possible.

## 3. Setup and Usage

You will need two files placed in the same directory:

- `download.bat`: The main script.
- `headers.txt`: A file containing browser headers.

### Step 1: Get `wget`

Ensure you have a command-line `wget` executable. This script is configured to find it at `C:/dev/msys64/usr/bin/wget.exe`, but you can change this path or add your `wget` location to your system's `PATH`.

### Step 2: Create `headers.txt`

Using your browser's developer tools (usually F12), start the download you want, and inspect the network request. Copy the main request headers into a text file named `headers.txt`. This file will tell `wget` how to identify itself.

**Example `headers.txt`:**

```
accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7
accept-language: en-US,en;q=0.9,ru;q=0.8
cache-control: max-age=0
priority: u=0, i
upgrade-insecure-requests: 1
user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36
```

### Step 3: Configure `download.bat`

Open `download.bat` and edit the configuration section at the top:

Code snippet

```
:: --- Set the full URL you want to download ---
set "URL=https://hirensbootcd.org/files/HBCD_PE_x64.iso"

:: --- Paste your full cookie data inside the quotes (if needed) ---
set "COOKIE_STRING="

:: --- Set the desired name for your output file ---
set "OUTPUT_FILE=HBCD_PE_x64.iso"
```

- **`URL`**: The initial download link you get from the website, if the downloads proceeds automatically. When guarded by a captcha-like challenge, it may be necessary to use the final redirected URL.
- **`COOKIE_STRING`**: If the download requires you to be logged in or guarded by a captcha-like challenge, paste the full cookie string from your browser's developer tools here.    
- **`OUTPUT_FILE`**: Set the final filename. If left blank, `wget` will try to determine it automatically.

### Step 4: Run the Script

Execute `download.bat` from your command prompt. It will start the download and automatically retry if it encounters an error.

## 4. How It Works: A Deeper Dive

The script is built around a single `wget` command inside a loop.

```batch
:LOOP_WGET_EXT_RETRY
...
%WGET% -c --max-redirect 100 --content-disposition --tries=0 --timeout=20 ^
       %LOAD_COOKIES%    ^
       %WGET_HEADERS%    ^
       %OUTPUT_DOCUMENT% ^
       "%URL%"
...
goto :LOOP_WGET_EXT_RETRY
```

- **Core Command Options**:
    - `-c`: **Continue**. This is the most important flag. It tells `wget` to resume a partially downloaded file.
    - `--max-redirect 100`: Follow up to 100 redirects to find the actual download URL.
    - `--tries=0`: Sets `wget`'s internal retries to infinite for temporary network issues.
- **The External Loop**:
    - The `:LOOP_WGET_EXT_RETRY` is a simple batch `goto` loop.
    - It executes `wget`. If `wget` exits with an error (status code is not 0), the script checks if it has reached `MAX_WGET_EXT_RETRIES`.
    - If not, it increments the counter and loops back to the start, re-running the entire `wget` command from the beginning. This is what allows it to get a fresh token from the original URL, resolving the expired link problem.

## 5. Handling Captcha Challenges

For downloads protected by a captcha, full automation is not possible. The workflow becomes a manual-resume process:
1. Solve the captcha in your browser and start the download.
2. Immediately cancel the download in your browser.
3. Use the browser's developer tools to get the newly generated **URL** and **cookie string** from final HTTP request.
4. Update these values in the `download.bat` configuration.
5. Run the script to download as much as possible before the link expires.
6. When the script fails (because the link expired), the partially downloaded file is kept safe.
7. Repeat the process from step 1 to get a new link and cookie, update the script, and run it again. `wget` will pick up right where it left off.