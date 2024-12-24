# Use a lightweight CUDA runtime image
FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04

# Use bash for subsequent RUN commands
SHELL ["/bin/bash", "-c"]

# Set non-interactive environment for apt-get
ENV DEBIAN_FRONTEND=noninteractive

# Set working directory
WORKDIR /workspace

# Copy project files into the image (including GROMACS tarball)
COPY . /workspace/

# Update system packages and install dependencies
RUN apt-get update && \
    apt-get install -y \
        python3 python3-pip libopenmpi-dev openmpi-bin \
        libopenblas-dev libopenblas0 libfftw3-dev xvfb grace \
        snakemake bc && \
    rm -rf /var/lib/apt/lists/* && \
    python3 -m pip install --upgrade pip && \
    pip install matplotlib numpy seaborn

# Install MDAnalysis in a separate step with --upgrade
RUN pip install --upgrade MDAnalysis

# Extract and configure GROMACS
RUN tar -xzvf gromacs.tar.gz -C /usr/local/ && \
    rm -rf gromacs.tar.gz

# Set environment variables for dynamic libraries and GROMACS
ENV PATH="/usr/local/gromacs/bin:$PATH"
ENV GMXLIB="/usr/local/share/gromacs/top"
ENV LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"

# (Optional) Verify GROMACS installation
# Uncomment the line below to verify installation during runtime
RUN gmx_mpi --version || true

# Set Snakemake as the entry point
ENTRYPOINT ["snakemake"]
CMD ["--cores", "all"]
