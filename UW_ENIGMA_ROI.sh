#!/bin/bash
## Runs ENIGMA singleSubjROI_exe and averageSubjectTracts_exe to generate table of average FA values from 63 ROIs
## Original script developed by: neda.jahanshad@ini.usc.edu
## Modified 03/2016 by: kelly89@uw.edu


ENIGMA_DIR=/mnt/stressdevlab/scripts/ROI/enigma
TBSS_DIR=$1

METRIC=FA
PROJECT_DIR="/mnt/stressdevlab/new_memory_pipeline"
DTI_DIR="${PROJECT_DIR}/DTI/${TBSS_DIR}"

SubjectList="${DTI_DIR}/FASubs.txt"
InDirList="${DTI_DIR}/FADirs.txt"
OutDir="${DTI_DIR}/EXTRAROI"


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
