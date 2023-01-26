#!/bin/bash
#SBATCH -t 3-0:00:00 
#SBATCH --mem-per-cpu=20gb
#SBATCH --output /home/ywang330/SBCI_Pipeline/HCP_example/sbatch_message.txt

# CHANGE SBATCH OPTIONS FOR SET AND FSFAST
options='-t 2-00:00:00 --mem-per-cpu=20gb'

scripts="/home/ywang330/SBCI_Pipeline/integrated_pipeline"
fsdir=/software/freesurfer/6.0.0/freesurfer/
. ${FSLDIR}/etc/fslconf/fsl.sh
cd /scratch/ywang330/output/subjects_dir/103818
subj="103818"
out="/scratch/ywang330/output/subjects_dir"
# export SBCI_CONFIG
export SBCI_CONFIG=/home/ywang330/SBCI_Pipeline/HCP_example/sbci_config
subdir=${out}/${subj}
# once Step3 is complete, the functional preprocessing can begin in parallel with diffusion

sbatch -o ${options} ${scripts}/preproc_step5_fmri.sh

source ${scripts}/preproc_step5_fmri.sh
echo "finish step5"