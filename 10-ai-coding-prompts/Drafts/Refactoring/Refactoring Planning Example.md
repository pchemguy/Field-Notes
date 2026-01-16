https://chatgpt.com/c/696744d4-77a0-832f-a4a5-8bae79ebaa17

## Sample Refactoring Planning

### User Prompt 1

Do I need to refactor io.py to have io.py+artifacts.py architecture match modern established best practices, making the code organization clear and sensible to an expert?

#### `io.py`

```python
"""GridPET run-scoped filesystem and serialization utilities.

This module provides a *non-algorithmic* I/O facade for GridPET pipeline runs.

A "run" corresponds to processing a single input image and producing a structured
output directory containing:
  - a copied input image (for auditability / reproducibility),
  - PNG artifacts (debug views, masks, overlays, intermediate visualizations),
  - JSON artifacts (measurements, QC, structured metadata),
  - a run manifest and an append-only artifact log.

Design constraints / non-goals:
  - No computer-vision logic or algorithmic decision-making lives here.
  - No preprocessing, filtering, resizing, or interpretation of results.
  - This module only standardizes filesystem layout, serialization, and logging.

Key conventions:
  - Images are represented in memory as `np.ndarray` uint8:
      * HxW uint8 (single-channel), or
      * HxWx3 uint8 (BGR for color images).
  - Input ingestion is explicit and auditable:
      * absolute paths are copied into the run's `input/` directory,
      * collision handling is controlled via `CollisionPolicy`.
  - Artifact naming is stable and derived from the primary input stem:
      `<input_stem>__<suffix>.<ext>`
  - Artifact registry is append-only JSON Lines (`artifacts.jsonl`) with a UTC
    timestamp and optional metadata.

This module is intentionally small and conservative to keep it testable and
stable across refactors, and to allow future orchestration layers (CLI, GUI,
batch runner) to reuse it unchanged.

https://chatgpt.com/g/g-p-6958a3950c3081919bd2dfdd2f46e96c-pet/c/6958a4c0-b904-8330-a504-82073734c0e1
"""

from __future__ import annotations

__all__ = ["IOManager", "CollisionPolicy", "ArtifactKind", "RunManifest"]

import hashlib
import json
import secrets
import shutil
import string
from collections.abc import Mapping, MutableMapping
from dataclasses import asdict, dataclass, field
from datetime import UTC, datetime
from enum import Enum
from pathlib import Path
from typing import Any

import cv2
import numpy as np
from PIL import Image, ImageOps

JsonMapping = Mapping[str, Any]


class CollisionPolicy(str, Enum):
    """Policy for handling filename collisions during input ingestion.

    Attributes:
      FAIL:
        Reject if the destination already exists.
      OVERWRITE:
        Remove the destination and replace it with the new file.
      RESUME:
        If destination exists, compare SHA-256 hashes:
          - if identical, treat as already ingested and proceed,
          - if different, raise an error.

    This policy only applies to ingesting the *primary input image* into the run.
    Artifact writing is handled separately and currently does not support
    collision policies (artifacts are expected to be uniquely named by suffix).
    """

    FAIL = "fail"
    OVERWRITE = "overwrite"
    RESUME = "resume"


class ArtifactKind(str, Enum):
    """High-level category for run artifacts.

    `ArtifactKind` controls which run subdirectory an artifact is written to.
    It is a classification mechanism only; it does not imply file type.

    Notes:
      - PNG artifacts may be written under any kind (grid overlays, segmentation
        masks, preprocess debug views, etc.).
      - JSON artifacts similarly may be written under any kind.
    """

    INPUT = "input"
    PREPROCESS = "preprocess"
    GRID = "grid"
    GEOM = "geom"
    SEGMENTATION = "segmentation"
    MEASUREMENT = "measurement"
    QC = "qc"
    LOGS = "logs"


def _utc_now_iso() -> str:
    """Return current time as an ISO-8601 UTC timestamp.

    Returns:
      ISO-8601 string with milliseconds, e.g. "2026-01-11T14:32:05.417+00:00".
    """
    return datetime.now(UTC).isoformat(timespec="milliseconds")


def make_default_run_id() -> str:
    """Generate a collision-resistant run identifier suitable for folder names.

    The ID is time-based with a short random suffix to avoid collisions when
    multiple runs start within the same millisecond or on parallel workers.

    Format:
      run_YYYYMMDD_HHMMSS_mmm_<8-char suffix>

    Example:
      run_20260111_143205_417_a9F3K2Qx

    Returns:
      A run identifier string intended for use as a directory name.
    """
    ts = datetime.now().strftime("%Y%m%d_%H%M%S_%f")[:-3]  ## milliseconds
    alphabet = string.ascii_letters + string.digits
    suffix = "".join(secrets.choice(alphabet) for _ in range(8))
    return f"run_{ts}_{suffix}"


def _sha256_file(path: Path, *, chunk_size: int = 1024 * 1024) -> str:
    """Compute a SHA-256 hash of a file.

    Args:
      path: Path to an existing file.
      chunk_size: Read chunk size in bytes.

    Returns:
      Hex digest of the SHA-256 hash.

    Raises:
      OSError: If the file cannot be opened/read.
    """
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(chunk_size), b""):
            h.update(chunk)
    return h.hexdigest()


def _validate_image_u8(image: np.ndarray) -> None:
    """Validate that an image array is uint8 and has a supported shape.

    Supported shapes:
      - HxW (single-channel)
      - HxWx3 (3-channel BGR/RGB, uint8)

    Args:
      image: Numpy array expected to be an image.

    Raises:
      ValueError: If `image` is not a numpy array, not uint8, or has an invalid
        dimensionality/channel count.
    """
    if not isinstance(image, np.ndarray):
        raise ValueError(f"Expected numpy array; got: {type(image)}")
    if image.dtype != np.uint8:
        raise ValueError(f"Expected uint8 image; got dtype={image.dtype}")
    if image.ndim == 2:
        return
    if image.ndim == 3 and image.shape[2] == 3:
        return
    raise ValueError(f"Expected HxW or HxWx3; got shape={image.shape}")


def encode_mask_u8(mask: np.ndarray, *, true_value: int = 255) -> np.ndarray:
    """Validate and encode a binary-like mask into uint8 {0,true_value}.

    This function standardizes masks for writing as PNG, ensuring:
      - 2D shape (HxW)
      - boolean or integer dtype
      - values are binary-like (subset of {0,1,255}) for integer masks

    Args:
      mask: 2D mask array.
      true_value: Value to use for "True" pixels in the output, in [1,255].

    Returns:
      A uint8 mask with values in {0,true_value}.

    Raises:
      ValueError: If mask is not a numpy array, not 2D, not binary-like, or if
        `true_value` is out of range.
    """
    """Validate and encode a binary-like mask into uint8 {0,true_value}."""
    if not isinstance(mask, np.ndarray):
        raise ValueError(f"Expected numpy array; got: {type(mask)}")
    if mask.ndim != 2:
        raise ValueError(f"Expected 2D mask (HxW); got shape={mask.shape}")
    if not (1 <= int(true_value) <= 255):
        raise ValueError(f"true_value must be in [1,255]; got: {true_value}")

    if mask.dtype == np.bool_:
        m = mask
    else:
        if not np.issubdtype(mask.dtype, np.integer):
            raise ValueError(f"Mask must be bool or integer; got dtype={mask.dtype}")
        unique = np.unique(mask)
        if unique.size == 0:
            raise ValueError("Mask is empty (no elements).")
        allowed = {0, 1, 255}
        if not set(int(v) for v in unique).issubset(allowed):
            raise ValueError(f"Mask not binary-like; unique values: {unique.tolist()}")
        m = mask != 0

    out = np.zeros(m.shape, dtype=np.uint8)
    out[m] = np.uint8(true_value)
    return out


@dataclass(frozen=True, slots=True)
class RunManifest:
    """Run metadata persisted to `run_manifest.json`.

    The manifest is written at run creation time and updated after input ingestion.
    It is intended as a lightweight audit record and "run header".

    Attributes:
      run_id: Run directory identifier.
      created_at_utc: ISO-8601 UTC creation timestamp.
      gridpet_version: Version string for the producing build (informational).
      input_original_path: Absolute path of the source input image, if known.
      input_copied_path: Path to the ingested copy inside the run directory.
      input_sha256: SHA-256 of the ingested input copy, if computed.
      config_snapshot: Optional configuration snapshot used for this run. This is
        stored as JSON in the manifest and should be kept reasonably small.

    Notes:
      - This dataclass is not used as a live in-memory state object; it is a
        schema for initial manifest writing.
      - Manifest updates are performed as best-effort merges by IOManager.
    """

    run_id: str
    created_at_utc: str
    gridpet_version: str = "0.0.0+dev"
    input_original_path: str | None = None
    input_copied_path: str | None = None
    input_sha256: str | None = None
    config_snapshot: dict[str, Any] = field(default_factory=dict)


@dataclass(slots=True)
class IOManager:
    """Run-scoped I/O facade for a single-image GridPET run.

    `IOManager` is the single source of truth for:
      - run directory layout,
      - ingesting and reading the primary input image,
      - artifact naming conventions,
      - writing PNG/JSON artifacts and logging them.

    Typical usage:
      1) ioman = IOManager.create(out_root)
      2) img_bgr = ioman.read_image_bgr(abs_input_path)  ## ingests + reads
      3) ioman.write_png(ArtifactKind.GRID, suffix="overlay", ...)
      4) ioman.write_measurement_json({...})
      5) ioman.write_qc_json({...})

    Important invariants:
      - `input_stem` and `input_name` are set only after a primary input is
        recorded (via `ingest_input()` or `read_image_bgr()`).
      - Artifact filenames are derived from `input_stem` and require it to be set.
      - Artifact descriptions must be unique *within a process* for a given
        IOManager instance (enforced by `_descriptions`). This is primarily a
        guardrail against accidental duplicate logging during development.

    Thread/process notes:
      - IOManager is not designed for concurrent writes from multiple processes to
        the same run directory. `artifacts.jsonl` is append-only but not locked.
    """

    run_dir: Path
    input_dir: Path
    preprocess_dir: Path
    grid_dir: Path
    geom_dir: Path
    segmentation_dir: Path
    measurement_dir: Path
    qc_dir: Path
    logs_dir: Path

    ## Per-run registry/log files (fixed names).
    manifest_path: Path
    artifacts_log_path: Path

    ## Primary input identity (set after ingest_input).
    input_stem: str | None = None
    input_name: str | None = None

    ## In-memory uniqueness guard for descriptions.
    _descriptions: set[str] = field(default_factory=set, repr=False, compare=False)

    @classmethod
    def create(
        cls,
        out_root: Path,
        run_id: str | None = None,
        *,
        gridpet_version: str = "0.0.0+dev",
        config_snapshot: Mapping[str, Any] | None = None,
    ) -> IOManager:
        """Create a new run directory tree and initialize the run manifest.

        This method eagerly creates all subdirectories for the run and writes an
        initial manifest (`run_manifest.json`) containing run metadata and an
        optional config snapshot.

        Args:
          out_root: Output root directory under which run directories are created.
            The directory is created if it does not exist.
          run_id: Optional explicit run directory name. If omitted, a default
            timestamp-based ID is generated.
          gridpet_version: Version string to record in the manifest.
          config_snapshot: Optional mapping of configuration values to record in the
            manifest.

        Returns:
          An initialized `IOManager` for the created run.

        Raises:
          ValueError: If `out_root` exists and is not a directory.
          OSError: If directories or manifest cannot be created/written.
        """
        out_root = out_root.expanduser().resolve()
        if out_root.exists() and not out_root.is_dir():
            raise ValueError(f"out_root exists and is not a directory: {out_root}")

        out_root.mkdir(parents=True, exist_ok=True)

        run_id = run_id or make_default_run_id()
        run_dir = (out_root / run_id).resolve()

        ioman = cls(
            run_dir=run_dir,
            input_dir=run_dir / "input",
            preprocess_dir=run_dir / "preprocess",
            grid_dir=run_dir / "grid",
            geom_dir=run_dir / "geom",
            segmentation_dir=run_dir / "segmentation",
            measurement_dir=run_dir / "measurement",
            qc_dir=run_dir / "qc",
            logs_dir=run_dir / "logs",
            manifest_path=run_dir / "run_manifest.json",
            artifacts_log_path=run_dir / "artifacts.jsonl",
            input_stem=None,
            input_name=None,
        )

        for d in (
            ioman.run_dir,
            ioman.input_dir,
            ioman.preprocess_dir,
            ioman.grid_dir,
            ioman.geom_dir,
            ioman.segmentation_dir,
            ioman.measurement_dir,
            ioman.qc_dir,
            ioman.logs_dir,
        ):
            d.mkdir(parents=True, exist_ok=True)

        ## Write initial manifest immediately (dummy input fields; filled after ingest).
        manifest = RunManifest(
            run_id=run_id,
            created_at_utc=_utc_now_iso(),
            gridpet_version=gridpet_version,
            config_snapshot=dict(config_snapshot or {}),
        )
        ioman._write_manifest(manifest)

        return ioman

    ## --------------------------
    ## Input ingestion + reading
    ## --------------------------

    def ingest_input(
        self,
        src_path: Path,
        *,
        collision_policy: CollisionPolicy = CollisionPolicy.FAIL,
    ) -> Path:
        """Copy the source image into `input_dir` and update the run manifest.

        The copied filename preserves `src_path.name`.

        Collision behavior is controlled by `collision_policy`:
          - FAIL: error if destination exists.
          - OVERWRITE: replace existing destination file.
          - RESUME: if destination exists, require identical SHA-256 content.

        Args:
          src_path: Absolute path to an existing file.
          collision_policy: Collision handling policy for destination filename.

        Returns:
          Path to the copied file under `input_dir`.

        Raises:
          ValueError: If `src_path` is not absolute, or if a collision occurs under
            a policy that forbids it.
          FileNotFoundError: If `src_path` does not exist or is not a file.
          OSError: If the file copy or hash read fails.
        """
        if not isinstance(src_path, Path):
            src_path = Path(src_path)

        if not src_path.is_absolute():
            raise ValueError(f"ingest_input requires an absolute path: {src_path}")

        if not src_path.is_file():
            raise FileNotFoundError(src_path)

        dst_path = self.input_dir / src_path.name

        if dst_path.exists():
            if collision_policy == CollisionPolicy.FAIL:
                raise ValueError(f"Input collision (policy=fail): {dst_path}")

            if collision_policy == CollisionPolicy.OVERWRITE:
                dst_path.unlink(missing_ok=False)

            if collision_policy == CollisionPolicy.RESUME:
                src_hash = _sha256_file(src_path)
                dst_hash = _sha256_file(dst_path)
                if src_hash != dst_hash:
                    raise ValueError(
                        "Input collision (policy=resume) but contents differ: "
                        f"{src_path} != {dst_path}"
                    )
                ## Identical file already present; do not overwrite.
                self._record_primary_input(dst_path, src_path=src_path, sha256=dst_hash)
                return dst_path

        shutil.copy2(src_path, dst_path)

        sha = _sha256_file(dst_path)
        self._record_primary_input(dst_path, src_path=src_path, sha256=sha)
        return dst_path

    def read_image_bgr(
        self,
        filename_or_abs_path: Path | str,
        *,
        collision_policy: CollisionPolicy = CollisionPolicy.FAIL,
    ) -> np.ndarray:
        """Read the primary input image as BGR uint8 with EXIF orientation applied.

        Two modes are supported:

        1) Filename-only (relative, no directories):
           The file is expected to already exist in `input_dir` and is read from
           there. This mode does not copy data and does not compute hashes.

        2) Absolute path:
           The file is first ingested into `input_dir` (see `ingest_input`) and then
           read from the ingested copy. Collision behavior is controlled via
           `collision_policy`.

        EXIF handling:
          - The image is opened via Pillow.
          - `ImageOps.exif_transpose` is applied to respect camera orientation tags.
          - The image is converted to RGB and then converted to BGR with OpenCV.

        Args:
          filename_or_abs_path: Either a filename-only reference to a file inside
            `input_dir`, or an absolute path to a source image.
          collision_policy: Collision handling policy used only for absolute paths.

        Returns:
          HxWx3 uint8 BGR image array.

        Raises:
          ValueError: If a non-absolute path includes directories.
          FileNotFoundError: If the resolved input file does not exist/is not a file.
          OSError: If ingestion or image decoding fails.
        """
        if not isinstance(filename_or_abs_path, Path):
            p = Path(filename_or_abs_path)
        else:
            p = filename_or_abs_path

        if not p.is_absolute():
            ## Disallow relative paths with directories.
            if p.parent != Path("."):
                raise ValueError(
                    f"Relative paths with directories are not allowed: {p}"
                )
            path = self.input_dir / p.name
            if not path.is_file():
                raise FileNotFoundError(path)
            self._record_primary_input(path, src_path=None, sha256=None)
        else:
            ## Absolute path: ingest first
            path = self.ingest_input(p, collision_policy=collision_policy)

        return self._read_with_exif_bgr(path)

    def _read_with_exif_bgr(self, path: Path) -> np.ndarray:
        """Read an image from disk, applying EXIF orientation, returning BGR uint8.

        Args:
          path: Path to an existing image file.

        Returns:
          HxWx3 uint8 BGR array.

        Raises:
          OSError: If the file cannot be opened or decoded.
        """
        ## Pillow -> exif transpose -> RGB -> BGR uint8
        with Image.open(path) as im:
            im = ImageOps.exif_transpose(im)
            im = im.convert("RGB")
            rgb = np.array(im, dtype=np.uint8)
        bgr = cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR)
        return bgr

    def _record_primary_input(
        self,
        copied_path: Path,
        *,
        src_path: Path | None,
        sha256: str | None,
    ) -> None:
        """Record the primary input identity and update the on-disk run manifest.

        This method:
          - sets `input_stem` and `input_name` on this instance,
          - merges input-related fields into `run_manifest.json` on disk.

        Manifest updates are best-effort: if the existing manifest cannot be read,
        a new minimal dict is created and written.

        Args:
          copied_path: Path to the input file inside the run directory.
          src_path: Optional original absolute source path.
          sha256: Optional SHA-256 of the ingested input.

        Raises:
          OSError: If the manifest cannot be written.
        """
        self.input_stem = copied_path.stem
        self.input_name = copied_path.name

        ## Update manifest on disk (best-effort; do not crash on read/merge issues).
        manifest = self._read_manifest_best_effort()
        manifest["input_copied_path"] = str(copied_path)
        if src_path is not None:
            manifest["input_original_path"] = str(src_path)
        if sha256 is not None:
            manifest["input_sha256"] = sha256
        self._atomic_write_json(self.manifest_path, manifest)

    ## --------------------------
    ## Artifact naming + registry
    ## --------------------------

    def artifact_filename(self, *, suffix: str, ext: str) -> str:
        """Build a stable artifact filename derived from the primary input stem.

        Format:
          <input_stem>__<suffix><ext>

        Args:
          suffix: A short descriptive suffix. Must be non-blank and trimmed.
          ext: File extension including the leading dot, e.g. ".png", ".json".

        Returns:
          The constructed filename.

        Raises:
          ValueError: If primary input is not set yet, or if arguments are invalid.
        """
        if not self.input_stem:
            raise ValueError(
                "Primary input not set. Call read_image_bgr()/ingest_input() first."
            )
        if not suffix or suffix.strip() != suffix:
            raise ValueError(f"suffix must be non-blank and trimmed; got: {suffix!r}")
        if not ext.startswith("."):
            raise ValueError(f"ext must start with '.'; got: {ext!r}")
        return f"{self.input_stem}__{suffix}{ext}"

    def _require_unique_description(self, description: str) -> None:
        """Enforce per-run in-memory uniqueness of artifact descriptions.

        This is a guardrail to prevent accidental duplicate artifact logging during
        development. It is not intended as a global or cross-process uniqueness
        mechanism.

        Args:
          description: Human-readable artifact description (trimmed, non-blank).

        Raises:
          ValueError: If the description is blank/untrimmed or already used.
        """
        if not description or description.strip() != description:
            raise ValueError("description must be non-blank and trimmed.")
        if description in self._descriptions:
            raise ValueError(
                f"Artifact description must be unique within run: {description!r}"
            )
        self._descriptions.add(description)

    def _log_artifact(
        self,
        *,
        kind: ArtifactKind,
        filename: str,
        description: str,
        meta: Mapping[str, Any] | None = None,
    ) -> None:
        """Append a record to the run's artifact log (`artifacts.jsonl`).

        The log is JSON Lines with stable keys:
          - ts_utc: ISO-8601 UTC timestamp
          - kind: ArtifactKind value
          - filename: run-relative filename/path string
          - description: human-readable description
          - meta: free-form JSON-serializable mapping

        Args:
          kind: Artifact category.
          filename: Run-relative filename/path string (platform separators allowed).
          description: Human-readable description (should be unique within run).
          meta: Optional additional metadata (must be JSON-serializable).

        Raises:
          OSError: If the log file cannot be created or appended to.
          TypeError: If `meta` contains non-JSON-serializable objects.
        """
        rec = {
            "ts_utc": _utc_now_iso(),
            "kind": kind.value,
            "filename": filename,
            "description": description,
            "meta": dict(meta or {}),
        }
        line = json.dumps(rec, ensure_ascii=False, sort_keys=True)
        self.artifacts_log_path.parent.mkdir(parents=True, exist_ok=True)
        with self.artifacts_log_path.open("a", encoding="utf-8") as f:
            f.write(line + "\n")

    ## --------------------------
    ## Writers (PNG/JSON)
    ## --------------------------

    def write_png(
        self,
        kind: ArtifactKind,
        *,
        suffix: str,
        description: str,
        image: np.ndarray,
        meta: Mapping[str, Any] | None = None,
    ) -> Path:
        """Write a uint8 image as PNG and register it in the artifact log.

        This is a thin persistence helper:
          - validates dtype/shape (`_validate_image_u8`)
          - chooses output directory based on `kind`
          - names the file based on primary input stem + suffix
          - writes the PNG using OpenCV
          - appends an artifact record to `artifacts.jsonl`

        Args:
          kind: Artifact category controlling output subdirectory.
          suffix: Artifact suffix used in filename generation.
          description: Human-readable description, unique within this IOManager.
          image: Image array to write (uint8, HxW or HxWx3).
          meta: Optional additional JSON-serializable metadata to merge into the
            logged metadata. Base metadata includes shape and dtype.

        Returns:
          Path to the written PNG.

        Raises:
          ValueError: If the input image is invalid or description is not unique.
          OSError: If writing fails.
        """
        _validate_image_u8(image)
        self._require_unique_description(description)

        filename = self.artifact_filename(suffix=suffix, ext=".png")
        out_dir = self._dir_for_kind(kind)
        out_dir.mkdir(parents=True, exist_ok=True)
        out_path = out_dir / filename
        if out_path.suffix.lower() != ".png":
            raise ValueError(f"Expected .png path; got: {out_path}")

        ok = cv2.imwrite(str(out_path), image)
        if not ok:
            raise OSError(f"Failed to write PNG: {out_path}")

        meta = {"shape": list(image.shape), "dtype": str(image.dtype)} | (meta or {})
        self._log_artifact(
            kind=kind,
            filename=str(out_path.relative_to(self.run_dir)),
            description=description,
            meta=meta,
        )
        return out_path

    def write_mask_png(
        self,
        kind: ArtifactKind,
        *,
        suffix: str,
        description: str,
        mask: np.ndarray,
        true_value: int = 255,
    ) -> Path:
        """Encode and write a binary-like mask as PNG and register it.

        This method standardizes masks to uint8 values {0,true_value} via
        `encode_mask_u8` and logs metadata indicating the mask encoding.

        Args:
          kind: Artifact category controlling output subdirectory.
          suffix: Artifact suffix used in filename generation.
          description: Human-readable description, unique within this IOManager.
          mask: 2D mask array (bool or integer binary-like).
          true_value: Value used for "True" pixels in output.

        Returns:
          Path to the written PNG.

        Raises:
          ValueError: If the mask is invalid or description is not unique.
          OSError: If writing fails.
        """
        image = encode_mask_u8(mask, true_value=true_value)
        meta = {"true_value": true_value, "is_mask": True}
        return self.write_png(
            kind=kind, suffix=suffix, description=description, image=image, meta=meta
        )

    def write_json(
        self,
        kind: ArtifactKind,
        *,
        suffix: str,
        description: str,
        data: JsonMapping,
        indent: int = 2,
        sort_keys: bool = True,
    ) -> Path:
        """Write a JSON artifact and register it in the artifact log.

        Args:
          kind: Artifact category controlling output subdirectory.
          suffix: Artifact suffix used in filename generation.
          description: Human-readable description, unique within this IOManager.
          data: JSON-serializable mapping to write.
          indent: JSON indentation level.
          sort_keys: Whether to sort keys in the output JSON.

        Returns:
          Path to the written JSON file.

        Raises:
          ValueError: If description is not unique or filename construction fails.
          TypeError: If `data` is not JSON-serializable.
          OSError: If writing fails.
        """
        self._require_unique_description(description)

        filename = self.artifact_filename(suffix=suffix, ext=".json")
        out_dir = self._dir_for_kind(kind)
        out_dir.mkdir(parents=True, exist_ok=True)
        out_path = out_dir / filename
        if out_path.suffix.lower() != ".json":
            raise ValueError(f"Expected .json path; got: {out_path}")

        payload = json.dumps(
            data, ensure_ascii=False, indent=indent, sort_keys=sort_keys
        )
        out_path.write_text(payload + "\n", encoding="utf-8")

        self._log_artifact(
            kind=kind,
            filename=str(out_path.relative_to(self.run_dir)),
            description=description,
        )
        return out_path

    def write_measurement_json(self, measurement: JsonMapping) -> Path:
        """Convenience helper to write the final measurement JSON artifact.

        This writes under `ArtifactKind.MEASUREMENT` with a canonical suffix and
        description.

        Args:
          measurement: JSON-serializable mapping containing final measurements.

        Returns:
          Path to the written JSON file.
        """
        ## Description uniqueness is enforced; caller can still choose to not use this helper.
        return self.write_json(
            ArtifactKind.MEASUREMENT,
            suffix="measurement",
            description="Final measurement (JSON)",
            data=measurement,
        )

    def write_qc_json(self, qc: JsonMapping) -> Path:
        """Convenience helper to write the final QC JSON artifact.

        This writes under `ArtifactKind.QC` with a canonical suffix and description.

        Args:
          qc: JSON-serializable mapping containing QC status and details.

        Returns:
          Path to the written JSON file.
        """
        return self.write_json(
            ArtifactKind.QC,
            suffix="qc",
            description="Quality control report (JSON)",
            data=qc,
        )

    ## --------------------------
    ## Manifest helpers
    ## --------------------------

    def _write_manifest(self, manifest: RunManifest) -> None:
        """Write the run manifest dataclass to disk as JSON.

        Args:
          manifest: RunManifest instance.

        Raises:
          OSError: If the manifest cannot be written.
          TypeError: If the manifest contains non-serializable fields.
        """
        self._atomic_write_json(self.manifest_path, asdict(manifest))

    def _read_manifest_best_effort(self) -> MutableMapping[str, Any]:
        """Read the run manifest as a mutable mapping, best-effort.

        Returns:
          A dict of manifest fields if read/parse succeeds, otherwise an empty dict.

        Notes:
          This method deliberately swallows exceptions to avoid making manifest
          parsing a hard runtime dependency. Callers should treat missing keys as
          optional.
        """
        try:
            return dict(json.loads(self.manifest_path.read_text(encoding="utf-8")))
        except Exception:
            return {}

    def _atomic_write_json(self, path: Path, data: Mapping[str, Any]) -> None:
        """Atomically write a JSON file to disk using a temporary sibling file.

        The implementation writes to `<path>.tmp` and then replaces `path`.

        Args:
          path: Destination path.
          data: JSON-serializable mapping.

        Raises:
          OSError: If writing or replace fails.
          TypeError: If `data` is not JSON-serializable.
        """
        tmp = path.with_suffix(path.suffix + ".tmp")
        payload = json.dumps(data, ensure_ascii=False, indent=2, sort_keys=True)
        tmp.write_text(payload + "\n", encoding="utf-8")
        tmp.replace(path)

    ## --------------------------
    ## Internal directory mapping
    ## --------------------------

    def _dir_for_kind(self, kind: ArtifactKind) -> Path:
        """Map an ArtifactKind to its corresponding run subdirectory.

        Args:
          kind: ArtifactKind enum value.

        Returns:
          Directory path under the run directory.

        Raises:
          ValueError: If `kind` is unknown (defensive against stale enums).
        """
        dir_from_kind = {
            ArtifactKind.INPUT: self.input_dir,
            ArtifactKind.PREPROCESS: self.preprocess_dir,
            ArtifactKind.GRID: self.grid_dir,
            ArtifactKind.GEOM: self.geom_dir,
            ArtifactKind.SEGMENTATION: self.segmentation_dir,
            ArtifactKind.MEASUREMENT: self.measurement_dir,
            ArtifactKind.QC: self.qc_dir,
            ArtifactKind.LOGS: self.logs_dir,
        }
        if kind not in dir_from_kind:
            raise ValueError(f"Unknown ArtifactKind: {kind}")

        return dir_from_kind[kind]
```

### AI Response 1

You do not *need* to refactor for correctness, but you **should refactor** (lightly) if your goal is “clear and sensible to an expert,” because your current `io.py` is doing two jobs:

1. **Run I/O plumbing** (directories, atomic writes, encoding, reading images)
2. **Artifact semantics** (kinds, naming conventions, artifact log schema, “final measurement/qc” convenience methods)

That is not “wrong,” but it is enough of a boundary blur that an experienced reviewer will likely recommend separating “mechanism” from “policy/contract.”

The best-practice outcome is:

* `io.py`: *mechanism* — “how we persist things safely”
* `engine/artifacts.py`: *contract/policy* — “what we persist, how it’s named, what’s required/optional, and what it means”

You can get there without a big rewrite.

---

#### What “modern established best practice” looks like here

A common, expert-friendly pattern in data/vision pipelines is a clean split between:

##### A) Storage backend / run filesystem (I/O mechanism)

* directory creation
* atomic write helpers
* write/read primitives (png/json/npy)
* safe ingestion of inputs (copy, hash, collision policy)
* **no domain vocabulary** (no “grid overlay” knowledge)

##### B) Artifact catalog + run contract (domain policy)

* artifact identifiers and their semantics
* stage→artifact mapping (required/optional)
* stable naming policy (suffixes, file types)
* artifact log schema (keys, meaning)
* “deliverables” vs debug artifacts
* (optionally) a manifest view for API/UI

Your current file mixes A and B.

---

#### Recommended refactor level: “moderate, low-risk”

##### Keep `IOManager` (mostly) as-is, but move “policy” out

Specifically:

###### Move out of `io.py` into `engine/artifacts.py`

* `ArtifactKind` (arguable, but it’s domain vocabulary: preprocess/grid/geom/…)
* naming policy text + suffix standards (the “input_stem__suffix.ext” rule)
* the `artifacts.jsonl` record schema (keys and meaning)
* canonical artifact IDs (preprocess image, grid points, overlay, etc.)
* stage contracts (required/optional)
* convenience functions like `write_measurement_json` / `write_qc_json` (these are domain policy)

###### Leave in `io.py`

* `CollisionPolicy`
* `RunManifest` as a persistence schema for run header (could stay here)
* `IOManager` directory creation and basic file ops
* `read_image_bgr`, EXIF handling
* `_atomic_write_json`, `_sha256_file`, `_validate_image_u8`, `encode_mask_u8`
* generic `write_png`, `write_json`, `write_mask_png` (they are mechanisms)

This yields a very clear story: `io.py` is a run-scoped storage facade; `artifacts.py` defines what the engine emits.

---

#### A cleaner “expert” architecture in your repo

Given your folder layout, the cleanest organization is:

* `gridpet/io.py`
  “run-scoped filesystem and serialization utilities”
* `gridpet/engine/artifacts.py`
  “artifact catalog + naming/contract + log record schema”
* optionally: `gridpet/engine/run_inspect.py` or `gridpet/service/artifact_index.py`
  “read artifacts.jsonl and provide a queryable view to API/UI”

That last piece matters because “artifact discovery” is operational/UI-facing, and experts typically keep it out of the low-level I/O primitives.

---

#### Concrete refactor plan (minimal churn)

##### Step 1: introduce `engine/artifacts.py` as definitions-only

Add:

* `ArtifactId` enum
* `ArtifactDef` dataclass:
    * `artifact_id`
    * `kind` (or “bucket”)
    * `suffix`, `ext`
    * `stage`
    * `is_deliverable`
    * `description`
* `ARTIFACTS` registry
* `REQUIRED_BY_STAGE`, `OPTIONAL_BY_STAGE`

No I/O here.

##### Step 2: adjust stages to stop using raw suffix strings

Stages use `ArtifactId` lookups to get `kind` and `suffix`.

##### Step 3: remove domain convenience methods from `IOManager`

Replace `write_measurement_json()` / `write_qc_json()` with either:

* helpers in `engine/artifacts.py` (if you allow thin wrappers that call IOManager), or better:
* keep them in engine stage code (explicit is fine), using the artifact catalog.

##### Step 4: decide what `ArtifactKind` really is

Two defensible options:

* Keep `ArtifactKind` in `io.py` if you interpret it as purely “directory mapping.”
* Move it to `engine/artifacts.py` if you interpret it as “domain taxonomy of outputs.”

Experts will accept either, but if you want maximal conceptual purity: move it.

---

#### When you should *not* refactor

Don’t refactor right now if:

* you are in early PoC mode and moving fast
* there is no service/UI yet consuming artifacts
* you do not yet know the stable artifact set

In that phase, a single `IOManager` doing both is acceptable.

But once you:

* expose artifacts through FastAPI
* start writing regression tests around outputs
* want consistent naming across runs and versions

…then separating definitions (contract) from I/O (mechanism) becomes high leverage.

---

#### Bottom line recommendation

If your objective is “reads as established best practice to an expert,” do a **small refactor**:

* keep `io.py` as storage mechanism
* make `engine/artifacts.py` the single source of truth for artifact definitions, suffixes, and stage contracts
* ensure stages never invent suffix strings again

This is not a rewrite; it is mainly moving definitions and deleting convenience helpers that embed domain choices.

If you want, I can propose a target `engine/artifacts.py` tailored to your stages and show exactly how a stage would emit artifacts using it (without adding any I/O code to `artifacts.py`).

### User Prompt 2

There is no risk. io.py is basically all I have now, so there is no problem to perform a large refactoring process, if it makes the code better organized.

### AI Response 2

Understood. If `io.py` is effectively your only “infrastructure” module today, then this is the ideal time to refactor into an expert-recognizable, mechanically clean architecture.

Below is a refactor target that (a) matches established practice in CV/data pipelines, (b) cleanly separates **mechanism vs policy**, and (c) will scale cleanly into your `engine/` + `service/` layers without creating future ambiguity.

---

### Target design: three-layer split

#### 1) `gridpet/io/` — storage mechanism (no GridPET semantics)

Purpose: “How we read/write files safely.”

Contains only:

* atomic writes
* JSON and PNG serialization primitives
* image loading with EXIF handling (this is “mechanism”)
* hashing/collision utilities

This layer must not know:

* what “grid overlay” is
* which artifacts exist
* which stage produces what

#### 2) `gridpet/run/` — run layout + artifact log storage (still mostly mechanism)

Purpose: “A run has a directory tree and an append-only log.”

Contains:

* run directory layout creation
* run manifest schema and persistence
* artifact log schema and append/read helpers
* path resolution helpers **without** stage-specific artifact catalog

This layer knows:

* a run has `input/`, `grid/`, `qc/`, etc. (layout)
* artifacts are logged to `artifacts.jsonl`

But it still must not define:

* canonical artifact IDs or suffixes
* stage contracts

#### 3) `gridpet/engine/artifacts.py` — domain contract (policy)

Purpose: “What artifacts exist, what they mean, and what is required.”

Contains:

* canonical artifact identifiers
* mapping: artifact → {kind, suffix, ext, stage, deliverable/debug, description}
* mapping: stage → required/optional artifacts
* *optional* small validation functions that operate on in-memory lists/records (no writing)

---

### Proposed new filesystem layout

You currently have `gridpet/io.py`. Refactor to:

```
gridpet/
  src/gridpet/
    io/
      __init__.py
      atomic.py          ## atomic writes, safe replace
      json_io.py         ## read/write JSON and JSONL primitives
      image_io.py        ## read image with EXIF, write image/mask
      hash_io.py         ## sha256 helpers
    run/
      __init__.py
      layout.py          ## run dir layout + path mapping
      manifest.py        ## RunManifest dataclass + read/write
      artifact_log.py    ## ArtifactRecord schema + append/read
      manager.py         ## RunIO (formerly IOManager) orchestrating the above
    engine/
      artifacts.py       ## canonical artifact catalog + stage contracts
      context.py
      pipeline.py
      stages/...
    service/...
```

This structure will look immediately “normal” to an experienced engineer: low-level I/O primitives; run model; engine domain contract.

---

### How your current `io.py` maps into the new modules

#### Keep (mechanism) → move into `io/`

* `_sha256_file` → `io/hash_io.py`
* `_atomic_write_json` → `io/atomic.py` + `io/json_io.py`
* `_validate_image_u8`, `encode_mask_u8` → `io/image_io.py`
* EXIF read logic (`_read_with_exif_bgr`) → `io/image_io.py`
* OpenCV write of PNG → `io/image_io.py`
* JSON serialization details → `io/json_io.py`

#### Run model (layout/log/manifest) → move into `run/`

* `CollisionPolicy` → `run/manager.py` (or `run/layout.py` if you treat it as ingestion policy)
* `ArtifactKind` → **I recommend moving to `run/layout.py`** as a “bucket/directory classifier”
* `RunManifest` → `run/manifest.py`
* artifact log (`artifacts.jsonl`) schema + append logic → `run/artifact_log.py`
* directory tree creation → `run/layout.py`
* `IOManager` → becomes `RunIO` in `run/manager.py`

#### Policy (artifact semantics) → move into `engine/artifacts.py`

* naming convention definition (“`<input_stem>__<suffix>.<ext>`”) becomes part of artifact contract, but the *implementation* remains in `run/manager.py`.
* convenience domain methods like `write_measurement_json` / `write_qc_json` should be removed from the I/O layer and replaced by catalog-driven calls from stages.

---

### What the refactored APIs look like

#### Engine stage code (clean, no strings invented)

Stages should not invent `"grid_points"` / `"overlay"` strings. They reference the catalog:

```python
from gridpet.engine.artifacts import ArtifactId, ARTIFACTS
from gridpet.run.manager import RunIO

def run(stage_ctx) -> None:
    run_io: RunIO = stage_ctx.run_io

    spec = ARTIFACTS[ArtifactId.GRID_POINTS]
    run_io.write_json(spec, data=points_dict)

    spec = ARTIFACTS[ArtifactId.GRID_OVERLAY]
    run_io.write_png(spec, image=overlay_bgr)
```

#### `RunIO` implements “write_*” but only by spec

`RunIO` does not accept random `suffix` strings anymore (or it can, but discourage).

```python
class RunIO:
    def write_png(self, spec: ArtifactSpec, *, image: np.ndarray, meta: dict | None):
        ...
```

This is a major cleanliness win: the I/O layer stops being permissive “anything goes.”

---

### Recommended “strong refactor” decisions

These are the design choices that most improve expert clarity.

#### Decision A: Make the artifact catalog the *only* stable source of suffixes

Deprecate `write_png(kind=..., suffix="...")` in engine usage.
Keep it only for ad-hoc debugging if you want (private method), but stages should use catalog.

#### Decision B: Artifact log records should include `artifact_id`

Right now you log `kind`, `filename`, `description`, `meta`.
Add:

* `artifact_id` (canonical key)
* `stage` (optional)
* `content_type` or `ext` (optional)

This makes the service/UI layer much easier.

#### Decision C: Use “description” as human text, not uniqueness key

Your `_require_unique_description` is a useful guardrail, but experts will find it odd as a primary uniqueness constraint.

Better:

* uniqueness key = `artifact_id` (or `(artifact_id, variant)` if you support multiple)
* `description` remains optional human text
* allow repeated descriptions safely

#### Decision D: Separate “log append” from “write file”

You already do both in one method. In the refactor, keep the convenience, but implement it as:

* write file
* create `ArtifactRecord`
* append to artifact log

This keeps things testable.

---

### Migration plan (fast and deterministic)

1. **Create new packages** `io/` and `run/` and copy code over mechanically.
2. Implement `ArtifactRecord` and `append_record()` in `run/artifact_log.py`.
3. Implement `RunLayout` (dir mapping) in `run/layout.py`.
4. Implement `RunIO` in `run/manager.py`:
    * `create_run()`
    * `ingest_input()`
    * `read_input_bgr()`
    * `write_png(spec, ...)`, `write_json(spec, ...)`, `write_mask_png(spec, ...)`
5. Create `engine/artifacts.py` catalog:
    * `ArtifactId` enum
    * `ArtifactSpec` dataclass
    * `ARTIFACTS` registry
    * `REQUIRED_BY_STAGE`
6. Update stages to use artifact catalog calls.
7. Delete the old monolithic `io.py` or keep it as a thin compatibility shim for a short period.

---

### What you gain (why an expert will approve this)

* **Single responsibility** per module (I/O primitives vs run model vs engine contract)
* No ad-hoc artifact strings scattered through stages
* A service layer can reliably enumerate and serve artifacts
* Stronger regression testing: stage completion = required artifacts present
* Easy evolution: adding a new artifact = add a spec, then emit it

---

### If you want one more “gold standard” tweak

Consider renaming “artifacts” to **outputs** in the engine layer:

* `engine/artifacts.py` is fine, but some teams prefer:
    * `engine/outputs.py` (domain contract)
    * “artifact” becomes a storage/log term
      This is optional; “artifacts” is widely used and acceptable.

---

If you want, I can produce the concrete skeletons for:

* `run/manager.py` (new `RunIO`)
* `run/artifact_log.py` (`ArtifactRecord`)
* `engine/artifacts.py` (catalog for your listed stages)

…in a way that preserves your current behavior (input stem naming, JSONL logging, EXIF handling), but makes the organization unambiguously “expert-grade.”
