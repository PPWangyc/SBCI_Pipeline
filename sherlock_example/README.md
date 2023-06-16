# Sherlock Instruction

## ENV Setup
Following the instruction of SBCI env and DTI ENV setup

after installation, you can run:

```
source sbci_install.sh # init sbci env
source dti_install.sh # init dti env
```

### SBCI ENV

```
module load gcc/9.1.0
module load biology ants/2.3.1
module load fsl/5.0.10 module load system git qt
module load java/11.0.11
module load contribs poldrack pigz/2.4
module load freesurfer/6.0.1 mrtrix/3.0.3 dcm2niix/1.0.20211006 
module load math matlab/R2017b
module load anaconda/2009.03

source ~/.bashrc
conda create --name sbci python=2.7
conda activate sbci

conda install numpy
conda install scipy
conda install matplotlib
conda install ipython
conda install jupyter
conda install cython

pip install h5py ==2.9.0 pip install imageio ==2.4.1
pip install moviepy ==0.2.3.5 pip install openpyxl ==2.4.8
pip install pandas ==0.20.3 pip install Pillow ==5.2.0
pip install requests ==2.19.1
pip install scikit-learn==0.19.0
pip install vtk ==8.1.2
pip install PyMCubes ==0.0.9
pip install nibabel ==2.4.0
pip install https://github.com/MarcCote/tractconverter/archive/
master.zip
pip install fury ==0.4.0
pip install dipy ==0.16.0
pip install trimeshpy ==0.0.2
```

### DTI ENV

```
conda create --name dti
pip install dcm2bids pydeface
```


### Install scilpy_set
```
mkdir -p $HOME/set
mv $HOME/SBCI_Pipeline/thirdparty/scilpy_set.py $HOME/set
unzip scilpy_set.zip

python setup.py build_all
```

### Install PSC_Pipeline
` git clone git clone https://github.com/zhengwu/PSC_Pipeline.git `

