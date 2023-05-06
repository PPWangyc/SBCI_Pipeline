#!/bin/bash
#SBATCH -t 0-1:00:00 
#SBATCH --mem-per-cpu=10gb

# IN=CogTE1001
# OUT=/scratch/tbaran2_lab/CogTE
IN=ACT.txt
DATA=/scratch/ywang330/ACT
SCRIPTS=/home/ywang330/SBCI_Pipeline/ACT_example

# CHANGE LOCATION TO THE CONFIGURATION FILE FOR SBCI
export SBCI_CONFIG=/home/ywang330/SBCI_Pipeline/ACT_example/sbci_config

# CHANGE FOR SPECIFIC SBATCH OPTIONS
OPTIONS=""

echo "Sourcing SBCI config file"
source $SBCI_CONFIG
. ${FSLDIR}/etc/fslconf/fsl.sh

# helper function to return job id
function sb() {
   result="$(sbatch "$@")"
   
   if [[ "$result" =~ Submitted\ batch\ job\ ([0-9]+) ]]; then
     echo "${BASH_REMATCH[1]}"
   fi 
}

# create a unique job name prefix
JID=$(uuidgen | tr '-' ' ' | awk {'print $1}')

# get all subject names
mapfile -t subjects < ${IN}

# make sure there are subjects
if [[ ${#subjects[@]} -eq 0 ]]; then
    echo "no subjects found in ${IN}"
    exit 1
fi

echo "Processing ${#subjects[@]} subject(s): ${JID}"

rootdir=$(pwd)

for i in $(seq 1 ${#subjects[@]}); do
    idx=$((i - 1))
    subj=${subjects[$idx]}
    echo "Placing subject ${subjects[$idx]} in queue"
    anatdata=${DATA}/${subj}/anat
    dwidata=${DATA}/${subj}/dwi
    funcdata=${DATA}/${subj}/func

    subdir=${OUTPUT_PATH}/${subj}
    echo "subdir:" ${subdir} 
    mkdir -p ${subdir}/anat
    mkdir -p ${subdir}/dwi

    mkdir -p ${subdir}/fsfast/bold/001

    # copy T1w data to output folder
    cp ${anatdata}/T1w.nii.gz ${subdir}/anat/${subj}_T1w.nii.gz

    # copy eddy-corrected DWI data to output folder
    cp ${dwidata}/dwi.bval ${subdir}/dwi/${subj}_dwi.bval
    cp ${dwidata}/dwi.bvec ${subdir}/dwi/${subj}_dwi.bvec
    cp ${dwidata}/dwi.nii.gz ${subdir}/dwi/${subj}_dwi.nii.gz

    # copy RAW fMRI data to output folder
    cp ${funcdata}/task-rest.nii.gz ${subdir}/fsfast/bold/001/f.nii.gz
    
    cd ${subdir}
    mkdir -p dwi_pipeline

    STEP1=$(sb $OPTIONS --time=1:00:00 --mem=10g --job-name=$JID.${subjects[$idx]}.${j}.preproc.step1 \
        --export=ALL,SBCI_CONFIG \
        --output=preproc_step1_preparedata.log \
        ${SCRIPTS}/preproc_step1_preparedata.sh)

    cd dwi_pipeline

    STEP2=$(sb $OPTIONS --time=4-0:00:00 --mem=20g --job-name=$JID.${subjects[$idx]}.${j}.preproc.step2 \
        --export=ALL,SBCI_CONFIG \
        --output=preproc_step2_t1_dwi_registration.log \
        --dependency=afterok:${STEP1} ${SCRIPTS}/preproc_step2_t1_dwi_registration.sh)

    STEP3=$(sb $OPTIONS --time=4-0:00:00 --mem=20g --job-name=$JID.${subjects[$idx]}.${j}.preproc.step3 \
        --export=ALL,SBCI_CONFIG \
        --output=preproc_step3_t1_freesurfer.log \
        --dependency=afterok:${STEP2} ${SCRIPTS}/preproc_step3_t1_freesurfer.sh)

    STEP4=$(sb $OPTIONS --time=4-0:00:00 --mem=20g --job-name=$JID.${subjects[$idx]}.${j}.preproc.step4 \
        --export=ALL,SBCI_CONFIG \
        --output=preproc_step4_fodf_estimation.log \
        --dependency=afterok:${STEP3} ${SCRIPTS}/preproc_step4_fodf_estimation.sh)

    cd ..

    STEP5=$(sb $OPTIONS --time=4-0:00:00 --mem=10g --job-name=$JID.${subjects[$idx]}.preproc.step5 \
        --export=ALL,SBCI_CONFIG \
        --output=preproc_step5_fmri.log \
        --dependency=afterok:${STEP4} ${SCRIPTS}/preproc_step5_fmri.sh)

    cd ${rootdir}
done
