# Dense Optical Flow Analysis (Farneback)

This script is designed to compute dense optical flow (pixel-level motion) within cardiac tissue videos using MATLAB and the Farneback algorithm.

This script estimates motion vectors between consecutive frames of a video and computes the average motion magnitude over time to assess contractile activity.

---

## Requirements

- MATLAB
- Computer Vision Toolbox
- Video file (e.g., .avi)

---

## Setup

1. Place the script in the same directory as your video.
2. Change this line to match your filename:

   ```matlab
   videoFile = "CM-4X.avi";
   ```

---

## Usage

1. Open MATLAB.
2. Change directories to the location of your script and video.
3. Execute the script.

This script will:
- Display the optical flow vectors (red arrows) on the video.
- Compute the mean motion magnitude per frame.
- Display motion magnitude as a function of time.

Optional:
To examine a certain region of interest within the video, you can add:

```matlab
useROI = true;
```

And provide a value for `roiPos`.

---

## Output
The script will produce:
- A window for visualizing motion vectors.
- A time series chart showing the mean motion magnitude (pixels/frame).
- A time vector in seconds.

The motion magnitude signal allows for the estimation of:
- Contraction frequency
- Relative contraction amplitude

---

## Limitations
- Measured in pixels, not physical units.
- Influenced by lighting and noise.
- Requires Computer Vision Toolbox.

---

## Role in the Pipeline
Raw Video -> Preprocessing -> Optical Flow Analysis (this script) -> Frequency & Amplitude Extraction

---

## Reproducibility Note
The script standardizes the analysis of motion in videos of cardiac tissue recordings.
