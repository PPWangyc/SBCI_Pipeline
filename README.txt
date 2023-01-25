run preproc in HCP_example
    sbatch HCP_sbci_preproc.slurm 103818 /scratch/ywang330/output/subjects_dir /scratch/ywang330/raw_data /home/ywang330/SBCI_Pipeline/integrated_pipeline
    squeue -u ywang330