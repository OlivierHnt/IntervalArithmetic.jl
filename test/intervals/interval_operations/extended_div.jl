using Test
using IntervalArithmetic

@testset "extended_div bare intervals" begin
    e = emptyinterval(BareInterval{Float64})
    entire = entireinterval(BareInterval{Float64})

    r = extended_div(bareinterval(1, 2), bareinterval(3, 4))
    @test isequal_interval(r[1], bareinterval(1, 2) / bareinterval(3, 4))
    @test bounds(r[1]) == (0.25, nextfloat(2/3))
    @test in_interval(2//3, r[1])
    @test isempty_interval(r[2])
    @test isequal_interval(extended_div(bareinterval(1, 1), bareinterval(3, 3))[1], bareinterval(1, 1) / bareinterval(3, 3))

    @test all(isequal_interval.(extended_div(bareinterval(1, 2), bareinterval(-1, 1)), (bareinterval(-Inf, -1), bareinterval(1, Inf))))
    @test all(isequal_interval.(extended_div(bareinterval(-2, -1), bareinterval(-1, 1)), (bareinterval(-Inf, -1), bareinterval(1, Inf))))
    @test all(isequal_interval.(extended_div(bareinterval(1, 2), bareinterval(0, 1)), (bareinterval(1, Inf), e)))
    @test all(isequal_interval.(extended_div(bareinterval(1, 2), bareinterval(-1, 0)), (bareinterval(-Inf, -1), e)))
    @test all(isequal_interval.(extended_div(bareinterval(-1, 1), bareinterval(-1, 1)), (entire, e)))
    @test all(isequal_interval.(extended_div(bareinterval(0, 0), bareinterval(0, 0)), (entire, e)))
    @test all(isequal_interval.(extended_div(bareinterval(1, 2), e), (e, e)))
    @test all(isequal_interval.(extended_div(e, bareinterval(1, 2)), (e, e)))
    @test all(isequal_interval.(extended_div(bareinterval(1, 2), bareinterval(0, 0)), (e, e)))
    @test all(isequal_interval.(extended_div(entire, bareinterval(-1, 1)), (entire, e)))

    for (x, y) ∈ ((bareinterval(1, 2), bareinterval(-1, 1)), (bareinterval(-2, -1), bareinterval(-2, 4)),
                  (bareinterval(1, 2), bareinterval(3, 4)), (bareinterval(-1, 1), bareinterval(-1, 1)))
        @test issubset_interval(x / y, hull(extended_div(x, y)...))
    end

    @test_throws MethodError extended_div(bareinterval(Float32, 1, 2), bareinterval(1.0, 2.0))

    @test all(isequal_interval.(extended_div(bareinterval(Float32, 1, 2), bareinterval(Float32, -1, 1)),
        (bareinterval(Float32, -Inf, -1), bareinterval(Float32, 1, Inf))))
    @test all(isequal_interval.(extended_div(bareinterval(BigFloat, 1, 2), bareinterval(BigFloat, -1, 1)),
        (bareinterval(BigFloat, -Inf, -1), bareinterval(BigFloat, 1, Inf))))
    @test all(isequal_interval.(extended_div(bareinterval(1//1, 2//1), bareinterval(-1//1, 1//1)),
        (bareinterval(-1//0, -1//1), bareinterval(1//1, 1//0))))
end

@testset "extended_div decorated intervals" begin
    a = interval(0.1, 1.1)
    c = interval(0.25, 4.0)
    @test all(isequal_interval.(extended_div(interval(-30.0, -15.0), interval(-5.0, -3.0)), (interval(3.0, 10.0), emptyinterval(c))))
    @test all(isequal_interval.(extended_div(interval(-30, -15), interval(-5, -3)), (interval(3.0, 10.0), emptyinterval(c))))
    @test all(isequal_interval.(extended_div(interval(1.0, 2.0), interval(0.1, 1.0)), (interval(1, 20.0), emptyinterval(c))))
    @test all(isequal_interval.(extended_div(a, c), (interval(0.025, 4.4e+00), emptyinterval(c))))
    @test all(isequal_interval.(extended_div(c, interval(4.0)), (interval(6.25e-02, 1e+00), emptyinterval(c))))
    @test all(isequal_interval.(extended_div(c, zero(c)), (emptyinterval(c), emptyinterval(c))))
    @test all(isequal_interval.(extended_div(interval(0.0, 1.0), interval(0.0, 1.0)), (entireinterval(c), emptyinterval(c))))
    @test all(isequal_interval.(extended_div(interval(-1.0, 1.0), interval(0.0, 1.0)), (entireinterval(c), emptyinterval(c))))
    @test all(isequal_interval.(extended_div(interval(-1.0, 1.0), interval(-1.0, 1.0)), (entireinterval(c), emptyinterval(c))))
    @test all(isequal_interval.(extended_div(interval(1.0, 2.0), interval(-4.0, 4.0)), (interval(-Inf, -0.25), interval(0.25, Inf))))
    @test all(isequal_interval.(extended_div(interval(-2.0, -1.0), interval(-2.0, 4.0)), (interval(-Inf, -0.25), interval(0.5, Inf))))
    @test all(isequal_interval.(extended_div(interval(0.0, 0.0), interval(-1.0, 1.0)), (entireinterval(c), emptyinterval(c))))
end

@testset "extended_div decorations" begin
    # IEEE 1788-2015 Section 10.5.5
    r = extended_div(interval(1, 2), interval(3, 4))
    @test decoration(r[1]) == com
    @test decoration(r[2]) == trv
    r = extended_div(interval(-1.0, 1.0), interval(3.0, 4.0))
    @test decoration(r[1]) == com
    @test decoration(r[2]) == trv
    r = extended_div(interval(-30.0, -15.0), interval(-5.0, -3.0))
    @test decoration(r[1]) == com
    @test decoration(r[2]) == trv
    r = extended_div(interval(1, 2), interval(0, 4))
    @test decoration(r[1]) == trv
    @test isequal_interval(r[1], interval(0.25, Inf))
    r = extended_div(interval(1.0, 2.0), interval(-4.0, 4.0))
    @test decoration(r[1]) == trv
    @test decoration(r[2]) == trv
    r = extended_div(interval(-1.0, 1.0), interval(-1.0, 1.0))
    @test decoration(r[1]) == trv
    @test decoration(r[2]) == trv
    r = extended_div(interval(1.0, 2.0), interval(0.0, 1.0))
    @test decoration(r[1]) == trv
    @test decoration(r[2]) == trv
    r = extended_div(interval(-1.0, 1.0, trv), interval(3.0, 4.0))
    @test decoration(r[1]) == trv
    @test decoration(r[2]) == trv
    r = extended_div(interval(-1.0, 1.0, def), interval(3.0, 4.0))
    @test decoration(r[1]) == def
    @test decoration(r[2]) == trv

    r = @test_logs (:warn,) extended_div(nai(), interval(1, 2))
    @test isnai(r[1]) & isnai(r[2])
    r = @test_logs (:warn,) extended_div(interval(1, 2), nai())
    @test isnai(r[1]) & isnai(r[2])

    r = extended_div(interval(1, 2), convert(Interval{Float64}, 4))
    @test !isguaranteed(r[1]) & !isguaranteed(r[2])
    r = extended_div(convert(Interval{Float64}, 1), interval(3, 4))
    @test !isguaranteed(r[1]) & !isguaranteed(r[2])
    r = extended_div(interval(1, 2), interval(3, 4))
    @test isguaranteed(r[1]) & isguaranteed(r[2])

    @test extended_div(interval(1, 2), interval(3, 4)) isa Tuple{Interval{Float64},Interval{Float64}}
    @test extended_div(interval(Float32, 1, 2), interval(Float32, 3, 4)) isa Tuple{Interval{Float32},Interval{Float32}}

    z = complex(interval(1), interval(2))
    @test_throws MethodError extended_div(z, z)
    @test_throws MethodError extended_div([interval(1)], [interval(1)])
end
