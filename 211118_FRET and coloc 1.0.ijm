// BATCH MACRO FOR FRET AND PEARSON-COEFFICIENT MEASUREMENT

// 1.0 RELEASE VERSION

// Intensity based FRET macro for ImageJ combined with colocalization analysis
// Written by Bernhard Hochreiter and Johannes A. Schmid, Medical University Vienna 
// Version 1.0 , 10. Nov. 2016

// This macro is available under GPLv3 (General Public Licence version 3). It can be used, modified and
// distributed freely under the same license with proper acknowledgement of the original authors.
// For more information visit: https://opensource.org/licenses/GPL-3.0

// For the use of this macro, you should have a stack containing three slices, including a Donor image,
// a rawFRET image and an Acceptor image in this order. Labelling of the slices is irrelevant as it will
// be done by this routine. Other image orders or amounts are possible, but the macro has to be modified for this.


//############################################################################################

//BATCH MODE?

	batchmode=true
						//Determines whether the image runs in batch mode or not
						//(true, false)
						//If batch mode is false, no further adjustments need to
						//be made as any variables will be asked during processing
	
//ENTER STANDARD FACTORS HERE (FOR BATCH MODE ONLY):

	donorbleed=0.173;
	acceptorbleed=0.042;
	cellsize=50;

//ENTER MACRO ADJUSTMENTS HERE (FOR BATCH MODE ONLY):		

	analysis="fret";
						//Which analysis type should be used?	
						//(donbleed, accbleed or fret)

	celldetection="minprojection";	
						//which channel do you want to use for cell detection?			
						//(donor, acceptor, maxprojection or minprojection)
						//donbleed and accbleed will automatically use the according channel

	pearson=true;				
						//do you want to determine the pearson coefficient?
						//(true or false)

	colormix=true;
						//Should the color mix coefficient be calculated?
						//(true or false)
						
	smooth=true;				
						//smooth images?	
						//(true or false)
	
	watershed=true;
						//do you want to separate the cells by watershedding?
						//(true or false)
						//You have to use watershedding if you have oversaturated compartments within your cells.
						//Otherwise, it will include these because ImageJ particle analysis is unable to exclude holes.
	
	oeremove=true;			
						//remove overexposed pixels from analysis?
						//(true or false)

	threshold="Moments";			
						//which thresholding method do you want to use for cell detection?
						//(Manual, Default, Huang, Intermodes,...)

	overlayimage=false;
						//do you want to create a green-red-yellow overlay image?
						//(true or false)
						
									
//DO NOT MAKE ANY ADJUSTMENTS BEYOND THIS LINE
//############################################################################################

//SINGLE MODE DIALOGUE BOX

	if(batchmode == false){
		Dialog.create("Settings");
			Dialog.addMessage(" Intensity based FRET Macro for ImageJ \n by Bernhard Hochreiter and Johannes A. Schmid, Medical University Vienna \n Version 1.0 - 10th November 2016 \n \n Please enter your settings:");			
			Dialog.addChoice(" Type of analysis", newArray("fret", "donbleed", "accbleed"));
			Dialog.addChoice(" Channel for Cell detection", newArray("Donor", "Acceptor", "minprojection", "maxprojection"));	
			Dialog.addCheckbox(" Pearson coefficient evaluation", true);
			Dialog.addCheckbox(" Color mix coefficient evaluation", true);
			Dialog.addCheckbox(" Smoothing of image", false);
			Dialog.addCheckbox(" Cell separation by Watershedding", true);
			Dialog.addCheckbox(" Exclude overexposed pixels", true);
			Dialog.addChoice(" Threshold type for cell detection", newArray("Default", "Manual", "Huang", "Intermodes", "IsoData", "Li", "MaxEntropy", "Mean", "MinError", "Minimum", "Moments", "Otsu", "Percentile", "RenyiEntropy", "Shanbhag", "Triangle", "Yen"));
			Dialog.addCheckbox(" Create an overlay image of Donor and acceptor channel", true);
			Dialog.addNumber(" Lower cell sice threshold (sqpixel)", cellsize);		
			Dialog.addMessage(" If you want to use any or all of this macro for your research, \n it is available to you under 'GNU General Public License, version 3 (GPL-3.0)' \n For more information visit: https://opensource.org/licenses/GPL-3.0");	
			Dialog.show();
				analysis = Dialog.getChoice();		
				celldetection = Dialog.getChoice();		
				pearson1 = Dialog.getCheckbox();
				colormix1 = Dialog.getCheckbox();	
				smooth1 = Dialog.getCheckbox();
				watershed1 = Dialog.getCheckbox();
				oeremove1 = Dialog.getCheckbox();
				threshold = Dialog.getChoice();
				overlayimage1 = Dialog.getCheckbox();
				cellsize = Dialog.getNumber();
				

		if(analysis=="fret"){
			Dialog.create("FRET system specific parameters");
				Dialog.addMessage(" Please enter the system specific parametes for \n Donor- and Acceptor bleed as determined by the \n sonbleed and accbleed functions of this macro");
				Dialog.addNumber(" Donor bleedthrough factor:", donorbleed);
				Dialog.addNumber(" Acceptor bleedthrough factor:", acceptorbleed);
				Dialog.show();
					donorbleed = Dialog.getNumber();
					acceptorbleed = Dialog.getNumber();
		}
							
	}

//RENAME IMAGES	
	
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");		
	setSlice(1);		
	run("Set Label...", "label=Donor");		
	run("Next Slice [>]");		
	run("Set Label...", "label=rawFRET");		
	run("Next Slice [>]");		
	run("Set Label...", "label=Acceptor");		

				
//BASICS	
				
	title=getTitle();			
	run("Set Measurements...", "display redirect=None decimal=3");
	run("Properties...", "channels=3 slices=1 frames=1 unit=pixel pixel_width=1 pixel_height=1 voxel_depth=1.0000000");
	if(smooth==true){
		run("Smooth", "stack");
	}	
	run("Stack to Images");			
				
				
//CLEAR ROI MANAGER		

	run("ROI Manager...");				
	if(roiManager("count")>0){			
		roiManager("Deselect");		
		roiManager("Delete");		
		}		
				
				
//CREATE OVEREXPOSURE MASK		
				
	imageCalculator("Max create 32-bit", "rawFRET","Donor");			
	imageCalculator("Max create 32-bit", "Result of rawFRET","Acceptor");			
	selectWindow("Result of rawFRET");			
	close();			
	selectWindow("Result of Result of rawFRET");			
	rename("Overexposuremask");						
	setThreshold(4000, 4095);			
		run("Make Binary");		
		run("Invert");		
		run("Divide...", "value=255");
	
	
//CREATE BACKGROUND MASK AND SELECTION
	
	selectWindow("Donor");
	run("Duplicate...", "title=BG-Donor");
	setAutoThreshold("Triangle dark");
	run("Make Binary");

	selectWindow("rawFRET");
	run("Duplicate...", "title=BG-rawFRET");
	setAutoThreshold("Triangle dark");
	run("Make Binary");
	
	selectWindow("Acceptor");
	run("Duplicate...", "title=BG-Acceptor");
	setAutoThreshold("Triangle dark");
	run("Make Binary");
	
	imageCalculator("Max create 32-bit", "BG-Donor","BG-rawFRET");
	imageCalculator("Max create 32-bit", "Result of BG-Donor","BG-Acceptor");
	selectWindow("Result of BG-Donor");	
	close();

	selectWindow("Result of Result of BG-Donor");			
	rename("BG-mask");
	setAutoThreshold("Triangle dark");		
	run("Create Selection");				
	run("Select None");	

	selectWindow("BG-Donor");
	close();

	selectWindow("BG-rawFRET");
	close();	

	selectWindow("BG-Acceptor");
	close();
	
//REMOVE BACKGROUND			
				
	selectWindow("Donor");			
		run("Restore Selection");		
		getStatistics(area, mean);		
		dbg=mean;
//		print(title+" Donor background: ",dbg);		
		run("Select None");		
		run("Subtract...", "value="+dbg);		
				
	selectWindow("rawFRET");			
		run("Restore Selection");		
		getStatistics(area, mean);		
		fbg=mean;		
//		print(title+" rawFRET background: ",fbg);		
		run("Select None");		
		run("Subtract...", "value="+fbg);		
				
	selectWindow("Acceptor");			
		run("Restore Selection");		
		getStatistics(area, mean);		
		abg=mean;		
//		print(title+" Acceptor background: ",abg);		
		run("Select None");		
		run("Subtract...", "value="+abg);		
		
	selectWindow("BG-mask");
	close();
	
//START ANALYSIS
			
	if(analysis=="donbleed"){
		donbleed();
	}

	if(analysis=="accbleed"){
		accbleed();
	}

	if(analysis=="FRET"){
		fret();
	}	

//REMOVE FALSE ROWS FROM PARTICLE ANALYSIS			
				
	p = nResults;
		for(i=1; i<p; i++) {
		k=p-i-1;
		l = getResultLabel(k);
		if (l == "celldetection") {
			IJ.deleteRows(k, k);
			}
		}
			
//############################################################################################			

function donbleed() { 
	
//DETECTION OF CELLS
	selectWindow("Donor");		
	run("Duplicate...", "title=celldetection");
	
	if(oeremove==true){			
	imageCalculator("Multiply create 32-bit", "celldetection","Overexposuremask");			
	selectWindow("celldetection");			
	close();			
	selectWindow("Result of celldetection");
	rename("celldetection");
	}

	selectWindow("celldetection");
	
	if(threshold=="Manual"){
		run("Threshold...");
		setAutoThreshold("Default dark");
		waitForUser("Adjust Threshold","Please select an appropriate threshold and then click 'OK'");
	}
	else{
	setAutoThreshold(threshold+" dark");
	}
			
	run("Make Binary");	
	if(watershed==true){
		run("Watershed");
	}
	
	run("Erode");
	run("Analyze Particles...", "size=cellsize-infinity add");

//CREATE CALCULATION IMAGES
	imageCalculator("Divide create 32-bit", "rawFRET","Donor");		
	selectWindow("Result of rawFRET");		
	rename("Donorbleed");


//CLOSE UNNEEDED WINDOWS
	selectWindow("celldetection");			
	close();			
	selectWindow("Overexposuremask");
	close();


	run("Images to Stack", "name=Stack title=[] use");	

//MEASURE INTENSITY

	for (c=0; c<=roiManager("count")-1 ;c++){			
		roiManager("Select", c);			
				
		row = nResults; 		
		setSlice(1);		
			getStatistics(area, mean); 	
			setResult("Label", row, title);	
			setResult("ROI", row, c+1); 	
			setResult("Area", row, area); 	
			setResult("Donor-Mean", row, mean);	
			d=mean;	
				
		setSlice(2);		
			getStatistics(area, mean); 	
			setResult("rawFRET-Mean", row, mean);	
			f=mean;	
				
		setSlice(3);		
			getStatistics(area, mean); 	
			setResult("Acceptor-Mean", row, mean);	
			a=mean;

		setSlice(4);	
			getStatistics(area, mean); 	
			setResult("Donor-bleed(df)", row, mean); 	
	}	
	
	setSlice(4);
	run("Delete Slice");
	
roiManager("Show All with labels");
}
//############################################################################################	

function accbleed() {

//DETECTION OF CELLS
	selectWindow("Acceptor");		
	run("Duplicate...", "title=celldetection");

	if(oeremove == true){			
	imageCalculator("Multiply create 32-bit", "celldetection","Overexposuremask");			
	selectWindow("celldetection");			
	close();			
	selectWindow("Result of celldetection");
	rename("celldetection");
	}

	selectWindow("celldetection");
	if(threshold=="Manual"){
		run("Threshold...");
		setAutoThreshold("Default dark");
		waitForUser("Adjust Threshold","Please select an appropriate threshold and then click 'OK'");
	}
	else{
	setAutoThreshold(threshold+" dark");
	}
	run("Make Binary");	
	if(watershed == true){
		run("Watershed");
	}	
	
	run("Erode");	
	run("Analyze Particles...", "size=cellsize-infinity add");

//CREATE CALCULATION IMAGES
	imageCalculator("Divide create 32-bit", "rawFRET","Acceptor");		
	selectWindow("Result of rawFRET");		
	rename("Acceptor bleed");

//CLOSE UNNEEDED WINDOWS
	selectWindow("celldetection");			
	close();			
	selectWindow("Overexposuremask");			
	close();			

	run("Images to Stack", "name=Stack title=[] use");	

//MEASURE INTENSITY

	for (c=0; c<=roiManager("count")-1 ;c++){			
		roiManager("Select", c);			
				
		row = nResults; 		
		setSlice(1);		
			getStatistics(area, mean); 	
			setResult("Label", row, title);	
			setResult("ROI", row, c+1); 	
			setResult("Area", row, area); 	
			setResult("Donor-Mean", row, mean);	
			d=mean;	
				
		setSlice(2);		
			getStatistics(area, mean); 	
			setResult("rawFRET-Mean", row, mean);	
			f=mean;	
				
		setSlice(3);		
			getStatistics(area, mean); 	
			setResult("Acceptor-Mean", row, mean);	
			a=mean;	

		setSlice(4);	
			getStatistics(area, mean); 	
			setResult("Acceptor-bleed(af)", row, mean); 	
	}

	setSlice(4);
	run("Delete Slice");
	roiManager("Show All with labels");
}
//############################################################################################	

function fret() {

//CREATE MIN AND MAX PROJECTION MASKS

	roiManager("Deselect");
	run("Select None");

selectWindow("Donor");
	run("Duplicate...", "title=Donorcells");
	if(threshold=="Manual"){
		run("Threshold...");
		setAutoThreshold("Default dark");
		waitForUser("Adjust Threshold","Please select an appropriate threshold and then click 'OK'");
	}
	else{
	setAutoThreshold(threshold+" dark");
	}
	run("Make Binary");

selectWindow("Acceptor");
	run("Duplicate...", "title=Acceptorcells");
	if(threshold=="Manual"){
		run("Threshold...");
		setAutoThreshold("Default dark");
		waitForUser("Adjust Threshold","Please select an appropriate threshold and then click 'OK'");
	}
	else{
	setAutoThreshold(threshold+" dark");
	}
	run("Make Binary");

	imageCalculator("Max create", "Donorcells","Acceptorcells");
	selectWindow("Result of Donorcells");
	rename("maxprojectionmask");

	imageCalculator("Min create", "Donorcells","Acceptorcells");
	selectWindow("Result of Donorcells");
	rename("minprojectionmask");
	

	selectWindow("Donorcells");
	close();
	selectWindow("Acceptorcells");
	close();

	
//DETECTION OF CELLS

	if(celldetection=="Donor"){			
		selectWindow("Donor");		
		run("Duplicate...", "title=celldetection");
		if(threshold=="Manual"){
			run("Threshold...");
			setAutoThreshold("Default dark");
			waitForUser("Adjust Threshold","Please select an appropriate threshold and then click 'OK'");
		}
		else{
			setAutoThreshold(threshold+" dark");
		}		
		run("Make Binary");	
	}
	
	if(celldetection=="Acceptor"){			
		selectWindow("Acceptor");		
		run("Duplicate...", "title=celldetection");	
		if(threshold=="Manual"){
			run("Threshold...");
			setAutoThreshold("Default dark");
			waitForUser("Adjust Threshold","Please select an appropriate threshold and then click 'OK'");
		}
		else{
			setAutoThreshold(threshold+" dark");
		}		
		run("Make Binary");	
	}		
				
	if(celldetection=="minprojection"){			
		selectWindow("minprojectionmask");		
		run("Duplicate...", "title=celldetection");	
	}		
				
	if(celldetection=="maxprojection"){			
		selectWindow("maxprojectionmask");		
		run("Duplicate...", "title=celldetection");		
	}


//REMOVAL OF OVEREXPOSED AREA		
	
	if(oeremove == true ){			
	imageCalculator("Multiply create 32-bit", "celldetection","Overexposuremask");			
	selectWindow("celldetection");			
	close();			
	selectWindow("Result of celldetection");
	rename("celldetection");
	}
	
	selectWindow("celldetection");
	run("Make Binary");
		
//WATERSHEDDING

	if(watershed== true ){
		run("Watershed");		
	}

	selectWindow("celldetection");
	run("Select All");
	getStatistics(area, mean);
	celldetmean=mean;
	imgarea=area;

	setAutoThreshold("Default");	
	run("Analyze Particles...", "size=cellsize-infinity add");	
	
	if(roiManager("count")>0){
		if(celldetmean==0){
			roiManager("Deselect");		
			roiManager("Delete");	
		}
		if(celldetmean==255){
			roiManager("Deselect");		
			roiManager("Delete");	
		}
	}
	
//CREATE CALCULATION IMAGES FOR FRET
	if(analysis=="FRET"){
		selectWindow("Donor");		
		run("Duplicate...", "title=Donor-bleedthrough");		
		run("Multiply...", "value=donorbleed");		
				
		selectWindow("Acceptor");		
		run("Duplicate...", "title=Acceptor-bleedthrough");		
		run("Multiply...", "value=acceptorbleed");		
				
		imageCalculator("Subtract create 32-bit", "rawFRET","Donor-bleedthrough");		
		rename("rawFRET-DonorBT");		
		imageCalculator("Subtract create 32-bit", "rawFRET-DonorBT","Acceptor-bleedthrough");		
		rename("FRET-Youvan");		
				
		selectWindow("Donor-bleedthrough");		
		close();		
		selectWindow("Acceptor-bleedthrough");		
		close();		
		selectWindow("rawFRET-DonorBT");		
		close();		
				
		imageCalculator("Add create 32-bit", "Donor","FRET-Youvan");		
		selectWindow("Result of Donor");		
		rename("DonorwithoutAcceptor");		
		imageCalculator("Divide create 32-bit", "FRET-Youvan","DonorwithoutAcceptor");		
		rename("FRET-Eff");		
		run("Multiply...", "value=100");		
				
		selectWindow("DonorwithoutAcceptor");		
		close();
	}		

	
//DETERMINE TOTAL AND OVERLAP AREA
	
	selectWindow("maxprojectionmask");
	setAutoThreshold("Default");
	run("Create Selection");
	getStatistics(area, mean);
	totalarea=area;
	run("Select None");	

	selectWindow("minprojectionmask");
	setAutoThreshold("Default");
	run("Create Selection");
	getStatistics(area, mean);
	overlaparea=area;
	run("Select None");

	if(imgarea==overlaparea){
		overlaparea=0;
	}
	
//CLOSE UNNEEDED WINDOWS		
	selectWindow("celldetection");			
	close();			
	selectWindow("Overexposuremask");			
	close();			
	selectWindow("maxprojectionmask");			
	close();
	selectWindow("minprojectionmask");			
	close();	
				
	run("Images to Stack", "name=Stack title=[] use");			
	
			
//MEASURE INTENSITY
	selectWindow("Stack");			
	rename(title);			

	if(roiManager("count")>0){			
		for (c=0; c<=roiManager("count")-1;c++){
			selectWindow(title);
			roiManager("Select", c);				
			row = nResults; 		
			setSlice(1);		
				getStatistics(area, mean); 	
				setResult("Label", row, title);	
				setResult("ROI", row, c+1); 	
				setResult("Area", row, area); 	
				setResult("Donor", row, mean);	
				d=mean;	
				
			setSlice(2);		
				getStatistics(area, mean); 	
				setResult("rawFRET", row, mean);	
				f=mean;	
				
			setSlice(3);		
				getStatistics(area, mean); 	
				setResult("Acceptor", row, mean);	
				a=mean;	
	
			setSlice(4);
					getStatistics(area, mean); 
					setResult("Youvan-FRET", row, mean);
					y=mean;
	
					setResult("Acc:Donor ratio", row, a/d);	

			setSlice(5);
					getStatistics(area, mean); 
					setResult("FRET-Eff.(%) (pixel)", row, mean);
					setResult("FRET-Eff.(%) (area)", row, y/d*100);

			setResult("Total cell area", row, totalarea);
			setResult("colocalisation area", row, overlaparea);

					
//COLOCALISATION ANALYSIS

			setSlice(1);
			getStatistics(area, mean);
			amean=mean;
				
			setSlice(3);
			getStatistics(area, mean);
			bmean=mean;
		
			setSlice(1);
			
			if(pearson== true ){
				sumu=0;
				sumd1=0;
				sumd2=0;
		
			getSelectionBounds(x0, y0, width, height); 
		
			for (y=y0; y<y0+height; y++) {
				for (x=x0; x<x0+width; x++) { 
					if (selectionContains(x, y)) { 
					
						setSlice(1);
						a = getPixel(x,y); 
					
						setSlice(3);
						b = getPixel(x,y);

							sumub=sumu;
							sumu=((a-amean)*(b-bmean))+sumub;

							sumd1b=sumd1;
							sumd1=((a-amean)*(a-amean))+sumd1b;

							sumd2b=sumd2;
							sumd2=((b-bmean)*(b-bmean))+sumd2b;
						}
					}
				}

				rp=sumu/(sqrt(sumd1)*sqrt(sumd2));
				setResult("Pearson-coeff", row, rp);
				selectWindow(title);
			}

//DETERMINE COLOR-MIX COEFFICIENT
			if(colormix== true ){
				if(amean<=bmean){
					m=amean/bmean;
				}
				else{
					m=bmean/amean;
				}
			setResult("Color-mix coeff.", row, m);
			}
			
		}
		
	}

	print(title+" 	"+roiManager("count")+"	ROIs analysed	totalarea:	"+totalarea+"	overlap area:	"+overlaparea+"	detection channel:	"+celldetection+"	thresholding method:	"+threshold+"	minimal cellsize:	"+cellsize+"	overexp.removed:	"+oeremove+"	watershed:	"+watershed+"	smooth:	"+smooth);

	roiManager("Deselect");
	run("Select None");

//CREATE IMAGE OVERLAY

	if(overlayimage==true){
		selectWindow(title);
		setSlice(1);
		run("Duplicate...", "use");
		run("Green");
		run("Enhance Contrast", "saturated=0.35");
	
		selectWindow(title);
		setSlice(3);
		run("Duplicate...", "use");
		run("Red");
		run("Enhance Contrast", "saturated=0.35");

		run("Merge Channels...", "c1=Acceptor c2=Donor");
		selectWindow("RGB");
		rename(title+"_coloc");

		roiManager("Show All");
		roiManager("Draw");

	}
}


//#####################################################################################
