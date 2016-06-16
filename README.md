ENIGMA QC Pipeline for DTI Acquisitions
---------------------------------------

See here http://enigma.ini.usc.edu/ongoing/dti-working-group/ for details, and the originators of this project.

This pipeline takes an input FA map from a DTI acquisition and reports (!!!Spooky Various Things!!!) about your DTI data.

This project was mostly produced by David Rotenberg, [the Rotenator](mailto:david.rotenberg@camh.ca).


Preparation of FA images
---------------

This software will extract mean FA values for each subject in a TBSS dataset.


Before using, please ensure that:

1. DTI data for all subjects has been preprocessed (all steps below should be complete):
	* Converted to NIFTI
	* Skull-stripped
	* Corrected for motion and eddy current-induced distortions
	* Tensor fit to produce FA image
	* QA checks of SNR and motion to ensure subject meets criteria for inclusion

2. All images that passed QA check have been added to TBSS directory (preferably with [SubjectID]_FA.nii.gz name)

3. The UW_ENIGMA_TBSS.sh and UW_ENIGMA_ROI.sh scripts have been edited and saved:
	* PROJECT_DIR and DTI_DIR likely will need to be changed
	* The pattern for subject FA files (in UW_ENIGMA_TBSS.sh) may need to be edited also



Running the ROI Analyses
---------------

1. Run the UW_ENIGMA_TBSS.sh script to execute first three steps of TBSS (preprocessing, registration, and post-registration):

    `bash /mnt/stressdevlab/scripts/ROI/enigma/UW_ENIGMA_TBSS.sh`

2. Double-check the FASubs.txt and FADirs.txt files to confirm that they match TBSS directory structure

3. Run the UW_ENIGMA_ROI.sh script to run ENIGMA C++ scripts that will create table of values for all subjects (63 ROIs each):

    `bash /mnt/stressdevlab/scripts/ROI/enigma/UW_ENIGMA_ROI.sh`

