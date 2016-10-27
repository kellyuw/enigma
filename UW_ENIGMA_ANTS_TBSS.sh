#!/bin/bash
## Runs TBSS preprocessing, registration, and postregistration steps to prepare DTI data for ENIGMA ROI analyses

## Original script developed by: neda.jahanshad@ini.usc.edu
## Modified 10/2016 by: kelly89@uw.edu

METRIC=FA
THRESH=0.2
PROJECT_DIR="/mnt/stressdevlab/new_memory_pipeline/DTI"
REG_DIR="${PROJECT_DIR}/NARSADTemplates/Final"
ENIGMA_DIR=/mnt/stressdevlab/scripts/DTI/enigma
TBSS_DIR="${PROJECT_DIR}/ANTS_TBSS_ENIGMA"
#TBSS_DIR=$1

export ANTSPATH=/usr/local/ANTs-2.1.0-rc3/bin/

#Make directories to organize target and skeleton
mkdir -p ${TBSS_DIR}/stats
mkdir -p ${TBSS_DIR}/${METRIC}_to_target
mkdir -p ${TBSS_DIR}/${METRIC}_skels

#Go to TBSS_DIR
cd ${TBSS_DIR}/stats

# create all FA
if [[ ! -e all_${METRIC}.nii.gz ]]; then
	for i in `cat ${PROJECT_DIR}/GoodSubjects.txt`; do
		echo "Registering FA -> template -> FMRIB with WarpImageMultiTransform (subject ${i})"
		WarpImageMultiTransform 3 ${PROJECT_DIR}/${i}/dti/dtifit/dti_FA.nii.gz ${TBSS_DIR}/${METRIC}_to_target/NARSAD${i}_to_FMRIB.nii.gz -R /usr/share/fsl/5.0/data/standard/FMRIB58_${METRIC}_1mm.nii.gz ${REG_DIR}/NARSADtemplateToFMRIB1Warp.nii.gz ${REG_DIR}/NARSADtemplateToFMRIB0GenericAffine.mat ${REG_DIR}/NARSAD${i}_${METRIC}Warp.nii.gz ${REG_DIR}/NARSAD${i}_${METRIC}Affine.txt ${PROJECT_DIR}/${i}/xfm_dir/dti_FA_to_MNI_1mm_r_0GenericAffine.mat
	done

	ls ${TBSS_DIR}/${METRIC}_to_target/NARSAD*_to_FMRIB.nii.gz > ${TBSS_DIR}/Dirs.txt
	rm ${TBSS_DIR}/Subjects.txt; while read line ; do s=`echo ${line} | tr -d -c 0-9`; echo $s >> ${TBSS_DIR}/Subjects.txt ; done < ${TBSS_DIR}/Dirs.txt

	echo "Merging all images together to create all_${METRIC}.nii.gz"
	fslmerge -a all_${METRIC}.nii.gz `ls ${TBSS_DIR}/${METRIC}_to_target/NARSAD*_to_FMRIB.nii.gz`
fi

# create mean FA
if [[ ! -e mean_${METRIC}.nii.gz ]]; then
	echo "Creating valid mask and mean ${METRIC}"
	${FSLDIR}/bin/fslmaths all_${METRIC}.nii.gz -max 0 -Tmin -bin mean_${METRIC}_mask.nii.gz -odt char
	${FSLDIR}/bin/fslmaths all_${METRIC}.nii.gz -Tmean mean_${METRIC}.nii.gz
fi

# create skeleton
if [[ ! -e mean_${METRIC}_skeleton.nii.gz ]]; then
	echo "Skeletonising mean ${METRIC}"
	${FSLDIR}/bin/tbss_skeleton -i mean_${METRIC}.nii.gz -o mean_${METRIC}_skeleton.nii.gz

	echo "Creating skeleton mask using threshold $thresh"
	echo $THRESH > ${TBSS_DIR}/thresh.txt
	${FSLDIR}/bin/fslmaths mean_${METRIC}_skeleton.nii.gz -thr $THRESH -bin mean_${METRIC}_skeleton_mask.nii.gz
fi

#create skeleton distance map
if [[ ! -e mean_${METRIC}_skeleton_mask_dst.nii.gz ]]; then
	echo "Creating skeleton distancemap (for use in projection search)"
	${FSLDIR}/bin/fslmaths mean_${METRIC}_mask.nii.gz -mul -1 -add 1 -add mean_${METRIC}_skeleton_mask.nii.gz mean_${METRIC}_skeleton_mask_dst.nii.gz
	${FSLDIR}/bin/distancemap -i mean_${METRIC}_skeleton_mask_dst.nii.gz -o mean_${METRIC}_skeleton_mask_dst.nii.gz
fi

#project data onto skeleton
if [[ ! -e all_${METRIC}_skeletonised.nii.gz ]]; then
	echo "Projecting all ${METRIC} data onto skeleton"
	${FSLDIR}/bin/tbss_skeleton -i mean_${METRIC}.nii.gz -p ${THRESH} mean_${METRIC}_skeleton_mask_dst.nii.gz ${FSLDIR}/data/standard/LowerCingulum_1mm all_${METRIC}.nii.gz all_${METRIC}_skeletonised.nii.gz
fi

#make edited enigma templates
if [[ ! -e ${TBSS_DIR}/ENIGMA_targets_edited/mean_FA_skeleton_mask_dst.nii.gz ]]; then
	echo "Making study-specific ENIGMA templates"
	mkdir -p ${TBSS_DIR}/ENIGMA_targets_edited

	${FSLDIR}/bin/fslmaths all_${METRIC}.nii.gz -bin -Tmean -thr 0.9 ${TBSS_DIR}/ENIGMA_targets_edited/mean_${METRIC}_mask.nii.gz
	${FSLDIR}/bin/fslmaths ${ENIGMA_DIR}/ENIGMA_DTI_${METRIC}.nii.gz -mas ${TBSS_DIR}/ENIGMA_targets_edited/mean_${METRIC}_mask.nii.gz ${TBSS_DIR}/ENIGMA_targets_edited/mean_${METRIC}.nii.gz 
	${FSLDIR}/bin/fslmaths ${ENIGMA_DIR}/ENIGMA_DTI_${METRIC}_skeleton.nii.gz -mas ${TBSS_DIR}/ENIGMA_targets_edited/mean_${METRIC}_mask.nii.gz ${TBSS_DIR}/ENIGMA_targets_edited/mean_${METRIC}_skeleton.nii.gz 
	
	cd ${TBSS_DIR}/ENIGMA_targets_edited
	tbss_4_prestats -0.049
	cd ${TBSS_DIR}/stats
fi

LastSub=`tail -n 1 ${TBSS_DIR}/Subjects.txt`
if [[ ! -e ${TBSS_DIR}/${METRIC}_skels/${LastSub}_masked_${METRIC}.nii.gz ]]; then
	for i in `cat ${TBSS_DIR}/Subjects.txt`; do
		echo "Masking individual images with mean_${METRIC}_mask (subject ${i})"
		fslmaths ${TBSS_DIR}/${METRIC}_to_target/NARSAD${i}_to_FMRIB.nii.gz -mas mean_${METRIC}_mask.nii.gz ${TBSS_DIR}/${METRIC}_skels/${i}_masked_${METRIC}.nii.gz

		${FSLDIR}/bin/tbss_skeleton -i mean_${METRIC}.nii.gz -p 0.049 mean_${METRIC}_skeleton_mask_dst.nii.gz ${FSLDIR}/data/standard/LowerCingulum_1mm.nii.gz ${TBSS_DIR}/${METRIC}_skels/${i}_masked_${METRIC}.nii.gz ${TBSS_DIR}/${METRIC}_skels/${i}_masked_${METRIC}skel.nii.gz -s mean_${METRIC}_skeleton_mask.nii.gz
	done
fi

if [[ ! -e ${TBSS_DIR}/ENIGMA_${METRIC}_skels/${LastSub}_masked_${METRIC}.nii.gz ]]; then
	mkdir -p ${TBSS_DIR}/ENIGMA_${METRIC}_skels

	for i in `cat ${TBSS_DIR}/Subjects.txt`; do
		echo "Masking individual images with ENIGMA mean_${METRIC}_mask (subject ${i})"
		fslmaths ${TBSS_DIR}/${METRIC}_to_target/NARSAD${i}_to_FMRIB.nii.gz -mas ${TBSS_DIR}/ENIGMA_targets_edited/mean_${METRIC}_mask.nii.gz ${TBSS_DIR}/ENIGMA_${METRIC}_skels/${i}_masked_${METRIC}.nii.gz

		${FSLDIR}/tbss_skeleton -i ${TBSS_DIR}/ENIGMA_targets_edited/mean_${METRIC}.nii.gz -p 0.049 ${TBSS_DIR}/ENIGMA_targets_edited/mean_${METRIC}_skeleton_mask_dst.nii.gz ${FSLDIR}/data/standard/LowerCingulum_1mm.nii.gz ${TBSS_DIR}/ENIGMA${METRIC}_skels/${i}_masked_${METRIC}.nii.gz ${TBSS_DIR}/ENIGMA${METRIC}_skels/${i}_masked_${METRIC}skel.nii.gz -s ${TBSS_DIR}/ENIGMA_targets_edited/mean_FA_skeleton_mask.nii.gz

	done
fi

#for sub in `ls *.nii.gz` ; do 
#	fslmaths $sub -mul 1 $sub -odt float
#done

#Subject file (FASubs.txt)
if [[ ! -f "${TBSS_DIR}/${METRIC}Subs.txt" ]]; then
	ls -1 ${TBSS_DIR}/${METRIC}_skels/* | grep ${METRIC}skel | awk -F "skels/" '{print $2}' | awk -F "_" '{print $1}' | tee ${TBSS_DIR}/FASubs.txt
fi

#Directory list (FADirs.txt)
if [[ ! -f "${TBSS_DIR}/FADirs.txt" ]]; then
	ls -1 ${TBSS_DIR}/${METRIC}_skels/*${METRIC}skel.nii.gz | tee ${TBSS_DIR}/FADirs.txt
fi
