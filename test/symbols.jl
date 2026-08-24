using Test
using IntervalArithmetic
using IntervalArithmetic.Symbols

@testset "Exports and docstrings" begin
    @test Set(names(IntervalArithmetic.Symbols)) ==
        Set([:Symbols, Symbol(".."), :±, :≛, :⊑, :⋤, :⪽, :⪯, :≺, :⊓, :⊔, :∅, :ℝ])

    for s ∈ (Symbol(".."), :±, :≛, :⊑, :⋤, :⪽, :⪯, :≺, :⊓, :⊔, :∅, :ℝ)
        str = string(eval(:(Base.@doc $s)))
        @test !isempty(str) && !occursin("No documentation found", str)
    end

    @test Symbols.:(..) isa Function
    @test Symbols.:± isa Function
    @test parentmodule(Symbols.:(..)) === IntervalArithmetic.Symbols
    @test parentmodule(Symbols.:±) === IntervalArithmetic.Symbols
    @test Symbols.:≛ === IntervalArithmetic.isequal_interval
    @test parentmodule(Symbols.:⊔) === IntervalArithmetic
end

@testset ".." begin
    @test IntervalArithmetic.Symbols.:..(1, 2) === interval(1, 2; format = :infsup)

    x = 0.1..0.3
    @test x isa Interval{Float64}
    @test inf(x) == 0.1 && sup(x) == 0.3
    @test decoration(x) === com && isguaranteed(x)
    @test isequal_interval(x, interval(0.1, 0.3))

    y = (1//1)..π
    @test y isa Interval{Rational{Int64}}
    @test inf(y) == 1//1 && sup(y) == 85563208//27235615
    @test decoration(y) === com && isguaranteed(y)

    z = 1..2
    @test z isa Interval{Float64}
    @test inf(z) == 1.0 && sup(z) == 2.0
    @test decoration(z) === com && isguaranteed(z)

    w = @test_logs (:warn,) 2..1
    @test isnai(w)

    @test isguaranteed(interval(1, 2)..interval(3, 4))
    @test !isguaranteed((interval(1) + 1)..3)
end

@testset "±" begin
    x = 0 ± π
    @test x isa Interval{Float64}
    @test inf(x) == -3.1415926535897936 && sup(x) == 3.1415926535897936
    @test decoration(x) === com && isguaranteed(x)

    y = 0//1 ± π
    @test y isa Interval{Rational{Int64}}
    @test inf(y) == -85563208//27235615 && sup(y) == 85563208//27235615
    @test decoration(y) === com && isguaranteed(y)

    @test isequal_interval(1 ± 0, interval(1, 1))
    @test isthin(1 ± 0)

    @test_throws DomainError 1 ± -1

    for (m, r) ∈ ((0.1, 0.2), (-2.5, 3.75), (1e10, 1e-10), (0.0, 0.0))
        @test isequal_interval(m ± r, interval(m, r; format = :midpoint))
    end
end

@testset "Comparison aliases" begin
    @test (≛) === isequal_interval
    @test interval(1, 2) ≛ interval(1, 2)
    @test !(interval(1, 2) ≛ interval(1, 3))

    @test (⊑) === issubset_interval
    @test interval(1, 2) ⊑ interval(0, 3)

    @test (⋤) === isstrictsubset
    @test interval(1, 2) ⋤ interval(0, 3)
    @test !(interval(1, 2) ⋤ interval(1, 2))

    @test (⪽) === isinterior
    @test interval(1, 2) ⪽ interval(0, 3)
    @test !(interval(0, 2) ⪽ interval(0, 3))

    @test (⪯) === precedes
    @test interval(1, 2) ⪯ interval(2, 3)

    @test (≺) === strictprecedes
    @test !(interval(1, 2) ≺ interval(2, 3))
    @test interval(1, 2) ≺ interval(3, 4)
end

@testset "Lattice aliases" begin
    @test (⊔) === hull
    x = interval(1, 2) ⊔ interval(3, 4)
    @test inf(x) == 1.0 && sup(x) == 4.0
    @test decoration(x) === trv && isguaranteed(x)

    @test (⊓) === intersect_interval
    y = interval(1, 2) ⊓ interval(1.5, 3)
    @test inf(y) == 1.5 && sup(y) == 2.0
    @test decoration(y) === trv && isguaranteed(y)
end

@testset "∅ and ℝ" begin
    @test ∅ === emptyinterval()
    @test ∅ isa Interval{Float64}
    @test isempty_interval(∅)
    @test decoration(∅) === trv && isguaranteed(∅)

    @test isequal_interval(ℝ, entireinterval())
    @test ℝ isa Interval{Float64}
    @test inf(ℝ) == -Inf && sup(ℝ) == Inf
    @test decoration(ℝ) === dac && isguaranteed(ℝ)
    @test isentire_interval(ℝ)

    # ∅ and ℝ are captured at load time, cf. src/symbols.jl
    try
        IntervalArithmetic.configure(numtype = Float32)
        @test ∅ isa Interval{Float64}
        @test ℝ isa Interval{Float64}
        @test Base.invokelatest(emptyinterval) isa Interval{Float32}
        @test Base.invokelatest(entireinterval) isa Interval{Float32}
    finally
        IntervalArithmetic.configure(numtype = Float64)
    end
    @test Base.invokelatest(emptyinterval) isa Interval{Float64}
    @test IntervalArithmetic.configuration_options.numtype === Float64
end
