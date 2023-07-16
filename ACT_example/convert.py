import os

# list folders in a directory
def get_folder_list(path):
    return [f for f in os.listdir(path) if os.path.isdir(os.path.join(path, f))]
ACT_PATH = '/scratch/tbaran2_lab/ACT'
CONFIG_PATH = os.path.join(ACT_PATH,'bids', 'config_asu.json')
OUTPUT_BIDS_PATH = os.path.join('/scratch/tbaran2_lab/ACT_BIDS_3')
session='01'
dicom_dirs = get_folder_list(os.path.join(ACT_PATH, 'ASU'))

def count_folders(path):
    count = 0
    with os.scandir(path) as entries:
        for entry in entries:
            if entry.is_dir():
                count += 1
    return count

def check_folders(path):
    folder_15_exists = False
    folder_16_exists = False
    
    for item in os.listdir(path):
        item_path = os.path.join(path, item)
        if os.path.isdir(item_path):
            if item == '15':
                folder_15_exists = True
            elif item == '16':
                folder_16_exists = True
    
    if folder_15_exists and folder_16_exists:
        return '15'
    elif folder_15_exists:
        return '15'
    elif folder_16_exists:
        return '16'
    else:
        return None

def count_files(path):
    return len(os.listdir(path))

# make output directory
if not os.path.exists(OUTPUT_BIDS_PATH):
    os.makedirs(OUTPUT_BIDS_PATH)
# dicom_dirs = ['/scratch/tbaran2_lab/ACT/dicom/001_S_0105']
print(len(dicom_dirs))
for dicom_dir in dicom_dirs:
    screen_id = dicom_dir.split('_')[2][:4]
    dicom_dir_path = os.path.join(ACT_PATH, 'ASU', dicom_dir)

    command = 'sbatch convert_step1.sh {} {} {} {} {}'.format(dicom_dir_path, screen_id, session,CONFIG_PATH, OUTPUT_BIDS_PATH)
    print(command)
    os.system(command)
    