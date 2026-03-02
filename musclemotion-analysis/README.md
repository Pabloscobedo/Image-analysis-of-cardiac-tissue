## Installation
1. Install **FIJI (Fiji Is Just ImageJ)**.
2. Make sure the **MuscleMotion** plugin is installed (or available in your FIJI distribution).
3. Copy the modified macro file (e.g., **MUSCLEMOTION_batch_fixed_v6.ijm**) into FIJI:
   - `Fiji.app/macros/` (or `Fiji.app/plugins/` depending on your setup)
4. Restart FIJI to ensure the macro is detected.

---

### Usage
1. Open FIJI.
2. Run the modified MuscleMotion macro:
   - `Plugins -> Macros -> Run...` and select the macro file  
   *(or run it from the Macro menu if you placed it inside the macros folder).*
3. In the parameter wizard:
   - Set **Batch analysis** to `Yes` to process a directory with multiple files.
   - Select frame rate and other parameters as needed.
4. When prompted:
   - Select an **output directory** (where results will be saved).
   - Select the **input directory** (the directory containing the videos/images).
5. Wait until all files are processed.

Supported input formats (batch):
- `.avi`, `.tif`, `.tiff`, `.png` (including uppercase extensions)
- Can discover files in subfolders (depending on folder structure)

*Do not close FIJI while batch processing is running.*

---

### Output
For each analyzed file, the macro creates a dedicated output folder:

`<VideoName>-Contr-Results/`

Inside that folder you will typically find:
- `Contraction.jpg` and `Speed of contraction.jpg` plots
- `contraction.txt` and `speed-of-contraction.txt` (time series export)
- `maxProjectStack.tif`
- `Log_file.txt` (versioned if rerun)
- `Results.txt` (versioned if rerun)
- `Results.csv` (versioned if rerun)

**Results.csv is Excel-friendly**:
- Includes column headers (generated automatically)
- Uses comma-separated format

Using the exported results, you can calculate metrics such as **BPM** from peak-to-peak timing (e.g., from the `Peak-to-peak time (ms)` column).

---

### What Was Modified (Batch Fixed v6)
This version is a batch-safe modification of the original MuscleMotion macro (algorithm logic unchanged). Key improvements:
- Robust batch file discovery (AVI/TIF/TIFF/PNG), including uppercase extensions
- Safer processing across files (prevents failures when Results window is missing)
- Consistent window naming (`original-stack`)
- Avoids `java.lang.String.toLowerCase` to support older macro engines
- Automatic per-video output folder creation
- Results are exported with proper headers to a CSV file suitable for Excel
- Versioned outputs (`Results_1.csv`, `Log_file_1.txt`, etc.) to prevent overwriting

---

### Limitations
- Requires FIJI/ImageJ macro environment and MuscleMotion dependencies.
- Batch behavior depends on file layout and supported formats.
- BPM calculation depends on successful peak detection (if no peaks are detected, a minimal Results row is created).
- Output CSV is comma-separated; regional Excel settings may require changing delimiter settings (comma vs semicolon).

---

### Reproducibility Note
This modified MuscleMotion macro was developed to standardize contractility analysis across multiple recordings by enabling reliable batch processing and structured output storage per video. Exporting the logfile/results into an Excel-friendly format (CSV with headers) improves traceability, reproducibility, and downstream quantitative analysis (e.g., BPM extraction).
