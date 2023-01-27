# command to check submitted jobs
    squeue -u ywang330

cd /home/ywang330/SBCI_Pipeline 
# activate environment and modules
    source install.sh

cd HCP_example

Part 1. Preprocessing
# start running HCP preproc scripts in pipeline_scripts
    sbatch HCP_sbci_preproc.slurm

Part 2. Processing the downsampled grid
    sbatch sbci_process_grid.slurm

Part 3. Processing the subject(s)
    sbatch sbci_process_subject.slurm


