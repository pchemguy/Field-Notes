# Resuming Large File Downloads with Dynamic Links

## The Problem

Modern web browsers often fail to robustly download large files (e.g., OS images) over unreliable or slow connections. There are two primary reasons for this:

1. **Limited Resume Capabilities:** Standard browser downloaders often cannot properly resume a failed download, deleting the partial file and forcing a restart.    
2. **Dynamic & Expiring Links:** Many services no longer provide direct download links. Instead, a browser must follow HTTP redirects to get a final link. This link is often temporary, containing a short-lived token (common on GitHub) or requiring a captcha challenge. When the token expires, the browser's attempt to resume from the invalid URL fails permanently.

The lack of a robust, general-purpose download manager in browsers has led to vendors providing single-purpose "stub" installers as a workaround (consider the standard Google's Chrome installer). While peer-to-peer protocols like Torrent are a robust solution, their adoption for direct software distribution remains limited.

## The Solution: Scripted Command-Line Downloaders

The most reliable solution is to use a powerful command-line tool like the classic **`wget`** or the more modern **`aria2`**. By wrapping them in a simple script, you can gain full control over the download process, including resuming failed downloads and handling dynamic links.

The specific solutions presented here are Windows batch scripts (.bat), but the core concepts and tool commands can be readily adapted to other operating systems and shell languages (like bash on Linux or macOS).

Both solutions rely on the same core concept: continuing a session initiated in the browser. The script achieves this goal by providing the command-line tool with the same HTTP headers (like `User-Agent` and cookies) that the browser used, giving the server the necessary context to recognize the request as a valid continuation of browser-based activity.

## `wget` Script

`wget` is a classic and highly reliable tool. Its built-in retry mechanism is excellent for temporary network errors, but it requires an external script loop to handle expiring links, where the entire download command must be re-initiated.

### Setup and Usage

You'll need two files: the script **[download_wget.bat](https://github.com/pchemguy/Field-Notes/blob/main/01-improving-large-file-downloads/download_wget.bat)** and a **`headers.txt`** file (see example [here](https://github.com/pchemguy/Field-Notes/blob/main/01-improving-large-file-downloads/headers.txt)).

1. **Locate `wget`:** The script is configured for `C:/dev/msys64/usr/bin/wget.exe`. You should update this path or add `wget` to your system's `PATH`.
2. **Create `headers.txt`:** Use your browser's developer tools (F12) to inspect the network request for your download and copy the main request headers (except for the cookie) into `headers.txt`.
3. **Configure `download_wget.bat`:** Open the script and edit the configuration section with your `URL`, `COOKIE_STRING`, and `OUTPUT_FILE`.
    > **Note on Special Characters for Windows Batch Scripts:** Remember to escape percent signs (`%` becomes `%%`) in the `URL` or `COOKIE_STRING` variables. Because both `URL` and `COOKIE_STRING` are quoted, the ampersand should not be escaped (do not change `&` to `^&`).
4. **Run the Script:** Execute `download_wget.bat` to begin.

### Execution Logic

The `wget` script is built around a single `wget` command inside a `goto` loop. The script
1. Parses the `headers.txt` file, converting each line into a `--header` argument for `wget`
2. Checks for cookie information, prioritizing the `COOKIE_STRING` variable over a `COOKIE_FILE` if both are present.
3. Executes a `goto` loop controlled by `MAX_WGET_EXT_RETRIES`. If `wget` fails because a link has expired, the loop re-runs the command, allowing it to get a fresh link from the original URL and then resume the download.

The core command is:

```
"%WGET%" -c --max-redirect 100 --content-disposition --tries=0 --timeout=20 ^
         %LOAD_COOKIES%    ^
         %WGET_HEADERS%    ^
         %OUTPUT_DOCUMENT% ^
         "%URL%"
```

| Option                  | Description                                                     |
| ----------------------- | --------------------------------------------------------------- |
| `-c`                    | Resumes a partially downloaded file.                            |
| `--max-redirect 100`    | Follows up to 100 HTTP redirects.                               |
| `--content-disposition` | Uses the server-suggested filename if `OUTPUT_FILE` is not set. |
| `--tries=0`             | Sets internal retries to infinite for temporary network issues. |
| `--timeout=20`          | Sets a 20-second connection timeout.                            |

## `aria2` Script

**[`aria2`](https://www.google.com/search?q=%5Bhttps://github.com/aria2/aria2/%5D\(https://github.com/aria2/aria2/\))** is a more modern downloader that supports multi-connection, multi-threaded downloads from multiple sources for significantly faster speeds. Its error handling is more advanced, meaning an external script loop is generally not necessary.

### Setup and Usage

You'll need **[download_aria2.bat](https://github.com/pchemguy/Field-Notes/blob/main/01-improving-large-file-downloads/download_aria2.bat)** and the same **`headers.txt`** file. The setup steps are identical to `wget`: locate the executable, create `headers.txt`, and configure the script's variables.

### Execution Logic

The first two steps of the `aria2` script are the same as for the `wget` script. The `aria2` script is simpler as it doesn't require an external loop. It executes a single, powerful command:

The core command is:

Code snippet

```
"%ARIA2%" -c --max-tries=20 --timeout=20 --file-allocation=none ^
          --max-connection-per-server=%THREAD_COUNT% --split=%THREAD_COUNT% ^
          %LOAD_COOKIES%    ^
          %ARIA2_HEADERS%   ^
          %OUTPUT_DOCUMENT% ^
          "%URL%"
```

| Option                                       | Description                                                                      |
| -------------------------------------------- | -------------------------------------------------------------------------------- |
| `-c`                                         | Resumes a partially downloaded file.                                             |
| `--file-allocation=none`                     | Do not pre-allocate file space.                                                  |
| `--max-connection-per-server=%THREAD_COUNT%` | Uses *up to* %THREAD_COUNT% connections *per* server to accelerate the download. |
| `--split=%THREAD_COUNT%`                     | Uses %THREAD_COUNT% connections (for *all* servers) to download in parallel.     |
| `--max-tries=20`                             | Retries at most 20 times on errors.                                              |
| `--timeout=20`                               | Sets a 20-second connection timeout.                                             |

Note, due to the limitations of the batch scripting environment and special character handling details, the script would need to be adjusted if more than one source is available and can be used.

## Handling Captcha Challenges

For downloads protected by a captcha, full automation is not possible with either tool.

1. Solve the captcha in your browser and start the download.
2. Immediately cancel the download.
3. Use the browser's developer tools to get the newly generated **URL** and **cookie string**.
4. Update these values in the script configuration, paying attention to special characters.
5. Run the script.
6. When the link expires and the script fails, the partial file is kept safe.
7. Repeat the process from step 3 to get a new link/cookie, update the script, and run it again. The tool will resume where it left off.
