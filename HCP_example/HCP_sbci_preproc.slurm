#!/bin/bash
#SBATCH -t 3-0:00:00 
#SBATCH -o preproc_scilpy_%j.log
#SBATCH --mem-per-cpu=256gb
#SBATCH --output /home/ywang330/SBCI_Pipeline/HCP_example/sbatch_message.txt

subj=${1}
out=${2}
data=${3}
scripts=${4}

subdir=${out}/${subj}

# CHANGE LOCATION TO YOUR SOURCE FILE
# echo "Sourcing .bashrc"
# source /home/ywang330/SBCI_Pipeline/install.sh

# CHANGE LOCATION TO THE CONFIGURATION FILE FOR SBCI
export SBCI_CONFIG=/home/ywang330/SBCI_Pipeline/HCP_example/sbci_config

# CHANGE LOCATION TO FREESURFER WITH PERSONAL LICENSE
fsdir=/software/freesurfer/6.0.0/freesurfer/
. ${FSLDIR}/etc/fslconf/fsl.sh

# CHANGE SBATCH OPTIONS FOR SET AND FSFAST
options='-t 5-00:00:00 --mem-per-cpu=20gb'

# link the log file into the output folder (bash variables don't work in #SBATCH -o)
# important to keep "#SBATCH -o preproc_scilpy_%j.log" in the options of this file
ln -f preproc_scilpy_${SLURM_JOB_ID}.log ${subdir}/preproc_scilpy_${1}.log

########################################

# setup directory structure for raw data
diffdata=${data}/Diffusion
funcdata=${data}/Functional

mkdir -p ${out}/${subj}/anat
mkdir -p ${out}/${subj}/dwi
mkdir -p ${out}/${subj}/fsfast/t1_freesurfer/bold/001
mkdir -p ${out}/${subj}/fsfast/t1_freesurfer/bold/002
mkdir -p ${out}/${subj}/fsfast/t1_freesurfer/bold/003
mkdir -p ${out}/${subj}/fsfast/t1_freesurfer/bold/004

# copy T1w data to output folder
cp ${diffdata}/${subj}/T1w/T1w_acpc_dc_restore_1.25.nii.gz ${subdir}/anat/${subj}_T1w.nii.gz

# copy eddy-corrected DWI data to output folder
cp ${diffdata}/${subj}/T1w/Diffusion/bvals ${subdir}/dwi/${subj}_dwi.bval
cp ${diffdata}/${subj}/T1w/Diffusion/bvecs ${subdir}/dwi/${subj}_dwi.bvec
cp ${diffdata}/${subj}/T1w/Diffusion/data.nii.gz ${subdir}/dwi/${subj}_dwi.nii.gz

# copy RAW fMRI data to output folder
cp ${funcdata}/${subj}/unprocessed/3T/rfMRI_REST1_LR/${subj}_3T_rfMRI_REST1_LR.nii.gz ${subdir}/fsfast/t1_freesurfer/bold/001/f.nii.gz
cp ${funcdata}/${subj}/unprocessed/3T/rfMRI_REST1_RL/${subj}_3T_rfMRI_REST1_RL.nii.gz ${subdir}/fsfast/t1_freesurfer/bold/002/f.nii.gz
cp ${funcdata}/${subj}/unprocessed/3T/rfMRI_REST2_LR/${subj}_3T_rfMRI_REST2_LR.nii.gz ${subdir}/fsfast/t1_freesurfer/bold/003/f.nii.gz
cp ${funcdata}/${subj}/unprocessed/3T/rfMRI_REST2_RL/${subj}_3T_rfMRI_REST2_RL.nii.gz ${subdir}/fsfast/t1_freesurfer/bold/004/f.nii.gz

echo "t1_freesurfer" > ${subdir}/fsfast/t1_freesurfer/subjectname

########################################

cd ${subdir}

echo "Beginning diffusion processing of HCP subject ${subj}."
date

source $SBCI_CONFIG
pwd
source ${scripts}/preproc_step1_preparedata.sh
echo "finish step1"
source ${scripts}/preproc_step2_t1_dwi_registration.sh
echo "finish step2"
source ${scripts}/preproc_step3_t1_freesurfer.sh
echo "finish step3"

# once Step3 is complete, the functional preprocessing can begin in parallel with diffusion
sbatch -o ${subdir}/preproc_fsfast_${subj}.log ${options} \
	${scripts}/preproc_step4_fmri.sh ${subdir} ${fsdir} ${scripts}/config_files

source ${scripts}/preproc_step5_fodf_estimation.sh
source ${scripts}/set_step1_preparedata.sh

echo "Starting parallel tracking jobs for SET."

# run SET tracking in parallel N_RUN times (sourced from SBCI_CONFIG)
for ((RUN = 1; RUN <= N_RUNS; RUN++)); do
  sbatch -o ${subdir}/preproc_set_${RUN}_${subj}.log ${options} \
  	  ${scripts}/set_step2_tracking_random_seed_n.sh $RUN &
done

echo "Done processing diffusion data."
date

# remove the temporary log file
rm preproc_scilpy_${SLURM_JOB_ID}.log
