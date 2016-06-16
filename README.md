ENIGMA QC Pipeline for DTI Acquisitions
---------------------------------------

See here http://enigma.ini.usc.edu/ongoing/dti-working-group/ for details, and the originators of this project.

This pipeline takes an input FA map from a DTI acquisition and reports (!!!Spooky Various Things!!!) about your DTI data.

This project was mostly produced by David Rotenberg, [the Rotenator](mailto:david.rotenberg@camh.ca).


Instructions
------------

This code will print out the average FA value along a skeleton and ROI values on that skeleton according to an ROI atlas, for example the JHU-ROI atlas (provided with this code).

The look up table for the atlas should be tab-delimited --  the first column should refer to the voxel value within the image and the second column should refer to the desired label of the region.

    ./singleSubjROI_exe look_up_table.txt skeleton.nii.gz JHU-WhiteMatter-labels-1mm.nii.gz OutputfileName Subject_FAskeleton.nii.gz
	
Example:
 
    ./singleSubjROI_exe ENIGMA_look_up_table.txt mean_FA_skeleton.nii.gz JHU-WhiteMatter-labels-1mm.nii.gz Subject*_ROIout Subject*_FA.nii.gz

DTI Quick Start
---------------

This software will extract mean FA values for each subject in a TBSS dataset.


Before using, please ensure that:

1. DTI data for all subjects has been preprocessed (all steps below should be complete):
	a. Converted to NIFTI
	b. Skull-stripped
	c. Corrected for motion and eddy current-induced distortions
	d. Tensor fit to produce FA image
	e. QA checks of SNR and motion to ensure subject meets criteria for inclusion

2. All images that passed QA check have been added to TBSS directory (preferably with [SubjectID]_FA.nii.gz name)

3. The run_ENIGMA_ROI_ALL_script.sh script has been edited and saved (as indicated below):
	a. PROJECT_DIR and DTI_DIR likely will need to be changed
	b. The pattern for subject files may need to be edited also


Finally, to run the ROI analyses:
1. bash /mnt/stressdevlab/scripts/ROI/enigma/run_ENIGMA_ROI_ALL_script.sh