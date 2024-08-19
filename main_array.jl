# instantiate environment
using Pkg; Pkg.activate(@__DIR__)
Pkg.instantiate()

# load dependencies and helper functions
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
indir  = joinpath(@__DIR__, "data")
outdir = joinpath(@__DIR__, "results")

# files to process
infiles = readdir(indir, join=true)
infile = infiles[parse(Int64, ENV["SLURM_ARRAY_TASK_ID"])]

# process file
println("Processing ", basename(infile), "...")
outfile = joinpath(outdir, basename(infile))
process(infile, outfile)