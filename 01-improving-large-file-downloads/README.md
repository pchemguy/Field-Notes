# Resurrection of the Large File Downloading Issue

In the early days of the Internet with slow unreliable connections, the facilitation of file downloading task rightfully attracted considerable attention. However, as the available network bandwidth has rapidly increased and protocol resilience improved, the downloading process has progressively become more robust. Surprisingly, no major browser provider (at least on Windows), be it Microsoft, Mozilla, or Google has ever cared to develop a robust built-in download manager. The problem was only addressed by third-party solutions, and their gradual abandonment (see, e.g., the "General Information" table in [this Wikipedia article](https://en.wikipedia.org/wiki/Comparison_of_download_managers)) signaled the improved downloading experience.

Meanwhile, distribution of rapidly swelling packages, such as operating systems and CAD systems, has been also increasingly shifted towards downloading over the Internet. The fact that modern browsers are absolutely not capable of properly handling large file downloads is indirectly and silently acknowledged by many major software vendors. Instead of providing a proper robust general-purpose solution, Microsoft, Google, Autodesk, and various other vendors increasingly adopted a ridiculous solution where instead of providing a direct download link to the target distribution, provided link downloads a stub, which is essentially a download manager focusing on one specific package or a group of packages. While this design with specialized managers is justified under certain scenarios, such as in the case of highly customizable multi-component downloads, most of the time I interpret this design as a sign of gross incompetence. For example, for years, Google provided the Chrome browser as a stubbed download and implemented a separate specialized solution for downloading updates instead of integrating a proper download manager. (Another vivid example is GitHub Desktop, which has a horrible built-in download manager.) These poor-man approaches to the downloading task partially masked resurrection of the issue.

The downloading problem has been further worsened due to two tendencies. On the one hand, the size of large files has grown substantially faster than generally available network bandwidth for end users and download providers (especially those not being able to use CDN networks). On the other hand, providers have largely moved from providing direct download links to providing "nominal" download links that must be used by the browser (or download manager) to obtain real, often dynamic, direct links in the course of "download negotiation" process. This negotiation process is often used by providers to automatically balance downloads from multiple sites and/or protect the resource from automatic mass downloads (e.g., by requiring a mandatory user involvement in the download negotiation process in the form of a captcha challenge or including a short-lived dynamically generated token in the final negotiated download link (e.g., GitHub assets downloads)). Perhaps, the only reliable general-purpose solution to large file downloads is the peer-to-peer Torrent protocol, but very few providers, if any, bother providing downloads over the Torrent protocol.

Resumed downloads is the primary means that is absolutely essential for robust downloading of large files over unreliable connections (regardless of bottleneck location on the client side, server side, or somewhere in the middle). However, in cases of dynamically negotiated links when connection error is not a temporary connectivity issue, but a result of an expired link, attempts to resume the download using the same expired link are useless. Browsers may not be capable of recognizing this matter and properly renegotiating a new link automatically even when such capability is available. In some cases, a new link (or new cookie) must be obtained by passing a new captcha challenge, so generally, cannot be performed automatically without AI. In either case, browsers fail download and delete partial files instead of letting user intervene and resume download. In such cases, it may be virtually impossible to download the file not because of any abusive user actions, but because of junk built-in download managers.

The only workable solution I have found is via scripted download (I primarily use Windows, so the script is based on Windows batch language, but can be straightforwardly adopted to bash) using an established command-line download tool, such as WGET. While I have no intention to circumvent anti-abusive features and I am not aiming for any kind of automated abusive mass download (I simply need to be able to download the target at all), special measures needs to be taken to ensure that WGET download request will not be rejected. Servers often use identification information provided by clients in HTTP headers (mainly, user agent and cookies) to distinguish browser-initiated versus non-browser downloads to reject the latter due to there frequent use for automated mass downloads. Therefore, WGET needs to identify itself in the download requests as a browser. This task can be accomplished by retrieving headers from HTTP request sent by the browser via built-in developer tools (while this task is relatively quick, I am intentionally on providing details on this part; besides, this information can be found elsewhere) and including them in WGET command line. HTTP request metadata also provide the actual negotiated URL and cookie, which may be necessary, especially when captcha challenge is performed.

In addition to user agent, I decided to include a few other common headers present in the actual browser request. These headers are browser specific (so do not depend on particular download target details) and placed in the `headers.txt` file, which is loaded and parsed by the script:

```batch
for /f "usebackq tokens=1,* delims=:" %%G in ("%HEADER_FILE%") do (
    set header_key=%%G
    set header_value=%%H

    :: Trim the leading space that often follows the colon in header values
    if "!header_value:~0,1!"==" " set header_value=!header_value:~1!

    set WGET_HEADERS=!WGET_HEADERS! --header="!header_key!: !header_value!"
)
```

The only other file is the download Windows batch script `download.bat`. The download URL and cookie are download specific and place in the configuration section of the script:

```batch
:: --- Set the full URL you want to download ---
set "URL=https://hirensbootcd.org/files/HBCD_PE_x64.iso"

:: --- Paste your full cookie data inside the quotes ---
set "COOKIE_STRING="

set WGET=C:/dev/msys64/usr/bin/wget.exe 
set HEADER_FILE=headers.txt

:: -- See docs next to the download loop below for adjusting MAX_WGET_EXT_RETRIES
set MAX_WGET_EXT_RETRIES=99
set COOKIE_FILE=
REM cookies.txt

set GITHUB_TOKEN=

:: --- Set the names for your output files ---
set OUTPUT_FILE=HBCD_PE_x64.iso
```

Importantly, special attention should be paid to potential presence of special characters in URL and cookie string, particularly ampersand and percent sign. Percent sign must always be escaped by doubling (`%%`) when used in batch file. Ampersand, on the other hand, if included in a quoted string (which is the case), should not be escaped. At the same time, when exporting URL and cookie from HTTP request as a `curl` command, Chrome escapes ampersands with carets (`^&`) while does not escape percent sign (special character behavior differs between direct execution of a command and commands placed in a batch script).

I do not have WGET in my `Path`, which is why I added the `WGET` variable to the script. The `MAX_WGET_EXT_RETRIES` variable will be discussed later. The `OUTPUT_FILE` variable may be left unset, in which case `wget` will select the name of the output file automatically.

```
if not "%OUTPUT_FILE%"=="" (
  set OUTPUT_DOCUMENT=--output-document "%OUTPUT_FILE%"
) else (
  set OUTPUT_DOCUMENT=
)
```

Cookie may be included in the script directly via the `COOKIE_STRING` variable or via an automatically generated `cookies.txt` file (the `COOKIE_FILE` variable, presently unset). I used the `cookies.txt`file before, but I have realized that setting the `COOKIE_STRING` variable directly is simpler (`cookies.txt` related code is still left and conditionally executed only if  the `COOKIE_STRING` variable is not set):

```
if "%COOKIE_STRING%"=="" (
  if not "%COOKIE_FILE%"=="" (
    set LOAD_COOKIES=--load-cookies="%COOKIE_FILE%"
  ) else (
    set LOAD_COOKIES=
  )
)

set WGET_HEADERS=
if not "%COOKIE_STRING%"=="" (
  set WGET_HEADERS=%WGET_HEADERS% --header="Cookie: %COOKIE_STRING%"
)
```

## WGET Command

The actual `WGET` command:

```
%WGET% -c --max-redirect 100 --content-disposition --tries=0 --timeout=20 ^
       %LOAD_COOKIES%    ^
       %WGET_HEADERS%    ^
       %OUTPUT_DOCUMENT% ^
       "%URL%"
```

instructs `WGET` to follow redirects (`-c --max-redirect 100`), use `--content-disposition` information for output file name selection, use unlimited number of retries (`--tries=0`) when connection is timed out (20 s time out, `--timeout=20`) or in case of small errors (perhaps, a finite number may need to be used, though I have not encountered problems due to this settings so far).

When a dynamically generated URL is invalidated (such as in case of short-lived tokens generated by GitHub when downloading assets) and an HTTP error is returned by the server, `WGET` terminates download process. In such a case, the original `WGET` command needs to be executed again to renew the token/URL. Hence the batch loop around the `WGET` command, which is terminated when the download is complete or the maximum number of retries (`MAX_WGET_EXT_RETRIES`) is reached.

A more complicated scenario arises when a dynamically generated URL is guarded by a captcha challenge. In such a case, automatic URL/cookie renewal is not practically possible, so should be set to a small number. In such a case the following workflow can be used. Initiate download in the browser by passing the captcha challenge and terminate the download immediately. Export dynamically generated URL and cookie from the HTTP request using developer tools, set variables in the batch script, taking care of appropriate escaping of special characters. Start the download. When the download URL/cookie expire, `WGET` will get an HTTP error and terminate the download process. However, as opposed to browsers, the partially downloaded file will remain intact. The user would need to go again through the captcha challenge, manually a renewing and exporting updated URL/cookie, updating variables in the script and resuming the download process.