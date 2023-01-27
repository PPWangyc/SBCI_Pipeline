#!/bin/bash
#SBATCH -t 5-0:00:00 
#SBATCH -o sbci_%j.log
#SBATCH --mem-per-cpu=256gb
#SBATCH --output /home/ywang330/SBCI_Pipeline/HCP_example/sbatch_message.txt

subj=103818
out=/scratch/ywang330/sbci/subjects_dir
scripts=/home/ywang330/SBCI_Pipeline/pipeline_scripts

subdir=${out}/${subj}

# CHANGE LOCATION TO YOUR SOURCE FILE
# echo "Sourcing .bashrc"
# source /home/user/bashrc

# CHANGE LOCATION TO THE CONFIGURATION FILE FOR SBCI
export SBCI_CONFIG=/home/ywang330/SBCI_Pipeline/HCP_example/sbci_config

. ${FSLDIR}/etc/fslconf/fsl.sh

# link the log file into the output folder (bash variables don't work in #SBATCH -o)
# important to keep "#SBATCH -o sbci_%j.log" in the options of this file
ln -f sbci_${SLURM_JOB_ID}.log ${subdir}/sbci_${subj}.log

echo "Beginning preprocessing of subject $subj"

date

cd ${subdir}
echo "start sbci_step2_process_surfaces"
source ${scripts}/sbci_step2_process_surfaces.sh
echo "done sbci_step2_process_surfaces"

echo "start sbci_step3_structural"
source ${scripts}/sbci_step3_structural.sh
echo "done sbci_step3_structural"

echo "start sbci_step4_functional"
source ${scripts}/sbci_step4_functional.sh
echo "done sbci_step4_functional"

echo "start sbci_step5_atlas_connectivity"
source ${scripts}/sbci_step5_atlas_connectivity.sh
cd -

date

echo "Done processing of subject $subj"

# remove the temporary log file
rm sbci_${SLURM_JOB_ID}.log
