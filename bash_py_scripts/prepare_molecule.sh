#!/bin/bash

# ============================
# GROMACS Simulation Workflow
# ============================
# This script automates a GROMACS simulation workflow. 
# It accepts a PDB file as an argument and generates
# the necessary input files, runs energy minimization, 
# equilibration (NVT & NPT), and prepares for REMD.

# ============================
# Input Validation
# ============================
if [[ $# -ne 1 ]]; then
    echo "Usage: bash $0 <input.pdb>"
    exit 1
fi

# Capture the input PDB file from the command line argument
PDB_FILE=$1

# Check if the input PDB file exists
if [[ ! -f "$PDB_FILE" ]]; then
    echo "Error: File '$PDB_FILE' not found."
    exit 1
fi

echo "Running simulation with input PDB file: $PDB_FILE"

# ============================
# Copy MDP Files to Working Directory
# ============================
if [[ -d "mdp_files" ]]; then
    cp mdp_files/*.mdp .
    echo "MDP files moved to the working directory."
else
    echo "Error: Directory 'mdp_files' not found. Please ensure it exists."
    exit 1
fi


# ============================
# Step 1: Generate Topology
# ============================
# Generate a GROMACS topology file and initial GRO file from the input PDB file
if ! gmx_mpi pdb2gmx -f "$PDB_FILE" -o input.gro -ignh -ter -missing -ff amber99sb-ildn -water tip3p; then
    echo "Error: Failed to generate topology."
    exit 1
fi

# ============================
# Step 2: Define Simulation Box
# ============================
# Edit the configuration to create a dodecahedron box
if ! gmx_mpi editconf -f input.gro -o input_box.gro -bt dodecahedron -d 1.0; then
    echo "Error: Failed to define simulation box."
    exit 1
fi

# ============================
# Step 3: Vacuum Energy Minimization
# ============================
# Preprocess and run energy minimization in vacuum
if ! gmx_mpi grompp -f em_vacuum.mdp -c input_box.gro -p topol.top -o em_vacuum.tpr; then
    echo "Error: Preprocessing for vacuum energy minimization failed."
    exit 1
fi
if ! gmx_mpi mdrun -v -deffnm em_vacuum; then
    echo "Error: Vacuum energy minimization failed."
    exit 1
fi

# ============================
# Step 4: Solvation
# ============================
# Solvate the system with water molecules
if ! gmx_mpi solvate -cp em_vacuum.gro -cs spc216.gro -p topol.top -o sol.gro; then
    echo "Error: Solvation step failed."
    exit 1
fi

# ============================
# Step 5: Add Ions
# ============================
# Preprocess and add ions to neutralize the system
if ! gmx_mpi grompp -f ions.mdp -c sol.gro -p topol.top -o ions.tpr; then
    echo "Error: Preprocessing for ion addition failed."
    exit 1
fi
if ! echo "13" | gmx_mpi genion -s ions.tpr -o solv_ions.gro -p topol.top -pname NA -nname CL -neutral -conc 0.15; then
    echo "Error: Adding ions failed."
    exit 1
fi

# ============================
# Step 6: Energy Minimization
# ============================
# Preprocess and perform energy minimization with solvent and ions
if ! gmx_mpi grompp -f em.mdp -c solv_ions.gro -p topol.top -o em.tpr -maxwarn 5; then
    echo "Error: Preprocessing for energy minimization failed."
    exit 1
fi
if ! gmx_mpi mdrun -v -deffnm em -s em.tpr; then
    echo "Error: Energy minimization failed."
    exit 1
fi

# Extract potential energy
if ! echo -e "10\n0" | gmx_mpi energy -f em.edr -o em_potential.xvg; then
    echo "Error: Failed to extract potential energy."
    exit 1
fi
if ! xvfb-run -a xmgrace -hardcopy -printfile em_potential.png -hdevice PNG em_potential.xvg; then
    echo "Error: Failed to generate potential energy plot."
    exit 1
fi

# ============================
# Step 7: NVT Equilibration
# ============================
# Preprocess and run NVT (constant volume and temperature) equilibration
if ! gmx_mpi grompp -f nvt.mdp -c em.gro -r em.gro -p topol.top -o nvt.tpr -maxwarn 5; then
    echo "Error: Preprocessing for NVT equilibration failed."
    exit 1
fi
if ! gmx_mpi mdrun -deffnm nvt -s nvt.tpr; then
    echo "Error: NVT equilibration failed."
    exit 1
fi

# Extract temperature
if ! echo -e "15\n0" | gmx_mpi energy -f nvt.edr -o nvt_temperature.xvg; then
    echo "Error: Failed to extract temperature."
    exit 1
fi
if ! xvfb-run -a xmgrace -hardcopy -printfile nvt_temperature.png -hdevice PNG nvt_temperature.xvg; then
    echo "Error: Failed to generate temperature plot."
    exit 1
fi

# ============================
# Step 8: NPT Equilibration
# ============================
# Preprocess and run NPT (constant pressure and temperature) equilibration
if ! gmx_mpi grompp -f npt.mdp -c nvt.gro -t nvt.cpt -r nvt.gro -p topol.top -o npt.tpr -maxwarn 5; then
    echo "Error: Preprocessing for NPT equilibration failed."
    exit 1
fi
if ! gmx_mpi mdrun -deffnm npt; then
    echo "Error: NPT equilibration failed."
    exit 1
fi

# Extract pressure and density
if ! echo -e "18\n0" | gmx_mpi energy -f npt.edr -o npt_pressure.xvg; then
    echo "Error: Failed to extract pressure."
    exit 1
fi
if ! echo -e "24\n0" | gmx_mpi energy -f npt.edr -o npt_density.xvg; then
    echo "Error: Failed to extract density."
    exit 1
fi
if ! xvfb-run -a xmgrace -hardcopy -printfile npt_pressure.png -hdevice PNG npt_pressure.xvg; then
    echo "Error: Failed to generate pressure plot."
    exit 1
fi
if ! xvfb-run -a xmgrace -hardcopy -printfile npt_density.png -hdevice PNG npt_density.xvg; then
    echo "Error: Failed to generate density plot."
    exit 1
fi

# ============================
# Final Cleanup and Organization
# ============================
# Move .xvg files to the output/dataf_iles directory
mkdir -p output/data_files
if ! mv *.xvg output/data_files/; then
    echo "Error: Failed to move .xvg files to output/data_files directory."
    exit 1
fi

# Move .png files to the output/plots directory
mkdir -p output/plots
if ! mv *.png output/plots/; then
    echo "Error: Failed to move .png files to output/plots directory."
    exit 1
fi

echo "Preparation complete. Now Generating temperatures"
