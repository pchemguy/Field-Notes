

|            |                                                    |
| ---------- | -------------------------------------------------- |
| FFCV       | https://github.com/libffcv/ffcv<br>https://ffcv.io |
| fastextend | https://fastxtend.benjaminwarner.dev               |
|            |                                                    |

## FFCV

>[!NOTE]
> 
> Source - https://github.com/libffcv/ffcv
>
> ### Windows
> 
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

### OpenCV

Note `/opencv/build/x64/vc15/bin`. The latest VC15 based build is OpenCV 4.6.0 (2022-06-12, https://sourceforge.net/projects/opencvlibrary/files/4.6.0/opencv-4.6.0-vc14_vc15.exe)

