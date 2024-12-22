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

# Validate placeholders in the base MDP file
if ! grep -q "\[NSTEPS\]" "$MDP_FILE"; then
    echo "Error: Placeholder [NSTEPS] not found in $MDP_FILE."
    exit 1
fi

if ! grep -q "\[TEMPERATURE\]" "$MDP_FILE"; then
    echo "Error: Placeholder [TEMPERATURE] not found in $MDP_FILE."
    exit 1
fi

# Step 1: Modify the base MDP file to replace [NSTEPS]
printf "\n=== Step 1: Setting nsteps = %s in Base MDP File ===\n" "$NSTEPS"
sed -i "s/\[NSTEPS\]/$NSTEPS/" $MDP_FILE

# Step 2: Generate MDP and TPR files with temperature-specific configurations
printf "\n=== Step 2: Generating MDP and TPR Files for Each Replica ===\n"
mkdir -p $OUTPUT_DIR && awk '{print $1}' $TEMPERATURE_FILE | while read -r T; do
    i=$(printf "%03d" $((++i)))
    mkdir -p $OUTPUT_DIR/replica_$i
    sed "s/\[TEMPERATURE\]/$T/" $MDP_FILE > $OUTPUT_DIR/replica_$i/remd_$i.mdp \
        && gmx_mpi grompp -f $OUTPUT_DIR/replica_$i/remd_$i.mdp -c $NPT_FILE -p topol.top -o $OUTPUT_DIR/replica_$i/remd.tpr \
        && printf "Replica %s: MDP and TPR files created at %s K\n" "$i" "$T"
done

# Step 3: Calculate REPLICAS count before changing directory
REPLICAS=$(awk 'END {print NR}' $TEMPERATURE_FILE)

# Step 4: Run REMD Simulation
printf "\n=== Step 4: Running REMD Simulation with Replex = %s ===\n" "$REPLEX"
cd $OUTPUT_DIR || { echo "Error: Could not enter $OUTPUT_DIR directory."; exit 1; }

# Collect replica directories for -multidir
REPLICA_DIRS=$(find . -type d -name 'replica_*' | sort -V | tr '\n' ' ')

# Run REMD with gmx_mpi mdrun
mpirun --allow-run-as-root -np "$REPLICAS" gmx_mpi mdrun -multidir $REPLICA_DIRS -replex $REPLEX -deffnm remd \
    && printf "REMD simulation completed successfully!\n" \
    || { printf "Error: REMD simulation failed!\n"; exit 1; }
