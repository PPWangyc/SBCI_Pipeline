#!/bin/bash
# .bashrc

module load gcc/9.1.0
module load biology ants/2.3.1
module load fsl/5.0.10
module load system qt git
module load java/11.0.11
module load freesurfer/6.0.1 mrtrix/3.0.3 dcm2niix/1.0.20211006 
module load math matlab/R2017b
module poldrack pigz/2.4

conda activate sbci

# create env variable for SBCI
export PATH="/home/users/ppwang/SBCI_Pipeline/scripts:$PATH"
export PYTHONPATH="/home/users/ppwang/SBCI_Pipeline:$PYTHONPATH"

# create env variable for PSC
export PATH="/home/users/ppwang/PSC_Pipeline/scripts:$PATH"
export PYTHONPATH="/home/users/ppwang/PSC_Pipeline:$PYTHONPATH"

scil_surface.py

extraction_sccm_withfeatures_cortical.py

echo done!