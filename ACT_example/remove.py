import os
import sys

# read ACT.txt
subject_list = []
with open('ACT.txt', 'r') as f:
    for line in f:
        subject_list.append(line.strip())

print('Total number of subjects: {}'.format(len(subject_list)))

SUBJ_PATH = '/scratch/tbaran2_lab/ACT_BIDS_UR/SBCI_AVG/'

for sub_id in subject_list:
    sub_path = os.path.join(SUBJ_PATH, sub_id)
    if os.path.exists(sub_path):
        print('Removing {}'.format(sub_path))
        os.system('rm -rf {}'.format(sub_path))
    else:
        print('No such directory: {}'.format(sub_path))