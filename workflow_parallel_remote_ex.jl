#for use on remote machine
using Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

using Distributed, SlurmClusterManager
slurm_manager = SlurmManager()

addprocs(slurm_manager)
# # print info on processes and workers
# println("Number of processes: ", nprocs())
# println("Number of workers: ", nworkers())
@everywhere println("Hello from $(myid()):$(gethostname())")

# instantiate and precompile environment
@everywhere begin
  using Pkg; Pkg.activate(@__DIR__); 
  Pkg.instantiate(); Pkg.precompile()
end

# load dependencies and helper functions
@everywhere begin
  using ProgressMeter
  using CSV
  using DataFrames

  function double(x)
    # perform calculations
    sleep(10)

    return 2*x
  end
end

# MAIN SCRIPT
# -----------

# relevant directories
indir  = joinpath(@__DIR__,"data")
outdir = joinpath(@__DIR__,"results")

# file to process
infile  = joinpath(indir, "baz.csv")

# read data
df = DataFrame(CSV.File(infile))

# process data
doubleC = @showprogress pmap(double, df.C)
insertcols!(df, :doubleC => doubleC)

# write results
res = joinpath.(outdir, "baz_results.csv")
CSV.write(res, df)