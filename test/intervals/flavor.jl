using Test
using IntervalArithmetic
using IntervalArithmetic: Flavor, zero_times_infinity, div_by_thin_zero, contains_infinity,
    is_valid_interval, default_flavor, _unsafe_bareinterval

@testset "flavor type and configuration" begin
    @test Base.issingletontype(Flavor{:set_based})
    @test default_flavor() === Flavor{:set_based}()
    @test_throws ArgumentError IntervalArithmetic.configure(flavor = :cset)
    @test IntervalArithmetic.configuration_options.flavor == :set_based
    @test default_flavor() === Flavor{:set_based}()
end

@testset "unimplemented flavors" begin
    @test_throws MethodError zero_times_infinity(Flavor{:cset}(), Float64)
    @test_throws MethodError div_by_thin_zero(Flavor{:cset}(), bareinterval(1, 2))
    @test_throws MethodError contains_infinity(Flavor{:cset}(), bareinterval(1, 2))
    @test_throws MethodError is_valid_interval(Flavor{:cset}(), 1, 2)
end

@testset "zero_times_infinity" begin
    for T ∈ (Float64, Float32, BigFloat, Rational{Int64})
        x = zero_times_infinity(Flavor{:set_based}(), T)
        @test typeof(x) === T
        @test iszero(x)
        @test zero_times_infinity(T) == x
    end
end

@testset "div_by_thin_zero" begin
    for x ∈ (bareinterval(1, 2), bareinterval(Float32, 1, 2), bareinterval(1//2, 3//4),
             entireinterval(BareInterval{Float64}))
        y = div_by_thin_zero(Flavor{:set_based}(), x)
        @test typeof(y) === typeof(x)
        @test isempty_interval(y)
        @test isequal_interval(div_by_thin_zero(x), y)
    end
end

@testset "contains_infinity" begin
    for x ∈ (bareinterval(1, 2), bareinterval(-Inf, Inf), bareinterval(1, Inf),
             emptyinterval(BareInterval{Float64}))
        @test contains_infinity(Flavor{:set_based}(), x) == false
        @test contains_infinity(x) == false
    end
end

@testset "is_valid_interval" begin
    @test is_valid_interval(1, 2) == true
    @test is_valid_interval(2, 1) == false
    @test is_valid_interval(1, 1) == true

    @test is_valid_interval(Inf, Inf) == false
    @test is_valid_interval(-Inf, -Inf) == false
    @test is_valid_interval(-Inf, Inf) == true
    @test is_valid_interval(1, Inf) == true

    @test is_valid_interval(NaN, 1) == false
    @test is_valid_interval(1, NaN) == false
    @test is_valid_interval(NaN, NaN) == false

    @test is_valid_interval(0.0, -0.0) == true
    @test is_valid_interval(-0.0, 0.0) == true

    @test is_valid_interval(1//1, 2//1) == true
    @test is_valid_interval(2//1, 1//1) == false
    @test is_valid_interval(1//2, 1//2) == true
    @test is_valid_interval(1//0, 1//0) == false
    @test is_valid_interval(-1//0, -1//0) == false
    @test is_valid_interval(typemin(Rational{Int64}), typemax(Rational{Int64})) == true
    @test is_valid_interval(typemax(Rational{Int64}), typemax(Rational{Int64})) == false
    @test is_valid_interval(typemin(Rational{Int64}), typemin(Rational{Int64})) == false

    @test is_valid_interval(1//2, 0.6) == true
    @test is_valid_interval(1//0, 1.0) == false

    for (a, b) ∈ ((1, 2), (2, 1), (Inf, Inf), (-Inf, Inf), (NaN, 1), (-0.0, 0.0),
                  (1//1, 2//1), (2//1, 1//1), (1//0, 1//0), (1//2, 0.6), (1//0, 1.0))
        @test is_valid_interval(a, b) == is_valid_interval(default_flavor(), a, b)
    end
end

@testset "set-based edge cases" begin
    @test isempty_interval(bareinterval(0)/bareinterval(0))
    @test isempty_interval(bareinterval(1)/bareinterval(0))
    @test isempty_interval(bareinterval(-Inf, Inf)/bareinterval(0))
    @test isthinzero(bareinterval(0)*bareinterval(-Inf, Inf))

    a = interval(0.1, 1.1)
    @test isequal_interval(inv(zero(a)), emptyinterval())
    @test isequal_interval(interval(0)/interval(0), emptyinterval())

    @test !in_interval(Inf, interval(1, Inf))
    @test !isbounded(interval(1, Inf))
end

@testset "constructor consequences" begin
    @test sup(_unsafe_bareinterval(Float64, Inf, Inf)) == Inf
    @test isempty_interval(@test_logs (:warn,) bareinterval(Inf, Inf))
    @test isnai(@test_logs (:warn,) interval(Inf, Inf))
    @test isnai(@test_logs (:warn,) interval(1//0, 1//0))
    @test isnai(@test_logs (:warn,) interval(-1//0, -1//0))
    @test isnai(@test_logs (:warn,) interval(1//0, -1//0))

    x = bareinterval(-Inf, Inf)
    @test isequal_interval(x, entireinterval(BareInterval{Float64}))
    @test decoration(interval(-Inf, Inf)) == dac
end
