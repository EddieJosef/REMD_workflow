import os
import numpy as np

def compute_average(file):
    """Load data and compute average and standard deviation."""
    if not os.path.exists(file):
        print(f"Error: File {file} not found.")
        return None, None
    try:
        data = np.loadtxt(file, comments=["@", "#"])
        return np.mean(data[:, 1]), np.std(data[:, 1])
    except Exception as e:
        print(f"Error processing file {file}: {e}")
        return None, None

# Directory containing the output files
OUTPUT_DIR = "output/convergence_metrics_xvg"
OUTPUT_FILE = "output/data_files/convergence_metrics_results.txt"

# Ensure output directory exists
os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)

# Dynamically determine replicas
replicas = sorted({f.split("_")[1] for f in os.listdir(OUTPUT_DIR) if f.startswith("replica_")})

# Define time interval indices (0 to 3)
intervals = ["0", "1", "2", "3"]

# Open a file to save results
with open(OUTPUT_FILE, "w") as f_out:
    print("===== Convergence Metrics for All Replicas =====")
    f_out.write("===== Convergence Metrics for All Replicas =====\n")

    for replica in replicas:
        print(f"\nReplica {replica}:")
        f_out.write(f"\nReplica {replica}:\n")

        for interval in intervals:
            # Define file paths for each metric
            pe_file = os.path.join(OUTPUT_DIR, f"replica_{replica}_pe_{interval}.xvg")
            rg_file = os.path.join(OUTPUT_DIR, f"replica_{replica}_rg_{interval}.xvg")
            rmsd_file = os.path.join(OUTPUT_DIR, f"replica_{replica}_rmsd_{interval}.xvg")

            # Compute metrics for the current interval
            pe_mean, pe_std = compute_average(pe_file)
            rg_mean, rg_std = compute_average(rg_file)
            rmsd_mean, rmsd_std = compute_average(rmsd_file)

            # Define a helper function for printing and writing results
            def log_metric(metric_name, mean, std, file_path):
                if mean is not None:
                    msg = f"    {metric_name}: {mean:.3f} ± {std:.3f}"
                else:
                    msg = f"    {metric_name}: Error reading {file_path}"
                print(msg)
                f_out.write(msg + "\n")

            # Log results for each metric
            log_metric("Potential Energy (kJ/mol)", pe_mean, pe_std, pe_file)
            log_metric("Radius of Gyration (nm)", rg_mean, rg_std, rg_file)
            log_metric("RMSD (nm)", rmsd_mean, rmsd_std, rmsd_file)

print(f"\nResults have been saved to '{OUTPUT_FILE}'")
