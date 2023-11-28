#!/bin/bash
#SBATCH -t 0-1:00:00 
#SBATCH --mem-per-cpu=10gb

IN=ACT.txt
OUT=/scratch/tbaran2_lab/ACT_BIDS_UR/SBCI_AVG
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

echo "Processing ${#subjects[@]} subject(s)"

echo "Beginning processing of SBCI grid: $(date)"
STEP1=$(sb ${OPTIONS} --time=4:00:00 --mem=4g -c 8 --job-name=$JID.step1 \
    --export=ALL,SBCI_CONFIG \
    --error=sbci_step1_process_grid.err \
    --output=sbci_step1_process_grid.log ${SCRIPTS}/sbci_step1_process_grid.sh)

sleep 0.01

ROOT=$(pwd)

for i in $(seq 1 ${#subjects[@]}); do
    idx=$((i - 1))

    cd ${OUT}/${subjects[$idx]}

    echo "Placing subject ${subjects[$idx]} in queue"
    STEP2=$(sb ${OPTIONS} --time=20:00:00 --mem=20g -c 8 --job-name=$JID.step2.${subjects[$idx]} \
        --export=ALL,SBCI_CONFIG \
        --output=sbci_step2_prepare_set.log \
        --error=sbci_step2_prepare_set.err \
        --dependency=afterok:${STEP1} ${SCRIPTS}/sbci_step2_prepare_set.sh)

    STEP3=()
    for ((RUN = 1; RUN <= N_RUNS; RUN++)); do
        STEP3+=($(sb ${OPTIONS} --time=40:00:00 --mem=20g -c 8 --job-name=$JID.step3-4.${subjects[$idx]} \
            --export=ALL,SBCI_CONFIG \
            --output=sbci_step3_set_${RUN}.log \
            --error=sbci_step3_set_${RUN}.err \
            --dependency=afterok:${STEP2} ${SCRIPTS}/sbci_step3_run_set.sh $RUN))

    done

    STEP4=$(sb ${OPTIONS} --time=4:00:00 --mem=4g -c 8 --job-name=$JID.step3-4.${subjects[$idx]} \
        --export=ALL,SBCI_CONFIG \
        --output=sbci_step4_process_surfaces.log \
        --error=sbci_step4_process_surfaces.err \
        --dependency=singleton ${SCRIPTS}/sbci_step4_process_surfaces.sh)

    STEP5=$(sb ${OPTIONS} --time=20:00:00 --mem=20g -c 8 --job-name=$JID.step5.${subjects[$idx]} \
        --export=ALL,SBCI_CONFIG \
        --output=sbci_step5_structural.log \
        --error=sbci_step5_structural.err \
        --dependency=afterok:${STEP4} ${SCRIPTS}/sbci_step5_structural.sh)

    STEP6=$(sb ${OPTIONS} --time=10:00:00 --mem=20g -c 8 --job-name=$JID.step6.${subjects[$idx]} \
        --export=ALL,SBCI_CONFIG \
        --output=sbci_step6_functional.log \
        --error=sbci_step6_functional.err \
        --dependency=afterok:${STEP5} ${SCRIPTS}/sbci_step6_functional.sh)

    cd ${ROOT}
done

