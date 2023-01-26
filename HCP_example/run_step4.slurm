#!/bin/bash
#SBATCH -t 3-0:00:00 
#SBATCH --mem-per-cpu=20gb
#SBATCH --output /home/ywang330/SBCI_Pipeline/HCP_example/sbatch_message.txt

# CHANGE SBATCH OPTIONS FOR SET AND FSFAST
options='-t 2-00:00:00 --mem-per-cpu=20gb'

scripts="/home/ywang330/SBCI_Pipeline/integrated_pipeline"
fsdir=/software/freesurfer/6.0.0/freesurfer/
. ${FSLDIR}/etc/fslconf/fsl.sh
cd /scratch/ywang330/output/subjects_dir/103818/dwi_pipeline
source ${scripts}/preproc_step4_fodf_estimation.sh