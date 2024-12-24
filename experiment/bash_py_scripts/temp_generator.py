import argparse
import math
import os
import MDAnalysis as mda

def count_atoms(gro_file):
    """Count the number of atoms in a .gro file using MDAnalysis."""
    try:
        u = mda.Universe(gro_file)
        return len(u.atoms)
    except Exception as e:
        raise RuntimeError(f"Error counting atoms in '{gro_file}': {e}")

def compute_temp_spacing(Tmin, Tmax, natoms, acceptance_target):
    """Compute temperature spacing dynamically based on acceptance ratio."""
    if Tmin <= 0 or Tmax <= 0:
        raise ValueError("Temperatures must be greater than 0.")
    if Tmin >= Tmax:
        raise ValueError("Tmin must be less than Tmax.")
    if natoms <= 0:
        raise ValueError("Number of atoms must be greater than 0.")
    if acceptance_target <= 0 or acceptance_target > 1:
        raise ValueError("Acceptance target must be between 0 and 1.")

    try:
        delta = (2 / (acceptance_target * natoms)) ** 0.5  # Scaled spacing factor
        n_replicas = int(math.ceil(math.log(Tmax / Tmin) / math.log(1 + delta)))
        return n_replicas
    except Exception as e:
        raise RuntimeError(f"Error computing temperature spacing: {e}")

def generate_temperature_ladder(Tmin, Tmax, n_replicas):
    """Generate an exponential temperature ladder."""
    if n_replicas < 2:
        raise ValueError("Number of replicas must be at least 2.")

    try:
        temperatures = [Tmin * (Tmax / Tmin) ** (i / (n_replicas - 1)) for i in range(n_replicas)]
        return temperatures
    except Exception as e:
        raise RuntimeError(f"Error generating temperature ladder: {e}")

def save_temperatures(temperatures, output_file):
    """Save generated temperatures to a file."""
    try:
        with open(output_file, 'w') as file:
            for T in temperatures:
                file.write(f"{T:.2f}\n")
    except Exception as e:
        raise RuntimeError(f"Error saving temperatures to file '{output_file}': {e}")

def main():
    parser = argparse.ArgumentParser(description="Temperature generator for REMD simulations.")
    parser.add_argument("-Tmin", type=float, required=True, help="Minimum temperature (K)")
    parser.add_argument("-Tmax", type=float, required=True, help="Maximum temperature (K)")
    parser.add_argument("-gro", type=str, required=True, help=".gro file to compute number of atoms")
    parser.add_argument("-accept", type=float, required=True, help="Target acceptance ratio (default: 0.2)")
    parser.add_argument("-nreplicas", type=int, required=True, help="Number of replicas (optional). If not provided, it will be calculated dynamically.")
    args = parser.parse_args()

    # Validate file existence
    if not os.path.exists(args.gro):
        raise FileNotFoundError(f"The file '{args.gro}' does not exist.")

    try:
        # Count atoms
        natoms = count_atoms(args.gro)

        # Compute number of replicas dynamically if not provided
        if args.nreplicas > 2:
            n_replicas = args.nreplicas
            print(f"Using user-specified number of replicas: {n_replicas}")
        else:
            n_replicas = compute_temp_spacing(args.Tmin, args.Tmax, natoms, args.accept)
            print(f"Calculated number of replicas: {n_replicas}")

        # Generate temperature ladder
        temperatures = generate_temperature_ladder(args.Tmin, args.Tmax, n_replicas)

        # Save to file
        save_temperatures(temperatures, "temperatures.txt")
        print("Generated temperatures:")
        print(" ".join([f"{T:.2f}" for T in temperatures]))
    except Exception as e:
        print(f"Error: {e}")
        exit(1)

if __name__ == "__main__":
    main()
