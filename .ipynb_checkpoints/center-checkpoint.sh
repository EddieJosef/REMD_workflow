#!/bin/bash

# Correct PBC, Center, and Extract Structures for Visualization
printf "\n=== Correcting PBC, Centering, and Extracting Structures for All Replicas ===\n"

# Validate input
if [[ -z "$1" ]]; then
    echo "Error: Total simulation steps not provided!"
    exit 1
fi

# Variables
TOTAL_STEPS=$1
DT=0.002  # Timestep in ps
LAST_TIME=$(awk "BEGIN {print $TOTAL_STEPS * $DT}")
REPLICAS_DIR="replicas"
OUTPUT_DIR="output/final_pdbs"

# Create output directory
mkdir -p "$OUTPUT_DIR" || { echo "Error: Failed to create $OUTPUT_DIR"; exit 1; }

# Loop through replicas
for REPLICA in ${REPLICAS_DIR}/replica_*; do
    REPLICA_ID=$(basename "$REPLICA")
    printf "\n--- Processing %s ---\n" "$REPLICA_ID"

    # Paths
    TPR_FILE="${REPLICA}/remd.tpr"
    XTC_FILE="${REPLICA}/remd.xtc"
    INDEX_FILE="${REPLICA}/index.ndx"
    FINAL_XTC="${REPLICA}/final.xtc"

    # Skip if necessary files are missing
    if [[ ! -f "$TPR_FILE" || ! -f "$XTC_FILE" ]]; then
        printf "Error: Missing remd.tpr or remd.xtc in %s. Skipping...\n" "$REPLICA_ID"
        continue
    fi

     # Check if the index file already exists
    if [[ -f "$INDEX_FILE" ]]; then
        printf "Index file already exists: %s. Skipping creation...\n" "$INDEX_FILE"
    else
        # Create index file with heavy atoms
        printf "Step 1: Creating index file...\n"
        gmx_mpi make_ndx -f em.gro -o "$INDEX_FILE" <<EOF
1 & ! a H*
name 17 protein_heavy
q
EOF
    fi

    # Fix PBC and center system in one step
    printf "Step 2: Centering and fixing PBC...\n"
    gmx_mpi trjconv -s "$TPR_FILE" -f "$XTC_FILE" -o "$FINAL_XTC" -center -pbc mol -ur compact -boxcenter tric <<EOF
1
0
EOF

    # Extract the last frame into a PDB file
    printf "Step 3: Extracting last frame...\n"
    gmx_mpi trjconv -s "$TPR_FILE" -f "$FINAL_XTC" -o "${OUTPUT_DIR}/${REPLICA_ID}_final_structure.pdb" -dump "$LAST_TIME" <<EOF
0
EOF

    printf "%s: Processed and last frame extracted.\n" "$REPLICA_ID"
done

printf "\n=== Processing Complete ===\n"
