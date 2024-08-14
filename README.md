# A basic guide to distributed computing in Julia

This repository is a short introduction to distributed computing in Julia using [Distributed.jl](https://github.com/JuliaLang/Distributed.jl) and a nice sandbox for further exploration. The base code is forked from [this repo](https://github.com/Arpeggeo/julia-distributed-computing).


## Sample script for serial task

We will consider the sample script `main_serial.jl` that processes a set of files in a data folder and saves the results in a results folder. We choose this task because it involves IO and file paths, which can get tricky on remote machines:

```julia
# instantiate and precompile environment
using Pkg; Pkg.activate(@__DIR__)
Pkg.instantiate(); Pkg.precompile()

# load dependencies and helper functions
using ProgressMeter
using CSV

function process(infile, outfile)
  # read file from disk
  csv = CSV.File(infile)

  # perform calculations
  sleep(60)

  # save new file to disk
  CSV.write(outfile, csv)
end

# MAIN SCRIPT
# -----------

# relevant directories
indir  = joinpath(@__DIR__,"data")
outdir = joinpath(@__DIR__,"results")

# files to process
infiles  = readdir(indir, join=true)
outfiles = joinpath.(outdir, basename.(infiles))
nfiles   = length(infiles)

@showprogress for i in 1:nfiles
  process(infiles[i], outfiles[i])
end
```

We follow Julia’s best practices:

1. We instantiate the environment in the host machine, which lives in the files `Project.toml` and `Manifest.toml` (in the same directory of the script). Additionally, we precompile the project in case of heavy dependencies.
2. We then load the dependencies of the project, and define helper functions to be used.
3. The main work is done in a loop that calls the helper function with various files.

On our local machine, we `cd` into the project directory and call the script as follows:

```shell
$ julia main.jl
```

On Hopper, we could submit this job using the following shell script:

```shell
#!/bin/bash
#SBATCH --job-name=test_script
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --output=results/out-%j.txt
#SBATCH --error=results/err-%j.txt

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

# Run the Julia code (specify Julia version with juliaup)
julia +1.9.0 main_serial.jl

exit 0
```

If the above were saved in `run.sh`, we would use `sbatch run.sh` to submit the job.

## Parallelization (same machine)

Our goal is to process the files in parallel on Hopper. First, we will make minor modifications to the script to be able to run it with multiple processes on the same machine. This step is important for debugging:

- We load the `Distributed` stdlib to replace the simple `for` loop by a `pmap` call. `Distributed` is always available so we don’t need to instantiate the environment before loading it.
- We use `addprocs` to add worker processes—in this case, a number of worker processes equal to the number of tasks requested.
- We wrap the preamble into *two* `@everywhere` blocks. Two separate blocks are needed so that the environment is properly instantiated in all processes before we start loading packages.
- We also add a `try-catch` to handle issues with specific files handled by different parallel processes.

Here is the script `main.jl` with the above modifications:

```julia
using Distributed

num_procs = parse(Int, ENV["SLURM_NTASKS"])
addprocs(num_procs)

# print info about processes and workers
println("Number of processes: ", nprocs())
println("Number of workers: ", nworkers())
@everywhere println("Hello from $(myid()):$(gethostname())")

# instantiate and precompile environment
@everywhere begin
  using Pkg; Pkg.activate(@__DIR__)
  Pkg.instantiate(); Pkg.precompile()
end

# load dependencies and helper functions
@everywhere begin
  using ProgressMeter
  using CSV

  function process(infile, outfile)
    # read file from disk
    csv = CSV.File(infile)

    # perform calculations
    sleep(60)

    # save new file to disk
    CSV.write(outfile, csv)
  end
end

# MAIN SCRIPT
# -----------

# relevant directories
indir  = joinpath(@__DIR__,"data")
outdir = joinpath(@__DIR__,"results")

# files to process
infiles  = readdir(indir, join=true)
outfiles = joinpath.(outdir, basename.(infiles))
nfiles   = length(infiles)

# process files in parallel
status = @showprogress pmap(1:nfiles) do i
  try
    process(infiles[i], outfiles[i])
    true # success
  catch e
    false # failure
  end
end

# report files that failed
failed = infiles[.!status]
if !isempty(failed)
  println("List of files that failed:")
  foreach(println, failed)
end
```

On Hopper, we could submit this job—using `sbatch` as before—using the following shell script:

```shell
#!/bin/bash
#SBATCH --job-name=test_script
#SBATCH --nodes=1
#SBATCH --ntasks=4 
#SBATCH --output=results/out-%j.txt
#SBATCH --error=results/err-%j.txt

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

# Run the Julia code (specify Julia version with juliaup)
julia +1.9.0 main_serial.jl

exit 0
```

Notice that we have specified `--ntasks=4`. See the CAC's [Slurm tutorial](https://www.cac.cornell.edu/techdocs/clusterinfo/slurm/) for more information about the various flags you can set.