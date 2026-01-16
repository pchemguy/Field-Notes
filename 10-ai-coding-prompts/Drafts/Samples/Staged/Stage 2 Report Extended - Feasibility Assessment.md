# Stage 2 Report Extended - Feasibility Assessment

## Preliminary Architecture and Feasibility Prototyping

**Scope:** Non-ML computer-vision proof-of-concept (PoC) for area estimation of mouse spleen over millimeter graph paper in smartphone images.

---

## 1. Target Problem Definition

### 1.1 Objective

Develop a user-friendly, standalone (“boxed”) software tool for automated analysis of non-professional smartphone or basic digital-camera photos depicting a mouse spleen inside a transparent, closed Petri dish, placed on millimeter graph paper. The primary quantitative output is organ area.

### 1.2 Input/Output Expectations

**Inputs**

- JPEG images retrieved directly from smartphone or basic digital camera
- No preprocessing assumed at acquisition time

**Outputs**

- Organ area estimate (target metric)
- Intended operational modes:
    - single-image processing
    - batch processing of folders/image sets
- Usability target: biologist-friendly workflow (non-developer end user)
- Distribution target: standalone/boxed application (no Python runtime or external dependencies required by the end user)

### 1.3 Operating Assumptions

- The grid occupies most of the image area.
- Petri dish occupies a substantial portion of the grid region:
    - approximately 40–50% of grid width
    - approximately ~1/3 of grid height
    - (based on a single image so far)
- The graph paper is placed inside a file; plastic glare and specimen occlusion can obscure the grid.
- Lighting and contrast are suboptimal.
- Moderate geometrical distortions. 

---

## 2. Proposed High-Level Workflow

This project explicitly targets a non-ML approach. Primary domain: computer vision, with potential supporting contributions from signal processing.

Proposed processing stages:

1. Image preprocessing / enhancement
2. Grid detection
3. Grid data analysis
4. Geometry distortion compensation
5. Image segmentation and organ area estimation
6. Error analysis

---

## 3. Development Dependencies

- OpenCV
- NumPy
- Matplotlib
- Pillow
- SciPy
- Scikit-learn

---

## 4. Feasibility Targets and Iteration Strategy

### 4.1 Primary Feasibility Targets

The Round 1 feasibility work prioritizes:

- Grid detection
- Grid analysis
- Organ segmentation

### 4.2 Geometry Compensation De-prioritization

Geometry distortion compensation (e.g., homography, lens distortion) is acknowledged as potentially relevant, but intentionally de-emphasized for the initial PoC iteration.

Rationale:

- The current manual baseline workflow used for semi-manual area estimation implicitly ignores geometry distortion.
- Therefore, a Stage 1 PoC should not invest significant effort in geometry correction.
- Initial attempts/strategies may be explored, but negative results are treated as non-decisive for feasibility at this stage.

---

## 5. Image Preprocessing

### 5.1 Separation of Preprocessing Requirements by Downstream Task

Grid detection and segmentation are treated as distinct computer-vision tasks with different preprocessing requirements. Accordingly, preprocessing is considered task-specific rather than global.

### 5.2 Stage 2 Implementation Stance

Preprocessing was treated as a supplementary stage. In Stage 2:

- emphasis was placed on manual preprocessing exploration using Fiji ImageJ
- preprocessing automation in code was considered non-essential for feasibility evaluation

### 5.3 Candidate Preprocessing Operations Considered

- global exposure/brightness/contrast correction
- denoising
- uneven illumination correction (shading-field correction)
- local contrast normalization

Observations:

- Global exposure/brightness/contrast correction attempts did not yield promising results.
- For grid detection, the highest-value preprocessing subtasks appear to be:
    - gridline contrast enhancement
    - illumination non-uniformity correction

### 5.4 Fiji ImageJ Methods Tried

- Retinex plugin for illumination compensation:
    - requires separate compilation/installation
    - appeared “worth further consideration”
    - influence on downstream stages not evaluated in Round 1
- CLAHE:
    - did not appear helpful in initial tests
- Fiji local contrast normalization:
    - `Fiji ImageJ -> Plugins -> Integral Image Filters -> Normalize Local Contrast 40x40x5.00/center/strech`
    - appeared robust for:
        - increasing gridline contrast
        - improving illumination evenness
    - trade-off: increased noise

---

## 6. Grid Detection

Three grid-detection approaches were explored:

1. OpenCV Line Segment Detector (LSD)
2. Custom morphological gridline intersection detector
3. Fiji ImageJ Ridge Detector

These approaches are algorithmically distinct; best performance may require hybridization.

Additional approaches considered for future exploration:

- 2D FFT
- 2D wavelet methods

---

### 6.1 OpenCV LSD (Line Segment Detector)

#### 6.1.1 Core Observations

- The OpenCV LSD implementation exposed via commonly available prebuilt binaries appears to provide only a basic / feature-reduced configuration relative to the broader LSD functionality described in OpenCV documentation (and/or available in the source code, possibly, from OpenCV-contrib).
- The detector returns a set of line segments; when the grid occupies most of the field of view, a substantial fraction of the returned segments correspond to gridlines.
- Minor gridlines typically exhibit lower signal-to-noise ratio and therefore produce a noticeably noisier subset of detected segments.

#### 6.1.2 Gridline Classification via Segment Thickness and Orientation

The observed difference in signal-to-noise ratio between major and minor gridlines is largely attributable to line thickness. The LSD output includes an estimate of segment width (thickness), which can be leveraged for structural classification.

Key observations:

- Segment thickness values are expected to follow a bimodal distribution, corresponding to major and minor gridlines.
- Segment orientation values likewise tend to be bimodal, reflecting the two approximately orthogonal grid directions.
- Consequently, the detected segments can be processed as follows:
    1. Partition into major and minor gridline subsets via clustering or mixture modeling of the thickness distribution.
    2. Partition each subset into horizontal and vertical families via clustering of segment orientation angles.
    3. Replace each segment with a representative point (e.g., segment midpoint or centroid) to produce a reduced point set suitable for downstream grid analysis.

This transformation converts the raw segment-level representation produced by LSD into a compact, geometry-oriented point representation that is more amenable to grid-structure modeling.

#### 6.1.3 Parameter Minimalism Advantage

A key advantage of LSD is that it is effectively parameter-light:

- no explicit pitch estimate required as an input
- segment thickness metadata appears to correspond to real structural thickness
- practical prior: major gridlines typically ~1.5× to 3× thicker than minor lines → supports thickness-based major/minor separation

#### 6.1.4 Quality Control and Failure Criteria (Proposed)

Several broadly applicable QC signals were identified.

1. **Segment length**
    - Reliable estimation of segment orientation is critical for downstream grid analysis and depends strongly on segment length. Short segments are inherently quantized on the pixel lattice and are therefore highly sensitive to endpoint localization error.
    - From a geometric standpoint, an N-pixel segment on a discrete grid admits only a limited set of encodable orientations; as N decreases, angular quantization effects dominate. In addition, thinner gridlines yield less reliable endpoint localization, further amplifying orientation uncertainty.
    - Consequently, the same absolute endpoint error induces a larger angular error for short segments than for long ones.
    - A practical mitigation is to analyze the segment-length distribution and truncate its short tail, discarding segments below a conservative minimum length (e.g., ≤ 4 px).
    - If the fraction of discarded short segments exceeds a threshold (==TODO==: define), the image should be flagged as insufficient quality for reliable grid analysis.
    - The minimum acceptable length cutoff can be further rationalized by grid resolvability constraints: if minor gridlines have a minimum thickness of ~2 px and the inter-line spacing is at least on the order of one additional linewidth, then the minor grid pitch is expected to be ≥ 4 px. Segments significantly shorter than this scale cannot reliably encode grid orientation or spacing and therefore provide little analytical value.
2. **Segment thickness**
    - Discard subpixel-thickness segments using conservative cutoff ~0.5–0.75 px.
    - If the fraction discarded is significant (==TODO==: define), flag image quality issues.
    - Expect bimodality:
        - two dominant components: minor and major gridline thickness
        - minor thickness should likely be ≥ ~2 px for reliability (contrast/noise dependent)
        - possibly allow conservative minor peak cutoff ~1.5 px (uncertain)
    - Major/minor thickness ratio should plausibly fall within ~[1.5, 3], conservatively [1.25, 4].
3. **Thickness distribution QC (explicit model checks)**
    - Current approach: analyze thickness distribution using:
        - `GaussianMixture` (`sklearn.mixture`)
        - `gaussian_kde` (`scipy.stats`)
    - ==TODO==: define robust distribution checks:
        - verify bimodality with exactly two dominant components (define quantitative dominance criteria)
        - assess component fit quality (Gaussian or skewed Gaussian: peak, variance, skewness, kurtosis)
        - expect minor component may be skewed toward higher values (thin lines underdetected)
        - minor component should not be distorted toward lower values
        - quantify skewness and kurtosis bounds
        - verify major/minor peak ratio within plausible band
    - Resolution checks:
        - peak separation ≥ 1 px (maybe 0.75 px conservative)
        - estimate FWHM of components
        - verify average FWHM smaller than peak separation (allow tolerance, e.g., avg(FWHM) not more than ~20% above separation)
4. **Pitch floor estimation heuristics derived from resolution considerations (5 minor per major design)**
    - Conservative assumptions:
        - blank spacing between minor lines ≥ `peak_minor` and ≥ 1 px
        - `pitch_minor = peak_minor + spacing_minor ≥ 2 * peak_minor`
        - major pitch should be > 5 × `peak_major`
        - `pitch_floor = 5 * (peak_major + 2 * peak_minor) / 2`
    - Example: `peak_minor = 2 px`, `peak_major = 2 * peak_minor` → `pitch_floor = 20 px`
    - Critical domain note:
        - when estimating major pitch, consider that millimeter graph paper major lines may occur every 5 mm or 10 mm (5 or 10 minor per major)
    - Pitch ceiling heuristic:
        - for a given image size, require at least ~5–10 major lines visible
        - major pitch should be substantially less than ~20% of the smaller image dimension

---

### 6.2 Morphological Gridline Intersection Detector

This method detects grid intersections via gradient-based binarization followed by directional morphology.

#### 6.2.1 Preprocessing Pipeline (Current; Not Fully Optimized)

> [!NOTE]
> This protocol has not been optimized. Steps 1–6 were essentially AI-generated. Step 0 is manual preprocessing, so Step 3 may be redundant.

Observed behavior:

- robust in suppressing spurious lines outside the grid region
- yields mostly major grid nodes on the tested image (likely due to minor-line weakness and/or `k_len` tuned to major pitch)

Pipeline:
0. Manual local contrast normalization:
   `Fiji ImageJ -> Plugins -> Integral Image Filters -> Normalize Local Contrast 40x40x5.00 / center/strech`
1. Convert to grayscale
2. Sobel gradient magnitude
3. CLAHE for local contrast normalization
4. Otsu threshold → binary mask for morphology

#### 6.2.2 Directional Morphology (Core Detector)

Apply directional morphological opening using elongated structuring elements:

5. `horiz_k = (k_len × 1)` isolates long horizontal strokes
6. `vert_k  = (1 × k_len)` isolates long vertical strokes

Interpretation:

- objects must contain at least `k_len` contiguous pixels along the kernel direction to survive erosion
- small blobs (text, digits, dust, noise) are removed
- long, coherent grid segments remain

Parameter:

- `k_len` is the minimum detectable run length
- expected to be ~40–70% of grid pitch
- currently manually set; automatic estimation remains open (see strategies below)

#### 6.2.3 Intersection Extraction

- Compute logical AND of horizontal and vertical line maps → candidate node blobs
- Use `cv2.connectedComponentsWithStats` to compute blob centroids
- Output: `(N, 2)` array of (x, y) node coordinates in image space

#### 6.2.4 Statistical Pitch Estimation (From Nodes)

Even though this detector requires `k_len` (which depends on pitch), once nodes are extracted, they can support statistical pitch estimation:

Method (LLM-suggested; promising but requires verification beyond current expertise):

```python
from sklearn.neighbors import NearestNeighbors

nbrs_scout = NearestNeighbors(n_neighbors=4).fit(points)
distances_scout, _ = nbrs_scout.kneighbors(points)

dist_2nd = distances_scout[:, 2]
dist_3rd = distances_scout[:, 3]

p90_2nd = np.percentile(dist_2nd, 90)
p90_3rd = np.percentile(dist_3rd, 90)

ref_pitch = (p90_2nd + p90_3rd) / 2.0
```

Rationale:

- robustly captures typical spacing while tolerating outliers and partial occlusion
- uses higher percentiles to mitigate clustering artifacts

#### 6.2.5 Automatic `k_len` Estimation Strategies (Proposed)

1. **FFT-based pitch estimation (recommended practical baseline)**
    - compute gradient magnitude
    - FFT → radial/axis-aligned spectral analysis
    - identify dominant frequency peaks → convert to pixel period
    - set `k_len ≈ 0.4–0.7 × pitch` (recommendation: `k_len = round(0.5 × pitch)`)
2. **Distance transform + maxima**
    - compute distance transform on binary
    - analyze distances along ridges
    - infer straight-segment run lengths
3. **Scan-and-score (`k_len` sweep)**
    - test `k_len` in a small grid (e.g., 10..40)
    - score by:
        - surviving pixels
        - number of components
        - component elongation
    - choose plateau region before collapse
4. **Hybrid: Hough or LSD for spacing only**
    - detect limited number of strong long segments
    - estimate spacing from nearest-neighbor distances
    - set `k_len = 0.5 × pitch`
5. **Grid-density response curve**
    - define `R(k_len) = line_pixels_after_opening / total_binary_pixels`
    - as `k_len` increases: noise removed → R rises; grid breaks → R drops
    - select `k_len` in maximal plateau (elbow method)
6. **Scale-space morphology**
    - opening at multiple scales
    - choose scale with maximal stability of line structures
7. **Probabilistic model (overkill)**
    - explicit posterior maximization for `k_len`
    - requires calibration but would be principled

**Recommendation retained:** FFT-based pitch estimation → `k_len = round(0.5 × pitch)`.

---

### 6.3 Fiji Ridge Detector

- Fiji plugin: `Fiji ImageJ -> Plugins -> Ridge Detection`
- Observed to be substantially superior to baseline OpenCV LSD.

References:

- [https://github.com/thorstenwagner/ij-ridgedetection](https://github.com/thorstenwagner/ij-ridgedetection)
- [https://github.com/lxfhfut/ridge-detector](https://github.com/lxfhfut/ridge-detector)
- [https://scikit-image.org/docs/0.25.x/auto_examples/edges/plot_ridge_filter.html](https://scikit-image.org/docs/0.25.x/auto_examples/edges/plot_ridge_filter.html)
- [https://github.com/clEsperanto/pyclesperanto](https://github.com/clEsperanto/pyclesperanto)

Limitations / open questions:

- algorithm requires multiple tuning parameters, including approximate target line thickness
- appears scale-specific
- unclear whether an equivalent implementation is readily available in Python or must be ported
- automatic parameter tuning would be required
- potential hybrid strategy:
    - use LSD-derived thickness statistics (or other pitch/thickness estimates) to auto-configure ridge-detector parameters

---

## 7. Grid Region Localization (Bounding Box)

Two approaches were explored, with a third readily available option.

### 7.1 Morphology-Based Grid Region Detection (Axis-Aligned)

Pipeline:
0. Manual local contrast normalization (as above)
1. Sobel gradient magnitude (emphasize line structure)
2. CLAHE (normalize local contrast; suppress illumination gradients)
3. Otsu threshold → binary high-frequency mask
4. large-kernel blur → convert dense grid lines into a soft “density cloud”
5. Otsu threshold again → segment macro-density region
6. contour extraction → bounding box of grid region
7. expand and round box to nearest 100 px with boundary-aware centering

Conceptual rationale:

- grid region exhibits high edge concentration
- gradient filters emphasize this, and subsequent smoothing/thresholding isolates dense-line area

Variant idea:

- for LSD/Ridge results, render detected segments (with thickness, possibly scaled 1–2×) to a blank canvas
- then apply the same density-cloud segmentation pipeline to isolate the segment-dense region

### 7.2 Grid Node Set Analysis (Oriented Bounding Box)

This method operates on node sets produced by the morphological intersection detector.

The node detector already suppresses many spurious detections outside the grid; however, additional filtering is applied to robustly estimate grid orientation and bounding box. The method targets approximately rectangular lattices and aims for minimal parameter tuning.

Algorithm stages:

1. **Neighborhood scale auto-tuning (if `eps` is None)**
    - compute distance to each point’s 2nd nearest neighbor
    - use 90th percentile as pitch estimate
    - set `eps = 1.5 × pitch` to allow diagonal adjacency and moderate noise
2. **Outlier removal via DBSCAN**
    - `min_samples = max(3, 0.5% of points)`
    - use auto or user-supplied `eps`
    - retain largest non-noise cluster
    - separate:
        - `clean_points` (grid inliers)
        - `noise_points` (discarded outliers)
3. **Grid orientation estimation**
    - compute local direction vectors to nearest neighbors
    - reduce angles modulo 90° (grid orthogonality)
    - histogram mode in [0°, 90°) defines dominant alignment (`best_angle`)
4. **Bounding box construction**
    - rotate points to align with axes
    - use robust percentiles (0.5 / 99.5) to define bounds resilient to jitter
    - expand bounds by `margin_ratio × grid_pitch`
    - rotate rectangle back → oriented 4-point box

### 7.3 OpenCV `minAreaRect` (Grid-Aligned)

- `cv2.minAreaRect` can be used to estimate an oriented bounding box.
- Could replace Steps 3–4 of node-set analysis.
- Presently used in segmentation pipeline, but not yet applied for grid bounding-box detection.

---

## 8. Grid Data Analysis

Downstream strategies depend on the detector output type:

- LSD/Ridge: sets of line segments with thickness and orientation
- Morphological intersection: sets of node points

### 8.1 Brute-Force Solver (Implemented; Moderate Success)

For LSD/Ridge:

- split segments into major/minor using bimodal thickness distribution
- split by orientation into vertical/horizontal via bimodal angle distribution
- estimate rotation; rotate data to align grid with axes
- replace segments with their centers

Solver approach:

- use self-correlation on histograms to infer spacing
- progressively slice the set in x/y directions and re-solve per cell
- produce an ensemble of solutions, potentially enabling spatial distortion characterization

Outcome:

- moderate success
- major limitation: low “visual transparency” of core computation (potentially fixable with better diagnostics)

### 8.2 Marginal KDE (mKDE) on Rotated Point Sets

Concept:

- rotate point set; project onto an axis; compute marginal KDE
- when grid is axis-aligned and sufficiently dense, projected points from the same gridlines collapse into narrow ranges → resonant peaks

Usage:

- for LSD/Ridge: mKDE applied to centers of major segments from a single orientation
- for morphological node detector:
    - no straightforward major/minor split
    - no meaningful orientation split (nodes are isotropic)
    - however, current protocol is highly selective and tends to return major nodes
    - therefore direct mKDE on the full node set produced strong resonant signal on the tested image

Local orientation optimization and distortion profiling:

- with moderate distortion, there may be no single globally optimal orientation
- different spatial slices may prefer slightly different rotations
- rather than slicing the image, slice the projection / mKDE domain
- local optimum orientations may provide distortion profiles and allow exclusion of sparse/occluded regions

Detector comparison (preliminary; based on one image):

- LSD-based analysis may yield broader mKDE peaks
    - reduced sensitivity to distortion
    - more robust average pitch detection
    - less suitable for distortion characterization
- requires proper evaluation across images

Important geometric note:

- mKDE signal emerges when points from the same gridlines align per projection axis
- for dense node sets, intermediate orientations can also produce signal:
    - particularly around 45° for square grids (diagonal-driven resonance)
    - and potentially at other rational-slope orientations (tan(α) = N or 1/N)
- ideal square grid:
    - strong, uniform signal when axis-aligned
    - at 45°, strongest in the center (main diagonal), decreasing toward edges due to shorter auxiliary diagonals

Programmatic selection of optimal orientation:

- candidate objective functions sensitive to resonance:
    - entropy
    - Gini coefficient
    - variance
    - similar concentration measures
- these can be computed per slice for local optimization

Bandwidth:

- mKDE bandwidth parameter:
    - if bandwidth = 1 → effectively parameter-free
    - bandwidth ~5–10% of expected pitch may improve SNR with minimal resolution loss (pitch must be estimated)

Pitch extraction once aligned:

- mKDE peaks correspond to projected gridlines
- identify peaks (e.g., `scipy.signal.find_peaks`)
- compute mean inter-peak distance → pitch estimate

### 8.3 Minor Gridlines (Open Task)

- Minor grid analysis is expected to be beneficial for consistency checking.
- No minor-grid analysis has been defined or tested.
- Minor-line data will be noisier but may be useful to:
    - refine and validate major grid inference
    - disambiguate 5 mm vs 10 mm major pitch using statistical consistency

---

## 9. Geometry Distortion Compensation (De-prioritized; Initial Attempt Failed)

- Early homography-based compensation attempts were made.
- Attempts were “black-box” and applied to raw point sets before mKDE analysis.
- Result: failure was expected; step is ignored for now in feasibility assessment.

---

## 10. Organ Segmentation and Area Estimation

### 10.1 Scene Model

Target: mouse spleen (dark red/bloody organ) in a transparent covered Petri dish over mostly gray millimeter graph paper.

Key complications:

- Petri dish introduces glare and reflections
- plastic file, protecting millimeter graph paper, introduces glare and reflections
- organ occludes gridlines
- blood stain near organ introduces confounding red pixels
- glare inside organ can create light regions that mimic stain statistics

Scale context (single image basis):

- grid occupies most of image
- dish diameter ~40–50% of grid width and ~1/3 of grid height

### 10.2 Color-Space Analysis (Preliminary)

Observation:

- The spleen is dark red; background is brighter and gray.
- CIELAB ‘a’ channel (red–green axis) provides strong separation between red organ and gray background.
- A light orange blood stain is also red; not separable from the organ via Lab-a alone.

Proposed differentiator:

- Blood stain vs organ separation is better in HSV saturation (S).
- Optimal strategy may combine:
    - Lab-L (lightness)
    - HSV-S (saturation)

Qualitative channel signatures:

|             | Lab-L (lightness) | HSV-S (saturation) |
| ----------- | ----------------- | ------------------ |
| Organ       | Low (dark)        | High (intense red) |
| Blood stain | High (lighter)    | Low (weaker color) |

Additional structural constraint:

- blood stain should share borders with the Lab-a-based mask
- glare inside the organ can yield:
    - higher Lab-L
    - lower HSV-S
      (potentially resembling blood stain)

==TODO:==

- Perform bimodal histogram analysis (and/or Otsu) on Lab-L and HSV-S to improve robustness.
- Consider suppressing distractions outside the detected grid area by clearing outside grid bounding box (cropping complicates processing flows due to changed size/coordinates).

### 10.3 Segmentation Pipeline (Implemented)

The segmentation pipeline uses the original image (no local contrast normalization) and applies:

1. initial mask from Lab-a via Otsu threshold
2. refinement using GrabCut
3. morphological cleanup (open/close)
4. dominant region selection and minimum bounding box construction
    - bounding box not currently used
5. construct organ mask as conjunction/product of:
    - low luminosity (Lab-L low)
    - high saturation (HSV-S high)
6. morphological cleanup (open/close)
7. final mask:
    - `Lab-a (high, refined) × Lab-L (low) × HSV-S (high)`
8. area computation:
    - count final mask pixels
    - divide by `major_pitch²`
    - ensure major pitch (5 mm vs 10 mm) is set according to actual paper grid

---

## 11. Summary of Round 1 Outcomes

### 11.1 Most Promising Components

- LSD-based grid feature extraction, particularly leveraging thickness metadata for major/minor separation and QC
- Morphological intersection detector, robust in suppressing non-grid clutter and producing node sets suitable for pitch estimation and mKDE
- mKDE-based grid analysis, especially as a potentially diagnostic-friendly method that supports local orientation optimization and distortion profiling
- Color-space segmentation using Lab-a + Lab-L + HSV-S, addressing stain vs organ separation and glare artifacts in principle

### 11.2 Key Open Tasks

- Define quantitative QC thresholds (segment length, thickness, bimodality dominance, etc.)
- Establish robust minor-grid analysis and use it to disambiguate 5 mm vs 10 mm pitch
- Evaluate Retinex/local-contrast preprocessing influence on grid detection vs segmentation independently
- Systematize k_len auto-estimation (FFT-based recommended baseline)
- Treat geometry compensation as optional, to be revisited only after stable grid/segmentation PoC

### 11.2 Key Tasks for Completing an MVP App

- Prototype GUI and CLI components
- Design application architecture
- Design strategy for transforming Python package to a standalone portable app.
- Batch mode.
