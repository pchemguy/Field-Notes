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
    storage/
      io.py
    service/
      api.py
      models.py          # Pydantic request/response models
      jobs.py            # job registry + filesystem paths
      executor.py        # background/worker integration
      static_ui/         # built web assets
    ui/
      gridpet_cli.py     # optional local CLI runner using same engine
  docs/
  data/                 # runtime output (gitignored)
```

```
gridpet/
  src/gridpet/
    io/
      __init__.py
      atomic.py          # atomic writes, safe replace
      json_io.py         # read/write JSON and JSONL primitives
      image_io.py        # read image with EXIF, write image/mask
      hash_io.py         # sha256 helpers
    run/
      __init__.py
      layout.py          # run dir layout + path mapping
      manifest.py        # RunManifest dataclass + read/write
      artifact_log.py    # ArtifactRecord schema + append/read
      manager.py         # RunIO (formerly IOManager) orchestrating the above
    engine/
      artifacts.py       # canonical artifact catalog + stage contracts
      context.py
      pipeline.py
      stages/
        preprocess.py
        grid_detect.py
        pitch.py
        segment.py
        area.py
        qc.py
    service/
      api.py
      models.py          # Pydantic request/response models
      jobs.py            # job registry + filesystem paths
      executor.py        # background/worker integration
      static_ui/         # built web assets
    ui/
      gridpet_cli.py     # optional local CLI runner using same engine

```

```
spleen_meter/
  pyproject.toml
  src/spleen_meter/
    __init__.py
    cli.py
    pipeline.py
    config.py
    artifacts.py
    io.py
    qc.py
    ops/
      preprocess_grid.py
      grid_nodes_morph.py
      grid_analyze_mkde.py
      grid_bbox.py
      segment_spleen.py
      measure_area.py
      visualize.py
    tests/
      test_smoke_single_image.py
      fixtures/
        sample_01.jpg
  docs/
    VISION.md
    ARCHITECTURE.md
    AGENTS.md
    DECISIONS.md
```

```
gridpet/
  __init__.py
  cli.py
  pipeline.py
  config.py
  artifacts.py
  io.py
  qc.py
  viz.py
  ops/
    preprocess_grid.py        # optional; keep minimal at v0
    grid_detect_morph.py      # your Sobel+morph node detector
    grid_detect_lsd.py        # LSD detector
    grid_postprocess_segments.py  # shared: thickness/orientation clustering -> points
    grid_analyze_mkde.py      # pitch/orientation via mKDE
    grid_bbox.py              # bbox from nodes/segments (axis aligned/oriented)
    segment_spleen.py         # Lab/HSV + GrabCut pipeline
    measure_area.py           # area = pixels / scale^2
  round_1_out/                # immutable
```