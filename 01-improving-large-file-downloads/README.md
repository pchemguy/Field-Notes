# Resuming Large File Downloads with Dynamic Links

> [!Note]
> https://github.com/BrisklyDev/brisk

## The Problem

Modern web browsers often fail to robustly download large files (e.g., OS images) over unreliable or slow connections. There are two primary reasons for this failure:

1. **Limited Resume Capabilities:** Standard browser downloaders often cannot properly resume a failed download, deleting the partial file and forcing a restart.
2. **Dynamic & Expiring Links:** Many services no longer provide direct download links. Instead, a browser must follow HTTP redirects to get a final link. This link is often temporary, containing a short-lived token (common on GitHub) or requiring a captcha challenge. When the token expires, the browser's attempt to resume from the invalid URL fails permanently.

The lack of a robust, general-purpose download manager in browsers has led to vendors providing single-purpose "stub" installers as a workaround. While peer-to-peer protocols like Torrent are a robust solution, their adoption for direct software distribution remains limited.

## The Solution

The most reliable solution for conventional HTTP downloads is to use a command-line tool like **`wget`** or a more modern [**`aria2`**](https://github.com/aria2/aria2/) in a script. This approach provides the most control for continuing browser initiated downloads, including handling complicated cases of dynamic, expiring, and guarded links. While `aria2` supports a wider spectrum of protocols, including `torrent` and fast multithreaded downloads, both of the tools provide similar advanced core functionality. Among shared advanced features is support for setting custom HTTP headers, including the `User-Agent` and any necessary session cookies. HTTP headers provide a context to the server, helping it identify the download tool's request as a valid continuation of the user's activity. Both tools also support resuming downloads and retrying on error. However, the more modern `aria2` implements a more robust error handling. To establish a similar behavior for classic `wget`, it is necessary to implement script-based loop wrapped around the actual download command. Such a loop enables, for example, automatic refreshing of expired links, if such feature is available (this is the case for GitHub asset downloads). Both tools would require manual intervention when the server prevents automatic link renewal by requiring passing a captcha challenge. While `aria2` implements a number of `wget` command line APIs, some changes may be necessary when adapting a `wget` script to `aria2`.

### Setup and Usage

You will need two files in the same directory: [download_wget.bat](https://github.com/pchemguy/Field-Notes/blob/main/01-improving-large-file-downloads/download_wget.bat) (or [download_aria2.bat](https://github.com/pchemguy/Field-Notes/blob/main/01-improving-large-file-downloads/download_aria2.bat)) and `headers.txt` (see example [here](https://github.com/pchemguy/Field-Notes/blob/main/01-improving-large-file-downloads/headers.txt)). While headers could be saved within the script, this split design is intentional, separating basically fixed data from the script code. The script config section is adjusted for each download (though this part could also be placed in a separate file).

#### Step 1: Locate `wget`

The script is configured to find `wget` at `C:/dev/msys64/usr/bin/wget.exe`, but you should change this path or add `wget` to your system's `PATH`.

#### Step 2: Create `headers.txt`

Using your browser's developer tools (F12), start the download and inspect the network request. Copy the main request headers (except for cookie) into `headers.txt`.

#### Step 3: Configure `download_wget.bat`

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

#### Step 4: Run the Script

Execute `download_wget.bat` from your command prompt. It will start the download and automatically retry if it encounters an error.

### `wget` Script Flow

The [download_wget.bat](https://github.com/pchemguy/Field-Notes/blob/main/01-improving-large-file-downloads/download_wget.bat) script is built around a single `wget` command inside a `goto` loop. The script first parses the `headers.txt` file, converting each line into a `--header` argument for `wget`. The script then checks for cookie information, prioritizing the `COOKIE_STRING` variable over a `COOKIE_FILE` if both are present.

The script uses a `goto` loop controlled by the `MAX_WGET_EXT_RETRIES` variable. If `wget` exits with an error (e.g., the link expired), the loop reruns the entire command. This step is critical for downloads with short-lived tokens, as it allows the script to get a fresh download link from the original URL and continue the download. The download is considered complete only when `wget` returns an exit status of 0. If the retry limit is reached, the script exits with an error.

The loop wraps the following `wget` command

```
"%WGET%" -c --max-redirect 100 --content-disposition --tries=0 --timeout=20 ^
         %LOAD_COOKIES%    ^
         %WGET_HEADERS%    ^
         %OUTPUT_DOCUMENT% ^
         "%URL%"
```

|                         |                                                                                        |
| ----------------------- | -------------------------------------------------------------------------------------- |
| `-c`                    | Tells `wget` to resume a partially downloaded file.                                    |
| `--max-redirect 100`    | Follows up to 100 HTTP redirects to find the actual file.                              |
| `--content-disposition` | Uses the server-suggested filename if `OUTPUT_FILE` is not set.                        |
| `--tries=0`             | Sets `wget`'s internal retries to infinite for temporary network issues like timeouts. |
| `--timeout=20`          | Sets a 20-second connection timeout.                                                   |

### aria2

The [download_aria2.bat](https://github.com/pchemguy/Field-Notes/blob/main/01-improving-large-file-downloads/download_aria2.bat) script is simpler, as `aria2` implements a more advanced HTTP error handling logic and the external loop is no longer necessary. The overall logic is similar to the `wget` script with minor adjustments to accommodate command line differences between the two tools.

### Handling Captcha Challenges

For downloads protected by a captcha, full automation is not possible.
1. Solve the captcha in your browser and start the download.
2. Immediately cancel the download.
3. Use the browser's developer tools to get the newly generated URL and cookie string from HTTP request metadata.
4. Update these values in the script configuration, paying attention to special characters.
5. Run the script.
6. When the script fails because the link expired, the partial file is kept safe.
7. Repeat the process from step 3 to get a new link/cookie, update the script, and run it again. `wget`/`aria2` will resume where it left off.
