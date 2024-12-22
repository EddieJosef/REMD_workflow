import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import glob
import os

# Load RMSD files from all replica directories
rmsd_files = sorted(glob.glob("output/data_files/rmsd_replica_*.xvg"))

# Check if files exist
if not rmsd_files:
    print("Error: No RMSD files found in 'output/data_files'. Please check the file path or pattern.")
    exit(1)

# Create a figure for the KDE plot
plt.figure(figsize=(10, 6))

# Plot RMSD KDE for each replica
for file in rmsd_files:
    try:
        # Skip GROMACS headers and load RMSD values
        data = np.loadtxt(file, comments=["@", "#"])
        rmsd_values = data[:, 1]  # Second column: RMSD values

        # Extract replica index from file name
        replica_index = int(file.split("_")[-1].split(".")[0])

        # KDE plot for each replica
        sns.kdeplot(rmsd_values, label=f"Replica {replica_index}", linewidth=2, fill=False)
    except Exception as e:
        print(f"Warning: Failed to process {file}: {e}")
        continue

# Customize the plot
plt.xlabel("RMSD (nm)")
plt.ylabel("Probability Density")
plt.title("RMSD Distribution Across Replicas")
plt.legend(loc="upper right")
plt.grid()
plt.tight_layout()

# Ensure output directory exists
os.makedirs("output/plots", exist_ok=True)

# Save and show the plot
output_file = "output/plots/rmsd_distribution_kde.png"
plt.savefig(output_file, dpi=300)
plt.show()

print(f"RMSD KDE plot saved as '{output_file}'.")
