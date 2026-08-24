using Test
using IntervalArithmetic
using IntervalArithmetic: lowerbound, upperbound, rightof, leftof, in_domain,
    intersect_domain, isempty_domain, overlap_domain, domain_string

@testset "Domain construction" begin
    d = Domain{:closed,:open}(0, 1)
    @test d isa Domain{:closed,:open,Int,Int}
    @test d.lo == 0 && d.hi == 1

    @test Domain{:open,:closed}(-Inf, 0) isa Domain{:open,:closed,Float64,Int}

    @test Domain((0, :closed), (1, :open)) == Domain{:closed,:open}(0, 1)

    @test Domain(interval(1, 2)) === Domain{:closed,:closed,Float64,Float64}(1.0, 2.0)
    @test Domain(entireinterval()) === Domain{:closed,:closed,Float64,Float64}(-Inf, Inf)

    @test Domain() === Domain{:open,:open,Float64,Float64}(Inf, -Inf)
    @test isempty_domain(Domain())

    err = try Domain{:oopen,:closed}(0, 1) catch e; e end
    @test err isa ArgumentError
    @test err.msg == "Domain bound must be either :open or :closed, got oopen and closed instead"
    @test_throws ArgumentError Domain{:open,:close}(0, 1)
end

@testset "Domain accessors" begin
    d = Domain{:closed,:open}(0, 1)
    @test lowerbound(d) == (0, :closed)
    @test upperbound(d) == (1, :open)
    @test inf(d) === d.lo
    @test sup(d) === d.hi
end

@testset "rightof and leftof" begin
    @test rightof(1.0, (1, :closed))
    @test !rightof(1.0, (1, :open))
    @test rightof(2.0, (1, :open))
    @test !rightof(0.0, (1, :closed))

    @test leftof(1.0, (1, :closed))
    @test !leftof(1.0, (1, :open))
    @test leftof(0.0, (1, :open))
    @test !leftof(2.0, (1, :closed))

    d1 = Domain{:open,:closed}(0, 1)
    d2 = Domain{:open,:open}(0, 1)
    d3 = Domain{:open,:closed}(1, 2)
    d4 = Domain{:closed,:closed}(1, 2)
    @test !leftof(d1, d2)
    @test leftof(d1, d3)
    @test !leftof(d1, d4)
    @test leftof(d2, d3)
    @test leftof(d2, d4)
    @test leftof(d1, Domain{:open,:closed}(5, 6))
end

@testset "in_domain" begin
    @test in_domain(0.5, Domain{:closed,:closed}(0, 1))
    @test !in_domain(0, Domain{:open,:closed}(0, 1))
    @test !in_domain(1, Domain{:closed,:open}(0, 1))
    @test in_domain(0, Domain{:closed,:open}(0, 1))
    @test in_domain(1, Domain{:open,:closed}(0, 1))
end

@testset "intersect_domain" begin
    d1 = Domain{:closed,:open}(0, 10)
    d2 = Domain{:closed,:open}(2, 15)
    d3 = Domain{:open,:closed}(4, 7)
    d4 = Domain{:open,:closed}(-20, 3)

    @test intersect_domain(d1, d2) == Domain{:closed,:open}(2, 10)
    @test intersect_domain(d1, d3) == Domain{:open,:closed}(4, 7)
    @test intersect_domain(d1, d4) == Domain{:closed,:closed}(0, 3)
    @test intersect_domain(d2, d3) == Domain{:open,:closed}(4, 7)
    @test intersect_domain(d2, d4) == Domain{:closed,:closed}(2, 3)
    @test intersect_domain(d3, d4) == Domain()

    @test intersect_domain(Domain{:closed,:closed}(0, 2), Domain{:open,:open}(1, 3)) ==
        Domain{:open,:closed}(1, 2)

    @test intersect_domain(Domain{:closed,:closed}(0, 1), Domain{:closed,:open}(0, 1)) ==
        Domain{:closed,:open}(0, 1)
    @test intersect_domain(Domain{:open,:closed}(0, 1), Domain{:closed,:closed}(0, 1)) ==
        Domain{:open,:closed}(0, 1)
end

@testset "isempty_domain" begin
    @test isempty_domain(Domain{:open,:open}(1, 1))
    @test isempty_domain(Domain{:open,:closed}(1, 1))
    @test !isempty_domain(Domain{:closed,:closed}(1, 1))
    @test !isempty_domain(Domain{:open,:open}(1, 2))
    @test isempty_domain(Domain{:closed,:closed}(2, 1))
    @test isempty_domain(Domain())
end

@testset "Constant" begin
    c = Constant(1.2)
    @test c isa Constant{Float64}
    @test c.value == 1.2

    @test c(22.2) === 1.2
    @test c(3) === 1.2
    @test_throws MethodError c("some string")

    @test !isguaranteed(c(convert(Interval{Float64}, 1)))

    x = c(interval(0, 1.3))
    @test x isa Interval{Float64}
    @test isequal_interval(x, interval(1.2))
    @test decoration(x) === com && isguaranteed(x)

    @test c(interval(Float32, 0, 1)) isa Interval{Float64}

    @test Returns(1.2)(interval(0, 1)) === 1.2
    @test Constant(1.2)(interval(0, 1)) isa Interval
end

@testset "Piecewise construction" begin
    d1 = Domain{:closed,:closed}(0, 1)
    d2 = Domain{:open,:closed}(1, 2)
    d3 = Domain{:closed,:closed}(1, 2)

    p = Piecewise(d1 => Constant(1.0), d2 => identity)
    @test p isa Piecewise{2,1}
    @test p.continuity == (-1,)
    @test p.singularities == sup.(domains(p)[1:end-1]) == (1,)

    p2 = Piecewise(d1 => Constant(1.0), d2 => identity; continuity = [0])
    @test p2.continuity == (0,)

    @test_throws ArgumentError Piecewise(d2 => Constant(0), d1 => Constant(1))
    @test_throws ArgumentError Piecewise(d1 => Constant(0), d3 => Constant(1))

    @test_throws MethodError Piecewise(
        (Domain{:closed,:closed}(1, 2), Domain{:open,:open}(2, 3)),
        (sin, cos), (-1,), (2, 3))
    @test_throws ArgumentError Piecewise(
        (Domain{:closed,:closed}(1, 2), Domain{:open,:open}(2, 3)),
        (sin, cos), (-1, -1), (2, 3))
    @test_throws MethodError Piecewise(
        (Domain{:closed,:closed}(1, 2), Domain{:open,:open}(2, 3)),
        (sin, cos, log), (-1,), (2))

    p3 = Piecewise((d1, d2), (identity, identity))
    @test p3 isa Piecewise{2,1}
    @test p3.continuity == (-1,)

    @test_throws ArgumentError Piecewise((d1, d2), (identity, identity), (-1, -1))
    @test_throws ArgumentError Piecewise((d1, d2), (identity,))
end

@testset "domains, pieces and discontinuities" begin
    d1 = Domain{:closed,:closed}(0, 1)
    d2 = Domain{:open,:closed}(1, 2)
    p = Piecewise(d1 => Constant(1.0), d2 => identity)
    p2 = Piecewise(d1 => Constant(1.0), d2 => identity; continuity = [0])

    @test domains(p) === p.domains == (d1, d2)
    ps = collect(pieces(p))
    @test length(ps) == 2
    @test ps[1] == (d1, Constant(1.0)) && ps[2] == (d2, identity)

    @test discontinuities(p) == [1]
    @test discontinuities(p, 1) == [1]
    @test discontinuities(p2) == Int[]
    @test discontinuities(p2, 1) == [1]
    @test discontinuities(p2, 100) == [1]
end

@testset "domain_string and show" begin
    @test domain_string(Domain{:open,:closed}(-Inf, 0)) == "(-Inf, 0]"
    @test domain_string(Domain{:closed,:open}(0, 1)) == "[0, 1)"

    p = Piecewise(Domain{:closed,:closed}(0, 1) => Constant(1.0), Domain{:open,:closed}(1, 2) => identity)
    @test domain_string(p) == "[0, 1] ∪ (1, 2]"
    @test sprint(show, MIME("text/plain"), p) ==
        "Piecewise function with 2 pieces:\n  [0, 1] -> Constant{Float64}(1.0)\n  (1, 2] -> identity"
end

@testset "overlap_domain and in_domain on Piecewise" begin
    p = Piecewise(Domain{:closed,:closed}(0, 1) => Constant(1.0), Domain{:open,:closed}(1, 2) => identity)
    pgap = Piecewise(Domain{:closed,:closed}(0, 1) => Constant(1.0), Domain{:closed,:closed}(2, 3) => Constant(2.0))

    @test overlap_domain(Domain(interval(0.5, 0.6)), pgap)
    @test overlap_domain(Domain(interval(2.5, 2.6)), pgap)
    @test !overlap_domain(Domain(interval(1.5, 1.6)), pgap)
    @test !overlap_domain(Domain(interval(4, 5)), pgap)

    @test in_domain(Domain(interval(0.2, 0.5)), p)
    @test in_domain(Domain(interval(0.5, 1.5)), p)
    @test in_domain(Domain(interval(1.5, 2)), p)
    @test decoration(p(interval(0.2, 0.5))) === com

    @test in_domain(Domain(interval(0, 0.5)), p)
    @test in_domain(Domain(interval(0.2, 0.5)), pgap)
    @test in_domain(Domain(interval(2.2, 2.5)), pgap)
    @test decoration(pgap(interval(2.2, 2.5))) === com

    @test !in_domain(Domain(interval(0, 5)), p)
    @test !in_domain(Domain(interval(0.2, 2.5)), p)
    @test !in_domain(Domain(interval(0, 3)), pgap)
    @test !in_domain(Domain(interval(0.5, 2.5)), pgap)
end

@testset "Interval evaluation" begin
    myabs = Piecewise(
        Domain{:open,:closed}(-Inf, 0) => x -> -x,
        Domain{:open,:open}(0, Inf) => identity
    )

    @test isequal_interval(myabs(interval(-5, 5)), interval(0, 5))
    @test decoration(myabs(interval(-5, 5))) === def
    @test isequal_interval(myabs(interval(1, 2)), interval(1, 2))
    @test decoration(myabs(interval(1, 2))) === com
    @test isequal_interval(myabs(interval(-10, -1)), interval(1, 10))
    @test decoration(myabs(interval(-10, -1))) === com

    p = Piecewise(Domain{:closed,:closed}(0, 1) => Constant(1.0), Domain{:open,:closed}(1, 2) => identity)
    @test isempty_interval(p(interval(3, 4)))
    @test decoration(p(interval(3, 4))) === trv

    x = p(interval(-1, 0.5))
    @test isequal_interval(x, interval(1)) && decoration(x) === trv && isguaranteed(x)

    x = p(interval(0.5, 1.5))
    @test isequal_interval(x, interval(1, 1.5)) && decoration(x) === def && isguaranteed(x)

    x = p(interval(Float32, 0.25, 0.5))
    @test x isa Interval{Float32}
    @test isequal_interval(x, interval(Float32, 1, 1)) && decoration(x) === com && isguaranteed(x)

    @test !isguaranteed(p(convert(Interval{Float64}, 0.5)))
    @test !isguaranteed(p(convert(Interval{Float64}, 5)))

    trvpiece = Piecewise(
        Domain{:closed,:closed}(0, 1) => x -> hull(x, x),
        Domain{:open,:closed}(1, 2) => identity;
        continuity = [0]
    )
    @test decoration(trvpiece(interval(0.2, 0.4))) === trv

    myabs0 = Piecewise(
        Domain{:open,:closed}(-Inf, 0) => x -> -x,
        Domain{:open,:open}(0, Inf) => identity;
        continuity = [0]
    )
    @test decoration(myabs0(interval(-11, 11))) === com
    @test decoration(myabs0(interval(-11, 11, def))) === def

    pgap = Piecewise(Domain{:closed,:closed}(0, 1) => Constant(1.0), Domain{:closed,:closed}(2, 3) => Constant(2.0))
    x = pgap(interval(0.5, 2.5))
    @test isequal_interval(x, interval(1, 2)) && decoration(x) === trv
end

@testset "Real evaluation" begin
    myabs = Piecewise(
        Domain{:open,:closed}(-Inf, 0) => x -> -x,
        Domain{:open,:open}(0, Inf) => identity
    )

    @test myabs(-22.3) == 22.3
    @test myabs(3.0) == 3.0
    @test myabs(0.0) === -0.0

    p = Piecewise(Domain{:closed,:closed}(0, 1) => Constant(1.0), Domain{:open,:closed}(1, 2) => identity)
    err = try p(5.0) catch e; e end
    @test err isa DomainError
    @test err.msg == "piecewise function was called outside of its domain [0, 1] ∪ (1, 2]"
end

@testset "Step function" begin
    step = Piecewise(
        Domain{:open,:closed}(-Inf, 0) => Constant(0),
        Domain{:open,:open}(0, 1000) => Constant(1)
    )

    @test step(-1) == 0
    @test step(100) == 1
    @test isequal_interval(step(interval(-3.2, -2.1)), interval(0))
    @test decoration(step(interval(-3.33))) === com
    @test isequal_interval(step(interval(2.3, 3.4)), interval(1))
    @test decoration(step(interval(4.44))) === com
    @test isequal_interval(step(interval(-22.2, 33.3)), interval(0, 1))
    @test decoration(step(interval(-11, 11))) === def
    @test decoration(step(interval(500, 2000))) === trv
end

@testset "abs with continuity annotation" begin
    myabs = Piecewise(
        Domain{:open,:closed}(-Inf, 0) => x -> -x,
        Domain{:open,:open}(0, Inf) => identity;
        continuity = [0]
    )

    @test myabs(-1) == 1
    @test myabs(100) == 100
    @test isequal_interval(myabs(interval(-3.2, -2.1)), interval(2.1, 3.2))
    @test decoration(myabs(interval(-3.33))) === com
    @test isequal_interval(myabs(interval(2.3, 3.4)), interval(2.3, 3.4))
    @test decoration(myabs(interval(4.444))) === com
    @test isequal_interval(myabs(interval(-22.2, 33.3)), interval(0, 33.3))
    @test decoration(myabs(interval(-11, 11))) === com
end

@testset "Out of domain" begin
    window = Piecewise(
        Domain{:open,:closed}(-π, π) => x -> 1/2 * (cos(x) + 1)
    )

    @test_throws DomainError window(123)
    @test isequal_interval(window(interval(0, π)), interval(0, 1))
    # `-π` is `Float64(-π)`, a point of the input excluded by the open bound of the domain
    @test decoration(window(interval(-π, 0))) === trv
    @test decoration(window(interval(-3.14, 0))) === com
    @test isequal_interval(window(interval(-10, 10)), interval(0, 1))
    @test decoration(window(interval(-10, 10))) === trv
    @test isempty_interval(window(interval(100, 1000)))
end

@testset "Singularities" begin
    f = Piecewise(
        Domain{:open,:closed}(0, 1) => Constant(0),
        Domain{:open,:closed}(1, 2) => x -> 0.5x,
        Domain{:open,:closed}(2, 3) => Constant(1),
        Domain{:open,:open}(3, 4) => x -> (x-3)^2 + 1;
        continuity = [-1, 0, 1]
    )

    @test decoration(f(interval(0.5, 1.5))) === def
    @test decoration(f(interval(1.5, 2.5))) === com
    @test decoration(f(interval(2.5, 3.5))) === com
end
