# instantiate and precompile environment
using Pkg; Pkg.activate(@__DIR__);
Pkg.instantiate(); Pkg.precompile()

# load packages and helper functions
using DelimitedFiles

function list(indir, outfile)
    # read directory from disk
    files = readdir(indir)

    # perform calculations
    sleep(10)

    # write names of files in indir to outfile
    open(outfile, "w") do io
        writedlm(io, files, '\n')
    end
end

# MAIN SCRIPT
# -----------

# relevant directories
indir = joinpath(@__DIR__, "data")
outfile = joinpath(@__DIR__, "files.txt")

list(indir, outfile)