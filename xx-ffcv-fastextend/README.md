

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
Will try a newer VC16-based OpenCV4. Incompatibility risks are relatively low, but should keep this in mind.

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

