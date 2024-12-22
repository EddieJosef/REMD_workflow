import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import glob
import os

# Load energy files from all replica directories
energy_files = sorted(glob.glob("output/data_files/energy_replica_*.xvg"))

# Check if files exist
if not energy_files:
    print("Error: No energy files found in 'output/data_files'. Please check the file path or pattern.")
    exit(1)

# Create a figure for the KDE plot
plt.figure(figsize=(10, 6))

# Plot Potential Energy KDE for each replica
for file in energy_files:
    try:
        # Skip GROMACS headers and load potential energy values
        data = np.loadtxt(file, comments=["@", "#"])
        energy_values = data[:, 1]  # Second column: Potential energy values

        # Extract replica index from file name
        replica_index = int(file.split("_")[-1].split(".")[0])

        # KDE plot for each replica
        sns.kdeplot(energy_values, label=f"Replica {replica_index}", linewidth=2, fill=False)
    except Exception as e:
        print(f"Warning: Failed to process {file}: {e}")
        continue

# Customize the plot
plt.xlabel("Potential Energy (kJ/mol)")
plt.ylabel("Probability Density")
plt.title("Potential Energy Overlap Between Replicas")
plt.legend(loc="upper right")
plt.grid()
plt.tight_layout()

# Ensure output directory exists
os.makedirs("output/plots", exist_ok=True)

# Save and show the plot
output_file = "output/plots/potential_energy_overlap_kde.png"
plt.savefig(output_file, dpi=300)
plt.show()

print(f"Potential Energy KDE plot saved as '{output_file}'.")
