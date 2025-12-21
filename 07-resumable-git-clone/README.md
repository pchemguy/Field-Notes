# Resumable Git Clone

I find it absolutely ridiculous and inexcusable that git developers apparently never bothered implementing a proper robust download management. Cloning of relatively large repositories over limited bandwidth/stability connection may readily becomes a big problem, because on network failure git starts the process from scratch, rendering the core command `git clone` largely useless. There are actually several problems here. In addition to complete lack of "resume on failure" feature, it does not separate metadata (its size a small fraction of that of the code base) and the code base. It is, in fact, possible to clone the repo metadata only via command (why a simple direct command for this task is not available is unclear):

```
git clone --filter=blob:none --no-checkout %URL%
```
 
 Getting blobs in a resumable fashion proved to be tricky. I tried a few options, but the one that worked best was based on the `sparse-checkout` feature that enables batched checkout. While blobs are not actually fetched, an attempt to perform a checkout command after the command above causes git to fetch blobs automatically. While `fetch` command does not provide batched mode, this indirect fetching makes it possible.
 
 Now, because the above command clones all metadata, but not blobs, all files present in a checked out currently active branch will appear as deleted to git. A full list of files can be generated:

```batch
git reset >nul
git ls-files --deleted >"%ROOT%/filelist.txt"
```

This full list of files that need to be downloaded can then be used for resumable process. The simplest approach is to split it into batch files of predefined size (files per batch), have a sparse-checkout loop over the directory containing these batch files, delete individual batch files immediately after a successful sparse-checkout process, and wrap the full loop in a retry loop, forcing retry, if the number of predefined maximum retries is not reached and there are some batch file lists still remaining due to prior errors.

The full proof-of-concept Windows batch script is presented bellow:

```batch
@echo off

set "BATCH_SIZE=50"
set "MAX_RETRY=3"
set "USER=pchemguy"
set "REPO=FGVC_Aircraft_dataset"
set "URL=https://github.com/%USER%/%REPO%.git"

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "ROOT=%ROOT:\=/%"

if not exist "%ROOT%/%REPO%/.git/config" (git clone --filter=blob:none --no-checkout %URL%)
cd /d "%ROOT%/%REPO%"
git reset >nul
if not exist "%ROOT%/filelist.txt" (git ls-files --deleted >"%ROOT%/filelist.txt")
if not exist "%ROOT%/%REPO%_batches" (mkdir "%ROOT%/%REPO%_batches")

set "LINE_COUNT=0"
set "FILE_COUNT=100"

if exist "%ROOT%/%REPO%_batches/_batches_created_flag" (goto :SKIP_BATCHING)

for /f "usebackq tokens=*" %%L in ("%ROOT%/filelist.txt") do (
    echo %%L>>"%ROOT%/%REPO%_batches/batch!FILE_COUNT!.txt"
    set /a "LINE_COUNT+=1"
    set /a "LINE_COUNT%%=%BATCH_SIZE%"
    if !LINE_COUNT!==0 (set /a "FILE_COUNT+=1")
)
echo. >"%ROOT%/%REPO%_batches/_batches_created_flag"

:SKIP_BATCHING

git sparse-checkout init --no-cone

echo Starting batch checkout. Attempts left: %MAX_RETRY%.

:RETRY_BATCH_CHECKOUT

set "TOTAL_ERRORS=0"
for %%B in (%ROOT%/%REPO%_batches/batch*.txt) do (
    set "EXIT_STATUS=1"
    set "NEXT_BATCH=%ROOT%/%REPO%_batches/%%~nxB"
    echo --- Processing "%ROOT%/%REPO%_batches/%%~nxB" ---
    call git sparse-checkout add --stdin < "!NEXT_BATCH!"
    set "EXIT_STATUS=!ERRORLEVEL!"
    set /a "TOTAL_ERRORS+=!EXIT_STATUS!"
    if !EXIT_STATUS!==0 (
        del /Q "!NEXT_BATCH:/=\!"
    )
)
set /a "MAX_RETRY-=1"

if exist "%ROOT%/%REPO%_batches/batch*.txt" (
    echo Some errors have occured...
    if !MAX_RETRY! gtr 0 (
        echo Retrying batch checkout. Attempts left: %MAX_RETRY%.
        goto :RETRY_BATCH_CHECKOUT
    ) else (
        echo No more retries left. Aborting...
        exit /b 1
    )
)

call git sparse-checkout disable
echo Batched checkout is complete.
rmdir /S /Q "%ROOT%/%REPO%_batches"

```
