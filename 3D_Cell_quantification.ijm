///Quanfication for Andre
//Use this script to count the number of different cell types in the gut
//Mate Naszai, 04/12/2018

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//SETUP

format=".czi";
tile=0;
//minimum_threshold= ???
//If there is three channels
// Channel 0 = green
// Channel 1 = blue
// Channel 2 = red
//If there are 4 channels, ie you have far red, it's
// Channel 0 = green
// Channel 1 = far red
// Channel 2 = blue
// Channel 3 = red
//Channel to quantify
t1=1;
mask_threshold_modifier_t1=2.5; //Should work, you may play around in test mode if necessary
//Channel of nuclei
n=2;
mask_threshold_modifier_n=2.5; //5 for tile?
//Do you want to quantfiy another channel?
o=1;
//What other channel would you like to quantify?
t2=3;
mask_threshold_modifier_t2=2.5;
//TEST MODE
test=1;
//END OF SETUP
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

//SCRIPT
//getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
//print("Start:",year, month,dayOfMonth, hour, minute, second);
run("Close All");
run("Clear Results");

setBatchMode(true);
//Test mode switch
if (test){
setBatchMode(false);
}


//Get directory
dir=getDirectory("Choose Source");
list=getFileList(dir);

for (i=0; i<list.length; i++){
if (endsWith(list[i],format)){
	//Open file
	if (tile){
	run("Bio-Formats Importer", "open=" + dir + list[i] + " color_mode=Default rois_import=[ROI manager] specify_range split_channels view=Hyperstack stack_order=XYCZT stitch_tiles c_begin=" + n+1 + " c_end=" + n+1 + " c_step=1");
	} else {
	run("Bio-Formats Importer", "open=" + dir + list[i] + " color_mode=Default rois_import=[ROI manager] split_channels view=Hyperstack stack_order=XYCZT stitch_tiles");
	}

	//Process the nuclei
	if (!tile){
	selectWindow(list[i] + " - C=" + n);
	run("Duplicate...", "duplicate");
	}
	//Get threshold and number of slices
	setAutoThreshold("Triangle dark stack");
	getThreshold(lower,upper);
	threshold=round(mask_threshold_modifier_n*lower);
	print("Threshold n:",list[i], threshold);
	//Pre-process nuclei
	run("Despeckle", "stack");
	run("Subtract Background...", "rolling=50");
	run("Despeckle", "stack");
	run("Despeckle", "stack");
	//Threshold nuclei
	setThreshold(threshold, 65535);
	setOption("BlackBackground", true);
	run("Convert to Mask", "method=Triangle background=Dark black");
	rename("Nuclei_Mask");
	if (!tile){
	run("Fill Holes", "stack");
	}
	//3D quanfity nuclei
	run("3D OC Options", "  dots_size=5 font_size=10 redirect_to=none");
	run("3D Objects Counter", "threshold=1 slice=1 min.=100 max.=10485760 objects");
	rename("Nuclei Objects");
	run("Duplicate...", "duplicate");
	Stack.getStatistics(nPixels, mean, min, max);
	print("Number of nuclei:",list[i], max);
	setThreshold(1, 65535);
	run("Convert to Mask", "method=Triangle background=Dark");
	rename("Object_Mask");
	if (tile){
		string=replace(list[i],"\\.tif",""); //have a look here
		newfolder=dir + string;
		File.makeDirectory(newfolder);
		selectWindow("Object_Mask");
		saveAs("Tiff", newfolder + File.separator + "Object_Mask.tif");
		rename("Object_Mask");
		close("Nuclei_Mask");
	}
	
	//Quantify t1 staining
	if (tile){
		run("Bio-Formats Importer", "open=" + dir + list[i] + " color_mode=Default rois_import=[ROI manager] specify_range split_channels view=Hyperstack stack_order=XYCZT stitch_tiles c_begin=" + t1+1 + " c_end=" + t1+1 + " c_step=1");
	} else {
		selectWindow(list[i] + " - C=" + t1);
		run("Duplicate...", "duplicate");
	}
	rename("Channel t1");
	//Pre-process t1
	run("Despeckle", "stack");
	run("Subtract Background...", "rolling=50");
	run("Despeckle", "stack");
	run("Despeckle", "stack");
	//Get threshold
	setAutoThreshold("Triangle dark stack");
	getThreshold(lower,upper);
	threshold=round(mask_threshold_modifier_t1*lower);
	print("Threshold t1:",list[i], threshold);
	run("Options...", "iterations=15 count=1 black pad do=Nothing");
	selectWindow("Object_Mask");
	run("Erode", "stack");
	run("Invert", "stack");
	imageCalculator("Transparent-zero create stack", "Channel t1","Object_Mask");
	rename("temp");
	imageCalculator("Subtract create stack", "temp","Object_Mask");
	rename("Masked_t1");
	close("temp");
	//Threshold t1
	selectWindow("Masked_t1");
	setThreshold(threshold, 65535);
	setOption("BlackBackground", true);
	run("Convert to Mask", "method=Triangle background=Dark black");
	rename("T1_Mask");
	run("Fill Holes", "stack");
	
	//3D quanfity t1
	run("3D OC Options", "  dots_size=5 font_size=10 redirect_to=none");
	run("3D Objects Counter", "threshold=1 slice=1 min.=100 max.=10485760 objects");
	rename("t1");
	Stack.getStatistics(nPixels, mean, min, max);
	print("Number of t1 cells:",list[i], max);
	if (tile){
		saveAs("Tiff", newfolder + File.separator + "t1.tif");
		close("T1_Mask");
		close("t1.tif");
	}
	
	//Quantify t2
	if (o){
		if (tile){
		run("Bio-Formats Importer", "open=" + dir + list[i] + " color_mode=Default rois_import=[ROI manager] specify_range split_channels view=Hyperstack stack_order=XYCZT stitch_tiles c_begin=" + t2+1 + " c_end=" + t2+1 + " c_step=1");
	} else {
		selectWindow(list[i] + " - C=" + t2);
		run("Duplicate...", "duplicate");
	}
	rename("Channel t2");
	
	//Pre-process t2
	run("Despeckle", "stack");
	run("Subtract Background...", "rolling=50");
	run("Despeckle", "stack");
	run("Despeckle", "stack");
	//Get threshold
	setAutoThreshold("Triangle dark stack");
	getThreshold(lower,upper);
	threshold=round(mask_threshold_modifier_t2*lower);
	print("Threshold t2:",list[i], threshold);
	imageCalculator("Transparent-zero create stack", "Channel t2","Object_Mask");
	rename("temp");
	imageCalculator("Subtract create stack", "temp","Object_Mask");
	rename("Masked_t2");
	selectWindow("Object_Mask");
	run("Invert", "stack");
	close("temp");
	//Threshold t1
	selectWindow("Masked_t2");
	setThreshold(threshold, 65535);
	setOption("BlackBackground", true);
	run("Convert to Mask", "method=Triangle background=Dark black");
	rename("T2_Mask");
	run("Fill Holes", "stack");
	//3D quanfity t2
	run("3D OC Options", "  dots_size=5 font_size=10 redirect_to=none");
	run("3D Objects Counter", "threshold=1 slice=1 min.=100 max.=10485760 objects");
	rename("t2");
	Stack.getStatistics(nPixels, mean, min, max);
	print("Number of t2 cells:",list[i], max);
	if (tile){
		saveAs("Tiff", newfolder + File.separator + "t2.tif");
		close("T2_Mask");
		close("t2");
	}
	}
}
}

//Test mode switch
if (!test){
run("Close All");
run("Clear Results");
}
setBatchMode(false);
//getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
//print("Finish:",year, month,dayOfMonth, hour, minute, second);