#!/bin/bash
#SBATCH --job-name=serial_test_julia
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --output=out_serial_2-%j.txt
#SBATCH --error=err_serial_2-%j.txt
#SBATCH --exclusive

# Print properties of job as submitted
echo "SLURM_JOB_ID = $SLURM_JOB_ID"
echo "SLURM_NTASKS = $SLURM_NTASKS"
echo "SLURM_NTASKS_PER_NODE = $SLURM_NTASKS_PER_NODE"
echo "SLURM_CPUS_PER_TASK = $SLURM_CPUS_PER_TASK"
echo "SLURM_JOB_NUM_NODES = $SLURM_JOB_NUM_NODES"

# Print properties of job as scheduled by Slurm
echo "SLURM_JOB_NODELIST = $SLURM_JOB_NODELIST"
echo "SLURM_TASKS_PER_NODE = $SLURM_TASKS_PER_NODE"
echo "SLURM_JOB_CPUS_PER_NODE = $SLURM_JOB_CPUS_PER_NODE"
echo "SLURM_CPUS_ON_NODE = $SLURM_CPUS_ON_NODE"

# Copy data to local temp space on compute node
MYTMP=/tmp/$USER/$SLURM_JOB_ID
/usr/bin/mkdir -p $MYTMP || exit $?
echo "Copying my data over..."
cp -rp $SLURM_SUBMIT_DIR/data $MYTMP || exit $?

# Load Julia (using juliaup) and run script
julia +1.9.0 main_serial_2.jl

# Copy output back to home directory
echo "Copying output back to $SLURM_SUBMIT_DIR"
/usr/bin/mkdir -p $SLURM_SUBMIT_DIR/output || exit $?
cp -rp $MYTMP/files.txt $SLURM_SUBMIT_DIR/output || exit $?

# Remove your data from the compute node
rm -rf $MYTMP