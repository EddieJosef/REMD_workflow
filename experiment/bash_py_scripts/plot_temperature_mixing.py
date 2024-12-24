import matplotlib.pyplot as plt
import numpy as np
import os

# Directories
OUTPUT_DIR = "output/temperature_xvg"
PLOT_DIR = "output/plots"

# Ensure directories exist
if not os.path.exists(OUTPUT_DIR):
    print(f"Error: Input directory '{OUTPUT_DIR}' does not exist. Exiting.")
    exit(1)
os.makedirs(PLOT_DIR, exist_ok=True)

# Initialize lists for logging
skipped_replicas = []
failed_replicas = []

# Dynamically determine replicas based on available files
replica_files = sorted([f for f in os.listdir(OUTPUT_DIR) if f.endswith("_temperature.xvg")])
replicas = [f.split("_")[0] + "_" + f.split("_")[1] for f in replica_files]

# Plot temperature trajectories
plt.figure(figsize=(10, 6))

for replica in replicas:
    file_path = os.path.join(OUTPUT_DIR, f"{replica}_temperature.xvg")
    if os.path.exists(file_path):
        try:
            data = np.loadtxt(file_path, comments=["@", "#"])
            time = data[:, 0]  # Time in ps
            temperature = data[:, 1]  # Temperature in K
            plt.plot(time, temperature, label=replica)
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
            failed_replicas.append(replica)
    else:
        print(f"File not found: {file_path}")
        skipped_replicas.append(replica)

# Plot settings
plt.xlabel('Time (ps)')
plt.ylabel('Temperature (K)')
plt.title('Temperature Mixing Across Replicas')
plt.legend(loc="best")
plt.grid(True)

# Save the plot
output_file = os.path.join(PLOT_DIR, "temperature_mixing.png")
plt.savefig(output_file)
plt.close()

print(f"Temperature mixing plot saved to {output_file}")

# Summarize skipped and failed replicas
if skipped_replicas:
    print("The following replicas were skipped due to missing files:")
    for replica in skipped_replicas:
        print(f"  - {replica}")

if failed_replicas:
    print("The following replicas failed due to read errors:")
    for replica in failed_replicas:
        print(f"  - {replica}")
