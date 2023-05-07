# ACT Data Processing(Bluehive)

## ENV Setup(Anaconda)
        install mrtrix3 in conda
        conda install -c anaconda qt
        pip install dcm2niix
        pip install dcm2bids


## Process ACT Step by Step
   1. Activate Environment
        ```
        cd ACT_example
        source install.sh 
        ```
    2. Convert to BIDS and DTI minimal process
        ```
        python convert.py
        ```
    3. Run SBCI Pipeline
        ```
        python output_subj.py
        sbatch preprocess.sh
        sbatch process_psc.sh
        sbatch process_sbci.sh
        ```