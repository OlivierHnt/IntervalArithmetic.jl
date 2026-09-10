using Test
using IntervalArithmetic
import IntervalSets as IS

@testset "IntervalSets to Interval" begin
    i = interval(IS.Interval(1, 2))
    @test isequal_interval(i, interval(1.0, 2.0))
    @test decoration(i) === com
    @test !isguaranteed(i)
    i = interval(IS.Interval(0.1, 2))
    @test isequal_interval(i, interval(0.1, 2.0)) && !isguaranteed(i)
    @test interval(Float64, IS.Interval(0.1, 2)) === i

    @test interval(IS.ClosedInterval(1, 2)) isa Interval{Float64}
    @test interval(Float32, IS.ClosedInterval(1, 2)) isa Interval{Float32}
    @test interval(BigFloat, IS.ClosedInterval(1, 2)) isa Interval{BigFloat}
    @test interval(IS.ClosedInterval(1//2, 3//4)) isa Interval{Rational{Int}}
    @test interval(IS.ClosedInterval(1.0f0, 2.0f0)) isa Interval{Float32}

    d = interval(IS.Interval{:closed,:closed}(1, 1))
    @test isequal_interval(d, interval(1, 1))
    @test decoration(d) === com
    @test !isguaranteed(d)
end

@testset "Open and infinite endpoints" begin
    i = interval(IS.Interval{:closed,:open}(0.1, Inf))
    @test isequal_interval(i, interval(0.1, Inf)) && !isguaranteed(i)
    @test decoration(i) === dac
    @test interval(IS.Interval{:closed,:closed}(0.1, Inf)) === nai(Float64)
    @test interval(IS.Interval{:open,:closed}(0.1, Inf)) === nai(Float64)
    @test interval(IS.Interval{:open,:open}(0.1, Inf)) === nai(Float64)
    @test interval(IS.Interval{:open,:open}(0.1, 1)) === nai(Float64)
    @test interval(IS.Interval{:open,:closed}(0.1, 1)) === nai(Float64)
    @test interval(IS.Interval{:closed,:open}(1, 2)) === nai(Float64)
    @test interval(IS.OpenInterval(1, 2)) === nai(Float64)
    @test_logs interval(IS.Interval{:open,:closed}(1, 2))

    j = interval(IS.Interval{:open,:closed}(-Inf, 2))
    @test isequal_interval(j, interval(-Inf, 2.0))
    @test decoration(j) === dac
    @test !isguaranteed(j)
    @test interval(IS.Interval{:closed,:closed}(-Inf, 2)) === nai(Float64)

    e = interval(IS.Interval{:open,:open}(-Inf, Inf))
    @test isentire_interval(e)
    @test decoration(e) === dac
    @test !isguaranteed(e)

    @test isnai(@test_logs (:warn,) (:warn,) interval(IS.Interval{:closed,:closed}(2, 1)))
end

@testset "Interval to IntervalSets" begin
    @test IS.Interval(interval(1, 2)) === IS.Interval(1.0, 2.0)
    @test IS.Interval(interval(0.1, 2)) === IS.Interval(0.1, 2.0)
    @test IS.Interval(interval(1, 2)) === IS.Interval{:closed,:closed}(1.0, 2.0)
    @test IS.Interval(interval(0.1, Inf)) === IS.Interval{:closed,:open}(0.1, Inf)
    @test IS.Interval(interval(-Inf, 2)) === IS.Interval{:open,:closed}(-Inf, 2.0)
    @test IS.Interval(interval(-Inf, Inf)) === IS.Interval{:open,:open}(-Inf, Inf)
    @test IS.Interval(emptyinterval()) === IS.Interval{:open,:open}(Inf, -Inf)
    @test IS.leftendpoint(IS.Interval(interval(0, 0))) === 0.0
    @test IS.Interval(interval(1//2, 3//4)) === IS.Interval(1//2, 3//4)
    @test IS.Interval(interval(Float32, 1, 2)) === IS.Interval(1.0f0, 2.0f0)
    # bounds(nai()) is (NaN, NaN), so NaI does not map to the empty IS.Interval
    r = IS.Interval(nai())
    @test r isa IS.ClosedInterval{Float64}
    @test isnan(IS.leftendpoint(r)) & isnan(IS.rightendpoint(r))
end

@testset "Round trips" begin
    for x ∈ (interval(0.1, 2.0), interval(1, 1), interval(-2, 3))
        y = interval(IS.Interval(x))
        @test isequal_interval(x, y)
        @test decoration(y) === decoration(x)
        @test !isguaranteed(y)
    end
    y = interval(IS.Interval(interval(1, Inf)))
    @test isequal_interval(y, interval(1, Inf)) && !isguaranteed(y)
    @test isnai(@test_logs (:warn,) (:warn,) interval(IS.Interval(emptyinterval())))
end
