#!/bin/bash

# Input arguments: --nsteps and --replex
MDP_FILE="md.mdp"        # Base MDP file
TEMPERATURE_FILE="temperatures.txt"
NPT_FILE="npt.gro"
OUTPUT_DIR="replicas"

# Function to print usage
usage() {
    echo "Usage: bash $0 --nsteps [value] --replex [value]"
    echo "  --nsteps VALUE     Number of steps for the simulation (required)"
    echo "  --replex VALUE     Exchange frequency for REMD (required)"
    exit 1
}

# Parse user-provided arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --nsteps)
            NSTEPS=$2
            shift 2
            ;;
        --replex)
            REPLEX=$2
            shift 2
            ;;
        --help|-h)
            usage
            ;;
        *)
            echo "Error: Invalid argument '$1'"
            usage
            ;;
    esac
done

# Validate input arguments
if [[ -z "$NSTEPS" || -z "$REPLEX" ]]; then
    echo "Error: --nsteps and --replex are required arguments."
    usage
fi

# Validate necessary files
if [[ ! -f $MDP_FILE ]]; then
    echo "Error: Base MDP file ($MDP_FILE) not found!"
    exit 1
fi

if [[ ! -f $TEMPERATURE_FILE ]]; then
    echo "Error: Temperature file ($TEMPERATURE_FILE) not found!"
    exit 1
fi

if [[ ! -f $NPT_FILE ]]; then
    echo "Error: NPT file ($NPT_FILE) not found!"
    exit 1
fi

if [[ $(wc -l < "$TEMPERATURE_FILE") -lt 1 ]]; then
    echo "Error: Temperature file ($TEMPERATURE_FILE) is empty or invalid!"
    exit 1
fi

# Step 1: Modify the base MDP file to replace [NSTEPS]
printf "\n=== Step 1: Setting nsteps = %s in Base MDP File ===\n" "$NSTEPS"
sed -i "s/\[NSTEPS\]/$NSTEPS/" $MDP_FILE || {
    echo "Error: Failed to update NSTEPS in $MDP_FILE"
    exit 1
}

# Step 2: Generate MDP and TPR files with temperature-specific configurations
printf "\n=== Step 2: Generating MDP and TPR Files for Each Replica ===\n"
mkdir -p $OUTPUT_DIR
i=0
while read -r T; do
    i=$((i + 1))
    replica_num=$(printf "%03d" "$i")
    mkdir -p $OUTPUT_DIR/replica_$replica_num
    sed "s/\[TEMPERATURE\]/$T/" $MDP_FILE > $OUTPUT_DIR/replica_$replica_num/remd_$replica_num.mdp || {
        echo "Error: Failed to create MDP file for replica $replica_num."
        exit 1
    }
    gmx_mpi grompp -f $OUTPUT_DIR/replica_$replica_num/remd_$replica_num.mdp -c $NPT_FILE -p topol.top -o $OUTPUT_DIR/replica_$replica_num/remd.tpr || {
        echo "Error: Failed to generate TPR file for replica $replica_num."
        exit 1
    }
    printf "Replica %s: MDP and TPR files created at %s K\n" "$replica_num" "$T"
done < "$TEMPERATURE_FILE"

# Step 3: Calculate REPLICAS count before changing directory
REPLICAS=$(wc -l < "$TEMPERATURE_FILE")

# Step 4: Run REMD Simulation
printf "\n=== Step 4: Running REMD Simulation with Replex = %s ===\n" "$REPLEX"
cd $OUTPUT_DIR || { echo "Error: Could not enter $OUTPUT_DIR directory."; exit 1; }

REPLICA_DIRS=$(find . -type d -name 'replica_*' | sort -V | tr '\n' ' ')
mpirun --allow-run-as-root -np "$REPLICAS" gmx_mpi mdrun -multidir $REPLICA_DIRS -replex $REPLEX -deffnm remd \
    && printf "REMD simulation completed successfully!\n" \
    || { printf "Error: REMD simulation failed!\n"; exit 1; }
