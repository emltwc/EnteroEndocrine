//Quanfication for Andre
//Use this script to count the number of different cell types in the gut
//Mate Naszai, 04/12/2018

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//SETUP
//Select channel t1 to quantify
//If there is three channels, it's
// Channel 0 = green
// Channel 1 = blue
// Channel 2 = red
//If there are 4 channels, ie you have far red, it's
// Channel 0 = green
// Channel 1 = farred
// Channel 2 = blue
// Channel 3 = red
t1=2;
//Mask threshold modifier
mask_threshold_modifier=2.5; //Should work, you may play around in test mode if necessary
//Count nuclei?
n=1; //0=no, 1=yes
//Channel of nuclei
t2=1;
mask_threshold_modifier2=1.5;
//Save thresholded images?
save_files=1;
//TEST MODE
test=0; //Activate test mode? Works with a single example image in a folder.  1=yes, 0=no.
//END OF SETUP
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%





//SCRIPT
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
newfolder=dir + "Results";
File.makeDirectory(newfolder); 

for (i=0; i<list.length; i++){
if (endsWith(list[i],".czi")){
	
//Open file
run("Bio-Formats Importer", "open=" + dir + list[i] + " color_mode=Default rois_import=[ROI manager] split_channels view=Hyperstack stack_order=XYCZT");
selectWindow(list[i] + " - C=" + t1);
run("Duplicate...", "duplicate");

//Get threshold and number of slices
setAutoThreshold("Triangle dark stack");
getThreshold(lower,upper);

threshold=round(mask_threshold_modifier*lower);
//print(list[i] + " Threshold:" + threshold);

//Pre-process the image
run("Despeckle", "stack");
run("Subtract Background...", "rolling=50");
run("Despeckle", "stack");
run("Despeckle", "stack");

//Threshold image
setThreshold(threshold, 65535);
setOption("BlackBackground", true);
run("Convert to Mask", "method=Triangle background=Dark black");
rename("Mask");
run("Fill Holes", "stack");

//Quanfity
run("Analyze Particles...", "size=5-Infinity show=Ellipses display clear");
cell_number=nResults;
print(list[i] + "_Cells: " + cell_number);
rename(list[i] + "_Cells");
run("16-bit");
run("Invert");

//Save images
if (save_files){
	saveAs("Tiff", dir + "Results"+ File.separator + list[i] + "_Cells.tif");
}

if(n){

	selectWindow(list[i] + " - C=" + t2);
	run("Duplicate...", "duplicate");
	
	//Get threshold and number of slices
	setAutoThreshold("Triangle dark stack");
	getThreshold(lower,upper);
	
	threshold=round(mask_threshold_modifier2*lower);
	
	//Pre-process the image
	run("Despeckle", "stack");
	run("Subtract Background...", "rolling=50");
	run("Despeckle", "stack");
	run("Despeckle", "stack");

	//Threshold image
	setThreshold(threshold, 65535);
	setOption("BlackBackground", true);
	run("Convert to Mask", "method=Triangle background=Dark black");
	rename("Nuclei");
	run("Options...", "iterations=1 count=1 black do=Nothing");
	run("Fill Holes", "stack");
	run("Watershed");

	//Quantify
	run("Analyze Particles...", "size=5-Infinity show=Ellipses display clear");
	nucleus_number=nResults;
	print(list[i] + "_Nuclei: " + nucleus_number);	
	rename(list[i] + "_Nucleus");
	run("16-bit");
	run("Invert");
	
	
	//Save images
	if (save_files){
		saveAs("Tiff", dir + "Results" + File.separator + list[i] + "_Nucleus.tif");
		run("Merge Channels...", "c1=[" + list[i] + " - C=" + t1 + "] c2=" + list[i] + "_Nucleus.tif c3=[" + list[i] + " - C=" + t2 + "] c7=" + list[i] + "_Cells.tif create keep ignore");
		run("RGB Color");
		saveAs("Tiff", dir + "Results" + File.separator + list[i] + "_Composite.tif");
	}
	print(list[i] + "_Ratio: " + cell_number/nucleus_number);
}

//Test mode switch
if (!test){
run("Close All");
run("Clear Results");
}
}
}

setBatchMode(false);