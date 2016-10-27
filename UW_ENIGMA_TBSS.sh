#!/bin/bash
## Runs TBSS preprocessing, registration, and postregistration steps to prepare DTI data for ENIGMA ROI analyses

## Original script developed by: neda.jahanshad@ini.usc.edu
## Modified 10/2016 by: kelly89@uw.edu


ENIGMA_DIR=/mnt/stressdevlab/scripts/DTI/enigma
TBSS_DIR=$1

METRIC=FA
PROJECT_DIR="/mnt/stressdevlab/new_memory_pipeline/DTI"
DTI_DIR="${PROJECT_DIR}/${TBSS_DIR}"

SubjectList="${DTI_DIR}/ENIGMA/${METRIC}Subs.txt"
InDirList="${DTI_DIR}/ENIGMA/${METRIC}Dirs.txt"
OutDir="${DTI_DIR}/ENIGMA/ENIGMA_ROI"


#######
## part 0 - Run TBSS analyses
######

#Go to main DTI directory
cd ${DTI_DIR}

# Set parameters for parallelization
export FSLPARALLEL=True
export FSLCLUSTER_DEFAULT_QUEUE=global.q

#Make directories to organize target and skeleton
mkdir -p ${DTI_DIR}/ENIGMA/${METRIC}_to_target
mkdir -p ${DTI_DIR}/ENIGMA/${METRIC}_skels

echo "TBSS STEP 1"
tbss_1_preproc *.nii.gz

echo "TBSS_STEP 2"
tbss_2_reg -t ${ENIGMA_DIR}/ENIGMA_DTI_${METRIC}.nii.gz
pause_crit=$( qstat | grep tbss_2_reg);

while [ -n "$pause_crit" ];
do
    pause_crit=$( qstat | grep tbss_2_reg)
    sleep 20
done
echo "Registration Complete"

echo "TBSS STEP 3"
tbss_3_postreg -S


#Copy ${METRIC}_to_target images to separate directory
for i in `ls ${METRIC}/*${METRIC}_to_target.nii.gz`; do
	echo "Copying ${i} to ${DTI_DIR}/ENIGMA/${METRIC}_to_target/`basename $i` ..."
	cp $i ${DTI_DIR}/ENIGMA/${METRIC}_to_target/`basename $i`
done

cd ${DTI_DIR}/ENIGMA/${METRIC}_to_target

for a in `ls *.nii.gz`; do
	echo "Skeletonizing ${METRIC}_to_target/${a} ..."
	tbss_skeleton -i ${ENIGMA_DIR}/ENIGMA_DTI_${METRIC}.nii.gz -p 0.049 ${ENIGMA_DIR}/ENIGMA_DTI_${METRIC}_skeleton_mask_dst.nii.gz ${FSLDIR}/data/standard/LowerCingulum_1mm.nii.gz ${a} ${DTI_DIR}/ENIGMA/${METRIC}_skels/`basename ${a} .nii.gz`_${METRIC}skel -s ${ENIGMA_DIR}/ENIGMA_DTI_${METRIC}_skeleton_mask.nii.gz
done

cd ${DTI_DIR}/ENIGMA

for j in `ls ${METRIC}_skels/*skel*.nii.gz`; do
	echo "Copying ${j} to ${METRIC}_to_target/`basename $j`"
	cp $j ${METRIC}_to_target/`basename $j`
done

cp *skel* ../${METRIC}_skels/ && cd ../${METRIC}_skels

cd ${DTI_DIR}/ENIGMA/${METRIC}_skels

for sub in `ls *.nii.gz` ; do 
	fslmaths $sub -mul 1 $sub -odt float
done

cd ${DTI_DIR}/ENIGMA

#Subject file (FASubs.txt)
if [[ ! -f "${METRIC}Subs.txt" ]]; then
	ls -1 ${DTI_DIR}/ENIGMA/${METRIC}_skels/* | grep ${METRIC}skel | awk -F "skels/" '{print $2}' | awk -F "_" '{print $1}' | tee ${METRIC}Subs.txt
fi

#Directory list (FADirs.txt)
if [[ ! -f "${METRIC}Dirs.txt" ]]; then
	ls -1 ${DTI_DIR}/ENIGMA/${METRIC}_skels/*${METRIC}skel.nii.gz | tee ${METRIC}Dirs.txt
fi