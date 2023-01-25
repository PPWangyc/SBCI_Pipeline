#!/bin/bash
#SBATCH -t 3-0:00:00 
#SBATCH --mem-per-cpu=256gb
#SBATCH --output /home/ywang330/SBCI_Pipeline/HCP_example/sbatch_message.txt
scripts="/home/ywang330/SBCI_Pipeline/integrated_pipeline"
fsdir=/software/freesurfer/6.0.0/freesurfer/
. ${FSLDIR}/etc/fslconf/fsl.sh
source ${scripts}/preproc_step3_t1_freesurfer.sh
echo "finish step3"