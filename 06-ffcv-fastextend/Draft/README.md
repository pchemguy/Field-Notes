# Summary

It appears that all prereqs, except for OpenCV and pthreads are installed via conda. Both OpenCV and pthreads are installed as portable software.
For pthreads, the latest (old) release is installed. There is no explicit restrictions on OpenCV versions. FFCV hints at VC15-based (the newest is 4.6, subsequent versions are VC16-based). Gemini analysis suggests sticking with 4.6.

|            |                                                    | Date         |
| ---------- | -------------------------------------------------- | ------------ |
| FFCV       | https://github.com/libffcv/ffcv<br>https://ffcv.io | Mar 3, 2023  |
| fastextend | https://fastxtend.benjaminwarner.dev               | Dec 18, 2023 |

## fastextend

```
conda create -n fastxtend python=3.11 "pytorch>=2.1" torchvision torchaudio pytorch-cuda=12.1 fastai nbdev pkg-config libjpeg-turbo opencv tqdm psutil terminaltables numpy "numba>=0.57" librosa timm kornia rich typer wandb "transformers>=4.34" "tokenizers>=0.14" "datasets>=2.14" ipykernel ipywidgets "matplotlib<3.8" -c pytorch -c nvidia -c fastai -c huggingface -c conda-forge

conda activate fastxtend

pip install "fastxtend[all]"
```

replacing pytorch-cuda=12.1 with your preferred supported version of Cuda.

Gemini analysis (https://gemini.google.com/app/c22c3e168bde40db) indicates critical dependence on pin `matplotlib<3.8`, but suggests that it could be relaxed to `matplotlib<=3.8`.

## FFCV

>[!NOTE]
> 
> Source - https://github.com/libffcv/ffcv
>
> ### Windows
> 
> * Install <a href="https://opencv.org/releases/">opencv4</a>
>   * Add `..../opencv/build/x64/vc15/bin` to PATH environment variable
> * Install <a href="https://sourceforge.net/projects/libjpeg-turbo/files/">libjpeg-turbo</a>, download libjpeg-turbo-x.x.x-vc64.exe, not gcc64
>   * Add `..../libjpeg-turbo64/bin` to PATH environment variable
> * Install <a href="https://www.sourceware.org/pthreads-win32/">pthread</a>, download last release.zip
>   * After unzip, rename Pre-build.2 folder to pthread
>   * Open `pthread/include/pthread.h`, and add the code below to the top of the file.  
>   ```cpp
>   #define HAVE_STRUCT_TIMESPEC
>   ```
>   * Add `..../pthread/dll` to PATH environment variable
> * Install <a href="https://docs.cupy.dev/en/stable/install.html#installing-cupy">cupy</a> depending on your CUDA Toolkit version.
> * `pip install ffcv`
> 
> ### **Requirements verification recipes**
> 
> **Need recipes for verifying/testing correct functioning of all individual requirements and their interoperability**

### OpenCV

Note `/opencv/build/x64/vc15/bin`. The latest VC15 based build is OpenCV 4.6.0 (2022-06-12) https://sourceforge.net/projects/opencvlibrary/files/4.6.0/opencv-4.6.0-vc14_vc15.exe
Gemini analysis (https://gemini.google.com/app/6de2654f343e3c01) suggests avoiding using VC16-based versions.

### Libjpeg-Turbo

- FFCV links to the old repo on SF with the latest 3.0.1(2023-10-16) https://sourceforge.net/projects/libjpeg-turbo/files/3.0.1/libjpeg-turbo-3.0.1-vc.exe
- libjpeg-turbo 3.1.0 https://anaconda.org/conda-forge/libjpeg-turbo
    - Installs Libjpeg-Turbo to "Library\bin". 
    - There are no clear direct evidence if that package is natively compiled (MSVC vs gcc), but Conda-forge, as a general practice, uses the native compiler for each platform. For now assuming that installing this package should satisfy requirements of FFCV, but keep this in mind.  
### pthreads

https://www.sourceware.org/pthreads-win32/
ftp://sourceware.org/pub/pthreads-win32
pthreads-w32-2-9-1-release.zip

### pytorch-cuda

By using the `fastextend` environment above with `pytorch-cuda` version unspecified per instructions, mamba installs
- python=3.11.13
- pytorch=2.5.1
- pytorch-cuda=12.4

It appears that pytorch-cuda is completely installed as Python package.

### cupy

https://docs.cupy.dev/en/stable/install.html#install-cupy-from-conda-forge
Matching version of cupy and associated libraries are installed via conda packages:

```
  - cupy
  - cudnn
  - cutensor
```


## CUDA Libs

CUDA Runtime (cudatoolkit) vs. SDK (cuda-toolkit): https://gemini.google.com/app/756a72112c16449b


 Install PyTorch and RAPIDS together in a new environment
 
```
conda create -n gpu-env -c rapidsai -c pytorch -c nvidia pytorch rapids cudatoolkit
 
 
conda create -n rapids-25.10 -c rapidsai -c conda-forge -c nvidia rapids=25.10 python=3.11 'cuda-version>=12.0,<=12.9' 'pytorch=*=*cuda*' jupyterlab graphistry dash xarray-spatial
```


---

```
DEPRECATION: Building 'ffcv' using the legacy setup.py bdist_wheel mechanism, which will be removed in a future version. pip 25.3 will enforce this behaviour change. A possible replacement is to use the standardized build interface by setting the `--use-pep517` option, (possibly combined with `--no-build-isolation`), or adding a `pyproject.toml` file to the source tree of 'ffcv'. Discussion can be found at https://github.com/pypa/pip/issues/6334
  error: subprocess-exited-with-error
  
  python setup.py bdist_wheel did not run successfully.
  exit code: 1
  
  [32 lines of output]
  G:\dev\AIPY\Anaconda\Lib\site-packages\setuptools\dist.py:483: SetuptoolsDeprecationWarning: Cannot find any files for the given pattern.
  !!
  
          ********************************************************************************
          Pattern 'LICENSE.txt' did not match any files.
  
          By 2026-Mar-20, you need to update your project and remove deprecated calls
          or your builds will no longer be supported.
          ********************************************************************************
  
  !!
    for path in sorted(cls._find_pattern(pattern, enforce_match))
  libffcv.cpp
  ./libffcv/libffcv.cpp(38): warning C4244: 'argument': conversion from 'int64_t' to 'int', possible loss of data
  ./libffcv/libffcv.cpp(38): warning C4244: 'argument': conversion from 'int64_t' to 'int', possible loss of data
  ./libffcv/libffcv.cpp(39): warning C4244: 'argument': conversion from 'int64_t' to 'int', possible loss of data
  ./libffcv/libffcv.cpp(39): warning C4244: 'argument': conversion from 'int64_t' to 'int', possible loss of data
  ./libffcv/libffcv.cpp(40): warning C4244: 'argument': conversion from 'int64_t' to 'int', possible loss of data
  ./libffcv/libffcv.cpp(40): warning C4244: 'argument': conversion from 'int64_t' to 'int', possible loss of data
  ./libffcv/libffcv.cpp(40): warning C4244: 'argument': conversion from 'int64_t' to 'int', possible loss of data
  ./libffcv/libffcv.cpp(40): warning C4244: 'argument': conversion from 'int64_t' to 'int', possible loss of data
  ./libffcv/libffcv.cpp(49): warning C4244: 'argument': conversion from 'int64_t' to 'long', possible loss of data
  ./libffcv/libffcv.cpp(98): warning C4244: 'argument': conversion from '__uint64_t' to 'unsigned long', possible loss of data
  ./libffcv/libffcv.cpp(102): warning C4244: '=': conversion from '__uint64_t' to 'unsigned long', possible loss of data
     Creating library build\temp.win-amd64-cpython-311\Release\libffcv\_libffcv.cp311-win_amd64.lib and object build\temp.win-amd64-cpython-311\Release\libffcv\_libffcv.cp311-win_amd64.exp
  libffcv.obj : error LNK2001: unresolved external symbol tjTransform
  libffcv.obj : error LNK2001: unresolved external symbol tjInitDecompress
  libffcv.obj : error LNK2001: unresolved external symbol tjDecompress2
  libffcv.obj : error LNK2001: unresolved external symbol tjFree
  libffcv.obj : error LNK2001: unresolved external symbol tjInitTransform
  build\lib.win-amd64-cpython-311\ffcv\_libffcv.cp311-win_amd64.pyd : fatal error LNK1120: 5 unresolved externals
  error: command 'G:\\dev\\MSBuildTools\\VC\\Tools\\MSVC\\14.44.35207\\bin\\HostX64\\x64\\link.exe' failed with exit code 1120
  [end of output]
  
  note: This error originates from a subprocess, and is likely not a problem with pip.
  ERROR: Failed building wheel for ffcv
error: failed-wheel-build-for-install

Failed to build installable wheels for some pyproject.toml based projects

ffcv
```
  