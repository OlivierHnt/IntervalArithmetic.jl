using Test
using IntervalArithmetic
using Aqua
using TOML

@testset "Aqua" begin
    # `test_ambiguities` is unreliable on Julia < 1.11
    Aqua.test_all(IntervalArithmetic; ambiguities = VERSION ≥ v"1.11")

    @test isempty(Aqua.detect_unbound_args_recursively(IntervalArithmetic))

    # ignore ambiguities with packages loaded by other test files but foreign to the declared dependencies
    project = TOML.parsefile(joinpath(pkgdir(IntervalArithmetic), "Project.toml"))
    deps = union!(Set(["Base", "Core"]), keys(project["deps"]), keys(project["weakdeps"]))
    known(m::Method) = String(nameof(Base.moduleroot(m.module))) ∈ deps ||
        startswith(String(nameof(Base.moduleroot(m.module))), "IntervalArithmetic")
    ambiguities = Aqua.detect_ambiguities(IntervalArithmetic; recursive = true)
    filter!(x -> all(known, x) && occursin("IntervalArithmetic", something(pkgdir(last(x).module), "")), ambiguities)
    @test isempty(ambiguities)
end
