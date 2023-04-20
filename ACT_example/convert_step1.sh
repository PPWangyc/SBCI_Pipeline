#!/bin/bash
#SBATCH -t 0-1:00:00 
#SBATCH --mem-per-cpu=10gb

dicom_dir_path=${1}
screen_id=${2}
session=${3}
CONFIG_PATH=${4}
OUTPUT_BIDS_PATH=${5}

dcm2bids -d $dicom_dir_path -p ${screen_id} -s $SBJ -c $CONFIG_PATH -o $OUTPUT_BIDS_PATH
# pydeface /bids/subject/session/anat/T1w
${OUTPUT_BIDS_PATH}/sub-${screen_id}/ses-${SBJ}/anat/sub-${screen_id}_ses-${session}_T1w.nii.gz