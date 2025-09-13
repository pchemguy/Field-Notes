# Resuming Large File Downloads with Dynamic Links

## 1. The Problem

Modern web browsers often fail to robustly download large files (e.g., OS images) over unreliable or slow connections. There are two primary reasons for this failure:

1. **Limited Resume Capabilities:** Standard browser downloaders often cannot properly resume a failed download, deleting the partial file and forcing a restart.
2. **Dynamic & Expiring Links:** Many services no longer provide direct download links. Instead, a browser must follow HTTP redirects to get a final link. This link is often temporary, containing a short-lived token (common on GitHub) or requiring a captcha challenge. When the token expires, the browser's attempt to resume from the invalid URL fails permanently.

The lack of a robust, general-purpose download manager in browsers has led to vendors providing single-purpose "stub" installers as a workaround. While peer-to-peer protocols like Torrent are a robust solution, their adoption for direct software distribution remains limited.

## 2. The Solution

The most reliable solution for conventional HTTP downloads is to use a command-line tool like **`wget`** in a script. This approach handles resuming downloads and can be re-run to get a fresh download link when needed.
- **Aligning with the Browser Request:** The script configures `wget` to use the same HTTP headers as your browser, including the `User-Agent` and any necessary session cookies. By providing this context, the server recognizes the `wget` request as a valid continuation of the user's activity.
- **External Retry Loop:** The `wget` command is wrapped in an external batch loop. If `wget` fails because a temporary link has expired, the loop re-runs the command, using the original URL to get a new, valid download link and then resumes the download from where it left off.

## 3. Setup and Usage

You will need two files in the same directory: [download.bat](./download.bat) and `headers.txt` (see example [here](./headers.txt)).

### Step 1: Get `wget`

The script is configured to find `wget` at `C:/dev/msys64/usr/bin/wget.exe`, but you should change this path or add `wget` to your system's `PATH`.

### Step 2: Create `headers.txt`

Using your browser's developer tools (F12), start the download and inspect the network request. Copy the main request headers into `headers.txt`.

### Step 3: Configure `download.bat`

Open the script and edit the configuration section.

```
:: --- Set the full URL you want to download ---
set "URL=https://hirensbootcd.org/files/HBCD_PE_x64.iso"

:: --- Paste your full cookie data inside the quotes (if needed) ---
set "COOKIE_STRING="

:: --- Set the desired name for your output file ---
set "OUTPUT_FILE=HBCD_PE_x64.iso"
```

- **`URL`**: The initial download link from the website. For captcha-protected downloads, you may need to use the final redirected URL after solving the captcha.    
- **`COOKIE_STRING`**: Required if the download needs a login or captcha session. Paste the full cookie string from your browser's developer tools here.
- **`OUTPUT_FILE`**: Set the final filename. If left blank, `wget` will try to determine it automatically.

> **Important Note on Special Characters:** When pasting into the `URL` or `COOKIE_STRING` variables, be mindful of batch script special characters. A percent sign (`%`) must always be escaped by doubling it (`%%`). An ampersand (`&`), if inside a quoted string as it is here, should not be escaped.

### Step 4: Run the Script

Execute `download.bat` from your command prompt. It will start the download and automatically retry if it encounters an error6.

## 4. How It Works: A Deeper Dive

The script is built around a single `wget` command inside a `goto` loop.

### Processing Headers and Cookies

The script first parses the `headers.txt` file, converting each line into a `--header` argument for `wget`. The script then checks for cookie information, prioritizing the `COOKIE_STRING` variable over a `COOKIE_FILE` if both are present.

### The `wget` Command

```
%WGET% -c --max-redirect 100 --content-disposition --tries=0 --timeout=20 ^
       %LOAD_COOKIES%    ^
       %WGET_HEADERS%    ^
       %OUTPUT_DOCUMENT% ^
       "%URL%"
```

- **Core Command Options**:
    - `-c`: Tells `wget` to resume a partially downloaded file.
    - `--max-redirect 100`: Follows up to 100 HTTP redirects to find the actual file.
    - `--content-disposition`: Uses the server-suggested filename if `OUTPUT_FILE` is not set.
    - `--tries=0`: Sets `wget`'s internal retries to infinite for temporary network issues like timeouts.
    - `--timeout=20`: Sets a 20-second connection timeout.

### The External Retry Loop

The script uses a `goto` loop controlled by the `MAX_WGET_EXT_RETRIES` variable. If `wget` exits with an error (e.g., the link expired), the loop reruns the entire command. This step is critical for downloads with short-lived tokens, as it allows the script to get a fresh download link from the original URL and continue the download. The download is considered complete only when `wget` returns an exit status of 0. If the retry limit is reached, the script exits with an error.

## 5. Handling Captcha Challenges

For downloads protected by a captcha, full automation is not possible.
1. Solve the captcha in your browser and start the download.
2. Immediately cancel the download.
3. Use the browser's developer tools to get the newly generated URL and cookie string from HTTP request metadata.
4. Update these values in the `download.bat` configuration, paying attention to special characters.
5. Run the script.
6. When the script fails because the link expired, the partial file is kept safe.
7. Repeat the process from step 1 to get a new link/cookie, update the script, and run it again. `wget` will resume where it left off.
