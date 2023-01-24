#!/bin/bash

# install prerequisite for current bluehive
# module load qt 
# module load gcc/9.1.0 
# module load mrtrix3 
# module load freesurfer/6.0.0 
# module load ants/2.3.1 
# module load fsl
# module load java/1.8.0_111 
# module load matlab 
# module load dcm2niix 
# module load pigz/2.6 
# module load anaconda
# module load git

# # install anaconda environment
# conda create -n sbci python=2.7
# conda activate sbci

# conda install numpy
# conda install scipy 
# conda install matplotlib
# conda install ipython
# conda install jupyter
# conda install cython

# pip install h5py==2.9.0
# pip install imageio==2.4.1
# pip install moviepy==0.2.3.5
# pip install openpyxl==2.4.8
# pip install pandas==0.20.3
# pip install Pillow==5.2.0
# pip install requests==2.19.1
# pip install scikit-learn==0.19.0
pip install vtk==8.1.2
pip install PyMCubes==0.0.9
pip install nibabel==2.4.0
pip install https://github.com/MarcCote/tractconverter/archive/master.zip
pip install fury==0.4.0
pip install dipy==0.16.0
pip install trimeshpy==0.0.2

echo "finish"