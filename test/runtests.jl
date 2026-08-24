using Test

using IntervalArithmetic

# mirrors the organization of src/ and ext/
repo_tests = String[]
for entry ∈ ("IntervalArithmetic.jl", "intervals", "piecewise.jl", "display.jl", "symbols.jl", "ext")
    if isdir(entry)
        for (root, _, files) ∈ walkdir(entry), f ∈ files
            push!(repo_tests, joinpath(root, f))
        end
    else
        push!(repo_tests, entry)
    end
end
for f ∈ repo_tests
    @testset "$f" begin
        include(f)
    end
end

using Pkg
Pkg.add(url = "https://github.com/Seelengrab/Supposition.jl.git", rev = "feat/support_x86")
for f ∈ filter(isfile, readdir("supposition"; join = true))
    @testset "$f" begin
        include(f)
    end
end
Pkg.rm("Supposition")

# generated via `generate(f)` for each non-LICENSE file f of itl/
include("generate_ITF1788.jl")
for f ∈ readdir("ITF1788_tests"; join = true)
    @testset "$f" begin
        include(f)
    end
end

include("aqua.jl")
