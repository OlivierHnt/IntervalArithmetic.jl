using Test
using IntervalArithmetic

@testset "_strictlessprime" begin
    @test IntervalArithmetic._strictlessprime(1, 2)
    @test !IntervalArithmetic._strictlessprime(2, 1)
    @test !IntervalArithmetic._strictlessprime(1, 1)
    @test IntervalArithmetic._strictlessprime(Inf, Inf)
    @test IntervalArithmetic._strictlessprime(-Inf, -Inf)
    @test !IntervalArithmetic._strictlessprime(Inf, -Inf)
end

@testset "isequal_interval" begin
    @test isequal_interval(bareinterval(1, 2), bareinterval(1, 2))
    @test !isequal_interval(bareinterval(1, 2), bareinterval(0, 2))
    @test !isequal_interval(bareinterval(1, 2), bareinterval(1, 3))
    @test isequal_interval(emptyinterval(BareInterval{Float64}), emptyinterval(BareInterval{Float64}))
    @test !isequal_interval(emptyinterval(BareInterval{Float64}), bareinterval(1, 2))
    @test isequal_interval(entireinterval(BareInterval{Float64}), entireinterval(BareInterval{Float64}))
    @test isequal_interval(bareinterval(-0.0, 1), bareinterval(0.0, 1))

    @test !isequal_interval(nai(), interval(1, 2))
    @test !isequal_interval(interval(1, 2), nai())
    @test !isequal_interval(nai(), nai())
    @test isequal_interval(emptyinterval(), emptyinterval())
    @test !isequal_interval(emptyinterval(), interval(0.1, 1.1))
    @test !isequal_interval(interval(0.1, 1.1), interval(0.9, 2.0))

    ng = convert(Interval{Float64}, 1) * interval(1, 2)
    @test !isguaranteed(ng)
    @test isequal_interval(interval(1, 2), ng)
    @test isequal_interval(interval(1, 2), IntervalArithmetic.setdecoration(interval(1, 2), trv))

    @test isequal_interval(interval(Float32, 1, 2), interval(1, 2))
    @test isequal_interval(emptyinterval(Rational{Int}), emptyinterval())

    @test isequal_interval(complex(interval(1), interval(2)), complex(interval(1), interval(2)))
    @test !isequal_interval(complex(interval(1), interval(2)), complex(interval(1), interval(3)))
    @test isequal_interval(complex(interval(1, 2), interval(0)), interval(1, 2))
    @test !isequal_interval(complex(interval(1, 2), interval(0, 1)), interval(1, 2))
    @test isequal_interval(interval(1, 2), complex(interval(1, 2), interval(0)))
    @test !isequal_interval(interval(1, 2), complex(interval(1, 2), interval(0, 1)))

    @test isequal_interval([interval(1), interval(2)], [interval(1), interval(2)])
    @test !isequal_interval([interval(1), interval(2)], [interval(1), interval(3)])
    @test_throws DimensionMismatch isequal_interval([interval(1)], [interval(1), interval(2)])

    a = interval(1, 2)
    b = interval(1, 3)
    @test isequal_interval(a, a, a)
    @test !isequal_interval(a, a, b)
    @test isequal_interval(a) isa Base.Fix2
    @test isequal_interval(a)(interval(1, 2))
    @test !isequal_interval(a)(b)

    @test issetequal_interval === isequal_interval
end

@testset "issubset_interval" begin
    @test issubset_interval(bareinterval(1, 2), bareinterval(0, 3))
    @test !issubset_interval(bareinterval(0, 3), bareinterval(1, 2))
    @test issubset_interval(bareinterval(1, 2), bareinterval(1, 2))
    e = emptyinterval(BareInterval{Float64})
    @test issubset_interval(e, bareinterval(1, 2))
    @test !issubset_interval(bareinterval(1, 2), e)
    @test issubset_interval(e, e)
    @test issubset_interval(entireinterval(BareInterval{Float64}), entireinterval(BareInterval{Float64}))
    @test issubset_interval(bareinterval(1, 2), entireinterval(BareInterval{Float64}))

    @test issubset_interval(interval(0.9, 2.0), interval(0.25, 4.0))
    @test issubset_interval(interval(0.9, 2.0), interval(0.9, 2.0))
    @test issubset_interval(emptyinterval(), interval(0.25, 4.0))
    @test !issubset_interval(interval(0.25, 4.0), emptyinterval())
    @test !issubset_interval(nai(), interval(1, 2))
    @test !issubset_interval(interval(1, 2), nai())

    c = complex(interval(-1, 4), interval(0, 2))
    @test issubset_interval(complex(interval(0), interval(1)), c)
    @test !issubset_interval(complex(interval(3), interval(4)), c)
    @test issubset_interval(complex(interval(1), interval(0)), interval(0, 2))
    @test !issubset_interval(complex(interval(1), interval(0, 1)), interval(0, 2))
    @test issubset_interval(interval(1), complex(interval(0, 2), interval(-1, 1)))
    @test !issubset_interval(interval(1), complex(interval(0, 2), interval(1, 2)))

    @test issubset_interval([interval(1), interval(2)], [interval(0, 2), interval(1, 3)])
    @test !issubset_interval([interval(1), interval(5)], [interval(0, 2), interval(1, 3)])
    @test_throws DimensionMismatch issubset_interval([interval(1)], [interval(1), interval(2)])

    @test issubset_interval(interval(1, 2), interval(0, 3), interval(-1, 4))
    @test !issubset_interval(interval(1, 2), interval(0, 3), interval(2, 4))
    @test_throws MethodError issubset_interval(interval(1, 2))
end

@testset "isstrictsubset" begin
    @test isstrictsubset(bareinterval(1, 2), bareinterval(0, 3))
    @test !isstrictsubset(bareinterval(1, 2), bareinterval(1, 2))
    @test isstrictsubset(bareinterval(1, 2), bareinterval(1, 3))
    e = emptyinterval(BareInterval{Float64})
    @test isstrictsubset(e, bareinterval(1, 2))
    @test !isstrictsubset(e, e)

    @test isstrictsubset(interval(1, 2), interval(0, 3))
    @test !isstrictsubset(interval(1, 2), interval(1, 2))
    @test !isstrictsubset(nai(), interval(1, 2))
    @test !isstrictsubset(interval(1, 2), nai())

    x = complex(interval(1, 2), interval(1, 2))
    @test isstrictsubset(x, complex(interval(1, 2), interval(0, 3)))
    @test isstrictsubset(x, complex(interval(0, 3), interval(1, 2)))
    @test !isstrictsubset(x, x)
    @test isstrictsubset(complex(interval(1), interval(0)), interval(0, 2))
    @test !isstrictsubset(complex(interval(1), interval(0, 1)), interval(0, 2))
    @test isstrictsubset(interval(1), complex(interval(0, 2), interval(-1, 1)))
    @test !isstrictsubset(interval(1), complex(interval(0, 2), interval(1, 2)))

    @test isstrictsubset([interval(1, 2), interval(1, 2)], [interval(1, 2), interval(0, 3)])
    @test !isstrictsubset([interval(1, 2), interval(1, 2)], [interval(1, 2), interval(1, 2)])

    @test isstrictsubset(interval(1, 2), interval(0, 3), interval(-1, 4))
    @test !isstrictsubset(interval(1, 2), interval(0, 3), interval(0, 3))
    @test isstrictsubset(interval(0, 3)) isa Base.Fix2
    @test isstrictsubset(interval(0, 3))(interval(1, 2))
end

@testset "isinterior" begin
    @test isinterior(bareinterval(1, 2), bareinterval(0, 3))
    @test !isinterior(bareinterval(1, 2), bareinterval(1, 3))
    e = emptyinterval(BareInterval{Float64})
    @test isinterior(e, e)
    @test isinterior(e, bareinterval(1, 2))
    @test !isinterior(bareinterval(1, 2), e)
    @test isinterior(entireinterval(BareInterval{Float64}), entireinterval(BareInterval{Float64}))
    @test isinterior(bareinterval(1, Inf), bareinterval(0, Inf))
    @test isinterior(bareinterval(-Inf, 1), bareinterval(-Inf, 2))

    @test isinterior(interval(0.9, 2.0), interval(0.25, 4.0))
    @test !isinterior(interval(0.9, 2.0), interval(0.9, 2.0))
    @test isinterior(emptyinterval(), interval(0.25, 4.0))
    @test !isinterior(interval(0.25, 4.0), emptyinterval())
    @test isinterior(emptyinterval(), emptyinterval())
    @test isinterior(interval(-Inf, Inf), interval(-Inf, Inf))
    @test !isinterior(nai(), interval(1, 2))
    @test !isinterior(interval(1, 2), nai())

    c = complex(interval(-1, 4), interval(0, 2))
    @test isinterior(complex(interval(0), interval(1)), c)
    @test !isinterior(complex(interval(3), interval(4)), c)
    @test !isinterior(complex(interval(1), interval(0)), interval(0, 2))
    @test isinterior(interval(1, 2), complex(interval(0, 3), interval(-1, 1)))
    @test !isinterior(interval(1, 2), complex(interval(0, 3), interval(0, 1)))

    @test isinterior([interval(1), interval(2)], [interval(0, 2), interval(1, 3)])
    @test !isinterior([interval(1), interval(2)], [interval(0, 2), interval(1, 2)])
    @test_throws DimensionMismatch isinterior([interval(1)], [interval(1), interval(2)])
    @test isinterior(interval(1, 2), interval(0, 3), interval(-1, 4))
    @test !isinterior(interval(1, 2), interval(0, 3), interval(0, 3))
end

@testset "isdisjoint_interval" begin
    @test isdisjoint_interval(bareinterval(1, 2), bareinterval(3, 4))
    @test !isdisjoint_interval(bareinterval(1, 2), bareinterval(2, 3))
    e = emptyinterval(BareInterval{Float64})
    @test isdisjoint_interval(e, bareinterval(1, 2))
    @test isdisjoint_interval(e, e)
    @test !isdisjoint_interval(entireinterval(BareInterval{Float64}), entireinterval(BareInterval{Float64}))
    @test !isdisjoint_interval(bareinterval(-Inf, 0), bareinterval(0, Inf))
    @test isdisjoint_interval(bareinterval(-Inf, -1), bareinterval(1, Inf))

    a = interval(0.1, 1.1)
    @test isdisjoint_interval(a, I"2.1")
    @test !isdisjoint_interval(a, interval(0.9, 2.0))
    @test isdisjoint_interval(emptyinterval(a), a)
    @test isdisjoint_interval(emptyinterval(), emptyinterval())
    @test !isdisjoint_interval(nai(), interval(1, 2))
    @test !isdisjoint_interval(interval(1, 2), nai())

    @test isdisjoint_interval(complex(interval(0), interval(1)), complex(interval(3), interval(4)))
    @test !isdisjoint_interval(complex(interval(0, 2), interval(0, 2)), complex(interval(1, 3), interval(1, 3)))
    @test isdisjoint_interval(complex(interval(1, 2), interval(1, 2)), interval(1, 2))
    @test !isdisjoint_interval(complex(interval(1, 2), interval(-1, 1)), interval(1, 2))
    @test isdisjoint_interval(interval(1, 2), complex(interval(1, 2), interval(1, 2)))
    @test !isdisjoint_interval(interval(1, 2), complex(interval(1, 2), interval(-1, 1)))

    @test isdisjoint_interval([interval(1, 2), interval(1, 2)], [interval(1, 2), interval(5, 6)])
    @test !isdisjoint_interval([interval(1, 2), interval(1, 2)], [interval(1, 2), interval(1, 2)])
    @test_throws DimensionMismatch isdisjoint_interval([interval(1)], [interval(1), interval(2)])

    @test isdisjoint_interval(interval(1, 2), interval(3, 4), interval(5, 6))
    @test !isdisjoint_interval(interval(1, 2), interval(3, 4), interval(1, 6))
    @test !isdisjoint_interval(interval(1, 2), interval(3, 4), interval(5, 6), interval(1, 2))
    @test IntervalArithmetic._isdisjoint_interval(interval(1, 2))
end

@testset "isweakless and isstrictless" begin
    @test isweakless(bareinterval(1, 2), bareinterval(1, 3))
    @test !isweakless(bareinterval(1, 2), bareinterval(0, 3))
    e = emptyinterval(BareInterval{Float64})
    @test isweakless(e, e)

    @test isweakless(emptyinterval(), emptyinterval())
    @test !isweakless(interval(1, 2), emptyinterval())
    @test isweakless(interval(-Inf, Inf), interval(-Inf, Inf))
    @test isweakless(interval(0.1, 2), interval(2))
    @test !isweakless(nai(), interval(1, 2))
    @test_throws MethodError isweakless(complex(interval(1), interval(2)), complex(interval(1), interval(2)))
    @test_throws MethodError isweakless([interval(1)], [interval(1)])

    @test !isstrictless(bareinterval(1, 2), bareinterval(1, 3))
    @test isstrictless(bareinterval(1, 2), bareinterval(2, 3))
    @test isstrictless(entireinterval(BareInterval{Float64}), entireinterval(BareInterval{Float64}))
    @test isstrictless(bareinterval(-Inf, 1), bareinterval(-Inf, 2))

    @test isstrictless(interval(0.1, 2), interval(3))
    @test isstrictless(interval(-1), interval(0.1, 2))
    @test !isstrictless(nai(), interval(1, 2))
end

@testset "precedes and strictprecedes" begin
    @test precedes(bareinterval(1, 2), bareinterval(2, 3))
    @test !precedes(bareinterval(1, 2), bareinterval(1.5, 3))

    @test precedes(emptyinterval(), emptyinterval())
    @test precedes(interval(3, 4), emptyinterval())
    @test precedes(emptyinterval(), interval(3, 4))
    @test !precedes(interval(0, 2), interval(-Inf, Inf))
    @test precedes(interval(1, 3), interval(3, 4))
    @test !precedes(nai(), interval(1, 2))

    @test !strictprecedes(bareinterval(1, 2), bareinterval(2, 3))
    @test strictprecedes(bareinterval(1, 2), bareinterval(2.5, 3))

    @test strictprecedes(interval(3, 4), emptyinterval())
    @test strictprecedes(emptyinterval(), interval(3, 4))
    @test !strictprecedes(interval(-3, -1), interval(-1, 0))
    @test !strictprecedes(nai(), interval(1, 2))
end

@testset "in_interval" begin
    @test in_interval(1, bareinterval(0, 2))
    @test in_interval(0, bareinterval(0, 2))
    @test in_interval(2, bareinterval(0, 2))
    @test !in_interval(3, bareinterval(0, 2))

    @test !in_interval(Inf, entireinterval())
    @test !in_interval(-Inf, entireinterval())
    @test !in_interval(Inf, entireinterval(BareInterval{Float64}))
    @test !in_interval(Inf, bareinterval(1, Inf))
    @test !in_interval(-Inf, bareinterval(-Inf, 1))
    @test in_interval(0.1, I"0.1")

    @test !in_interval(0, emptyinterval(BareInterval{Float64}))
    @test !in_interval(1, emptyinterval())

    @test in_interval(1 + 0im, bareinterval(0, 2))
    @test !in_interval(1 + 1im, bareinterval(0, 2))
    @test_throws MethodError in_interval(interval(1), bareinterval(0, 2))
    @test_throws ArgumentError in_interval(bareinterval(1, 2), bareinterval(0, 2))
    @test_throws ArgumentError in_interval(interval(3, 4), interval(3, 4))

    @test !in_interval(1, nai())

    c = complex(interval(-1, 4), interval(0, 2))
    @test in_interval(3 + 2im, c)
    @test !in_interval(3 + 3im, c)
    @test in_interval(1, complex(interval(0, 2), interval(-1, 1)))
    @test !in_interval(1, complex(interval(0, 2), interval(1, 2)))

    @test in_interval(bareinterval(0, 2)) isa Base.Fix2
    @test in_interval(bareinterval(0, 2))(1)
    @test in_interval(interval(0, 2))(1)

    @test in_interval(1//3, bareinterval(0, 1))
    @test in_interval(1//3, bareinterval(0//1, 1//1))
    @test in_interval(big(1)/big(3), bareinterval(BigFloat, 0, 1))
end

@testset "isempty_interval and isentire_interval" begin
    @test isempty_interval(emptyinterval(BareInterval{Float64}))
    @test isempty_interval(IntervalArithmetic._unsafe_bareinterval(Float64, typemax(Float64), typemin(Float64)))
    @test !isempty_interval(bareinterval(1, 2))
    @test !isempty_interval(entireinterval(BareInterval{Float64}))
    @test isempty_interval(emptyinterval())
    @test !isempty_interval(interval(0.1, 1.1))
    @test !isempty_interval(nai())
    @test isempty_interval(complex(emptyinterval(), interval(1)))
    @test !isempty_interval(complex(interval(1), interval(2)))
    @test isempty_interval([interval(1), emptyinterval()])
    @test !isempty_interval([interval(1), interval(2)])

    @test isentire_interval(entireinterval(BareInterval{Float64}))
    @test isentire_interval(entireinterval(BareInterval{Rational{Int64}}))
    @test !isentire_interval(bareinterval(1, Inf))
    @test !isentire_interval(emptyinterval(BareInterval{Float64}))
    @test isentire_interval(entireinterval(interval(0.1, 1.1)))
    @test isentire_interval(interval(-Inf, Inf))
    @test !isentire_interval(interval(0.1, 1.1))
    @test !isentire_interval(nai())
    @test isentire_interval(complex(entireinterval(), entireinterval()))
    @test !isentire_interval(complex(entireinterval(), interval(1)))
end

@testset "isnai" begin
    @test !isnai(bareinterval(1, 2))
    @test !isnai(emptyinterval(BareInterval{Float64}))
    @test isnai(nai())
    @test !isnai(emptyinterval())
    @test !isnai(interval(0.1, 1.1))
    x = @test_logs (:warn,) interval(NaN)
    @test isnai(x)
    x = @test_logs (:warn,) (:warn,) convert(Interval{Float64}, NaN)
    @test isnai(x)
    x = @test_logs (:warn,) interval(Inf)
    @test isnai(x)
    @test isnai(complex(nai(), nai()))
    @test !isnai(complex(nai(), interval(1)))
end

@testset "isbounded, isunbounded and iscommon" begin
    @test isbounded(emptyinterval(BareInterval{Float64}))
    @test !isbounded(entireinterval(BareInterval{Float64}))
    @test !isbounded(bareinterval(1, Inf))
    @test isbounded(bareinterval(1, 2))
    @test !isunbounded(emptyinterval(BareInterval{Float64}))
    @test isunbounded(entireinterval(BareInterval{Float64}))

    @test !isunbounded(emptyinterval())
    @test isunbounded(entireinterval())
    @test isunbounded(interval(-Inf, 0))
    @test isunbounded(interval(0, Inf))
    @test !isunbounded(interval(0.1, 1.1))
    @test !isbounded(nai())
    @test !isunbounded(nai())
    @test isbounded(complex(interval(1), interval(2)))
    @test !isbounded(complex(interval(1), entireinterval()))
    @test isunbounded(complex(interval(1), entireinterval()))
    @test !isunbounded(complex(interval(1), interval(2)))

    @test !iscommon(emptyinterval())
    @test !iscommon(entireinterval())
    @test !iscommon(interval(1, Inf))
    @test iscommon(interval(0.1, 1.1))
    @test iscommon(IntervalArithmetic.setdecoration(interval(1, 2), trv))
    @test !iscommon(nai())
    @test !iscommon(emptyinterval(BareInterval{Float64}))
    @test !iscommon(entireinterval(BareInterval{Float64}))
    @test iscommon(bareinterval(1, 2))
    @test iscommon(complex(interval(1), interval(2)))
    @test !iscommon(complex(interval(1), entireinterval()))
end

@testset "isatomic" begin
    @test isatomic(emptyinterval(BareInterval{Float64}))
    @test isatomic(bareinterval(1, 1))
    @test isatomic(bareinterval(0.1, nextfloat(0.1)))
    @test !isatomic(bareinterval(0, 1))
    @test !isatomic(entireinterval(BareInterval{Float64}))

    @test isatomic(emptyinterval(BareInterval{Rational{Int}}))
    @test isatomic(bareinterval(1//2, 1//2))
    @test !isatomic(bareinterval(1//1, 2//1))

    @test isatomic(interval(1))
    @test isatomic(interval(2.3, 2.3))
    @test isatomic(emptyinterval())
    @test !isatomic(interval(1, 2))
    @test !isatomic(interval(1, nextfloat(1.0, 2)))
    @test !isatomic(nai())
    @test isatomic(complex(interval(1), interval(2)))
    @test !isatomic(complex(interval(1), interval(1, 2)))
end

@testset "isthin" begin
    @test isthin(bareinterval(1, 1))
    @test !isthin(bareinterval(1, 2))
    @test !isthin(emptyinterval(BareInterval{Float64}))
    @test !isthin(nai())
    @test isthin(complex(interval(1), interval(2)))
    @test !isthin(complex(interval(1), interval(1, 2)))

    @test isthin(bareinterval(1, 1), 1)
    @test !isthin(bareinterval(1, 1), 2)
    @test !isthin(bareinterval(1, 2), 1)
    @test !isthin(emptyinterval(BareInterval{Float64}), 1)
    @test isthin(bareinterval(1, 1), 1 + 0im)
    @test !isthin(bareinterval(1, 1), 1 + 1im)
    @test_throws ArgumentError isthin(bareinterval(1, 1), interval(1))
    @test isthin(interval(1), 1)
    @test !isthin(nai(), 1)
    @test isthin(complex(interval(1), interval(0)), 1)
    @test !isthin(complex(interval(1), interval(1)), 1)
    @test isthin(complex(interval(1), interval(2)), 1 + 2im)
end

@testset "isthinzero, isthinone and isthininteger" begin
    @test isthinzero(bareinterval(0, 0))
    @test isthinzero(bareinterval(-0.0, 0.0))
    @test !isthinzero(bareinterval(0, 1))
    @test !isthinzero(emptyinterval(BareInterval{Float64}))
    @test !isthinzero(nai())
    @test isthinzero(interval(0))
    @test isthinzero(interval(Rational{Int}, 0//1))
    @test isthinzero(interval(big(0)))
    @test isthinzero(interval(-0.0))
    @test isthinzero(interval(-0.0, 0.0))
    @test !isthinzero(interval(1, 2))
    @test !isthinzero(interval(0.0, nextfloat(0.0)))
    @test isthinzero(complex(interval(0), interval(0)))
    @test !isthinzero(complex(interval(0), interval(1)))

    @test isthinone(bareinterval(1, 1))
    @test !isthinone(bareinterval(1, 2))
    @test !isthinone(nai())
    @test isthinone(complex(interval(1), interval(0)))
    @test !isthinone(complex(interval(1), interval(1)))

    @test isthininteger(bareinterval(2, 2))
    @test !isthininteger(bareinterval(2.5, 2.5))
    @test !isthininteger(bareinterval(1, 2))
    @test !isthininteger(emptyinterval(BareInterval{Float64}))
    @test !isthininteger(nai())
    @test isthininteger(bareinterval(2//1, 2//1))
    @test !isthininteger(bareinterval(1//2, 1//2))
    @test isthininteger(complex(interval(2), interval(0)))
    @test !isthininteger(complex(interval(2), interval(1)))
end

@testset "no warning on NaI input" begin
    n = nai()
    x = interval(1, 2)
    for f ∈ (isequal_interval, issubset_interval, isstrictsubset, isinterior,
             isdisjoint_interval, isweakless, isstrictless, precedes, strictprecedes)
        @test !(@test_logs f(n, x))
        @test !(@test_logs f(x, n))
    end
    for f ∈ (isempty_interval, isentire_interval, isbounded, isunbounded,
             iscommon, isatomic, isthin, isthinzero, isthinone, isthininteger)
        @test !(@test_logs f(n))
    end
    @test !(@test_logs in_interval(1, n))
    @test @test_logs isnai(n)
end
