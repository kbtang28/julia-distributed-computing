# instantiate and precompile environment
using Pkg; Pkg.activate(@__DIR__); 
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
  
# process files in parallel
status = @showprogress for i in 1:nfiles
    process(infiles[i], outfiles[i])
end