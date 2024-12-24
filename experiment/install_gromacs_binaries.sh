#!/bin/bash

# Update system packages
apt-get update
python -m pip install --upgrade pip
pip install matplotlib numpy
pip install --upgrade MDAnalysis
pip install seaborn
apt-get install -y libopenmpi-dev openmpi-bin
apt-get install -y libopenblas-dev libopenblas0 libfftw3-dev
apt-get install -y xvfb grace
apt-get install -y snakemake
apt-get install -y bc

# Set environment variables for dynamic libraries
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
echo 'export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH' >> ~/.bashrc
tar -xzvf gromacs.tar.gz -C /usr/local/
source /usr/local/gromacs/bin/GMXRC
export GMXLIB=/usr/local/share/gromacs/top
echo 'export GMXLIB=/usr/local/gromacs/share/gromacs/top' >> ~/.bashrc
echo "source /usr/local/gromacs/bin/GMXRC" > ~/.bashrc
source ~/.bashrc
gmx_mpi --version
rm -rf gromacs.tar.gz

