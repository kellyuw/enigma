#!/bin/bash -l
#$ -S /bin/bash

# Generalized October 2nd David Rotenberg.
#######
## part 1 - loop through all subjects to create a subject ROI file 
#######
#make an output directory for all files


function usage() {
  echo
  echo "###############################################################"
  echo " Usage: $0 [OPTIONS]"
  echo "  -h    print help."
  echo "  -t    Define Metric Name (FA, FA_CORR, FW, MD)."
  echo "  -d    Directory where FA/...to_target...nii.gz are located." 
  echo "###############################################################"
  exit
}

function help() {
  echo
  echo "Apply Distortion Correction: Snippet"
  echo "This script requires two inputs:"
  echo " " 
  echo " 1. Type of Data."
  echo " FA, FA_CORR, FW, MD (...)"
  echo " "
  echo " 2. Dataset Name."
  echo " "
  echo " /////////////////////////////" 
  exit
}

while getopts ":h" opt; do
  case $opt in
    h)
      help
      exit 1
      ;;
    *)
      echo "Unknown option: $opt"
      usage
      exit 1
    ;;
  esac
done

if [ $OPTIND -eq 0 ]; then
   echo "No options were passed"
   shift $OPTIND
   echo "$# non-option arguments"
   usage
   exit 1
else
   echo "$# option arguments"
fi

echo  "Default Type = FA"
typed=FA
dataset=NARSAD
PROJECT_DIR="/mnt/stressdevlab/new_memory_pipeline/DTI"
ENIGMA_DIR="/mnt/stressdevlab/scripts/ROI/enigma"
DTI_DIR="${PROJECT_DIR}/TBSS"

#Go to main DTI directory
cd ${DTI_DIR}

#Make directories to organize target and skeleton
mkdir -p ${DTI_DIR}/${typed}_to_target
mkdir -p ${DTI_DIR}/${typed}_skels

#echo "TBSS STEP 1"
#tbss_1_preproc *.nii.gz

#echo "TBSS_STEP 2"
#tbss_2_reg -t ${ENIGMA_DIR}/ENIGMA_DTI_FA.nii.gz

#pause_crit=$( qstat | grep tbss_2_reg);

#while [ -n "$pause_crit" ];
#do
#    pause_crit=$( qstat | grep tbss_2_reg)
#    sleep 20
#done
#echo "Registration Complete"

#echo "TBSS STEP 3"
#tbss_3_postreg -S

#Copy FA_to_target images to separate directory
for i in `ls FA/*FA_to_target.nii.gz`; do
	cp $i ${DTI_DIR}/FA_to_target/`basename $i`
done

cd ${DTI_DIR}/${typed}_to_target

for a in `ls *.nii.gz`; do 
	tbss_skeleton -i ${ENIGMA_DIR}/ENIGMA_DTI_FA.nii.gz -p 0.049 ${ENIGMA_DIR}/ENIGMA_DTI_FA_skeleton_mask_dst.nii.gz /usr/share/data/fsl-mni152-templates/LowerCingulum_1mm.nii.gz ${a} ${DTI_DIR}/${typed}_skels/`basename ${a} .nii.gz`_FAskel -s ${ENIGMA_DIR}/ENIGMA_DTI_FA_skeleton_mask.nii.gz
done

cd ${DTI_DIR}

for j in `ls ${typed}_skels/*skel*.nii.gz`; do
	cp $i FA_to_target/`basename $i`
done

cp *skel* ../FA_skels/ && cd ../FA_skels

cd ${DTI_DIR}/FA_skels

for sub in `ls *.nii.gz` ; do 
	fslmaths $sub -mul 1 $sub -odt float
done

cd ${DTI_DIR}

dirO1="${DTI_DIR}/${dataset}_${typed}"
mkdir -p ${dir01}


for subject in $( ls FA_skels | grep .nii.gz); do
	base=$(basename $subject .nii.gz);
	echo "Basename $base"
	${ENIGMA_DIR}/singleSubjROI_exe ${ENIGMA_DIR}/ENIGMA_look_up_table.txt ${ENIGMA_DIR}/ENIGMA_DTI_FA_skeleton_mask.nii.gz ${ENIGMA_DIR}/JHU-WhiteMatter-labels-1mm.nii.gz ${dirO1}/${base}_ROIout ${DTI_DIR}/FA_skels/${subject}

done
