https://chatgpt.com/g/g-p-6958a3950c3081919bd2dfdd2f46e96c-pet/c/69661113-f410-8330-b75e-912e350fcc1f

## 1. System goals and non-goals

### Goals

- **Non-ML classical CV pipeline** for object area estimation on mm graph paper photos.
- **Server/client** split: compute on a desktop/server; access from desktop and smartphone.
- **Modular, stage-oriented pipeline** with traceable intermediate artifacts.
- **Fast prototyping** (single-host) but **scalable** to multi-worker execution later.
- **Strong QC** at each stage, with structured metrics and flags.
- **Artifacts-first** outputs: intermediate images, overlays, masks, stats, logs, downloadable bundles.

### Non-goals (for MVP)

- Full photogrammetric calibration, robust lens model inference, batch scheduling across a cluster, user management/ACLs beyond basics.

---

## 2. Recommended top-level architecture

### Components

1. **API Server (FastAPI recommended)**
    - Receives uploads (single JPG/PNG or archive ZIP/TAR/TAR.GZ).
    - Creates “jobs”, schedules processing, streams job state.
    - Serves artifacts and HTML/JS web UI.
2. **Processing Engine (Python package)**
    - Pure Python module(s) implementing the pipeline stages.
    - Zero dependency on FastAPI/web concepts.
    - Produces artifacts and metrics through a stable interface.
3. **Job Runner / Executor**
    - MVP: in-process background execution (FastAPI BackgroundTasks or a simple thread/process pool).
    - Scale-up: external queue (RQ/Celery/Arq) with one or more worker processes.
4. **Artifact Store (filesystem-first)**
    - A structured directory per job and per image.
    - Artifacts are files + a canonical JSON manifest.
    - Easy to download as a bundle; easy to inspect manually.
5. **Web UI (server-hosted static app)**
    - Upload single image or directory (as archive).
    - Smartphone: capture image via `getUserMedia()` and upload directly.
    - Results page polls or subscribes to progress and progressively renders previews.

---

## 3. Why FastAPI over Flask

### FastAPI advantages for this design

- Native **OpenAPI** schema generation (critical for client tooling and future integrations).
- First-class **type hints / validation** (Pydantic) for stable contracts: job status, manifest schema, QC schema.
- Easier to add **async** endpoints (upload + progress + streaming logs) and SSE/WebSockets if desired.
- Cleaner long-term maintainability in a modular system.

Flask is still viable, but FastAPI aligns better with “scalable, modular, server/client, contract-driven” goals.

---

## 4. Domain model and storage specification

### 4.1 Job and ImageRun entities

- **Job**: one user submission; contains N images.
- **ImageRun**: processing of a single image within a job.

Each Job has:

- `job_id` (UUID)
- `created_at`
- `inputs[]` (list of original filenames + derived `image_id`)
- `status` (queued/running/partial_failed/succeeded/failed)
- `progress` (0–100, plus stage detail)
- `links` (API URLs)

Each ImageRun has:

- `image_id`
- `status` (same)
- `stage_states[]`
- `qc_summary` (pass/warn/fail + reasons)
- `outputs` (artifact references)

### 4.2 Artifact store layout (filesystem)

A deterministic layout so that both humans and tools can navigate:

```
data/
  jobs/
    {job_id}/
      job.json
      input/
        original/
          {image_id}.jpg
      images/
        {image_id}/
          manifest.json
          stages/
            01_preprocess/
              img_preprocessed.png
              metrics.json
            02_grid_detect/
              grid_lines.png
              grid_points.json
              metrics.json
            03_pitch/
              pitch_plot.png
              metrics.json
            04_segmentation/
              mask.png
              overlay.png
              metrics.json
            05_area/
              result.json
              metrics.json
            99_qc/
              qc.json
          logs/
            pipeline.log
          previews/
            thumb.jpg
            overlay_preview.jpg
      bundles/
        job_artifacts.zip
```

### 4.3 Manifest (per image)

A single canonical JSON that the UI and CLI can rely on:

`manifest.json` (example structure)

- `image_id`, `source_filename`, `timestamps`
- `pipeline_version` (git commit or semantic version)
- `parameters` (all stage params, including auto-derived values)
- `stages[]`:
    - `stage_id`, `name`, `status`, `start/end`, `metrics_path`, `artifacts[]`
- `results`:
    - `area_mm2`, `area_px`, `scale_mm_per_px`, confidence/uncertainty if available
- `qc`:
    - `summary`: pass/warn/fail
    - `checks[]`: each with `id`, `severity`, `value`, `threshold`, `message`

This manifest is the *contract* that allows you to evolve internals without breaking clients.

---

## 5. Processing pipeline specification

### 5.1 Pipeline stages (MVP)

Stage IDs are stable; internals may evolve.

1. **Preprocessing**
    - Inputs: original image
    - Outputs:
        - normalized image (`img_preprocessed.png`)
        - metrics: brightness/contrast stats, noise estimate, glare estimate (if possible)
2. **Grid detection**
    - Outputs:
        - grid line overlay image
        - grid intersections / line model params
        - metrics: detected line count, orientation histogram, inlier ratio
3. **Grid data processing + pitch estimation**
    - Outputs:
        - estimated pitch (mm/px or px/mm)
        - metrics: pitch distribution, robust spread, confidence score
    - Decision: if pitch confidence low → QC warn/fail
4. **Segmentation**
    - Outputs:
        - binary mask
        - overlay
        - metrics: mask area px, edge smoothness proxies, connected components, fill holes stats
5. **Area computation**
    - Outputs:
        - `area_px`, `area_mm2` (using pitch)
        - optional perimeter, convex hull area, etc.
6. **QC aggregation**
    - Consolidates stage QC into final QC verdict.
    - Writes `qc.json` and updates `manifest.json`.

### 5.2 Advanced stages (later)

- **Geometry distortion estimation / compensation**
    - Introduce stages:
        - `03b_distortion_estimate`
        - `03c_rectification`
    - Contract remains unchanged: pitch and scale are derived from whichever geometry model is active.

### 5.3 Stage interface (internal)

Each stage should implement a uniform interface:

- Input: `PipelineContext` (paths, params, shared computed artifacts)
- Output: `StageResult`:
    - artifacts produced
    - metrics dict
    - QC check results
    - updated context fields

This enables:

- stage swapping
- stage skipping
- re-running a single stage with different params (fast iteration)

---

## 6. Execution model and scalability

### MVP execution

- API server accepts upload → creates job → schedules background processing.
- Use a **process pool** for CPU-heavy OpenCV work (safer than threads).
- Maintain a lightweight job registry:
    - `job.json` updated incrementally (atomic writes)
    - per-image manifest updated after each stage

### Scale-up path

Replace in-process execution with:

- Redis + RQ/Celery/Arq
- A dedicated `gridpet-worker` process
- Same artifact store + manifest contract
- API server becomes orchestration + artifact serving

This keeps the compute core unchanged.

---

## 7. API surface specification (versioned)

All endpoints under `/api/v1`.

### Upload and job creation

- `POST /jobs`
    - Accept:
        - `multipart/form-data` with `file` (jpg/png/zip/tar/tar.gz)
        - optional JSON `options` (pipeline profile, QC strictness, preview settings)
    - Returns: `{job_id, status_url, results_url}`

### Job status and progress

- `GET /jobs/{job_id}`
    - Returns job summary + per-image status
- `GET /jobs/{job_id}/events` (optional)
    - SSE stream of stage progress events (nice-to-have; polling is fine for MVP)

### Results and artifacts

- `GET /jobs/{job_id}/images/{image_id}/manifest`
- `GET /jobs/{job_id}/images/{image_id}/artifact/{artifact_path}`
    - Artifact path should be validated (no traversal)
- `GET /jobs/{job_id}/bundle`
    - Returns zip of all artifacts (or triggers generation if missing)

### Lightweight previews for UI

- `GET /jobs/{job_id}/images/{image_id}/previews`
    - Returns URLs for thumbnails and overlay previews (JPG) plus key metrics

### Automation-friendly CLI patterns

- Upload:
    - `curl -F "file=@images.tar.gz" https://host/api/v1/jobs`
- Poll status:
    - `curl https://host/api/v1/jobs/{job_id}`
- Download bundle:
    - `curl -L -o job.zip https://host/api/v1/jobs/{job_id}/bundle`

---

## 8. Web UI specification

### Pages

1. **Upload page**
    - Desktop: drag-drop single file or archive.
    - Smartphone:
        - “Capture” using `getUserMedia()` and upload directly.
        - Also allow “choose from gallery” for fallback.
2. **Job results page**
    - Immediately navigates to `/jobs/{job_id}` (UI route).
    - Shows:
        - list of images with per-stage progress
        - QC summary per image (pass/warn/fail)
        - gradually populates preview tiles as they appear
    - Interaction:
        - click image → detail view with stage tabs and downloadable artifacts

### Data acquisition strategy

- MVP: polling `GET /api/v1/jobs/{job_id}` every 0.5–2s with backoff.
- Later: SSE/WebSocket event stream.

### Preview policy

- Server stores **PNG** intermediates for fidelity.
- Server produces **JPG previews** (thumbnails/overlays) for UI speed.
- UI never needs to download full PNGs unless user clicks “download”.

---

## 9. QC and statistics: contract and minimum set

### QC design principles

- QC is not “one score”; it is a list of explicit checks with thresholds and severity.
- Checks should be stage-local, then aggregated.

### Minimum QC checks (MVP)

- Preprocess:
    - saturation / clipped highlights ratio
    - blur estimate (e.g., variance of Laplacian)
- Grid:
    - detected line count above minimum
    - two dominant orthogonal orientations present
    - inlier ratio above threshold
- Pitch:
    - robust spread within limits
    - pitch within plausible mm grid bounds (domain knowledge)
- Segmentation:
    - single dominant component
    - mask not touching image border (optional but useful)
- Area:
    - area within plausible bounds (domain knowledge; warn-only initially)

### Statistical outputs

- Persist per-image metrics and also a job-level `summary.json`:
    - distribution of pitch estimates
    - area stats
    - QC counts

---

## 10. Modularity and code organization (recommended)

At repository level, separate “engine” from “service”:

```
gridpet/
  src/gridpet/
    engine/
      pipeline.py
      context.py
      stages/
        preprocess.py
        grid_detect.py
        pitch.py
        segment.py
        area.py
        qc.py
      artifacts.py
      metrics_schema.py
    service/
      api.py
      models.py          # Pydantic request/response models
      jobs.py            # job registry + filesystem paths
      executor.py        # background/worker integration
      static_ui/         # built web assets
    cli/
      gridpet_cli.py     # optional local CLI runner using same engine
  docs/
  data/                 # runtime output (gitignored)
```

Key rule: **engine must be runnable without the server** (critical for fast iteration and unit tests).

---

## 11. Versioning, reproducibility, and prototyping discipline

- Every manifest includes:
    - `pipeline_version` (git commit hash)
    - `config_profile` name
    - full resolved parameters (including auto-tuned values)
- Support a “re-run image with same params” action by storing params in manifest.
- Add a “pipeline profile” concept early:
    - `mvp_default`
    - `high_glare`
    - `fast_preview`
    - etc.

---

## 12. Security and operational considerations (pragmatic MVP)

- Limit upload size; enforce content-type and extension checks.
- Archive extraction must prevent path traversal and zip bombs.
- Job IDs should be unguessable (UUIDv4 is fine).
- Provide basic retention policy:
    - delete jobs older than N days, or manual cleanup endpoint (admin-only in later stages).

---

## 13. MVP scope boundary (explicit)

### MVP deliverables

- FastAPI server with:
    - upload (jpg + zip/tar)
    - background processing
    - job status polling
    - artifact serving + job bundle download
- Engine with:
    - preprocess, grid detect, pitch, segmentation, area, QC
- Web UI:
    - upload + results with progressive previews

### Deferred (but architected for)

- distortion estimation/rectification
- multi-host scaling via queue
- auth/users/projects
- advanced QC analytics dashboard

## 14. Recommended UI frameworks (no HTML required)

If you do not want to write HTML (at all) and you want **fast prototyping with minimal boilerplate**, you should treat the UI as a *Python-first* layer that sits on top of your FastAPI “job/artifact” backend.

### 1) Streamlit (best “minimum boilerplate”)

Use if you want the fastest path to a usable UI:

- Pure Python UI code; essentially no web dev.
- Has **native camera capture** on mobile via `st.camera_input`.
- Very fast to iterate; good for internal tools and early MVP.
- Can call your FastAPI endpoints (or share the engine directly).

Trade-offs:

- Less control over “progressively populated results page” as a traditional web app; you implement progress via reruns/polling patterns.
- Not a classical multi-page web app; it’s an app-style UI.

**Best for:** MVP and rapid experimentation with pipeline stages and QC visualization.

### 2) Gradio (best for “submit → async job → live progress/results”)

Use if your UI is fundamentally “upload/capture → run → display artifacts”:

- Pure Python; minimal boilerplate.
- Strong fit for **queued jobs**, progress, and per-image outputs.
- Has webcam/camera components that work well on mobile.
- Clean integration with an async backend.

Trade-offs:

- UI layout is more “app-like” than “website-like”.
- If you want a very custom results dashboard, you may eventually prefer NiceGUI/Panel.

**Best for:** your exact workflow with progressive artifacts and simple interaction.

### 3) NiceGUI (best “Python UI, but closer to a real web app”)

Use if you want a more “web app” feel without writing HTML:

- Python-only UI code, built on a component model (Quasar/Vue under the hood).
- Good for multi-page navigation, richer layout, and a true results dashboard.
- You can implement polling or push updates for job progress cleanly.

Trade-offs:

- Slightly more framework surface area than Streamlit/Gradio.

**Best for:** a more product-like UI while still staying Python-only.

### 4) Panel (HoloViz) / Dash

Use if you anticipate heavier analytics dashboards (plots, tables, QC metrics):

- Strong dashboarding ecosystem.
- More “engineering overhead” than Streamlit/Gradio, but very capable.

**Best for:** later-stage QC/analytics dashboards.

---

### What I would choose for GridPET (given your constraints)

#### MVP UI: **Gradio** (or Streamlit if you prefer its simplicity)

- You have a **job model** and **artifacts** that appear over time. Gradio maps well to:
    - upload/camera capture
    - trigger processing
    - stream progress
    - show intermediate images/overlays/metrics as they become available

#### Product-like UI: **NiceGUI**

- When you want:
    - a results “workspace” page per job,
    - artifact browsers, tabs per stage, QC summaries,
    - a more traditional navigation structure.

---

### How this fits your FastAPI + curl automation requirement

Keep **FastAPI as the canonical backend** (API + job/artifact store). Then pick one:

#### Option A (cleanest): UI is a separate Python app that calls FastAPI

- `FastAPI`: `/api/v1/jobs`, `/api/v1/artifacts`, `/api/v1/bundle` (your automation and clients)
- `Gradio/Streamlit/NiceGUI`: calls the API and renders results
- Pros: clear separation; UI can change without breaking automation.

#### Option B (tighter): mount UI inside FastAPI (possible, framework-dependent)

- Works, but can be slightly more complex operationally.
- I generally prefer Option A unless you strongly want a single process.

---

### Bottom line

- If your priority is **fast prototyping, no HTML, minimal boilerplate**: **Streamlit**.
- If your priority is **submit jobs, track progress, progressively display artifacts**: **Gradio** (my recommended MVP choice for GridPET).
- If you want **Python-only but more “real web app” control**: **NiceGUI**.
