import os
import pandas as pd

# read ACT.txt
subject_list = []
with open('ACT.txt', 'r') as f:
    for line in f:
        subject_list.append(line.strip())

BIDS_PATH = '/scratch/tbaran2_lab/ACT_BIDS_UR'
OUTPUT_PATH = '/scratch/tbaran2_lab/ACT/derivatives/sbci/qc'

# check if recon-all without error
def check_recon_all(sub_id):
    recon_all_path = os.path.join(BIDS_PATH, 'SBCI_AVG', sub_id,'dwi_pipeline/structure/t1_freesurfer/scripts/recon-all-status.log')
    if os.path.exists(recon_all_path):
        with open(recon_all_path, 'r') as f:
            for line in f:
                if 'finished without error' in line:
                    return True, recon_all_path
    return False, recon_all_path

# check fodf, return number of files
def check_fodf(sub_id):
    qodf_path = os.path.join(BIDS_PATH, 'SBCI_AVG', sub_id,'dwi_pipeline/diffusion/fodf')
    if os.path.exists(qodf_path):
        return len(os.listdir(qodf_path))
    return 0

# check if sc mats exist, file name: smoothed_sc_avg_*.mat; 
def check_sc(sub_id):
    sc_path = os.path.join(BIDS_PATH, 'SBCI_AVG', sub_id,'dwi_pipeline/sbci_connectome/')
    log_path = os.path.join(BIDS_PATH, 'SBCI_AVG', sub_id,'sbci_step4_process_surfaces.log')
    
    assert os.path.exists(log_path), 'No log file'
    if os.path.exists(sc_path):
        for item in os.listdir(sc_path):
            if item.startswith('smoothed_sc_avg_') and item.endswith('.mat'):
                return True, os.path.join(sc_path, item), log_path
    return False, 'No sc mats', log_path

recon_df = pd.DataFrame(columns=['sub_id', 'status', 'log_path'])
fodf_df = pd.DataFrame(columns=['sub_id', 'num_files'])
sc_df = pd.DataFrame(columns=['sub_id', 'status', 'sc_path', 'log_path'])

for sub_id in subject_list:
    recon_status, recon_log_path = check_recon_all(sub_id)
    if recon_status:
        recon_df = recon_df.append({'sub_id':sub_id, 'status':'No Error', 'log_path':recon_log_path}, ignore_index=True)
    else:
        recon_df = recon_df.append({'sub_id':sub_id, 'status':'Error', 'log_path':recon_log_path}, ignore_index=True)
    
    num_files = check_fodf(sub_id)
    fodf_df = fodf_df.append({'sub_id':sub_id, 'num_files':num_files}, ignore_index=True)

    sc_status, sc_path, sc_log_path = check_sc(sub_id)
    if sc_status:
        sc_df = sc_df.append({'sub_id':sub_id, 'status':'Success', 'sc_path':sc_path, 'log_path':sc_log_path}, ignore_index=True)
    else:
        sc_df = sc_df.append({'sub_id':sub_id, 'status':'Fail', 'sc_path':sc_path, 'log_path':sc_log_path}, ignore_index=True)

if not os.path.exists(OUTPUT_PATH):
    print('Creating output directory: {}'.format(OUTPUT_PATH))
    os.makedirs(OUTPUT_PATH)

recon_df.to_csv(os.path.join(OUTPUT_PATH, 'recon_all.csv'), index=False)
fodf_df.to_csv(os.path.join(OUTPUT_PATH, 'fodf.csv'), index=False)
sc_df.to_csv(os.path.join(OUTPUT_PATH, 'sc.csv'), index=False)

