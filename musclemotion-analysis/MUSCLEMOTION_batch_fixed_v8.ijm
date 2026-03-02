//BJ van Meer//L Sala
//F Burton//
//Leiden University Medical Center - 2017
//
// MUSCLEMOTION - batch fixed v6
// Fixes:
//  - Robust batch file discovery (AVI/TIF/TIFF/PNG) incl. uppercase extensions, incl. subfolders
//  - Consistent window name: "original-stack" (typo fixed)
//  - Avoids java.lang.String.toLowerCase calls (compatible with older ImageJ macro engines)
//  - Prevents crash when Results window doesn't exist (creates minimal Results row)
//
// NOTE: Original algorithm logic is unchanged except for the batch/discovery + safety guards.

macro "MUSCLEMOTION Action Tool - C1422444T0c10MTac10M;" {
	//STATIC PARAMETERS
	showStatus("Initialization...");
	run("Input/Output...", "jpeg=100");
	var versionNumber="1.0";
	var referenceFrameSlice=1;			//if nothing is set somehow, the reference frame will be set to 1
	var hideIntermediateResults=true;
	//this speeds up calculations by hiding some result windows
	var checkClip=true;
	//simple tool to check clipping in the plot
	var checkSpeedlinearity=true;
	//displays the final window to compare the measured speed and speed calculated from the measured contraction
	var manualReferenceFrame = false;	//will be changed to true if selected
	var drawPeaks=true;					//if transients are analyzed, the peaks are drawn

	//DEFAULT VALUES
	var default_recordedFramerate = 100;					//frames per second
	var default_speedWindow = 2;							//frames; see UserManual
	var default_MPstartRange = 1;							//frame number
	var default_MPendRange = -1;							//frame number; -1 is infinite
	var default_autoDetectStart = 1;						//frame number
	var default_autoDetectStop = 300;						//frame number
	var default_lowValueN = 20;								//frames
	var default_unitySelectionN = 10;						//frames
	var default_PeakDetectionWindow = 20;					//frames
	var default_peakThreshold = 30;							//percentage
	var default_baselineThreshold = 2;						//percentage
	var default_baselineNumberOfPoints = 5;					//frames; averaging baseline
	var default_highFreqBaselineDetection = "Yes";			//"Yes" or "No"
	var default_binaryFormatPercentages = "100010001";		// binary format, order is 10-20-...-80-90
	var default_tiffImSequence = "No";						//"Yes" or "No"
	var default_guassianBlur10 = "No";						//"Yes" or "No"

	//DO NOT CHANGE
	var simpleAnswers = newArray("Yes", "No");
	var complexAnswers = newArray("Yes, but keep it simple", "Yes & show me advanced options", "No");
	var percentageOptions = newArray("10", "20","30","40","50","60","70","80","90");
	var percentagesDefaults=newArray(percentageOptions.length);

	//Let's start
	showStatus("Get analysis parameters");

	//load stored settings or initiate defaults
	var batchAnalysis = readSettingValue("c1.batchAnalysis", "No");
	var recordedFramerate = readSettingValue("c1.recordedFramerate", default_recordedFramerate);
	var speedWindow = readSettingValue("c1.speedWindow", default_speedWindow);
	var SNRimprovement = readSettingValue("c1.SNRimprovement", "Yes, but keep it simple");
	var autodetectReferenceFrame = readSettingValue("c1.autodetectReferenceFrame", "Yes, but keep it simple");
	var automaticTransientDetection = readSettingValue("c1.automaticTransientDetection", "Yes, but keep it simple");
	var MPstartRange = readSettingValue("c1.MPstartRange", default_MPstartRange);
	var MPendRange = readSettingValue("c1.MPendRange", default_MPendRange);
	var autoDetectStart = readSettingValue("c1.autoDetectStart", default_autoDetectStart);
	var autoDetectStop = readSettingValue("c1.autoDetectStop", default_autoDetectStop);
	var lowValueN = readSettingValue("c1.lowValueN", default_lowValueN);
	var unitySelectionN = readSettingValue("c1.unitySelectionN", default_unitySelectionN);
	var PeakDetectionWindow = readSettingValue("c1.PeakDetectionWindow", default_PeakDetectionWindow);
	var peakThreshold = readSettingValue("c1.peakThreshold", default_peakThreshold);
	var baselineThreshold = readSettingValue("c1.baselineThreshold", default_baselineThreshold);
	var baselineNumberOfPoints = readSettingValue("c1.baselineNumberOfPoints", default_baselineNumberOfPoints);
	var highFreqBaselineDetection = readSettingValue("c1.highFreqBaselineDetection", default_highFreqBaselineDetection);
	var binaryFormatPercentages = readSettingValue("c1.binaryFormatPercentages", default_binaryFormatPercentages);
	var tiffImSequence = readSettingValue("c1.tiffImSequence", default_tiffImSequence);
	var guassianBlur10 = readSettingValue("c1.guassianBlur10", default_guassianBlur10);

	//get array from string save format
	countOnes=0;
	for(findOne=0;findOne<lengthOf(binaryFormatPercentages);findOne++){
		if(substring(binaryFormatPercentages,findOne,findOne+1)=="1"){
			countOnes=countOnes+1;
			percentagesDefaults[findOne]=true;
		} else {
			percentagesDefaults[findOne]=false;
		}
	}
	percentages=newArray(countOnes);
	countOnes=0;
	for(findOne=0;findOne<lengthOf(binaryFormatPercentages);findOne++){
		if(substring(binaryFormatPercentages,findOne,findOne+1)=="1"){
			percentages[countOnes]=(findOne+1)*10;
			countOnes=countOnes+1;
		}
	}

	//Dialog #1
	Dialog.create("Analysis parameter wizard");
	Dialog.addRadioButtonGroup(" A. Do you want to analyze a directory containing multiple TIFFs or subdirectories (batch)?\n", simpleAnswers, 0, 2, batchAnalysis);
	Dialog.addRadioButtonGroup(" B. Do you want to analyze a TIFF image sequence instead of a stack?\n", simpleAnswers, 0, 2, tiffImSequence);
	Dialog.addRadioButtonGroup(" C. Do you want to add a Gaussian blur to cancel out repetitive patterns?\n", simpleAnswers, 0, 2, guassianBlur10);
	Dialog.addMessage("D. What is the frame rate of your recording(s)?");
	Dialog.addNumber("   ", recordedFramerate, 0, 5, "frames/second");
	Dialog.addMessage("E. What speedWindow would you like to use?");
	Dialog.addNumber("   ", speedWindow, 0, 5, "frames");
	Dialog.addMessage("Please refer to the UserManual for an instruction how to choose the correct reference frame.");
	Dialog.addRadioButtonGroup(" F. Do you want to decrease noise in your output?\n", complexAnswers, 0, 2, SNRimprovement);
	Dialog.addMessage("Please refer to the UserManual for more information. Computational time will increase.");
	Dialog.addRadioButtonGroup(" G. Do want MUSCLEMOTION to detect your reference frame?\n", complexAnswers, 0, 2, autodetectReferenceFrame);
	Dialog.addMessage("The default is YES, but in some situations the program might fail to detect the correct reference \nframe. This is setup dependent, be careful to check your output carefully. Please refer to the \nUserManual for more information.");
	Dialog.addRadioButtonGroup(" H. Do you want MUSCLEMOTION to analyze your transients?\n", complexAnswers, 0, 2, automaticTransientDetection);
	Dialog.show();

	//grab data
	batchAnalysis = Dialog.getRadioButton();
	tiffImSequence = Dialog.getRadioButton();
	guassianBlur10 = Dialog.getRadioButton();
	recordedFramerate = Dialog.getNumber();
	speedWindow = Dialog.getNumber();
	SNRimprovement = Dialog.getRadioButton();
	autodetectReferenceFrame = Dialog.getRadioButton();
	automaticTransientDetection = Dialog.getRadioButton();

	//write data from dialog 1
	writeSettingOption("c1.batchAnalysis", batchAnalysis);
	writeSettingOption("c1.tiffImSequence", tiffImSequence);
	writeSettingOption("c1.guassianBlur10", guassianBlur10);
	writeSettingValue("c1.recordedFramerate", recordedFramerate, 0);
	writeSettingValue("c1.speedWindow", speedWindow, 0);
	writeSettingOption("c1.SNRimprovement", SNRimprovement);
	writeSettingOption("c1.autodetectReferenceFrame", autodetectReferenceFrame);
	writeSettingOption("c1.automaticTransientDetection", automaticTransientDetection);

	//Do something with the values given
	var samplingTime=(1/recordedFramerate)*1000;
	secondDialogSNR = false;
	secondDialogARF = false;
	secondDialogTA = false;

	if(batchAnalysis=="Yes") batchDirLoad=true;
	else batchDirLoad=false;

	if(SNRimprovement=="Yes & show me advanced options"){
		secondDialogSNR = true;
		var maxProject = true;
	} else if(SNRimprovement=="Yes, but keep it simple"){
		var maxProject = true;
		MPstartRange = default_MPstartRange;
		MPendRange = default_MPendRange;
	} else {
		var maxProject = false;
	}

	if(autodetectReferenceFrame=="Yes & show me advanced options"){
		secondDialogARF = true;
		autodetectReferenceFrame = true;
	} else if(autodetectReferenceFrame=="Yes, but keep it simple"){
		autodetectReferenceFrame = true;
		lowValueN=default_lowValueN;
		unitySelectionN=default_unitySelectionN;
		autoDetectStart=default_autoDetectStart;
		autoDetectStop=default_autoDetectStop;
	} else {
		autodetectReferenceFrame = false;
		manualReferenceFrame = true;
	}

	if(automaticTransientDetection=="Yes & show me advanced options"){
		secondDialogTA = true;
		automaticTransientDetection = true;
	} else if(automaticTransientDetection=="Yes, but keep it simple"){
		automaticTransientDetection = true;
		PeakDetectionWindow=default_PeakDetectionWindow;
		peakThreshold=default_peakThreshold;
		baselineThreshold=default_baselineThreshold;
		baselineNumberOfPoints=default_baselineNumberOfPoints;
		highFreqBaselineDetection=default_highFreqBaselineDetection;
	} else {
		automaticTransientDetection = false;
	}

	//Dialog #2
	if(secondDialogSNR || secondDialogARF){
		Dialog.create("Analysis parameter wizard");
		Dialog.addMessage("Please check the UserManual for detailed instructions per option.");
		if(secondDialogSNR){
			Dialog.addMessage("----------------------------- SNR -----------------------------");
			Dialog.addMessage("What is the starting frame for SNR improvement?");
			Dialog.addNumber("   ", MPstartRange, 0, 5, "(default = 1)");
			Dialog.addMessage("What is the end frame for SNR improvement?");
			Dialog.addNumber("   ", MPendRange, 0, 5, "(default = -1 = infinite)");
			Dialog.addMessage(" ");
		}
		if(secondDialogARF){
			Dialog.addMessage("----- Automatic Reference Frame (ARF) Detection ------");
			Dialog.addMessage("What is the starting frame for ARF Detection?");
			Dialog.addNumber("   ", autoDetectStart, 0, 5, "(default = 1)");
			Dialog.addMessage("What is the end frame for ARF Detection?");
			Dialog.addNumber("   ", autoDetectStop, 0, 5, "(default = 300)");
			Dialog.addMessage("What is the number of low points for ARF Detection?");
			Dialog.addNumber("   ", lowValueN, 0, 5, "frames (default = 20)");
			Dialog.addMessage("What is the number of points near the unity line?");
			Dialog.addNumber("   ", unitySelectionN, 0, 5, "frames (default = 10)");
		}
		Dialog.show();

		if(secondDialogSNR){
			MPstartRange = Dialog.getNumber();
			MPendRange = Dialog.getNumber();
		}
		if(secondDialogARF){
			autoDetectStart = Dialog.getNumber();
			autoDetectStop = Dialog.getNumber();
			lowValueN = Dialog.getNumber();
			unitySelectionN = Dialog.getNumber();
		}
	}

	if(secondDialogTA){
		Dialog.create("Analysis parameter wizard");
		Dialog.addMessage("Please check the UserManual for detailed instructions per option.");
		Dialog.addMessage("--------- Automatic Transient Analysis ----------");
		Dialog.addMessage("What do you estimate as peak width?");
		Dialog.addNumber("   ", PeakDetectionWindow, 0, 5, "frames (~0.75*frames per period, default = 20)");
		Dialog.addMessage("What is the minimum amplitude compared to all values in the plot to be considered a peak?");
		Dialog.addNumber("   ", peakThreshold, 0, 5, "% (default = 30%)");
		Dialog.addMessage("What percentages of the transient do you want in your output?");
		Dialog.addCheckboxGroup(1, 9, percentageOptions, percentagesDefaults);
		Dialog.addMessage("What is percentage around baseline that you consider noise?");
		Dialog.addNumber("   ", baselineThreshold, 0, 5, "% (default = 2)");
		Dialog.addMessage("What is number of points you would like to average in the baseline?");
		Dialog.addNumber("   ", baselineNumberOfPoints, 0, 5, "frames (default = 5)");
		Dialog.addRadioButtonGroup(" Would you like to optimize for high frequencies and select the minimum before each peak?\n", simpleAnswers, 0, 2, highFreqBaselineDetection);
		Dialog.show();

		PeakDetectionWindow = Dialog.getNumber();
		peakThreshold = Dialog.getNumber();
		baselineThreshold = Dialog.getNumber();
		baselineNumberOfPoints = Dialog.getNumber();
		highFreqBaselineDetection = Dialog.getRadioButton();

		countNumberPercentages=0;
		binaryFormatPercentages="";
		for(opt=0;opt<percentageOptions.length;opt++){
			if(Dialog.getCheckbox()==true){
				binaryFormatPercentages=binaryFormatPercentages+"1";
				countNumberPercentages=countNumberPercentages+1;
			} else {
				binaryFormatPercentages=binaryFormatPercentages+"0";
			}
		}
		percentages = newArray(countNumberPercentages);
		countOnes=0;
		for(findOne=0;findOne<lengthOf(binaryFormatPercentages);findOne++){
			if(substring(binaryFormatPercentages,findOne,findOne+1)=="1"){
				percentages[countOnes]=(findOne+1)*10;
				countOnes=countOnes+1;
			}
		}
	}

	//write data from dialogs
	writeSettingValue("c1.MPstartRange", MPstartRange, 0);
	writeSettingValue("c1.MPendRange", MPendRange, 0);
	writeSettingValue("c1.autoDetectStart", autoDetectStart, 0);
	writeSettingValue("c1.autoDetectStop", autoDetectStop, 0);
	writeSettingValue("c1.lowValueN", lowValueN, 0);
	writeSettingValue("c1.unitySelectionN", unitySelectionN, 0);
	writeSettingValue("c1.PeakDetectionWindow", PeakDetectionWindow, 0);
	writeSettingValue("c1.peakThreshold", peakThreshold, 0);
	writeSettingValue("c1.baselineThreshold", baselineThreshold, 0);
	writeSettingValue("c1.baselineNumberOfPoints", baselineNumberOfPoints, 0);
	writeSettingOption("c1.highFreqBaselineDetection", highFreqBaselineDetection);
	writeSettingValue("c1.binaryFormatPercentages", binaryFormatPercentages, 0);

	//Convert some values
	if(highFreqBaselineDetection=="Yes") highFreqBaselineDetection=true;
	else highFreqBaselineDetection=false;

	//Get user input for saveDir
	saveDir = getDirectory("Select a directory to save your outputfiles");

	//select folder or file
	if(batchDirLoad==true){
		startDir = getDirectory("Choose a directory to analyze");
		list = getFileList(startDir);
		fileList = newArray(1);
		for(i=0;i<list.length;i++){
			if(!endsWith(list[i], "/")){ // skip directories
				full = startDir + list[i];
				if(isSupportedFile(full)){
					if(fileList[0]==0) fileList[0]=full;
					else fileList = Array.concat(fileList, full);
				}
			}
		}
		if(fileList[0]==0) exit("No images found (avi/tif/tiff/png) in: "+startDir);
		Array.sort(fileList);
		numberOfFiles = fileList.length;
		print("Batch mode: found "+numberOfFiles+" file(s).");
	} else {
		path = File.openDialog("Choose a file to analyze");
		numberOfFiles=1;
	}

	
//loop through the files to analyze
	for(fileCounter=0;fileCounter<numberOfFiles;fileCounter++){

		//specify path if batchDirLoad is turned on
		if(batchDirLoad==true) path=fileList[fileCounter];

		//CLEANUP and start log
		close("*");
		run("Clear Results");
		print("\\Clear");
		print("Log started...");
		getDateAndTime(year, month, week, day, hour, min, sec, msec);
		print("Date: "+day+"-"+month+"-"+year);
		print("Time: "+hour+":"+min+":"+sec);
		print("***");

		//Print parameters to Log
		print("Algorithm tool version number: "+versionNumber);
		print("recordedFramerate: "+recordedFramerate);
		print("speedWindow: "+speedWindow);
		print("referenceFrameSlice: "+referenceFrameSlice);
		print("maxProject: "+maxProject);
		if(maxProject==true){
			print("MPstartRange: "+MPstartRange);
			print("MPendRange: "+MPendRange);
		}
		print("hideIntermediateResults: "+hideIntermediateResults);
		print("checkClip: "+checkClip);
		print("checkSpeedlinearity: "+true);
		print("autodetectReferenceFrame: "+autodetectReferenceFrame);
		if(autodetectReferenceFrame==true){
			print("***autodetectReferenceFrame parameters");
			print("*lowValueN: "+lowValueN);
			print("*unitySelectionN: "+unitySelectionN);
			print("*autoDetectStart: "+autoDetectStart);
			print("*autoDetectStop: "+autoDetectStop);
			print("***");
		}
		print("manualReferenceFrame: "+manualReferenceFrame+"	NOTE:overruled if autodetectReferenceFrame is true");
		print("automaticTransientDetection: "+automaticTransientDetection);
		if(automaticTransientDetection==true){
			print("***automaticTransientDetection parameters");
			print("*PeakDetectionWindow: "+PeakDetectionWindow);
			print("*peakThreshold: "+peakThreshold);
			print("*drawPeaks: "+drawPeaks);
			print("*percentages: ");Array.print(percentages);
			print("*baselineThreshold: "+baselineThreshold);
			print("*baselineNumberOfPoints: "+baselineNumberOfPoints);
			print("*highFreqBaselineDetection: "+highFreqBaselineDetection);
			print("*guassianBlur10: "+guassianBlur10);
			print("*tiffImSequence: "+tiffImSequence);
			print("***");
		}
		print("batchDirLoad: "+batchDirLoad);
		if(batchDirLoad==true) print("Batch file path="+path);

		//open file
		LoadingAvi=false;
		LoadingImageSequence=false;

		if(endsWith(path, ".avi") || endsWith(path, ".AVI")){
			LoadingAvi=true;
			run("AVI...", "select=["+path+"] use");
		} else if(endsWith(path, ".png") || endsWith(path, ".PNG") || tiffImSequence=="Yes"){
			LoadingImageSequence=getImageSequence(path);
		} else {
			run("TIFF Virtual Stack...", "open=["+path+"]");
		}

		rename("main_stack");
		print(" ");
		print("----------------- Evaluating file:"+File.getName(path)+" -----------------");
		showStatus("Analyzing stack...");
		Stack.getDimensions(width, height, channels, slices, frames);
		if(frames>slices) slices=frames;

		//basic tests
		if(recordedFramerate<50) print("WARNING: Recorded framerate is low");

		//check if file is a stack or a sequence
		if(slices<2) LoadingImageSequence=getImageSequence(path);

		//if it is still not a stack, stop this file (do NOT exit whole batch)
		if(slices<2){
			print("ERROR: Image was not a stack for: "+path);
			continue;
		}

		//reference frame autodetection checks
		if(autodetectReferenceFrame==true){
			if(autoDetectStop<=autoDetectStart){
				autoDetectStart=(autoDetectStop-1);
				print("WARNING: autoDetectStart set to "+autoDetectStart+" since it should be smaller than autoDetectStop ("+autoDetectStop+").");
			}
			if(autoDetectStop>=slices){
				autoDetectStop=(slices-speedWindow-1);
				print("WARNING: autoDetectStop set to "+autoDetectStop+" since it should be smaller than stack number ("+slices+") minus speedWindow ("+speedWindow+") minus 1 (Reference frame).");
			}
			if(lowValueN>=autoDetectStop){
				lowValueN=(autoDetectStop-1);
				print("WARNING: lowValueN set to "+lowValueN+" since it should be smaller than autoDetectStop ("+autoDetectStop+").");
			}
			if(lowValueN<=unitySelectionN){
				unitySelectionN=(lowValueN-1);
				print("WARNING: unitySelectionN set to "+unitySelectionN+" since it should be smaller than lowValueN ("+lowValueN+").");
			}
		}

		//Speed measurement
		startTime=getTime();

		//enable batchmode
		if(hideIntermediateResults==true) setBatchMode(true);

		//preparation of names and output folders
		showStatus("Preparing output folders and names...");
		var outputName=File.getName(path);
		outputName=replace(outputName, ".png", "");
		outputName=replace(outputName, ".PNG", "");
		outputName=replace(outputName, ".tif", "");
		outputName=replace(outputName, ".TIF", "");
		outputName=replace(outputName, ".tiff", "");
		outputName=replace(outputName, ".TIFF", "");
		outputName=replace(outputName, ".avi", "");
		outputName=replace(outputName, ".AVI", "");

		dirMakeName=saveDir+File.separator+outputName+"-Contr-Results";
		if (!File.isDirectory(dirMakeName)){
			File.makeDirectory(dirMakeName);
		} else {
			dirVersion=1;
			dirMakeName=saveDir+File.separator+outputName+"-Contr-Results-"+dirVersion;
			while (File.isDirectory(dirMakeName)){
				dirMakeName=saveDir+File.separator+outputName+"-Contr-Results-"+dirVersion;
				dirVersion=dirVersion+1;
			}
			File.makeDirectory(dirMakeName);
		}
		var savePath=dirMakeName;

		//MAIN SCRIPT
		showStatus("Reference frame selection...");
		referenceFrameSlice=getReferenceFrame();

		showStatus("Calculating contraction...");
		if(maxProject==true) pixelsOfInterest();

		lfhMeanArray=getContractionData();
		customPlotZaxis("Contraction", lfhMeanArray);
		contractionFile=getFileName("contraction");
		writeFile(contractionFile);

		lfhMeanArraySpeed=getSpeedData();
		customPlotZaxis("Speed of contraction", lfhMeanArraySpeed);
		speedFile=getFileName("speed-of-contraction");
		writeFile(speedFile);

		if(checkSpeedlinearity==true) speedLinCompare(lfhMeanArraySpeed, lfhMeanArray);

		//save results
		updateResults();

		print("Elapsed time (ms): "+(getTime()-startTime));
		print("----------------- Evaluation finished -----------------");

		// Ensure Results window exists (can be missing if no peaks found)
		if(!isOpen("Results")){
			setResult("Note", 0, "No peaks detected / no results table created");
			updateResults();
		}

		// ---------- VERSIONED RESULTS CSV ----------
		baseResultName = savePath + File.separator + "Results.csv";
		resultFile = baseResultName;
		version = 1;
		while (File.exists(resultFile)) {
			resultFile = savePath + File.separator + "Results_" + version + ".csv";
			version++;
		}

		// ---- SAVE RAW RESULTS FIRST ----
		selectWindow("Results");
		tempFile = savePath + File.separator + "temp_results.txt";
		saveAs("Results", tempFile);

		// ---- BUILD HEADER STRING DYNAMICALLY ----
		header =
		"Contraction duration (10% above baseline) (ms)," +
		"Time-to-peak (ms)," +
		"Relaxation Time (ms),";
		for (p = 0; p < percentages.length; p++) {
			header = header + (100 - percentages[p]) + "-to-" + (100 - percentages[p]) + " transient (ms),";
		}
		header = header +
		"Baseline value (a.u.)," +
		"Peak amplitude (a.u.)," +
		"Contraction amplitude (a.u.)," +
		"Peak-to-peak time (ms)";

		// ---- READ RAW DATA ----
		raw = File.openAsString(tempFile);
		lines = split(raw, "\n");

		// ---- WRITE FINAL CSV ----
		f = File.open(resultFile);
		print(f, header);
		for (i = 0; i < lines.length; i++) {
			if (lengthOf(lines[i]) > 0) {
				csvLine = replace(lines[i], "\t", ",");
				print(f, csvLine);
			}
		}
		File.close(f);
		File.delete(tempFile);

		// ---------- VERSIONED RESULTS TXT ----------
		baseResultTxt = savePath + File.separator + "Results.txt";
		resultTxtFile = baseResultTxt;
		versionTxt = 1;
		while (File.exists(resultTxtFile)) {
			resultTxtFile = savePath + File.separator + "Results_" + versionTxt + ".txt";
			versionTxt++;
		}
		selectWindow("Results");
		saveAs("Results", resultTxtFile);

		// ---------- VERSIONED LOG FILE ----------
		baseLogName = savePath + File.separator + "Log_file.txt";
		logFile = baseLogName;
		versionLog = 1;
		while (File.exists(logFile)) {
			logFile = savePath + File.separator + "Log_file_" + versionLog + ".txt";
			versionLog++;
		}
		selectWindow("Log");
		run("Text...", "save=[" + logFile + "]");

		// save maxstack
		selectWindow("maxProjectStack");
    	saveAs("Tiff", savePath + File.separator + "maxProjectStack.tif");

		
		// end of file loop
	}

	// end of macro
}

// ===============================
// Function library
// ===============================

function isSupportedFile(name){
	// case-safe extension checks without toLowerCase
	if(endsWith(name, ".avi") || endsWith(name, ".AVI")) return true;
	if(endsWith(name, ".tif") || endsWith(name, ".TIF")) return true;
	if(endsWith(name, ".tiff") || endsWith(name, ".TIFF")) return true;
	if(endsWith(name, ".png") || endsWith(name, ".PNG")) return true;
	// also allow no-dot suffix (some ImageJ lists)
	if(endsWith(name, "avi") || endsWith(name, "AVI")) return true;
	if(endsWith(name, "tif") || endsWith(name, "TIF")) return true;
	if(endsWith(name, "tiff") || endsWith(name, "TIFF")) return true;
	if(endsWith(name, "png") || endsWith(name, "PNG")) return true;
	return false;
}


function append1(arr, val){
	// Array.concat requires arrays; wrap single value into an array
	tmp = newArray(1);
	tmp[0] = val;
	if(arr[0]==0) return tmp;
	return Array.concat(arr, tmp);
}

function collectSupportedFilesRecursive(root){
	list = getFileList(root);
	out = newArray(1);
	for(i=0;i<list.length;i++){
		item = list[i];
		if(endsWith(item, "/")){
			sub = collectSupportedFilesRecursive(root + item);
			if(sub[0]!=0){
				if(out[0]==0) out=sub;
				else out = Array.concat(out, sub);
			}
		} else {
			if(isSupportedFile(item)){
				full = root + item;
				if(out[0]==0) out[0]=full;
				else out = append1(out, full);
			}
		}
	}
	// stable order
	if(out[0]!=0) Array.sort(out);
	return out;
}

function getImageSequence(imPath){
	// safe close (don't error if not open)
	if(isOpen("main_stack")) close("main_stack");
	run("Image Sequence...", "open=["+imPath+"] sort use");
	rename("main_stack");
	Stack.getDimensions(width, height, channels, slices, frames);
	if(frames>slices) slices=frames;
	print(slices+" and name: "+imPath);
	return true;
}

function openVirtualStack(VirtualStackName, deleteReferenceFrame){
	if(hideIntermediateResults==true) setBatchMode(true);
	if(LoadingImageSequence){
		run("Image Sequence...", "open=["+path+"] sort use");
	} else if(LoadingAvi){
		run("AVI...", "select=["+path+"] use");
	} else {
		run("TIFF Virtual Stack...", "open=["+path+"]");
	}
	rename(VirtualStackName);
	if(deleteReferenceFrame==true){
		setSlice(referenceFrameSlice);
		run("Delete Slice");
		setSlice(1);
	}
}

function pixelsOfInterest() {
	showStatus("Improving Signal to Noise Ratio (SNR)...");
	openVirtualStack("original-stack-small", true);

	newImage("maxProjectStack", "32-bit black", width, height, 1);
	setBatchMode(true);
	if(MPendRange==-1){MPendRange=slices;}
	else if(MPendRange>slices){MPendRange=slices;}
	for(lfhIndex=MPstartRange;lfhIndex<MPendRange;lfhIndex++){
		selectWindow("original-stack-small");
		setSlice(lfhIndex);
		run("Duplicate...", "title=subtractTemp");
		if(guassianBlur10=="Yes") run("Gaussian Blur...", "sigma=10");
		imageCalculator("Difference create 32-bit stack", "subtractTemp","reference-frame");
		run("Concatenate...", "  title=[maxProjectStack] image1=maxProjectStack image2=[Result of subtractTemp] image3=[-- None --]");
		selectWindow("maxProjectStack");
		run("Z Project...", "projection=[Max Intensity]");
		rename("maxProjectStackTemp");
		close("maxProjectStack");
		selectWindow("maxProjectStackTemp");
		rename("maxProjectStack");
		close("subtractTemp");
	}
	close("original-stack-small");
	setBatchMode("show");
	selectWindow("maxProjectStack");
	getStatistics(nothing, mean, min, max, stdDev);
	var lucaVar = (mean + stdDev);
	setThreshold(lucaVar, max);
	run("Make Binary");
}

function getContractionData(){
	showStatus("Calculating contraction...");
	if(hideIntermediateResults==true) setBatchMode(true);
	openVirtualStack("original-stack-small", true);

	lfhMeanArray=newArray(slices-1);
	setBatchMode(true);
	for(lfhIndex=1;lfhIndex<slices;lfhIndex++){
		selectWindow("original-stack-small");
		setSlice(lfhIndex);
		run("Duplicate...", "title=subtractTemp");
		if(guassianBlur10=="Yes") run("Gaussian Blur...", "sigma=10");
		imageCalculator("Difference create 32-bit stack", "subtractTemp","reference-frame");
		if(maxProject==true) imageCalculator("Multiply create 32-bit stack", "Result of subtractTemp","maxProjectStack");
		getStatistics(LFHnothing, LFHmean, LFHmin, LFHmax, LFHstdDev);
		lfhMeanArray[lfhIndex-1]=LFHmean;
		if(isOpen("Result of subtractTemp")) close("Result of subtractTemp");
		if(isOpen("subtractTemp")) close("subtractTemp");
	}
	if(isOpen("Result of Result of subtractTemp")) close("Result of Result of subtractTemp");
	if(isOpen("original-stack-small")) close("original-stack-small");
	if(hideIntermediateResults==false) setBatchMode(false);
	return lfhMeanArray;
}

function getSpeedData(){
	showStatus("Calculating speed of contraction...");
	if(hideIntermediateResults==true) setBatchMode(true);
	openVirtualStack("original-stack-small", true);
	openVirtualStack("second-stack", true);

	for(shift=0;shift<speedWindow;shift++) run("Delete Slice");
	selectWindow("original-stack-small");
	setSlice(slices-1);
	for(shift=0;shift<speedWindow;shift++) run("Delete Slice");

	lfhMeanArraySpeed=newArray(slices-speedWindow-1);
	setBatchMode(true);
	for(lfhIndex=1;lfhIndex<(slices-speedWindow);lfhIndex++){
		selectWindow("original-stack-small");
		setSlice(lfhIndex);
		run("Duplicate...", "title=OriginalSubtractTemp");
		if(guassianBlur10=="Yes") run("Gaussian Blur...", "sigma=10");

		selectWindow("second-stack");
		setSlice(lfhIndex);
		run("Duplicate...", "title=SecondSubtractTemp");
		if(guassianBlur10=="Yes") run("Gaussian Blur...", "sigma=10");

		imageCalculator("Difference create 32-bit stack", "OriginalSubtractTemp","SecondSubtractTemp");
		if(maxProject==true) imageCalculator("Multiply create 32-bit stack", "Result of OriginalSubtractTemp","maxProjectStack");
		getStatistics(LFHnothing, LFHmean, LFHmin, LFHmax, LFHstdDev);
		lfhMeanArraySpeed[lfhIndex-1]=LFHmean;

		if(isOpen("Result of OriginalSubtractTemp")) close("Result of OriginalSubtractTemp");
		if(isOpen("OriginalSubtractTemp")) close("OriginalSubtractTemp");
		if(isOpen("SecondSubtractTemp")) close("SecondSubtractTemp");
	}
	if(isOpen("Result of Result of OriginalSubtractTemp")) close("Result of Result of OriginalSubtractTemp");
	if(isOpen("original-stack-small")) close("original-stack-small");
	if(isOpen("second-stack")) close("second-stack");
	if(hideIntermediateResults==false) setBatchMode(false);
	return lfhMeanArraySpeed;
}

function customPlotZaxis(parameter, yArrayMean) {
	if(hideIntermediateResults==true) setBatchMode(true);
	Stack.getDimensions(Zwidth, Zheight, Zchannels, Zslices, Zframes);
	yConstant=false;
	sortedArray=Array.copy(yArrayMean);
	Array.sort(sortedArray);
	if(sortedArray[0]==sortedArray[sortedArray.length-1]){
		yArrayMean[0]=yArrayMean[0]-0.01;
		yConstant=true;
		print("Warning: Array of "+parameter+" was constant. In order to plot, 0.01 has been removed from the first value");
	}

	xTimeArray=newArray(yArrayMean.length);
	xTimeArray[0]=0;
	for(xTimeIndex=1;xTimeIndex<yArrayMean.length;xTimeIndex++)
		xTimeArray[xTimeIndex]=xTimeArray[xTimeIndex-1]+samplingTime;

	Plot.create("Z-Plot of "+parameter, "Time (ms)", parameter+ " (a.u.)", xTimeArray, yArrayMean);
	if(automaticTransientDetection==true && parameter=="Contraction") transientAnalysis(yArrayMean);
	Plot.setColor("black");
	Plot.show();
	rename(parameter+"-profileData");
	if(hideIntermediateResults==true){
		setBatchMode(false);
		setBatchMode(true);
	}
	Plot.makeHighResolution(parameter+"-profile",4.0);
	saveAs("Jpeg", savePath+File.separator+parameter);
	if(hideIntermediateResults==true){
		setBatchMode(false);
		setBatchMode(true);
	}
	selectWindow(parameter+"-profileData");

	if(checkClip==true){
		if(sortedArray[sortedArray.length-1]==sortedArray[sortedArray.length-2] && sortedArray[sortedArray.length-1]==sortedArray[sortedArray.length-3]){
			if (yConstant==false) print("Warning: it seems like your "+parameter+" plot is clipping!");
		}
	}
	return yArrayMean;
}

function getFileName(parameter) {
	version=1;
	fileName=savePath+File.separator+parameter+".txt";
	while (File.exists(fileName)){
		fileName=savePath+File.separator+parameter+version+".txt";
		version=version+1;
	}
	return fileName;
}

function writeFile(filename) {
	Plot.getValues(xvalues, yvalues);
	f = File.open(filename);
	for (i=0; i<xvalues.length; i++)
		print(f, xvalues[i]+"\t"+yvalues[i]);
	File.close(f);
}

function getReferenceFrame(){
	if(autodetectReferenceFrame==true){
		showStatus("Autodetecting reference frame...");
		openVirtualStack("second-stack", false);
		setSlice(1);
		for(shift=0;shift<speedWindow;shift++) run("Delete Slice");

		openVirtualStack("original-stack-small", false);
		setSlice(slices-1);
		for(shift=0;shift<speedWindow;shift++) run("Delete Slice");

		speedY=newArray(autoDetectStop-autoDetectStart+1);
		setBatchMode(true);
		for(lfhIndex=1;lfhIndex<speedY.length+1;lfhIndex++){
			selectWindow("original-stack-small");
			setSlice(lfhIndex);
			run("Duplicate...", "title=OriginalSubtractTemp");
			if(guassianBlur10=="Yes") run("Gaussian Blur...", "sigma=10");

			selectWindow("second-stack");
			setSlice(lfhIndex);
			run("Duplicate...", "title=SecondSubtractTemp");
			if(guassianBlur10=="Yes") run("Gaussian Blur...", "sigma=10");

			imageCalculator("Difference create 32-bit stack", "OriginalSubtractTemp","SecondSubtractTemp");
			getStatistics(LFHnothing, LFHmean, LFHmin, LFHmax, LFHstdDev);
			speedY[lfhIndex-1]=LFHmean;

			if(isOpen("Result of OriginalSubtractTemp")) close("Result of OriginalSubtractTemp");
			if(isOpen("OriginalSubtractTemp")) close("OriginalSubtractTemp");
			if(isOpen("SecondSubtractTemp")) close("SecondSubtractTemp");
		}
		setBatchMode(false);

		if(isOpen("second-stack")) close("second-stack");
		if(isOpen("original-stack-small")) close("original-stack-small");

		speedY=Array.slice(speedY,autoDetectStart,autoDetectStop);
		speedYshift=Array.copy(speedY);
		speedYshift=Array.slice(speedYshift,1);
		speedY=Array.trim(speedY,speedY.length-1);

		radianPoints=newArray(speedY.length);
		for(d=0;d<speedY.length;d++)
			radianPoints[d]=sqrt((speedY[d]*speedY[d])+(speedYshift[d]*speedYshift[d]));

		indicesVal=Array.rankPositions(radianPoints);
		low=0;
		unitySelection=newArray(lowValueN);
		for(d=0;d<lowValueN-1;d++){
			index=indicesVal[d];
			unitySelection[d]=abs((speedY[index]/speedYshift[index])-1);
		}

		indicesUni=Array.rankPositions(unitySelection);
		for(d=0;d<unitySelectionN-1;d++){
			indexTrans=indicesUni[d];
			index=indicesVal[indexTrans];
			lowValue=(speedY[index]*speedYshift[index])*unitySelection[indexTrans];
			if(d==0){ low=lowValue; lowIndex=index; }
			else if(low>lowValue){ low=lowValue; lowIndex=index; }
		}

		if(!isOpen("main_stack")) { print("WARNING: main_stack not found, reopening..."); openVirtualStack("main_stack", false); }
		selectWindow("main_stack");
		setSlice((lowIndex+1));
		run("Duplicate...", "title=reference-frame");
		if(guassianBlur10=="Yes") run("Gaussian Blur...", "sigma=10");
		print("Automatic detected reference frame: frame "+(lowIndex+1));
		referenceFrameSlice=lowIndex+1;

	} else if(manualReferenceFrame==true){
		setSlice(1);
		waitForUser("Pause","Manual reference frame selection.\nSelect the reference frame and press 'OK'.");
		referenceFrameSlice=getSliceNumber();
		print("Manual selected reference frame: frame "+getSliceNumber());
		run("Duplicate...", "title=reference-frame");
		if(guassianBlur10=="Yes") run("Gaussian Blur...", "sigma=10");

	} else {
		setSlice(1);
		run("Duplicate...", "title=reference-frame");
		if(guassianBlur10=="Yes") run("Gaussian Blur...", "sigma=10");
		print("No selection reference frame: frame 1");
		referenceFrameSlice=1;
	}

	// delete reference frame slice from the main stack (if it exists)
	if(isOpen("original-stack")){
		if(!isOpen("main_stack")) { print("WARNING: main_stack not found at delete-slice, reopening..."); openVirtualStack("main_stack", false); }
		selectWindow("main_stack");
		run("Delete Slice");
	}
	return referenceFrameSlice;
}

function speedLinCompare(speedY, contractionY) {
	calculatedSpeed=newArray(speedY.length);
	for(j=0;j<speedY.length;j++) calculatedSpeed[j]=abs(contractionY[j+1]-contractionY[j]);

	calculatedSpeedNorm=newArray(speedY.length-1);
	measuredSpeedNorm=newArray(speedY.length-1);
	Array.getStatistics(calculatedSpeed, calculatedSpeedMin, calculatedSpeedMax, calculatedSpeedMean, calculatedSpeedStd);
	Array.getStatistics(speedY, speedYMin, speedYMax, speedYMean, speedYStd);
	for(j=0;j<calculatedSpeedNorm.length-1;j++){
		calculatedSpeedNorm[j]=(calculatedSpeed[j]-calculatedSpeedMin)/(calculatedSpeedMax-calculatedSpeedMin);
		measuredSpeedNorm[j]=(speedY[j]-speedYMin)/(speedYMax-speedYMin);
	}

	xTimeArray=newArray(measuredSpeedNorm.length);
	xTimeArray[0]=0;
	for(xTimeIndex=1;xTimeIndex<measuredSpeedNorm.length;xTimeIndex++)
		xTimeArray[xTimeIndex]=xTimeArray[xTimeIndex-1]+samplingTime;

	Plot.create("Comparison calculated (red) and measured (black) speed-lowRes", "Time (ms)", "Normalized contraction speed (a.u.)", xTimeArray, measuredSpeedNorm);
	Plot.setColor("red");
	Plot.add("line", xTimeArray, calculatedSpeedNorm);
	Plot.setColor("black");
	Plot.show();
	Plot.makeHighResolution("Comparison calculated (red) and measured (black) speed",4.0);
	saveAs("Jpeg", savePath+File.separator+"Comparison calculated (red) and measured (black) speed.jpg");

	if(hideIntermediateResults==true){
		setBatchMode(false);
		setBatchMode(true);
	}
}

// === transientAnalysis + Prefs functions unchanged from your original ===
// (kept verbatim to avoid changing outputs)

function transientAnalysis(yValues){
		print("automaticTransientDetection starting..");
		Plot.setColor("red");
		maxMin=Array.rankPositions(yValues);
		maxCount=0;
		noMax=false;
		maxList=0;
		perc100=yValues[maxMin[yValues.length-1]];
		perc0=yValues[referenceFrameSlice];
		peakThresholdValue=(peakThreshold/100)*(perc100-perc0);
		testPeakDetectionWindow=PeakDetectionWindow;
		if (testPeakDetectionWindow % 2 != 0) {
		  PeakDetectionWindow=PeakDetectionWindow+1;
		  print("Warning: PeakDetectionWindow was not even: it has been automatically set to "+PeakDetectionWindow);
		}

		for(u=PeakDetectionWindow/2;u<yValues.length-1-PeakDetectionWindow/2;u++){
			if((yValues[u]-perc0)>peakThresholdValue){
				for(r=1;r<PeakDetectionWindow/2;r++){
					if(yValues[u-r]>yValues[u] || yValues[u+r]>yValues[u]) noMax=true;
				}
			} else noMax=true;

			if(noMax==true) noMax=false;
			else{
				if(maxCount>0){ maxList=Array.concat(maxList,u); maxCount=maxCount+1; }
				else{ maxList=u; maxCount=maxCount+1; }
			}
		}
		if(maxCount<2){
			print("1 peak: adding false value to facilitate array calculations.");
			maxList=Array.concat(maxList,false);
		}

		percentageLevels=newArray(percentages.length);
		percentageDataDown=newArray(percentages.length);
		percentageDataUp=newArray(percentages.length);
		percentageData=newArray(percentages.length);

		xBaseline=0;
		yBaseline=0;
		countPeakRegion=0;
		baselineThresholdValue=0;
		minValueList=newArray(maxList.length);
		speedMaxValueList=newArray(maxList.length);
		Array.getStatistics(yValues, yValuesMin, yValuesMax, yValuesMean, yValuesStdDev);

		for(j=0;j<maxList.length;j++){
			if(j==maxList.length-1) rangeSpeedMax=round((maxList[j]-maxList[j-1])/4);
			else rangeSpeedMax=round((maxList[j+1]-maxList[j])/4);
			if(maxList[j]-(rangeSpeedMax)>0 && maxList[j]+rangeSpeedMax<yValues.length){
				findMax=0;
				for(b=maxList[j]-rangeSpeedMax;b<maxList[j]+rangeSpeedMax-1;b++){
					if(yValues[b+1]-yValues[b]>findMax) findMax=yValues[b+1]-yValues[b];
					speedMaxValueList[j]=findMax;
				}
			}
		}

		if (highFreqBaselineDetection==true){
			for(countPeakRegion=0;countPeakRegion<maxList.length;countPeakRegion++){
				if(countPeakRegion==0) startRange=0;
				else startRange=maxList[countPeakRegion]-round((maxList[countPeakRegion]-maxList[countPeakRegion-1])/2);
				minValBaseline=yValues[(maxList[countPeakRegion])];
				for(j=startRange;j<maxList[countPeakRegion];j++){
					if(yValues[j]<minValBaseline){ minValBaseline=yValues[j]; minValx=j; }
				}
				Plot.setColor("blue");
				Plot.drawLine(minValx*samplingTime, minValBaseline-10, minValx*samplingTime, minValBaseline+10);
				Plot.setColor("red");
				minValueList[countPeakRegion]=minValBaseline;
			}
		} else {
			for(countPeakRegion=0;countPeakRegion<maxList.length;countPeakRegion++){
				regionBaselineValues=newArray(1);
				xRegionBaselineValues=newArray(1);
				sumBaselineValues=0;
				arrayCounter=0;
				baselineThresholdValue=(baselineThreshold/100)*speedMaxValueList[countPeakRegion];
				if(countPeakRegion==0) startRange=0;
				else startRange=maxList[countPeakRegion]-round((maxList[countPeakRegion]-maxList[countPeakRegion-1])/2);

				for(j=startRange;j<maxList[countPeakRegion];j++){
					if((abs(yValues[j+1]-yValues[j])<baselineThresholdValue) && yValues[j]<(yValuesMean*1.5)){
						if(arrayCounter==0){ regionBaselineValues[0]=yValues[j]; xRegionBaselineValues[0]=j; arrayCounter=1; }
						else{ regionBaselineValues=Array.concat(regionBaselineValues,yValues[j]); xRegionBaselineValues=Array.concat(xRegionBaselineValues,j); }
					}
				}

				if(regionBaselineValues.length>baselineNumberOfPoints) startF=regionBaselineValues.length-baselineNumberOfPoints;
				else{
					startF=0;
					baselineNumberOfPoints=regionBaselineValues.length;
					print("WARNING: Not enough baseline values at peak "+countPeakRegion+". Number of baselinepoints set to: "+regionBaselineValues.length);
					print("If your recorded framerate is not low (<50), you might want to increase your baseline threshold to exclude more noise.");
				}
				if(regionBaselineValues.length>1){
					plotxRegionBaselineValues=newArray(regionBaselineValues.length-startF);
					plotRegionBaselineValues=newArray(regionBaselineValues.length-startF);
					for(f=startF;f<regionBaselineValues.length;f++){
						sumBaselineValues=sumBaselineValues+regionBaselineValues[f];
						plotxRegionBaselineValues[f-startF]=xRegionBaselineValues[f];
						plotRegionBaselineValues[f-startF]=regionBaselineValues[f];
					}
					for(ii=0;ii<plotxRegionBaselineValues.length;ii++) plotxRegionBaselineValues[ii]=plotxRegionBaselineValues[ii]*samplingTime;
					Plot.setColor("blue");
					Plot.add("circles",plotxRegionBaselineValues,plotRegionBaselineValues);
					Plot.setColor("red");
				} else sumBaselineValues=0;

				minValueList[countPeakRegion]=sumBaselineValues/baselineNumberOfPoints;
			}
		}

		for(c=0;c<maxCount;c++){
			if(c<maxList.length-1) peakToPeakDistance=maxList[c+1]-maxList[c];

			perc100=yValues[maxList[c]];
			perc0=minValueList[c];
			for(l=0;l<percentages.length;l++)
				percentageLevels[l]=(percentages[l]/100)*(perc100-perc0)+perc0;

			lowDown=false;
			lowUp=false;
			for(m=0;m<percentageLevels.length;m++){
				minBorder=maxList[c]-abs(peakToPeakDistance);
				maxBorder=maxList[c]+abs(peakToPeakDistance);
				if(minBorder<2) minBorder=2;
				if(maxBorder>yValues.length-3) maxBorder=yValues.length-3;

				for(l=maxList[c];l>minBorder;l--){
					if(yValues[l]<percentageLevels[m] && yValues[l-1]<percentageLevels[m] && yValues[l-2]<percentageLevels[m]){
						percentageDataDown[m]=l;
						if(m==0) lowDown=l;
						l=minBorder;
					}
				}
				for(l=maxList[c];l<maxBorder;l++){
					if(yValues[l]<percentageLevels[m] && yValues[l+1]<percentageLevels[m] && yValues[l+2]<percentageLevels[m]){
						percentageDataUp[m]=l;
						if(m==0) lowUp=l;
						l=maxBorder;
					}
				}
			}

			if(lowDown==false){
				print("lowDown false at peak: "+c);
				contractionTime=false;
				transientDuration=false;
				if(lowUp==false) relaxationTime=false;
				else relaxationTime=abs((maxList[c]-lowUp)*samplingTime);
			} else {
				contractionTime=abs((maxList[c]-lowDown)*samplingTime);
				if(lowUp==false){
					print("lowUp false at peak: "+(c+1));
					relaxationTime=false;
					transientDuration=false;
				} else {
					relaxationTime=abs((maxList[c]-lowUp)*samplingTime);
					transientDuration=abs((lowUp-lowDown)*samplingTime);
				}
			}
			setResult("Contraction duration [10% above baseline] (ms)", c, transientDuration);
			setResult("Time-to-peak (ms)", c, contractionTime);
			setResult("Relaxation Time (ms)", c, relaxationTime);
			for(m=0;m<percentageLevels.length;m++){
				if(transientDuration!=false){
					percentageData[m]=(percentageDataUp[m]-percentageDataDown[m])*samplingTime;
					Plot.drawLine(percentageDataDown[m]*samplingTime, yValues[percentageDataDown[m]], percentageDataUp[m]*samplingTime, yValues[percentageDataUp[m]]);
				} else percentageData[m]=false;
				setResult(100-percentages[m]+"-to-"+100-percentages[m]+" transient (ms)", c, percentageData[m]);
			}
		}

		print("Peaks detected at points (frames):");
		Array.print(maxList);
		if(drawPeaks==true){
			for(k=0;k<maxCount;k++){
				Plot.drawLine(maxList[k]*samplingTime, minValueList[k], maxList[k]*samplingTime, yValues[maxList[k]]);
				if(k>0) setResult("Peak-to-peak time (ms)", k, (maxList[k]-maxList[k-1])*samplingTime);
				setResult("Baseline value (a.u.)", k, minValueList[k]);
				setResult("Peak amplitude (a.u.)", k, yValues[maxList[k]]);
				setResult("Contraction amplitude (a.u.)", k, yValues[maxList[k]]-minValueList[k]);
			}
		}
}

function readSettingValue(name, defval) {
	s = call("ij.Prefs.get", "contractility."+name, "?");
	if (s=="?") return defval;
	else return s;
}

function writeSettingOption(name, option) {
	call("ij.Prefs.set", "contractility."+name, option);
}

function writeSettingValue(name, val, ndecpl) {
	call("ij.Prefs.set", "contractility."+name, d2s(val,ndecpl));
}

function readSettingBoolean(name, defval) {
	s = call("ij.Prefs.get", "contractility."+name, "?");
	if (s=="?") return defval;
	else if (s=="0") return false;
	else return true;
}

function writeSettingBoolean(name, val) {
	s = "contractility."+name;
	if (val==false) call("ij.Prefs.set", s, "0");
	else call("ij.Prefs.set", s, "1");
}
