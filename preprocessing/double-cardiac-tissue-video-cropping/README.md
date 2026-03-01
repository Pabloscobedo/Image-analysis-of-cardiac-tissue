## Installation
1. Install FFmpeg using PowerShell:
   ```
   winget install Gyan.FFmpeg
   ```
2. Verify the installation by running:
   ```
   ffmpeg -version
   ```
3. Copy the file **cortar_left_right.ps1** into the directory containing the videos you want to process.

---

### Usage
1. Make sure all the dual-field cardiac tissue videos are in the same folder as the script **cortar_left_right.ps1**.
2. Right-click on the **cortar_left_right.ps1** script.
3. Click on **Run with PowerShell**.
4. Wait until the automatic cropping is done.
5. Do not close the PowerShell window until the process is done.
*Do not move, rename, or change the video files during the process.*

---

### Output
A new folder named **OUT** will be created in the same folder where the script is located.

Inside this folder, you will find the cropped video:
- **videoName_Left.extension**
- **videoName_Right.extension**
The video files will not change.

---

### Limitations
- This script has only been tested on the Windows OS.
- It is assumed that the left and right spatial fields are always the same.
- The cropping is done to the dimensions specified in the script.
- Automatic regions are not detected.
- It may take some time to process the video depending on the video size and the OS performance.

---

### Role in the Full Pipeline
This tool is part of the full **Cardiac Tissue Image Analysis Pipeline**, which is defined as follows:

Raw Dual Field Video → Left/Right Split → AVI Conversion (Uncompressed) → FIJI Processing → MATLAB Quantification

---
### Reproducibility Note
This tool was created to standardize the spatial splitting of dual cardiac tissue recordings across all experiments for reproducibility.

