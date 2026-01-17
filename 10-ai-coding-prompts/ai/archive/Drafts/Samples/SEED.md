Help me develop a specification for a high-level architecture for my GridPET app. The app's objective is to estimate area of an object (presently, mouse spleen) shown on a smartphone taken photograph over millimeter graph paper. Expected processing workflow (non-ML) is expected to involve
- preprocessing (local contrast normalization, denoising)
- grid detection
- grid data processing, pitch estimation
- geometry distortion estimation (advanced feature planned for later stages)
- geometry distortion compensation (advanced feature planned for later stages)
- image segmentation
- object area computation
- QC checks and statistical analysis at all stages

# Specification

- flexible cross-platform architecture
- modular
- fast prototyping 
- scalable
- server/client
- computation platform / server - desktop with Python/NumPy/OpenCV/skimage/SciPy stack
- access via FastAPI or Flask?
- server runs Python-based web server
- base automation from desktop clients via curl/tar/shell
- the server should accept a single jpg or a zip/tar archive containing a set of images
- the server processes each input images and generates a number of artifacts for each input image (intermediate images, overlays, masks, stat data, QC information, etc.) to be made available for downloads.
- a web app running on the server should provide interactive cross-platform browser-based interface that can be used to upload a single image or a directory containing a set of images. Additionally, on smartphone, the web app should provide the ability to take a camera image and send it directly.
- For interactive interface, after image(s) is submitted, the app should redirect to the results page, that should be gradually populated with processed artifacts. On the server, intermediate artifacts are saved as PNGs and should be made available for download. The results page should provide previews saved to client as JPGs.


 