using Test
using IntervalArithmetic

@testset "emptyinterval" begin
    @test bounds(emptyinterval(BareInterval{Float64})) === (Inf, -Inf)
    @test bounds(emptyinterval(BareInterval{Float32})) === (Inf32, -Inf32)
    @test bounds(emptyinterval(BareInterval{Rational{Int64}})) == (1//0, -1//0)
    for T ∈ (Float16, Float32, Float64, BigFloat, Rational{Int32}, Rational{Int64})
        @test isempty_interval(emptyinterval(BareInterval{T}))
    end
    @test emptyinterval(bareinterval(1, 2)) === emptyinterval(BareInterval{Float64})

    x = emptyinterval(Interval{Float64})
    @test decoration(x) == trv
    @test isguaranteed(x)
    @test isempty_interval(x)
    @test emptyinterval(interval(1, 2)) === x

    ng = convert(Interval{Float64}, 1)
    @test !isguaranteed(emptyinterval(ng))
    @test isempty_interval(emptyinterval(ng))

    @test emptyinterval(Float32) isa Interval{Float32}
    @test emptyinterval(Rational{Int}) isa Interval{Rational{Int}}
    @test emptyinterval(1.0) isa Interval{Float64}
    @test emptyinterval(1//2) isa Interval{Rational{Int}}

    z = emptyinterval(Complex{Interval{Float64}})
    @test z isa Complex{Interval{Float64}}
    @test isempty_interval(real(z)) & isempty_interval(imag(z))
    @test emptyinterval(Complex{Float64}) isa Complex{Interval{Float64}}
    @test emptyinterval(complex(1.0, 2.0)) isa Complex{Interval{Float64}}
    z = emptyinterval(complex(interval(1), ng))
    @test isguaranteed(real(z)) & !isguaranteed(imag(z))

    @test typeof(emptyinterval()) == Interval{Float64}
    @test isequal_interval(emptyinterval(Rational{Int}), emptyinterval())
    @test_throws MethodError emptyinterval(Int)
end

@testset "entireinterval" begin
    @test bounds(entireinterval(BareInterval{Float64})) === (-Inf, Inf)
    @test bounds(entireinterval(BareInterval{Rational{Int64}})) == (-1//0, 1//0)
    @test isentire_interval(entireinterval(BareInterval{Float64}))
    @test entireinterval(bareinterval(1, 2)) === entireinterval(BareInterval{Float64})

    x = entireinterval(Interval{Float64})
    @test decoration(x) == dac
    @test isguaranteed(x)
    @test isentire_interval(x)

    a = interval(0.1, 1.1)
    @test isentire_interval(entireinterval(a))
    @test isequal_interval(entireinterval(Float64), interval(-Inf, Inf))
    @test isentire_interval(interval(-Inf, Inf))
    @test !isentire_interval(a)

    ng = convert(Interval{Float64}, 1)
    @test !isguaranteed(entireinterval(ng))

    @test entireinterval(Float32) isa Interval{Float32}
    @test entireinterval(1.0) isa Interval{Float64}
    @test entireinterval(Complex{Float64}) isa Complex{Interval{Float64}}
    z = entireinterval(complex(interval(1), ng))
    @test isguaranteed(real(z)) & !isguaranteed(imag(z))
    @test isentire_interval(entireinterval(Complex{Interval{Float64}}))

    @test entireinterval() === entireinterval(Interval{Float64})
    @test bounds(entireinterval()) === (-Inf, Inf)
    @test decoration(entireinterval()) == dac

    @test !in_interval(Inf, entireinterval())
    @test !in_interval(-Inf, entireinterval())
end

@testset "nai" begin
    x = nai(Interval{Float64})
    @test decoration(x) == ill
    @test isguaranteed(x)
    b = @test_logs (:warn,) bareinterval(x)
    @test isempty_interval(b)

    @test isnai(nai())
    @test !isempty_interval(nai())
    @test !isequal_interval(nai(), nai())
    @test isnan(inf(nai(BigFloat)))

    ng = convert(Interval{Float64}, 1)
    @test !isguaranteed(nai(ng))
    @test isnai(nai(ng))

    @test nai(Float32) isa Interval{Float32}
    @test numtype(nai(Interval{Float32})) == Float32
    @test nai(1.0) isa Interval{Float64}

    z = nai(Complex{Interval{Float64}})
    @test z isa Complex{Interval{Float64}}
    @test isnai(z)
    @test isnai(nai(Complex{Float64}))
    z = nai(complex(interval(1), ng))
    @test isnai(z)
    @test isguaranteed(real(z)) & !isguaranteed(imag(z))

    @test nai() === nai(Interval{Float64})

    @test_throws MethodError nai(BareInterval{Float64})
    @test_throws MethodError nai(bareinterval(1, 2))
end

@testset "decorations and predicates of the constants" begin
    @test decoration(emptyinterval()) == trv
    @test decoration(entireinterval()) == dac
    @test decoration(nai()) == ill
    @test decoration(emptyinterval(BareInterval{Float64})) == trv
    @test decoration(entireinterval(BareInterval{Float64})) == dac

    @test !iscommon(emptyinterval())
    @test !iscommon(entireinterval())
    @test !iscommon(nai())
    @test isbounded(emptyinterval())
    @test !isbounded(entireinterval())
    @test !isbounded(nai())
end

@testset "round-trip through the type constructors" begin
    for x ∈ (bareinterval(1, 2), interval(1, 2), complex(interval(1), interval(2)), 1.0, 1//2, complex(1.0, 2.0))
        @test emptyinterval(typeof(x)) === emptyinterval(x)
        @test entireinterval(typeof(x)) === entireinterval(x)
    end
    for x ∈ (interval(1, 2), complex(interval(1), interval(2)), 1.0, complex(1.0, 2.0))
        @test nai(typeof(x)) === nai(x)
    end
end
