## **Introduction**

This workflow automates the **Replica Exchange Molecular Dynamics (REMD)** simulation process, a robust technique that enhances conformational sampling in molecular dynamics simulations, particularly for systems with complex energy landscapes.

This repository contains the results of **two REMD runs**:

- **First Run**: The results are located in the `output` directory. This run provided baseline performance metrics and identified areas for improvement.
- **Second Run**: The results are located in the `Experiment` directory. This run performed significantly better after parameter optimizations. With a bit more fine-tuning, the simulation results are expected to improve even further, showcasing the potential for robust sampling and convergence.

### **Overview**

- The project aims to streamline and standardize the REMD simulation workflow.
- It provides a Dockerized solution with configurable parameters, generating critical outputs and analysis plots for user-defined simulations.

---

## **Installation Guide**

### **Docker Image**

The REMD workflow is prepackaged in a Docker image for straightforward deployment:

- **Docker Image**: `docker pull edjosef96/remd:v1.0.2`

---

## **Usage Instructions**

### **Running the Workflow**

To execute the REMD workflow, use the following command:

```bash
docker run -v /path/to/input:/workspace/input -v /path/to/output:/workspace/output edjosef96/remd:v1.0.2 \
    --configfile /input/config.yaml --cores all
```

You can also mount additional directories as needed:

- **Replicas:** `-v /path/to/replicas:/workspace/replicas` for accessing replica files.
- **MDP Parameters:** Mount their directories to `/workspace/mdp_files` to use your own MDP parameter files.

---

## **Configuration File Example**

### **`config.yaml`**

Here’s an example of the configuration file used in the REMD workflow:

```yaml
# Configuration for REMD Workflow
input: "input/1l2y.pdb"               # Path to the input PDB file
temp_min: 300                         # Minimum temperature for the temperature ladder (K)
temp_max: 400                         # Maximum temperature for the temperature ladder (K)
exchange_frequency: 1000              # Frequency of temperature exchanges
simulation_time: 5000000              # Simulation time in picoseconds
accept_ratio: 0.2                     # Target acceptance ratio for exchanges
nreplicas: 10                         # Number of replicas (set to 0 for automatic calculation)
```

### **Dynamic Parameter Passing**

You can override configuration values directly using the `--config` flag. If no values are specified, the script uses default parameters in `Snakefile` :

```python
# Example of default fallback values using config.get()
input_pdb = config.get("input", "input/1l2y.pdb")
temp_min = config.get("temp_min", 300)
temp_max = config.get("temp_max", 400)
exchange_frequency = config.get("exchange_frequency", 1000)
simulation_time = config.get("simulation_time", 1000000)
target_acceptance_ratio = config.get("accept_ratio", 0.2)
nreplicas = config.get("nreplicas", 0)
```

If `nreplicas` is not provided or is less than 2, it is automatically computed using the `temp_generator.py` function, specifically the `compute_temp_spacing()` function.

### **Example Command**

To override specific parameters, use:

```bash
docker run -v /path/to/input:/input -v /path/to/output:/output edjosef96/remd \
    --config temp_min=350 temp_max=450 simulation_time=500000
```

---

## **Project Structure**

- **`./input`**: Directory containing the input PDB structure and optional `config.yaml` configuration file.
- **`./output`**: Directory for storing all outputs generated by the workflow:
    - **`data_files`**: Includes files such as `temperatures.txt` and `convergence_metrics_results.txt`.
    - **`final_pdbs`**: Contains final structures extracted from trajectory files.
    - **`logs`**: Logs from all scripts executed during the simulation.
    - **`plots`**: Visualization outputs, including temperature mixing and RMSD distribution plots.
    - **`sim_files`**: Intermediate files generated during system equilibration and a complete Snakemake log.
    - **`temperature_xvg`**: Contains temperature trajectory `.xvg` files.
    - **`convergence_metrics`**: Stores `.xvg` files for potential energy (PE), RMSD, and radius of gyration at four time intervals.
- **`./bash_py_scripts`**: Directory containing all Bash scripts required for running the REMD workflow.
- **`./replicas`**: Directory generated post-simulation, containing files for each replica.
- **`./mdp_files`**: Directory housing all MDP files required for system equilibration.
- **`./Snakefile`**: Snakemake workflow file for automating the simulation steps.
- **`./gromacs.tar.gz`**: Precompiled GROMACS binaries with MPI and CUDA support.
- **`./install_gromacs_binaries.sh`**: Bash script for installing dependencies, extracting GROMACS binaries, and configuring the environment.
- **`README.md`**: Documentation file providing an overview and usage instructions for the workflow.
- **`Theoretical_Documentation.md`**: Detailed theoretical documentation explaining the methodology, implementation, and scientific principles behind the workflow.

---

## **Technical Documentation**

### **Key Workflow Steps**

- **`Prepare_Molecule.sh`**:
    
    - **System Preparation**: Generates topology, solvation, and ionization files.
    - **Energy Minimization**: Resolves steric clashes by minimizing potential energy.
    - **Equilibration**: Performs NVT and NPT simulations to equilibrate the system.
- **`temp_generator.py`**:
    
    - **Replica Setup**: Creates the temperature ladder and replica configurations.
- **`run_remd.sh`**:
    
    - **REMD Execution**: Manages REMD simulation using GROMACS.
- **`Center.sh`**:
    
    - Centers the system, creates an index group for protein heavy atoms, and extracts final structures.
- **Post-Processing**:
    
    - Parses simulation data and generates plots for temperature mixing, exchange success rates, energy overlaps, RMSD distributions, and convergence metrics.
- **`clean.sh`**:
    
    - Finalizes organization and cleanup.

---

## **Outputs**

- **Exchange Rates**: `output/data_files/exchange_rates_statistics.txt`, `output/plots/exchange_acceptance_rate_percent.png`
- **Temperature Trajectories**: `output/temperature_trajectories_xvg`, `output/plots/temperature_mixing.png`
- **Potential Energy Distributions**: `output/data_files/energy_replica_*.xvg`, `output/plots/potential_energy_overlap_kde.png`
- **RMSD Plots**: `output/data_files/rmsd_replica_*.xvg`, `output/plots/rmsd_distribution_kde.png`
- **Final Structures**: `output/final_pdbs/replica_*_final_structure.pdb`
- **Convergence Metrics**: `output/data_files/convergence_metrics_results.txt`

---

## **Example of other inportant Outputs**

### **Generated Files**
- `output/data_files/temperatures.txt` : generated temperature ladder based on system size, number of replicas, target acceptance ratio, Exponential Temperature Spacing, and specified temperature range
- **output/data_files**:`em_potential.xvg` `npt_density.xvg` `npt_pressure.xvg` `nvt_temperature.xvg`
- **output/plots**: `em_potential.png npt_density.png npt_pressure.png nvt_temperature.png`

---
