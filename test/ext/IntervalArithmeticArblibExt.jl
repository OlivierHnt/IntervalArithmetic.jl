using Test
using IntervalArithmetic
import Arblib
using Arblib: Arf, ArfRef, Arb, ArbRef, Acb, AcbRef, setball

# Flint < 3.3.0 returns NaN from getinterval on balls with infinite midpoint and radius
broken_getinterval = isnan(Arblib.getinterval(setball(Arb, -Inf, Inf))[2])

@testset "Promotion rules" begin
    @test promote_type(Arf, Interval{Float64}) == Interval{Arf}
    @test promote_type(Arf, Interval{BigFloat}) == Interval{Arf}
    @test promote_type(Arf, Interval{Rational{Int}}) == Interval{Arf}
    @test promote_type(ArfRef, Interval{Float64}) == Interval{Arf}
    @test promote_type(ArfRef, Interval{BigFloat}) == Interval{Arf}
    @test promote_type(ArfRef, Interval{Rational{Int}}) == Interval{Arf}
    @test promote_type(Interval{Float64}, Arf) == Interval{Arf}
    @test promote_type(Interval{BigFloat}, Arf) == Interval{Arf}
    @test promote_type(Interval{Rational{Int}}, Arf) == Interval{Arf}
    @test promote_type(Interval{Float64}, ArfRef) == Interval{Arf}
    @test promote_type(Interval{BigFloat}, ArfRef) == Interval{Arf}
    @test promote_type(Interval{Rational{Int}}, ArfRef) == Interval{Arf}
    @test promote_type(Interval{Float32}, ArfRef) == Interval{Arf}

    @test_throws ArgumentError promote_type(Arb, Interval{Float64})
    @test_throws ArgumentError promote_type(Arb, Interval{BigFloat})
    @test_throws ArgumentError promote_type(Arb, Interval{Arf})
    @test_throws ArgumentError promote_type(Arb, Interval{Arb})
    @test_throws ArgumentError promote_type(ArbRef, Interval{Float64})
    @test_throws ArgumentError promote_type(ArbRef, Interval{BigFloat})
    @test_throws ArgumentError promote_type(ArbRef, Interval{Arf})
    @test_throws ArgumentError promote_type(ArbRef, Interval{Arb})
    @test_throws ArgumentError promote_type(Interval{Float64}, Arb)
    @test_throws ArgumentError promote_type(Interval{BigFloat}, Arb)
    @test_throws ArgumentError promote_type(Interval{Arf}, Arb)
    @test_throws ArgumentError promote_type(Interval{Arb}, Arb)
    @test_throws ArgumentError promote_type(Interval{Float64}, ArbRef)
    @test_throws ArgumentError promote_type(Interval{BigFloat}, ArbRef)
    @test_throws ArgumentError promote_type(Interval{Arf}, ArbRef)
    @test_throws ArgumentError promote_type(Interval{Arb}, ArbRef)
end

@testset "promote_numtype" begin
    @test IntervalArithmetic.promote_numtype(Arb, Arb) == BigFloat
    @test IntervalArithmetic.promote_numtype(Arb, ArbRef) == BigFloat
    @test IntervalArithmetic.promote_numtype(ArbRef, Arb) == BigFloat
    @test IntervalArithmetic.promote_numtype(ArbRef, ArbRef) == BigFloat

    @test IntervalArithmetic.promote_numtype(Arb, Float64) == BigFloat
    @test IntervalArithmetic.promote_numtype(Float64, Arb) == BigFloat
    @test IntervalArithmetic.promote_numtype(Arb, Float32) == BigFloat
    @test IntervalArithmetic.promote_numtype(ArbRef, Float64) == BigFloat
    @test IntervalArithmetic.promote_numtype(Arb, Rational{Int}) == BigFloat
    @test IntervalArithmetic.promote_numtype(ArbRef, Rational{Int}) == BigFloat
    @test IntervalArithmetic.promote_numtype(Arb, Int) == BigFloat
    @test IntervalArithmetic.promote_numtype(Int, Arb) == BigFloat

    @test IntervalArithmetic.promote_numtype(Arb, Arf) == Arf
    @test IntervalArithmetic.promote_numtype(ArbRef, Arf) == Arf
    @test IntervalArithmetic.promote_numtype(Arb, ArfRef) == Arf
    @test IntervalArithmetic.promote_numtype(ArbRef, ArfRef) == Arf
end

@testset "Single argument constructor" begin
    xs = Arb[0, 1, π, ℯ, 1//3, Arb((1, 2)), Arb((-Inf, Inf)), setball(Arb, 5, Inf)]

    for x ∈ xs
        @test interval(x) isa Interval{BigFloat}
        @test isguaranteed(interval(x))

        for T ∈ [BigFloat, Arf, Float64, Float32]
            y = interval(T, x)
            @test y isa Interval{T}
            @test !isnai(y)
            @test isbounded(y) == isfinite(x)
            @test Arblib.contains(Arb(y), x)
        end
    end

    x = interval(Arb(π; prec = 64))
    @test in_interval(π, x)
    @test decoration(x) === com
    @test isguaranteed(x)
    xf = interval(Float64, Arb(π; prec = 64))
    @test isequal_interval(xf, interval(3.141592653589793, 3.1415926535897936))
    @test decoration(xf) === com
    @test isguaranteed(xf)

    @test IntervalArithmetic._inf(Arb((1, 2))) == BigFloat(Arblib.lbound(Arb((1, 2))))
    @test IntervalArithmetic._sup(Arb((1, 2))) == BigFloat(Arblib.ubound(Arb((1, 2))))

    @test isnai(@test_logs (:warn,) interval(Arb(-Inf)))
    @test isnai(@test_logs (:warn,) interval(Arb(Inf)))
    @test isnai(@test_logs (:warn,) interval(Arb(NaN)))
end

@testset "Two argument constructor" begin
    as1 = Real[0, 1, ℯ, 1//3, 0.1, BigFloat(1.1), BigInt(3)]
    bs1 = Real[3, π, 7//2, BigFloat(4.1), BigInt(4)]

    for a ∈ as1
        for b ∈ bs1
            a_Arb = Arb(a)
            b_Arb = Arb(b)

            y1 = interval(a, b_Arb)
            y2 = interval(a_Arb, b)
            y3 = interval(a_Arb, b_Arb)

            @test y1 isa Interval{BigFloat}
            @test y2 isa Interval{BigFloat}
            @test y3 isa Interval{BigFloat}

            for y ∈ (y1, y2, y3)
                @test Arblib.overlaps(Arb(y), a_Arb)
                @test Arblib.overlaps(Arb(y), b_Arb)
            end

            for T ∈ [BigFloat, Float64, Float32]
                y1 = interval(T, a, b_Arb)
                y2 = interval(T, a_Arb, b)
                y3 = interval(T, a_Arb, b_Arb)

                @test y1 isa Interval{T}
                @test y2 isa Interval{T}
                @test y3 isa Interval{T}

                for y ∈ (y1, y2, y3)
                    @test Arblib.overlaps(Arb(y), a_Arb)
                    @test Arblib.overlaps(Arb(y), b_Arb)
                end
            end
        end
    end

    @test isequal_interval(
        interval(interval(1, 3), interval(2, 4)),
        interval(setball(Arb, 2, 1), setball(Arb, 3, 1)),
    )
    @test isequal_interval(
        interval(interval(1, 3), interval(0, 4)),
        interval(setball(Arb, 2, 1), setball(Arb, 2, 2)),
    )
    @test isequal_interval(
        interval(interval(1, 5), interval(2, 4)),
        interval(setball(Arb, 3, 2), setball(Arb, 3, 1)),
    )

    as2 = [Arb(-Inf), Arb((-Inf, Inf)), setball(Arb, 0, Inf)]
    bs2 = [Arb(Inf), Arb((-Inf, Inf)), setball(Arb, 0, Inf)]

    for a ∈ as2
        for b ∈ bs2
            broken =
                broken_getinterval && (
                    isequal(a, setball(Arb, Inf, Inf)) ||
                    isequal(b, setball(Arb, -Inf, Inf))
                )
            @test isequal_interval(interval(a, b), interval(-Inf, Inf)) broken = broken
        end
    end

    for a ∈ as2
        broken = broken_getinterval && isequal(a, setball(Arb, Inf, Inf))
        @test isequal_interval(interval(a, Inf), interval(-Inf, Inf)) broken = broken
    end

    for b ∈ bs2
        broken = broken_getinterval && isequal(b, setball(Arb, -Inf, Inf))
        @test isequal_interval(interval(-Inf, b), interval(-Inf, Inf)) broken = broken
    end

    @test isnai(@test_logs (:warn,) interval(Arb(-Inf), Arb(-Inf)))
    @test isnai(@test_logs (:warn,) interval(-Inf, Arb(-Inf)))
    @test isnai(@test_logs (:warn,) interval(Arb(-Inf), -Inf))
    @test isnai(@test_logs (:warn,) interval(setball(Arb, -Inf, 1), Arb(-Inf)))
    @test isnai(@test_logs (:warn,) interval(Arb(-Inf), setball(Arb, -Inf, 1)))
    @test isnai(@test_logs (:warn,) interval(Arb(Inf), Arb(Inf)))
    @test isnai(@test_logs (:warn,) interval(Inf, Arb(Inf)))
    @test isnai(@test_logs (:warn,) interval(Arb(Inf), Inf))
    @test isnai(@test_logs (:warn,) interval(setball(Arb, Inf, 1), Arb(Inf)))
    @test isnai(@test_logs (:warn,) interval(Arb(Inf), setball(Arb, Inf, 1)))

    @test isnai(@test_logs (:warn,) interval(Arb(NaN), 0))
    @test isnai(@test_logs (:warn,) interval(setball(Arb, NaN, Inf), 0))
    @test isnai(@test_logs (:warn,) interval(Arb(NaN), -Inf))
    @test isnai(@test_logs (:warn,) interval(Arb(NaN), Inf))
    @test isnai(@test_logs (:warn,) interval(0, Arb(NaN)))
    @test isnai(@test_logs (:warn,) interval(0, setball(Arb, NaN, Inf)))
    @test isnai(@test_logs (:warn,) interval(-Inf, Arb(NaN)))
    @test isnai(@test_logs (:warn,) interval(Inf, Arb(NaN)))

    @test isnai(@test_logs (:warn,) interval(Arb(2), Arb(1)))

    @test isequal_interval(
        interval(setball(Arb, 0, 1), format = :midpoint),
        interval(-1, 1),
    )
    @test isequal_interval(
        interval(setball(Arb, 0, 1), setball(Arb, 4, 1), format = :midpoint),
        interval(-6, 6),
    )
    @test_throws DomainError interval(0, Arb((-1, 1)), format = :midpoint)
end

@testset "Complex intervals" begin
    @test numtype(Acb) === Arb
    @test numtype(AcbRef) === Arb

    z = interval(Acb(1, 2))
    @test z isa Complex{Interval{BigFloat}}
    @test isequal_interval(z, complex(interval(1, 1), interval(2, 2)))
    @test isequal_interval(interval(Acb(1, 2), Acb(3, 4)), complex(interval(1, 3), interval(2, 4)))

    @test isequal_interval(
        interval(1 + 2im, 3 + 4im),
        interval(Acb(setball(Arb, 2, 1), setball(Arb, 3, 1))),
    )
    @test isequal_interval(
        interval(Float64, 1 + 2im, 3 + 4im),
        interval(Acb(setball(Arb, 2, 1), setball(Arb, 3, 1))),
    )

    @test isequal_interval(interval(1 + 2im, 3 + 4im), interval(Acb(1, 2), Acb(3, 4)))

    @test isequal_interval(interval(1 + 2im, 3 + 4im), interval(Acb(1, 2), 3 + 4im))
    @test isequal_interval(interval(1 - 2im, 3), interval(Acb(1, -2), 3))
    @test isequal_interval(interval(1 - 2im, 3), interval(Acb(1, -2), interval(3, 3)))

    @test isequal_interval(interval(1 + 2im, 3 + 4im), interval(1 + 2im, Acb(3, 4)))
    @test isequal_interval(interval(1, 3 + 2im), interval(1, Acb(3, 2)))
    @test isequal_interval(interval(1, 3 + 2im), interval(interval(1), Acb(3, 2)))

    # the BareInterval ambiguity methods dispatch but real(::BareInterval) is undefined
    @test_throws MethodError interval(Acb(1, 2), bareinterval(3, 4))
    @test_throws MethodError interval(bareinterval(1, 2), Acb(3, 4))
end

@testset "convert" begin
    @test isguaranteed(convert(Interval{Float64}, Arb(1)))
    @test isguaranteed(convert(Interval{Float64}, Acb(1)))
    @test_throws DomainError convert(Interval{Float64}, Acb(1, 1))

    @test isequal_interval(convert(Interval{Float64}, Arb(1)), interval(Float64, Arb(1)))
    @test isequal_interval(convert(Interval{Float64}, Acb(1, 0)), interval(1))

    @test isguaranteed(convert(Complex{Interval{Float64}}, Arb(1)))
    @test isguaranteed(convert(Complex{Interval{Float64}}, Acb(1)))
    @test isguaranteed(convert(Complex{Interval{Float64}}, Acb(1, 1)))
    @test isequal_interval(convert(Complex{Interval{Float64}}, Arb(1)), complex(interval(1), interval(0)))

    v = [interval(0.0), interval(0.0)]
    v[1] = Arb(1)
    @test isguaranteed(v[1])
    @test isequal_interval(v[1], interval(1))
end

@testset "Arb from Interval" begin
    @test isequal(Arb((0, 1)), Arb(interval(0, 1)))
    @test isequal(setball(Arb, NaN, Inf), Arb(nai(Float64)))
    @test Arblib.overlaps(Arb(π), Arb(interval(π)))
    @test Arblib.overlaps(Arb(π), Arb(interval(BigFloat, π)))
    @test isequal(Arblib.indeterminate!(Arb()), Arb(emptyinterval()))
    @test isequal(Arblib.indeterminate!(Arb()), Arb(emptyinterval(BareInterval{BigFloat})))
    @test isequal(Acb(1, 2), Acb(interval(1 + 2im)))

    a = Arb(interval(BigFloat, 1, 2))
    @test Arblib.lbound(a) <= 1
    @test Arblib.ubound(a) >= 2

    x = interval(BigFloat, 1, 2)
    @test issubset_interval(x, interval(Arb(x)))

    @test isequal(Arb((0, 1)), Arblib.set!(Arb(), interval(0, 1)))
    @test isequal(setball(Arb, NaN, Inf), Arblib.set!(Arb(), nai(Float64)))
    @test isequal(Arb(interval(π)), Arblib.set!(Arb(), interval(π)))
    @test isequal(Arb(interval(BigFloat, π)), Arblib.set!(Arb(), interval(BigFloat, π)))
    @test isequal(Arblib.indeterminate!(Arb()), Arblib.set!(Arb(), emptyinterval()))
    @test isequal(Acb(1, 2), Arblib.set!(Acb(), interval(1 + 2im)))
    r = Arb()
    @test Arblib.set!(r, interval(BigFloat, π), prec = 64) === r
    @test Arblib.contains_interior(
        Arblib.set!(Arb(), interval(BigFloat, π), prec = 64),
        Arb(interval(BigFloat, π)),
    )

    @test Arblib._precision(interval(1, 2)) == precision(Arb)
    @test Arblib._precision(interval(1, 2)) == Arblib._precision(inf(interval(1, 2)), sup(interval(1, 2)))
    @test Arblib._precision(bareinterval(BigFloat(1), BigFloat(2))) == Arblib._precision(BigFloat(1), BigFloat(2))
    @test Arblib._precision(interval(BigFloat, BigFloat(1, precision = 80))) == 80
    @test Arblib._precision(
        interval(BigFloat, BigFloat(1, precision = 80), BigFloat(1, precision = 64)),
    ) == 80
    @test Arblib._precision(
        interval(BigFloat, BigFloat(1, precision = 64), BigFloat(1, precision = 80)),
    ) == 80

    @test precision(
        Arb(interval(BigFloat(1, precision = 80), BigFloat(2, precision = 64))),
    ) == 80
    @test precision(Arb(interval(Arf(0, prec = 64), Arf(1, prec = 80)))) == 80
end

@testset "ExactReal" begin
    @test Arblib.Mag(exact(5)) == Arblib.Mag(5)
    @test Arf(exact(5)) == Arf(5)
    @test Arb(exact(5)) == Arb(5)
    @test Arblib.Mag(exact(2.0)) == Arblib.Mag(2.0)
    @test Arf(exact(2.0)) == 2
    @test Arb(exact(2.0)) == 2

    @test promote_type(Arf, ExactReal{Float64}) == Arf
    @test promote_type(ArfRef, ExactReal{Float64}) == Arf
    @test promote_type(ExactReal{Float64}, Arf) == Arf
    @test promote_type(ExactReal{Float64}, ArfRef) == Arf

    @test promote_type(Arb, ExactReal{Float64}) == Arb
    @test promote_type(ArbRef, ExactReal{Float64}) == Arb
    @test promote_type(ExactReal{Float64}, Arb) == Arb
    @test promote_type(ExactReal{Float64}, ArbRef) == Arb

    s = exact(2.0) + Arb(1)
    @test s isa Arb
    @test s == 3
    t = exact(2.0) + Arf(1)
    @test t isa Arf
    @test t == 3
end
