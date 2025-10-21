FFCV package has three native library dependencies required for building the package:
- OpenCV
- LibJPEG-Turbo
- pthreads-win32

LibJPEG-Turbo and pthreads-win32 are C/C++ dependencies, whereas OpenCV is called from both C++ (native dependency) and Python (Python package dependency) modules. In turn, there are three major distinct sources of dependencies:
- official releases (typically available from GitHub or project sites, such as [opencv.org](https://opencv.org))
- PyPI Python packages (such, as [opencv-python](https://pypi.org/project/opencv-python))
- Conda Python packages (such as, [opencv](https://anaconda.org/conda-forge/opencv))

Because binaries 