#!/bin/bash

# Directories setup
REPLICAS_DIR="replicas"
OUTPUT_DIR="output/temperature_xvg"
mkdir -p "$OUTPUT_DIR"

echo "=== Extracting Temperature Trajectories for All Replicas ==="

# Initialize variables for logging
skipped_replicas=()

# Loop through each replica directory
for REPLICA in ${REPLICAS_DIR}/replica_*; do
    REPLICA_ID=$(basename "$REPLICA")
    echo "$(date): Processing ${REPLICA_ID}"

    # Check for the existence of remd.edr
    ENERGY_FILE="${REPLICA}/remd.edr"
    if [[ ! -f "$ENERGY_FILE" ]]; then
        echo "Warning: Missing remd.edr file in ${REPLICA}. Skipping..."
        skipped_replicas+=("$REPLICA_ID")
        continue
    fi

    # Extract temperature trajectory
    OUTPUT_FILE="${OUTPUT_DIR}/${REPLICA_ID}_temperature.xvg"
    gmx_mpi energy -f "$ENERGY_FILE" -o "$OUTPUT_FILE" <<EOF
15
EOF

    if [[ $? -eq 0 ]]; then
        echo "$(date): Temperature trajectory saved for ${REPLICA_ID}"
    else
        echo "$(date): Error processing ${REPLICA_ID}"
        skipped_replicas+=("$REPLICA_ID")
    fi
done

echo "=== Temperature Trajectories Extracted Successfully ==="

# Summarize skipped replicas
if [[ ${#skipped_replicas[@]} -gt 0 ]]; then
    echo "The following replicas were skipped due to errors or missing files:"
    printf "  - %s\n" "${skipped_replicas[@]}"
else
    echo "All replicas processed successfully."
fi
