using Test
using IntervalArithmetic

@testset "cancelminus bare intervals" begin
    z = cancelminus(bareinterval(1, 3), bareinterval(1, 2))
    @test isequal_interval(z, bareinterval(0, 1))
    @test issubset_interval(bareinterval(1, 3), bareinterval(1, 2) + z)

    @test isequal_interval(cancelminus(bareinterval(-5, 1), bareinterval(-1, 5)), bareinterval(-4, -4))
    @test isequal_interval(cancelminus(bareinterval(1, 2), bareinterval(1, 3)), entireinterval(BareInterval{Float64}))

    for x ∈ (bareinterval(1, 3), bareinterval(-2, 5), bareinterval(0.1, 1.1))
        @test isequal_interval(cancelminus(x, x), bareinterval(0, 0))
    end

    e = emptyinterval(BareInterval{Float64})
    entire = entireinterval(BareInterval{Float64})
    @test isequal_interval(cancelminus(e, e), e)
    @test isequal_interval(cancelminus(e, bareinterval(1, 2)), e)
    @test isequal_interval(cancelminus(e, entire), entire)
    @test isequal_interval(cancelminus(bareinterval(1, 2), e), entire)
    @test isequal_interval(cancelminus(entire, bareinterval(1, 2)), entire)
    @test isequal_interval(cancelminus(bareinterval(1, 2), entire), entire)
    @test isequal_interval(cancelminus(bareinterval(-Inf, -1), bareinterval(1, 2)), entire)
    @test isequal_interval(cancelminus(bareinterval(1, 2), bareinterval(-1, Inf)), entire)
    @test isequal_interval(cancelminus(bareinterval(-5.0, -1.0), bareinterval(-5.1, -1.0)), entire)

    z = cancelminus(bareinterval(-5.1, -0.9), bareinterval(-5.0, -1.0))
    @test issubset_interval(bareinterval(-5.1, -0.9), bareinterval(-5.0, -1.0) + z)
    @test bounds(z) == (-0.09999999999999964, 0.09999999999999998)
end

@testset "cancelminus corner cases" begin
    # IEEE 1788-2015 Section 9.2, page 62
    fm = floatmax(Float64)
    entire = entireinterval(BareInterval{Float64})

    @test isequal_interval(cancelminus(bareinterval(fm, fm), bareinterval(-fm, -fm)), bareinterval(fm, Inf))
    @test isequal_interval(cancelminus(bareinterval(-fm, -fm), bareinterval(fm, fm)), bareinterval(-Inf, -fm))

    @test isequal_interval(cancelminus(bareinterval(-fm, prevfloat(fm)), bareinterval(-fm, fm)), entire)
    @test isequal_interval(cancelminus(bareinterval(nextfloat(-fm), fm), bareinterval(-fm, fm)), entire)
    @test isequal_interval(cancelminus(bareinterval(-fm, fm), bareinterval(-fm, fm)), bareinterval(0, 0))
    @test isequal_interval(cancelminus(bareinterval(-fm, fm), bareinterval(-fm, prevfloat(fm))), bareinterval(0.0, 0x1p971))

    a = nextfloat(0.0)
    @test isequal_interval(cancelminus(bareinterval(a, a), bareinterval(-a, -a)), bareinterval(2a, 2a))
    b = floatmin(Float64)
    @test isequal_interval(cancelminus(bareinterval(b, nextfloat(b, 2)), bareinterval(b, nextfloat(b))), bareinterval(0.0, nextfloat(0.0)))
end

@testset "cancelminus bound types" begin
    @test cancelminus(bareinterval(Float32, 1, 3), bareinterval(1.0, 2.0)) isa BareInterval{Float64}
    @test isequal_interval(cancelminus(bareinterval(Float32, 1, 3), bareinterval(1.0, 2.0)), bareinterval(0, 1))
    @test isequal_interval(cancelminus(bareinterval(BigFloat, 1, 3), bareinterval(BigFloat, 1, 2)), bareinterval(BigFloat, 0, 1))
    # `prevfloat` has no `Rational` method, cf. src/intervals/interval_operations/cancellative.jl
    @test_throws MethodError cancelminus(bareinterval(1//1, 3//1), bareinterval(1//1, 2//1))
end

@testset "cancelplus" begin
    @test isequal_interval(cancelplus(bareinterval(1, 3), bareinterval(-2, -1)), bareinterval(0, 1))
    z = cancelplus(bareinterval(1, 3), bareinterval(-2, -1))
    @test issubset_interval(bareinterval(1, 3), z - bareinterval(-2, -1))
    @test isequal_interval(z, cancelminus(bareinterval(1, 3), bareinterval(1, 2)))

    x = interval(-2.0, 4.440892098500622e-16)
    y = interval(-4.440892098500624e-16, 2.0)
    @test isequal_interval(cancelminus(x, y), entireinterval(Float64))
    @test isequal_interval(cancelplus(x, y), entireinterval(Float64))
    x = interval(-big(1.0), eps(big(1.0))/4)
    y = interval(-eps(big(1.0))/2, big(1.0))
    @test isequal_interval(cancelminus(x, y), entireinterval(BigFloat))
    @test isequal_interval(cancelplus(x, y), entireinterval(BigFloat))
    x = interval(-big(1.0), eps(big(1.0))/2)
    y = interval(-eps(big(1.0))/2, big(1.0))
    @test issubset_interval(cancelminus(x, y), interval(-one(BigFloat), one(BigFloat)))
    @test isequal_interval(cancelplus(x, y), interval(zero(BigFloat), zero(BigFloat)))
    @test isequal_interval(cancelminus(emptyinterval(), emptyinterval()), emptyinterval())
    @test isequal_interval(cancelplus(emptyinterval(), emptyinterval()), emptyinterval())
    @test isequal_interval(cancelminus(emptyinterval(), interval(0.0, 5.0)), emptyinterval())
    @test isequal_interval(cancelplus(emptyinterval(), interval(0.0, 5.0)), emptyinterval())
    @test isequal_interval(cancelminus(entireinterval(), interval(0.0, 5.0)), entireinterval())
    @test isequal_interval(cancelplus(entireinterval(), interval(0.0, 5.0)), entireinterval())
    @test isequal_interval(cancelminus(interval(5.0), interval(-Inf, 0.0)), entireinterval())
    @test isequal_interval(cancelplus(interval(5.0), interval(-Inf, 0.0)), entireinterval())
    @test isequal_interval(cancelminus(interval(0.0, 5.0), emptyinterval()), entireinterval())
    @test isequal_interval(cancelplus(interval(0.0, 5.0), emptyinterval()), entireinterval())
    @test isequal_interval(cancelminus(interval(0.0), interval(0.0, 1.0)), entireinterval())
    @test isequal_interval(cancelplus(interval(0.0), interval(0.0, 1.0)), entireinterval())
    @test isequal_interval(cancelminus(interval(0.0), interval(1.0)), interval(-1.0))
    @test isequal_interval(cancelplus(interval(0.0), interval(1.0)), interval(1.0))
    @test isequal_interval(cancelminus(interval(-5.0, 0.0), interval(0.0, 5.0)), interval(-5.0))
    @test isequal_interval(cancelplus(interval(-5.0, 0.0), interval(0.0, 5.0)), interval(0.0))
end

@testset "decoration and guarantee" begin
    @test decoration(cancelminus(interval(1, 3), interval(1, 2))) == trv
    @test decoration(cancelminus(interval(1, 3), interval(1, 2); dec = :default)) == trv
    @test decoration(cancelminus(interval(1, 3), interval(1, 2); dec = :auto)) == com
    @test decoration(cancelminus(interval(1, 3), IntervalArithmetic.setdecoration(interval(1, 2), def); dec = :auto)) == def
    @test decoration(cancelminus(interval(1, 3), interval(1, 2); dec = com)) == com
    @test decoration(cancelminus(interval(1, 3), interval(1, 2); dec = def)) == def
    @test isnai(cancelminus(interval(1, 3), interval(1, 2); dec = ill))
    @test decoration(cancelminus(interval(1, 2), interval(1, 3); dec = com)) == dac
    @test decoration(cancelminus(emptyinterval(), interval(1, 2); dec = com)) == trv
    @test_throws ArgumentError cancelminus(interval(1, 3), interval(1, 2); dec = :bogus)

    r = @test_logs (:warn,) cancelminus(nai(), interval(1, 2))
    @test isnai(r)
    r = @test_logs (:warn,) cancelminus(interval(1, 2), nai())
    @test isnai(r)

    @test isguaranteed(cancelminus(interval(1, 3), interval(1, 2)))
    @test !isguaranteed(cancelminus(interval(1, 3), convert(Interval{Float64}, 1)))
    @test !isguaranteed(cancelminus(convert(Interval{Float64}, 1), interval(1, 3)))

    @test decoration(cancelplus(interval(1, 3), interval(-2, -1); dec = :auto)) == com
    @test decoration(cancelplus(interval(1, 3), interval(-2, -1); dec = def)) == def
    @test isnai(cancelplus(interval(1, 3), interval(-2, -1); dec = ill))

    z = complex(interval(1), interval(2))
    @test_throws MethodError cancelminus(z, z)
    @test_throws MethodError cancelplus(z, z)
    @test_throws MethodError cancelminus([interval(1)], [interval(1)])
end
