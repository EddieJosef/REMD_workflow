import matplotlib.pyplot as plt
import re
import os

# Input file
input_file = "output/data_files/exchange_rates_statistics.txt"

# Data storage
replica_pairs = []
exchange_probs = []

# Check if input file exists
if not os.path.exists(input_file):
    print(f"Error: Input file '{input_file}' does not exist.")
    exit(1)

# Parse the file
try:
    with open(input_file, "r") as file:
        lines = file.readlines()
        for i, line in enumerate(lines):
            if "average probabilities" in line:
                # Move to the 2nd line after the "average probabilities" line
                target_line = lines[i + 2].strip()
                print(f"Parsing line: {target_line}")  # Debugging print
                # Extract values in .00 format
                values = re.findall(r"\.\d+", target_line)
                for j, value in enumerate(values):
                    replica_pairs.append(f"{j+1} -> {j+2}")
                    exchange_probs.append(float(value) * 100)  # Convert to percentage
except Exception as e:
    print(f"Error while parsing the file: {e}")
    exit(1)

# Check if data was extracted
if not replica_pairs or not exchange_probs:
    print("Error: No data found! Please check the log file formatting.")
    exit(1)

# Sort the data for visualization
sorted_pairs = sorted(zip(replica_pairs, exchange_probs), key=lambda x: x[0])
pairs, probs = zip(*sorted_pairs)

# Plot the data
try:
    plt.figure(figsize=(10, 6))
    bars = plt.bar(pairs, probs, color="skyblue")

    # Annotate bars with values
    for bar in bars:
        yval = bar.get_height()
        plt.text(bar.get_x() + bar.get_width() / 2, yval + 0.5, f"{yval:.1f}%", ha="center", va="bottom")

    # Plot settings
    plt.xticks(rotation=45)
    plt.xlabel("Replica Pair")
    plt.ylabel("Exchange Acceptance Rate (%)")
    plt.title("Exchange Acceptance Rate Between Neighboring Replicas")
    plt.tight_layout()
    plt.savefig("output/plots/exchange_acceptance_rate_percent.png", dpi=300)
    plt.show()

    print("Plot saved as 'output/plots/exchange_acceptance_rate_percent.png'")
except Exception as e:
    print(f"Error while plotting or saving the plot: {e}")
    exit(1)
