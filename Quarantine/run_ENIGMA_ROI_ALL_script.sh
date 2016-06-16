#!/bin/bash
## Original script developed by: neda.jahanshad@ini.usc.edu
## Modified 03/2016 by: kelly89@uw.edu

## ENIGMA-DTI ##


ENIGMA_DIR=/mnt/stressdevlab/scripts/ROI/enigma
TBSS_DIR=$1

METRIC=FA
PROJECT_DIR="/mnt/stressdevlab/new_memory_pipeline"
#DTI_DIR="${PROJECT_DIR}/DTI/TBSS_RESTORE"
DTI_DIR="${PROJECT_DIR}/DTI/${TBSS_DIR}"

SubjectList="${DTI_DIR}/FASubs.txt"
InDirList="${DTI_DIR}/FADirs.txt"
OutDir="${DTI_DIR}/EXTRAROI"

#######
## part 0 - Run TBSS analyses
######

#Go to main DTI directory
cd ${DTI_DIR}

#Make directories to organize target and skeleton
mkdir -p ${DTI_DIR}/${METRIC}_to_target
mkdir -p ${DTI_DIR}/${METRIC}_skels

echo "TBSS STEP 1"
tbss_1_preproc *.nii.gz

echo "TBSS_STEP 2"
tbss_2_reg -t ${ENIGMA_DIR}/ENIGMA_DTI_FA.nii.gz
pause_crit=$( qstat | grep tbss_2_reg);

while [ -n "$pause_crit" ];
do
    pause_crit=$( qstat | grep tbss_2_reg)
    sleep 20
done
echo "Registration Complete"

echo "TBSS STEP 3"
tbss_3_postreg -S

#Copy FA_to_target images to separate directory
for i in `ls FA/*FA_to_target.nii.gz`; do
	echo "Copying ${i} to ${DTI_DIR}/FA_to_target/`basename $i` ..."
	cp $i ${DTI_DIR}/FA_to_target/`basename $i`
done

cd ${DTI_DIR}/${METRIC}_to_target

for a in `ls *.nii.gz`; do
	echo "Skeletonizing ${METRIC}_to_target/${a} ..."
	tbss_skeleton -i ${ENIGMA_DIR}/ENIGMA_DTI_FA.nii.gz -p 0.049 ${ENIGMA_DIR}/ENIGMA_DTI_FA_skeleton_mask_dst.nii.gz /usr/share/data/fsl-mni152-templates/LowerCingulum_1mm.nii.gz ${a} ${DTI_DIR}/${METRIC}_skels/`basename ${a} .nii.gz`_FAskel -s ${ENIGMA_DIR}/ENIGMA_DTI_FA_skeleton_mask.nii.gz
done

cd ${DTI_DIR}

for j in `ls ${METRIC}_skels/*skel*.nii.gz`; do
	echo "Copying ${j} to FA_to_target/`basename $i`"
	cp $i FA_to_target/`basename $i`
done

cp *skel* ../FA_skels/ && cd ../FA_skels

cd ${DTI_DIR}/FA_skels

for sub in `ls *.nii.gz` ; do 
	fslmaths $sub -mul 1 $sub -odt float
done

cd ${DTI_DIR}

#Subject file (FASubs.txt)
if [[ ! -f "${DTI_DIR}/FASubs.txt" ]]; then
	ls -1 ${DTI_DIR}/FA_skels/* | awk -F "skels/" '{print $2}' | awk -F "_" '{print $1"_"$2}' | tee ${DTI_DIR}/FASubs.txt
fi

#Directory list (FADirs.txt)
if [[ ! -f "${DTI_DIR}/FADirs.txt" ]]; then
	ls -1 ${DTI_DIR}/FA_skels/* | tee ${DTI_DIR}/FADirs.txt
fi

#######
## part 1 - loop through all subjects to create a subject ROI file 
#######

mkdir -p ${OutDir}

for Subject in `cat ${SubjectList}` ; do

	infile=`grep -E "${Subject}" ${InDirList}`
	echo ${infile}

	${ENIGMA_DIR}/singleSubjROI_exe ${ENIGMA_DIR}/ENIGMA_look_up_table.txt ${ENIGMA_DIR}/mean_FA_skeleton.nii.gz ${ENIGMA_DIR}/JHU-WhiteMatter-labels-1mm.nii.gz ${OutDir}/${Subject}_ROI ${infile}

done

#######
## part 2 - loop through all subjects to create ROI file 
##			removing ROIs not of interest and averaging others
#######

for Subject in `cat ${SubjectList}` ; do
	${ENIGMA_DIR}/averageSubjectTracts_exe ${OutDir}/${Subject}_ROI.csv ${OutDir}/${Subject}_ROI_avg.csv

	# Add to subject list for part 3
	echo "${Subject},${OutDir}/${Subject}_ROI_avg.csv" >> ${OutDir}/AvgList.csv
done

#######
## part 3 - combine all 
#######

mkdir -p ${OutDir}/Final
for Subject in `cat ${SubjectList}`; do
	cat ${OutDir}/${Subject}_ROI_avg.csv | awk -F "," '{print $1","$2}' > ${OutDir}/${Subject}_ROI_AverageFA.csv
	cat ${OutDir}/${Subject}_ROI_avg.csv | awk -F "," '{print $1","$3}' > ${OutDir}/${Subject}_ROI_NumVoxels.csv

	echo ${Subject} > ${OutDir}/Final/Final_AverageFA_${Subject}.csv
	tail -n 63 ${OutDir}/${Subject}_ROI_AverageFA.csv | awk -F "," '{print $2}' >> ${OutDir}/Final/Final_AverageFA_${Subject}.csv
done

paste ${ENIGMA_DIR}/Rows.csv `ls -1 ${OutDir}/Final/Final_AverageFA_*.csv` | tee ${OutDir}/Final/Final_AverageFA_AllSubjects.csv
#Table="`dirname ${OutDir}`/SubCov.txt"
#subjectIDcol=SubjectID
##subjectList=./subjectList.csv
#subjectlist=${OutDir}/AvgList.csv
#outTable=${OutDir}/CombinedROITable.csv
#Ncov=0
#covariates=""
#covariates="Age;ChildAbuse"
#Nroi="all" #2
#rois="IC;EC"

#location of R binary 
#Rbin=/usr/bin/R

#Run the R code
#${Rbin} --no-save --slave --args ${Table} ${subjectIDcol} ${subjectList} ${outTable} ${Ncov} ${covariates} ${Nroi} ${rois} <  ${ENIGMA_DIR}/combine_subject_tables.R  
