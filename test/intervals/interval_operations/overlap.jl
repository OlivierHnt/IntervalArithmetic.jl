using Test
using IntervalArithmetic

@testset "Overlap.State" begin
    @test Overlap isa Module
    @test Overlap === IntervalArithmetic.Overlap
    @test Overlap.State isa DataType
    # IEEE 1788-2015 Table 10.7 ordering
    @test instances(Overlap.State) ==
        (Overlap.both_empty, Overlap.first_empty, Overlap.second_empty,
         Overlap.before, Overlap.meets, Overlap.overlaps, Overlap.starts,
         Overlap.contained_by, Overlap.finishes, Overlap.equals,
         Overlap.finished_by, Overlap.contains, Overlap.started_by,
         Overlap.overlapped_by, Overlap.met_by, Overlap.after)
    @test collect(Int.(instances(Overlap.State))) == collect(1:16)
    @test Int(Overlap.both_empty) == 1
    @test Int(Overlap.equals) == 10
    @test Int(Overlap.after) == 16
end

@testset "overlap states" begin
    e = emptyinterval(BareInterval{Float64})
    @test overlap(e, e) == Overlap.both_empty
    @test overlap(e, bareinterval(1, 2)) == Overlap.first_empty
    @test overlap(bareinterval(1, 2), e) == Overlap.second_empty
    @test overlap(bareinterval(1, 2), bareinterval(3, 4)) == Overlap.before
    @test overlap(bareinterval(1, 2), bareinterval(2, 3)) == Overlap.meets
    @test overlap(bareinterval(1, 3), bareinterval(2, 4)) == Overlap.overlaps
    @test overlap(bareinterval(1, 2), bareinterval(1, 3)) == Overlap.starts
    @test overlap(bareinterval(2, 3), bareinterval(1, 4)) == Overlap.contained_by
    @test overlap(bareinterval(2, 4), bareinterval(1, 4)) == Overlap.finishes
    @test overlap(bareinterval(1, 2), bareinterval(1, 2)) == Overlap.equals
    @test overlap(bareinterval(1, 1), bareinterval(1, 1)) == Overlap.equals
    @test overlap(bareinterval(1, 4), bareinterval(2, 4)) == Overlap.finished_by
    @test overlap(bareinterval(1, 4), bareinterval(2, 3)) == Overlap.contains
    @test overlap(bareinterval(1, 3), bareinterval(1, 2)) == Overlap.started_by
    @test overlap(bareinterval(2, 4), bareinterval(1, 3)) == Overlap.overlapped_by
    @test overlap(bareinterval(2, 3), bareinterval(1, 2)) == Overlap.met_by
    @test overlap(bareinterval(3, 4), bareinterval(1, 2)) == Overlap.after
    @test overlap(bareinterval(2, 2), bareinterval(1, 1)) == Overlap.after

    # `meets` requires both intervals to be non-thin
    @test overlap(bareinterval(1, 1), bareinterval(1, 2)) == Overlap.starts
    @test overlap(bareinterval(1, 2), bareinterval(2, 2)) == Overlap.finished_by
    @test overlap(bareinterval(2, 2), bareinterval(1, 2)) == Overlap.finishes
    @test overlap(bareinterval(1, 2), bareinterval(1, 1)) == Overlap.started_by

    entire = entireinterval(BareInterval{Float64})
    @test overlap(entire, entire) == Overlap.equals
    @test overlap(bareinterval(-Inf, 0), bareinterval(0, Inf)) == Overlap.meets
    @test overlap(bareinterval(-Inf, 0), entire) == Overlap.starts

    for T ∈ (Float32, BigFloat)
        @test overlap(bareinterval(T, 1, 2), bareinterval(T, 2, 3)) == Overlap.meets
        @test overlap(bareinterval(T, 1, 2), bareinterval(T, 1, 3)) == Overlap.starts
        @test overlap(bareinterval(T, 3, 4), bareinterval(T, 1, 2)) == Overlap.after
    end
    @test overlap(bareinterval(1//1, 2//1), bareinterval(2//1, 3//1)) == Overlap.meets
    @test overlap(bareinterval(1//1, 2//1), bareinterval(1//1, 3//1)) == Overlap.starts
end

@testset "exhaustive sweep and duality" begin
    dual = Dict(
        Overlap.both_empty    => Overlap.both_empty,
        Overlap.first_empty   => Overlap.second_empty,
        Overlap.second_empty  => Overlap.first_empty,
        Overlap.before        => Overlap.after,
        Overlap.meets         => Overlap.met_by,
        Overlap.overlaps      => Overlap.overlapped_by,
        Overlap.starts        => Overlap.started_by,
        Overlap.contained_by  => Overlap.contains,
        Overlap.finishes      => Overlap.finished_by,
        Overlap.equals        => Overlap.equals,
        Overlap.finished_by   => Overlap.finishes,
        Overlap.contains      => Overlap.contained_by,
        Overlap.started_by    => Overlap.starts,
        Overlap.overlapped_by => Overlap.overlaps,
        Overlap.met_by        => Overlap.meets,
        Overlap.after         => Overlap.before)
    endpoints = [-Inf, -2, -1, 0, 1, 2, Inf]
    xs = [bareinterval(a, b) for a ∈ endpoints for b ∈ endpoints if a ≤ b && !(isinf(a) & (a == b))]
    push!(xs, emptyinterval(BareInterval{Float64}))
    for x ∈ xs, y ∈ xs
        s = overlap(x, y)
        @test s isa Overlap.State
        @test overlap(y, x) == dual[s]
    end
end

@testset "overlap of decorated intervals" begin
    @test overlap(interval(1, 2), interval(3, 4)) == Overlap.before
    @test overlap(IntervalArithmetic.setdecoration(interval(1, 2), trv), interval(1, 2)) == Overlap.equals
    @test overlap(emptyinterval(), emptyinterval()) == Overlap.both_empty
    @test overlap(emptyinterval(), interval(1, 2)) == Overlap.first_empty
    @test overlap(interval(1, 2), emptyinterval()) == Overlap.second_empty

    @test_throws ArgumentError overlap(nai(), interval(1, 2))
    @test_throws ArgumentError overlap(interval(1, 2), nai())
    @test_throws ArgumentError overlap(nai(), nai())
    @test_logs @test_throws ArgumentError overlap(nai(), interval(1, 2))

    z = complex(interval(1), interval(2))
    @test_throws MethodError overlap(z, z)
    @test_throws MethodError overlap([bareinterval(1, 2)], [bareinterval(1, 2)])
end
