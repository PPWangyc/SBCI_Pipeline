#!/bin/bash

IN=${1}
OUT=${2}
SCRIPTS=${3}

ROOTDIR=$(pwd)

# CHANGE LOCATION TO YOUR SOURCE FILE
echo "Sourcing .bashrc"
source /home/mcole22/.bashrc-set

# CHANGE LOCATION TO THE CONFIGURATION FILE FOR SBCI
export SBCI_CONFIG=/scratch/dmi/zzhang87_lab/mcole22/SBCI/CogTE/integrated_pipeline/sbci_config

# CHANGE FOR SPECIFIC SBATCH OPTIONS
# OPTIONS="-p dmi --qos abcd"

echo "Sourcing SBCI config file"
source $SBCI_CONFIG

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
    mapfile -t subjects < $1
    
    # make sure there are subjects
    if [[ ${#subjects[@]} -eq 0 ]]; then
        echo "no subjects found in ${1}"
        exit 1
    fi
    
    echo "Processing ${#subjects[@]} subject(s): ${JID}"
    
    
    # example slurm parameters
    # #SBATCH -J job_name                # job name
    # #SBATCH -a 0-39                    # job array size, starting at 0
    # #SBATCH -c 8                       # cpus per task (slurm "cores")
    # #SBATCH -N 1                       # number of nodes (usually 1)
    # #SBATCH --ntasks=1                 # parallel ntasks per node
    # #SBATCH --mem-per-cpu=24G          # memory per core (GB)
    # #SBATCH -t 06:00:00                # job time ([d-]:hh:mm:ss)
    
    for i in $(seq 1 ${#subjects[@]}); do
        idx=$((i - 1))
        cd ${OUT}/${subjects[$idx]}
        
        echo "Placing subject ${subjects[$idx]} in queue"
        echo "Beginning processing of SBCI grid: $(date)"
        
        STEP1=$(sb ${OPTIONS} \
            --time=4:00:00 \
            --mem=4g \
            --job-name=$JID.step1 \
            --export=ALL,SBCI_CONFIG \
        --output=sbci_step1_process_grid.log ${SCRIPTS}/sbci_step1_process_grid.sh)
        
        sleep 0.01
        
        STEP2=$(sb ${OPTIONS} \
            --time=20:00:00 \
            --mem=20g \
            --job-name=$JID.step2.${subjects[$idx]} \
            --export=ALL,SBCI_CONFIG \
            --output=sbci_step2_prepare_set.log \
        --dependency=afterok:${STEP1} ${SCRIPTS}/sbci_step2_prepare_set.sh)
        
        sleep 0.01
        
        STEP3+=$(sb ${OPTIONS} \
            --time=40:00:00 \
            --mem=20g \
            --job-name=$JID.step3-4.${subjects[$idx]} \
            --export=ALL,SBCI_CONFIG \
            --output=sbci_step3_set_${RUN}.log \
        --dependency=afterok:${STEP2} ${SCRIPTS}/sbci_step3_run_set.sh $RUN)
        
        sleep 0.01
        
    done
    
    STEP4=$(sb ${OPTIONS} \
        --time=4:00:00 \
        --mem=4g \
        --job-name=$JID.step3-4.${subjects[$idx]} \
        --export=ALL,SBCI_CONFIG \
        --output=sbci_step4_process_surfaces.log \
    --dependency=singleton ${SCRIPTS}/sbci_step4_process_surfaces.sh)
    
    sleep 0.01
    
    STEP5=$(sb ${OPTIONS} \
        --time=20:00:00 \
        --mem=20g \
        --job-name=$JID.step5.${subjects[$idx]} \
        --export=ALL,SBCI_CONFIG \
        --output=sbci_step5_structural.log \
    --dependency=afterok:${STEP4} ${SCRIPTS}/sbci_step5_structural.sh)
    
    sleep 0.01
    
    STEP6=$(sb ${OPTIONS} \
        --time=10:00:00 \
        --mem=20g \
        --job-name=$JID.step6.${subjects[$idx]} \
        --export=ALL,SBCI_CONFIG \
        --output=sbci_step6_functional.log \
    --dependency=afterok:${STEP1} ${SCRIPTS}/sbci_step6_functional.sh)
    
    sleep 0.01
    
    cd ${ROOTDIR}
done