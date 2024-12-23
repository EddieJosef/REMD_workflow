#!/bin/bash

# Directories setup
OUTPUT_DIR="output/convergence_metrics_xvg"
REPLICAS_DIR="replicas"
mkdir -p "$OUTPUT_DIR"

# Reference structure for RMSD
REF_STRUCTURE="em.tpr"
if [[ ! -f "$REF_STRUCTURE" ]]; then
    echo "Error: Reference structure $REF_STRUCTURE not found!"
    exit 1
fi

# Extract dt and nsteps from md.mdp in the root directory
MDP_FILE="md.mdp"

if [[ -f "$MDP_FILE" ]]; then
    DT=$(grep -E "dt\\s*=" $MDP_FILE | awk '{print $3}')
    NSTEPS=$(grep -E "nsteps\\s*=" $MDP_FILE | awk '{print $3}')
    if [[ -n "$DT" && -n "$NSTEPS" ]]; then
        LAST_TIME=$(echo "$DT * $NSTEPS" | bc)   # Calculate total simulation time
        TIME_INTERVAL=$(echo "$LAST_TIME / 4" | bc) # Divide time into 4 intervals
        echo "Detected from $MDP_FILE:"
        echo "  Time Step (dt): $DT"
        echo "  Number of Steps (nsteps): $NSTEPS"
        echo "  Total Simulation Time: $LAST_TIME ps"
        echo "  Time Interval for Analysis: $TIME_INTERVAL ps"
    else
        echo "Error: Could not extract dt or nsteps from $MDP_FILE. Exiting."
        exit 1
    fi
else
    echo "Error: $MDP_FILE not found. Exiting."
    exit 1
fi

echo "=== Starting Convergence Metrics Calculation at Four Time Intervals ==="

# Loop through each replica directory
for REPLICA in ${REPLICAS_DIR}/replica_*; do
    REPLICA_ID=$(basename "$REPLICA")
    echo "Processing $REPLICA_ID"

    # Check required files
    if [[ ! -f "${REPLICA}/remd.edr" || ! -f "${REPLICA}/final.xtc" ]]; then
        echo "Warning: Missing required files in $REPLICA. Skipping..."
        continue
    fi
    
    # Output files for potential energy, Rg, and RMSD
    PE_0="${OUTPUT_DIR}/${REPLICA_ID}_pe_0.xvg"
    PE_1="${OUTPUT_DIR}/${REPLICA_ID}_pe_1.xvg"
    PE_2="${OUTPUT_DIR}/${REPLICA_ID}_pe_2.xvg"
    PE_3="${OUTPUT_DIR}/${REPLICA_ID}_pe_3.xvg"

    RG_0="${OUTPUT_DIR}/${REPLICA_ID}_rg_0.xvg"
    RG_1="${OUTPUT_DIR}/${REPLICA_ID}_rg_1.xvg"
    RG_2="${OUTPUT_DIR}/${REPLICA_ID}_rg_2.xvg"
    RG_3="${OUTPUT_DIR}/${REPLICA_ID}_rg_3.xvg"

    RMSD_0="${OUTPUT_DIR}/${REPLICA_ID}_rmsd_0.xvg"
    RMSD_1="${OUTPUT_DIR}/${REPLICA_ID}_rmsd_1.xvg"
    RMSD_2="${OUTPUT_DIR}/${REPLICA_ID}_rmsd_2.xvg"
    RMSD_3="${OUTPUT_DIR}/${REPLICA_ID}_rmsd_3.xvg"

    # Calculate time ranges
    TIME_1=$(echo "$TIME_INTERVAL" | bc)
    TIME_2=$(echo "$TIME_INTERVAL * 2" | bc)
    TIME_3=$(echo "$TIME_INTERVAL * 3" | bc)

    echo "Time Ranges: [0-$TIME_1 ps], [$TIME_1-$TIME_2 ps], [$TIME_2-$TIME_3 ps], [$TIME_3-$LAST_TIME ps]"

    # 1. Potential Energy
    echo "Calculating Potential Energy..."
    gmx_mpi energy -f ${REPLICA}/remd.edr -b 0 -e $TIME_1 -o "$PE_0" <<< "11" || { echo "Error: Failed to calculate potential energy for $REPLICA_ID"; continue; }
    gmx_mpi energy -f ${REPLICA}/remd.edr -b $TIME_1 -e $TIME_2 -o "$PE_1" <<< "11" || continue
    gmx_mpi energy -f ${REPLICA}/remd.edr -b $TIME_2 -e $TIME_3 -o "$PE_2" <<< "11" || continue
    gmx_mpi energy -f ${REPLICA}/remd.edr -b $TIME_3 -e $LAST_TIME -o "$PE_3" <<< "11" || continue

    # 2. Radius of Gyration
    echo "Calculating Radius of Gyration..."
    gmx_mpi gyrate -s ${REPLICA}/remd.tpr -f ${REPLICA}/final.xtc -b 0 -e $TIME_1 -o "$RG_0" -n ${REPLICA}/index.ndx <<< "17" || continue
    gmx_mpi gyrate -s ${REPLICA}/remd.tpr -f ${REPLICA}/final.xtc -b $TIME_1 -e $TIME_2 -o "$RG_1" -n ${REPLICA}/index.ndx <<< "17" || continue
    gmx_mpi gyrate -s ${REPLICA}/remd.tpr -f ${REPLICA}/final.xtc -b $TIME_2 -e $TIME_3 -o "$RG_2" -n ${REPLICA}/index.ndx <<< "17" || continue
    gmx_mpi gyrate -s ${REPLICA}/remd.tpr -f ${REPLICA}/final.xtc -b $TIME_3 -e $LAST_TIME -o "$RG_3" -n ${REPLICA}/index.ndx <<< "17" || continue

    # 3. RMSD
    echo "Calculating RMSD..."
    gmx_mpi rms -s $REF_STRUCTURE -f ${REPLICA}/final.xtc -b 0 -e $TIME_1 -o "$RMSD_0" -n ${REPLICA}/index.ndx <<< "4 17" || continue
    gmx_mpi rms -s $REF_STRUCTURE -f ${REPLICA}/final.xtc -b $TIME_1 -e $TIME_2 -o "$RMSD_1" -n ${REPLICA}/index.ndx <<< "4 17" || continue
    gmx_mpi rms -s $REF_STRUCTURE -f ${REPLICA}/final.xtc -b $TIME_2 -e $TIME_3 -o "$RMSD_2" -n ${REPLICA}/index.ndx <<< "4 17" || continue
    gmx_mpi rms -s $REF_STRUCTURE -f ${REPLICA}/final.xtc -b $TIME_3 -e $LAST_TIME -o "$RMSD_3" -n ${REPLICA}/index.ndx <<< "4 17" || continue

    echo "Completed $REPLICA_ID"
done

echo "=== All Replicas Processed. Results saved to $OUTPUT_DIR ==="
