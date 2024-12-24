#!/bin/bash

# Define directories and files
ROOT_DIR=$(pwd)  # Assumes the script is run from the root directory
OUTPUT_DIR="${ROOT_DIR}/output/sim_files"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR" || { echo "Error: Failed to create output directory $OUTPUT_DIR"; exit 1; }

# List of files to delete
FILES_TO_DELETE=(
    # Scripts
    "calculate_convergence.sh"
    "center.sh"
    "Epot_rmsd.sh"
    "parse_convergence_metrics.py"
    "parse_exchange_rates.py"
    "plot_energy_overlap.py"
    "plot_rmsd_distribution.py"
    "plot_temperature_mixing.py"
    "prepare_molecule.sh"
    "run_remd.sh"
    "temperature_traj.sh"
    "temp_generator.py"
    # MDP files
    "em.mdp"
    "em_vacuum.mdp"
    "ions.mdp"
    "md.mdp"
    "npt.mdp"
    "nvt.mdp"
)

# Delete specified files
echo "Deleting specified files..."
for file in "${FILES_TO_DELETE[@]}"; do
    if [[ -f "$ROOT_DIR/$file" ]]; then
        echo "Deleting $file"
        rm "$ROOT_DIR/$file" || { echo "Error: Failed to delete $file"; exit 1; }
    else
        echo "Warning: $file not found. Skipping."
    fi
done

# Move remaining files to output directory, excluding Snakefile and install_gromacs_binaries.sh
echo "Moving remaining files to $OUTPUT_DIR..."
find "$ROOT_DIR" -maxdepth 1 -type f ! -name "Snakefile" ! -name "install_gromacs_binaries.sh" ! -name "index.ndx" -exec mv {} "$OUTPUT_DIR" \;

echo "Cleanup and file organization complete."
