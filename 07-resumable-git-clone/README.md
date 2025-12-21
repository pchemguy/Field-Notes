<!-- https://chatgpt.com/c/69486ad4-e3cc-832c-9956-839a9ba31f9f -->

# Resumable Git Clone via Sparse Checkout (Windows, Low-Bandwidth)

## Problem Statement

`git clone` does **not** support resumable downloads. On unstable or bandwidth-limited connections, cloning large repositories becomes fragile: a single network failure causes the entire transfer to restart from scratch.

Two structural limitations are involved:

1. **No resume-on-failure semantics** for blob transfer.
2. **No clean separation between metadata and blobs** in the default workflow, despite the fact that metadata is typically a small fraction of repository size.

While Git supports *partial clones*, it provides no first-class, resumable mechanism for completing the blob transfer in controlled batches.

---

## Metadata-Only Clone

Git *can* clone repository metadata without blobs:

```bash
git clone --filter=blob:none --no-checkout <URL>
```

This creates a valid repository with:

* full commit history,
* trees,
* refs,
* but **no file contents**.

At this stage, all files appear as deleted in the working tree.

---

## Strategy: Indirect, Batched Blob Fetching

Git does **not** offer a batched or resumable `git fetch` for blobs. However:

* `git sparse-checkout add` *implicitly fetches blobs*
* Sparse paths can be supplied incrementally
* Each successful checkout persists downloaded blobs

This makes it possible to:

* split the file list into batches,
* fetch blobs batch-by-batch,
* retry failed batches,
* resume safely after interruption.

---

## Generating the File List

After metadata-only clone:

```batch
git reset >nul
git ls-files --deleted > filelist.txt
```

This produces the full list of paths requiring blob download.

---

## Execution Model

1. Split file list into fixed-size batches
2. Initialize sparse checkout (non-cone mode)
3. Iteratively:
    * add batch paths via stdin,
    * delete batch file on success,
    * retry remaining batches on failure
4. Disable sparse checkout after completion

This approach is:

* resumable,
* deterministic,
* connection-failure tolerant.

---

## Proof-of-Concept Windows Batch Script

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

---

## Notes & Limitations

* This is a **workflow hack**, not a replacement for native resumable clone support.
* Performance depends on batch size and server behavior.
* The approach is especially useful for:
    * large datasets,
    * archival repositories,
    * constrained or unstable networks.

---

## Takeaway

Git already contains the primitives needed for resumable cloning — but they are not composed into a usable, documented workflow. Sparse checkout can be repurposed to bridge this gap.

---
