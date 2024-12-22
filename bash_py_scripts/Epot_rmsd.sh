#!/bin/bash

# Base directory containing replica folders
BASE_DIR="replicas"

# Output directory for processed data
OUTPUT_DIR="output/data_files"

# Reference structure for RMSD
REF_STRUCTURE="em.tpr"

# Check if reference structure exists
if [[ ! -f "${REF_STRUCTURE}" ]]; then
    echo "Error: Reference structure ${REF_STRUCTURE} not found!"
    exit 1
fi

# Ensure output directory exists
if [[ ! -d "${OUTPUT_DIR}" ]]; then
    mkdir -p "${OUTPUT_DIR}" || { echo "Error: Failed to create output directory ${OUTPUT_DIR}"; exit 1; }
fi

# Loop through all replica directories
for replica_dir in ${BASE_DIR}/replica_*; do
    if [[ -d "${replica_dir}" ]]; then
        echo "Processing ${replica_dir}..."

        # Extract replica index from directory name
        replica_index=$(basename "${replica_dir}" | awk -F_ '{print $2}')

        # Define input files
        TRAJECTORY_FILE="${replica_dir}/final.xtc"
        ENERGY_FILE="${replica_dir}/remd.edr"
        INDEX_FILE="${replica_dir}/index.ndx"

        # Define output files
        RMSD_OUTPUT="${OUTPUT_DIR}/rmsd_replica_${replica_index}.xvg"
        ENERGY_OUTPUT="${OUTPUT_DIR}/energy_replica_${replica_index}.xvg"

        # Step 1: Calculate RMSD using final.xtc and em.tpr as reference
        if [[ -f "${TRAJECTORY_FILE}" ]]; then
            echo "Calculating RMSD for Replica ${replica_index}..."
            gmx_mpi rms -s "${REF_STRUCTURE}" -f "${TRAJECTORY_FILE}" -o "${RMSD_OUTPUT}" -n "${INDEX_FILE}" <<EOF
4
17
EOF
            if [[ $? -ne 0 ]]; then
                echo "Error: RMSD calculation failed for Replica ${replica_index}."
                continue
            fi
        else
            echo "Warning: Missing trajectory file for ${replica_dir}"
        fi

        # Step 2: Extract potential energy
        if [[ -f "${ENERGY_FILE}" ]]; then
            echo "Extracting Potential Energy for Replica ${replica_index}..."
            gmx_mpi energy -f "${ENERGY_FILE}" -o "${ENERGY_OUTPUT}" <<EOF
Potential
EOF
            if [[ $? -ne 0 ]]; then
                echo "Error: Potential energy extraction failed for Replica ${replica_index}."
                continue
            fi
        else
            echo "Warning: Missing energy file for ${replica_dir}"
        fi

        echo "Replica ${replica_index} processed successfully."
    fi
done

echo "RMSD and Potential Energy extraction complete."
