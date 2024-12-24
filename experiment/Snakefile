# Set up fallback values using config.get()
# These values are passed via --config or default to the provided values
input_pdb = config.get("input", "input/1l2y.pdb")
temp_min = config.get("temp_min", 300)
temp_max = config.get("temp_max", 400)
exchange_frequency = config.get("exchange_frequency", 1000)
simulation_time = config.get("simulation_time", 1000000)
target_acceptance_ratio = config.get("accept_ratio", 0.2)
nreplicas = config.get("nreplicas", 0)

# Print the configurations to check
print(f"""
Configuration:
Input PDB: {input_pdb}
Temperature Range: {temp_min} - {temp_max} K
Exchange Frequency: {exchange_frequency} steps
Simulation Time: {simulation_time} steps
Acceptance Ratio: {target_acceptance_ratio}
""")

# Define the final output of the pipeline
rule all:
    input:
        "output/plots/temperature_mixing.png"


rule prepare_molecule:
    output:
        "temperatures.txt"
    shell:
        """
        mkdir -p output/logs
        if [ ! -f {input_pdb} ]; then
            echo "Error: Input PDB file '{input_pdb}' not found." 
            exit 1
        fi
        cp {input_pdb} .
        cp bash_py_scripts/* .
        bash prepare_molecule.sh $(basename {input_pdb}) 2>&1 | tee -a output/logs/prepare_molecule.log
        python3 temp_generator.py -Tmin {temp_min} -Tmax {temp_max} -gro npt.gro -accept {target_acceptance_ratio} \
        -nreplicas {nreplicas} 2>&1 | tee -a output/logs/temp_generator.log
        """

# Rule to run the REMD simulation
rule run_remd:
    input:
        temps="temperatures.txt"
    output:
        "replicas/replica_001/remd.log"
    shell:
        """
        echo "{input.temps} generated. Running simulation"
        bash run_remd.sh --nsteps {simulation_time} --replex {exchange_frequency} 2>&1 | tee -a output/logs/run_remd.log
        mv temperatures.txt output/data_files/
        """

# Rule to center the system and fix periodic boundary conditions
rule center_system:
    input:
        log="replicas/replica_001/remd.log"
    output:
        "output/final_pdbs/replica_001_final_structure.pdb"
    shell:
        """
        echo "{input.log} generated. Fixing PBC."
        bash center.sh {simulation_time} 2>&1 | tee -a output/logs/center.log
        """

# Rule to analyze the REMD output
rule analyze_output:
    input:
        final_pdb="output/final_pdbs/replica_001_final_structure.pdb"
    output:
        "output/plots/temperature_mixing.png"
    shell:
       """
        echo "{input.final_pdb} generated. Analyzing output." 

        # Extract exchange probabilities
        grep -A9 "average probabilities" replicas/replica_*/remd.log 2>&1 | tee -a output/data_files/exchange_rates_statistics.txt

        # Parse exchange rates
        python3 parse_exchange_rates.py 2>&1 | tee -a output/logs/parse_exchange_rates.log

        # Extract potential energy and RMSD xvgs for each replica
        bash Epot_rmsd.sh 2>&1 | tee -a output/logs/Epot_rmsd.log

        # Plot RMSD distribution
        python3 plot_rmsd_distribution.py 2>&1 | tee -a output/logs/plot_rmsd_distribution.log

        # Plot potential energy overlap
        python3 plot_energy_overlap.py 2>&1 | tee -a output/logs/plot_energy_overlap.log

        # Calculate convergence metrics
        bash calculate_convergence.sh {simulation_time} 2>&1 | tee -a output/logs/calculate_convergence.log

        # Parse convergence metrics
        python3 parse_convergence_metrics.py 2>&1 | tee -a output/logs/parse_convergence_metrics.log

        # Generate temperature mixing plot
        bash temperature_traj.sh 2>&1 | tee -a output/logs/temperature_traj.log

        # Plot temperature trajectories
        python3 plot_temperature_mixing.py 2>&1 | tee -a output/logs/plot_temperature_mixing.log
        
        #clean root directory
        bash clean.sh
        """

