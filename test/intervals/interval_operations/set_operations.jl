using Test
using IntervalArithmetic
using IntervalArithmetic: interval_diff, interiordiff!

sameset(A, B) = length(A) == length(B) &&
    all(a -> any(b -> all(isequal_interval.(a, b)), B), A) &&
    all(b -> any(a -> all(isequal_interval.(a, b)), A), B)

@testset "_set_decoration" begin
    x = interval(1, 2)
    @test IntervalArithmetic._set_decoration(x, :auto) === x
    @test decoration(IntervalArithmetic._set_decoration(x, :default)) == trv
    @test decoration(IntervalArithmetic._set_decoration(x, def)) == def
    @test_throws ArgumentError IntervalArithmetic._set_decoration(x, :bogus)
end

@testset "intersect_interval" begin
    e = emptyinterval(BareInterval{Float64})
    entire = entireinterval(BareInterval{Float64})

    @test isequal_interval(e, @test_logs (:warn,) bareinterval(Inf, -Inf))

    @test isequal_interval(intersect_interval(bareinterval(1, 3), bareinterval(2, 4)), bareinterval(2, 3))
    @test isequal_interval(intersect_interval(bareinterval(1, 2), bareinterval(3, 4)), e)
    @test isequal_interval(intersect_interval(bareinterval(1, 2), bareinterval(2, 3)), bareinterval(2, 2))
    @test isequal_interval(intersect_interval(e, entire), e)
    @test isequal_interval(intersect_interval(e, e), e)
    for x ∈ (bareinterval(1, 2), e, entire, bareinterval(-Inf, 0))
        @test isequal_interval(intersect_interval(entire, x), x)
    end

    @test intersect_interval(bareinterval(Float32, 1, 3), bareinterval(1.5, 4.0)) isa BareInterval{Float64}
    @test isequal_interval(intersect_interval(bareinterval(1//2, 3//2), bareinterval(1//1, 2//1)), bareinterval(1//1, 3//2))
    @test isequal_interval(intersect_interval(bareinterval(BigFloat, 1, 3), bareinterval(BigFloat, 2, 4)), bareinterval(BigFloat, 2, 3))

    @test isequal_interval(intersect_interval(bareinterval(1, 5), bareinterval(2, 6), bareinterval(3, 7)), bareinterval(3, 5))
    @test isequal_interval(intersect_interval(bareinterval(1, 5), bareinterval(2, 6), bareinterval(3, 7), bareinterval(0, 4)), bareinterval(3, 4))

    a = interval(0.1, 1.1)
    @test isequal_interval(intersect_interval(a, interval(-1)), emptyinterval(a))
    @test isempty_interval(intersect_interval(a, interval(-1)))
    @test isequal_interval(intersect_interval(a, hull(a, interval(0.9, 2.0))), a)
    @test isequal_interval(intersect_interval(interval(1.0, 2.0), interval(-1.0, 5.0), interval(1.8, 3.0)), interval(1.8, 2.0))
    @test isequal_interval(intersect_interval(a, emptyinterval(), interval(0.9, 2.0)), emptyinterval())
    @test isequal_interval(intersect_interval(interval(0, 1), interval(3, 4), interval(0, 1), interval(0, 1)), emptyinterval())

    r = intersect_interval(interval(1, 3), interval(2, 4))
    @test isequal_interval(r, interval(2, 3))
    @test decoration(r) == trv
    @test decoration(intersect_interval(interval(1, 3), interval(2, 4); dec = :auto)) == com
    @test decoration(intersect_interval(interval(1, 3), interval(2, 4); dec = com)) == com
    @test decoration(intersect_interval(interval(1, 3), interval(2, 4); dec = def)) == def
    @test isnai(intersect_interval(interval(1, 3), interval(2, 4); dec = ill))
    @test decoration(intersect_interval(interval(1, 2), interval(3, 4); dec = com)) == trv
    @test_throws ArgumentError intersect_interval(interval(1, 3), interval(2, 4); dec = :bogus)

    @test intersect_interval(interval(Float32, 1, 3), interval(2.0, 4.0)) isa Interval{Float64}
end

@testset "hull" begin
    e = emptyinterval(BareInterval{Float64})
    entire = entireinterval(BareInterval{Float64})

    @test isequal_interval(hull(bareinterval(1, 2), bareinterval(5, 6)), bareinterval(1, 6))
    @test isequal_interval(hull(e, bareinterval(1, 2)), bareinterval(1, 2))
    @test isequal_interval(hull(e, e), e)
    @test isequal_interval(hull(entire, bareinterval(1, 2)), entire)
    @test isequal_interval(hull(bareinterval(-Inf, 0), bareinterval(0, Inf)), entire)
    @test hull(bareinterval(Float32, 1, 2), bareinterval(3.0, 4.0)) isa BareInterval{Float64}

    @test union_interval === hull

    @test isequal_interval(hull(bareinterval(1, 2), bareinterval(5, 6), bareinterval(-1, 0), bareinterval(9, 10)), bareinterval(-1, 10))

    @test isequal_interval(hull(interval(1, 2), interval(3, 4)), interval(1, 4))
    @test isequal_interval(hull(interval(1//3, 3//4), interval(3, 4)), interval(1/3, 4))
    @test isequal_interval(hull(interval(0.1, 1.1), interval(0.9, 2.0)), interval(0.1, 2.0))

    @test decoration(hull(interval(1, 2), interval(5, 6))) == trv
    @test decoration(hull(interval(1, 2), interval(5, 6); dec = :auto)) == com
    @test decoration(hull(interval(1, 2), interval(-Inf, 0); dec = com)) == dac
end

@testset "hull and intersect_interval" begin
    for T ∈ (Float64, Float32, BigFloat, Rational{Int})
        x = bareinterval(T, 1, 2)
        e = emptyinterval(BareInterval{T})

        @test isequal_interval(hull(e, e), e)
        @test isequal_interval(hull(x, e), x)
        @test isequal_interval(hull(e, x), x)
        @test isequal_interval(hull(x, bareinterval(T, 5, 6)), bareinterval(T, 1, 6))

        @test isempty_interval(intersect_interval(e, e))
        @test isempty_interval(intersect_interval(x, e))
        @test isempty_interval(intersect_interval(e, x))
        @test isempty_interval(intersect_interval(x, bareinterval(T, 5, 6)))
        @test isequal_interval(intersect_interval(x, bareinterval(T, 0, 3)), x)

        y = interval(T, 1, 2)
        f = emptyinterval(Interval{T})

        @test isempty_interval(hull(f, f))
        @test isequal_interval(hull(y, f), y)
        @test isequal_interval(hull(f, y), y)
        @test isempty_interval(intersect_interval(y, f))
        @test isempty_interval(intersect_interval(f, y))
    end

    n = nai(Float64)
    x = interval(1, 2)

    @test isnai(hull(n, x)) & isnai(hull(x, n)) & isnai(hull(n, n))
    @test isnai(intersect_interval(n, x)) & isnai(intersect_interval(x, n))
    @test isnai(hull(x, x, n)) & isnai(hull(x, n, x)) & isnai(hull(n, x, x))
    @test isnai(hull(x, x, x, n))
    @test isnai(intersect_interval(x, x, n)) & isnai(intersect_interval(n, x, x))
    @test isnai(@test_logs hull(n, x))
    @test isnai(@test_logs intersect_interval(n, x))
    @test isnai(@test_logs hull(x, x, x, n))

    y = interval(3, 4)
    z = interval(5, Inf)

    @test decoration(hull(x, y)) == trv
    @test decoration(hull(x, y; dec = :auto)) == com
    @test decoration(hull(x, z; dec = :auto)) == dac
    @test decoration(hull(x, y; dec = def)) == def
    @test decoration(intersect_interval(x, y)) == trv
    @test decoration(intersect_interval(x, interval(2, 3); dec = :auto)) == com
    @test_throws ArgumentError hull(x, y; dec = :nonsense)
    @test_throws ArgumentError intersect_interval(x, y; dec = :nonsense)

    @test decoration(hull(interval(-Inf, 0), interval(1, 2); dec = :auto)) == dac

    bs = (bareinterval(1, 2), bareinterval(-3, 0), bareinterval(5, 6))

    @test isequal_interval(hull(bs...), bareinterval(-3, 6))
    @test isequal_interval(hull(bs..., bareinterval(7, 9)), bareinterval(-3, 9))
    @test isempty_interval(intersect_interval(bs...))
    @test isequal_interval(
        intersect_interval(bareinterval(0, 4), bareinterval(1, 5), bareinterval(2, 6)),
        bareinterval(2, 4))
    @test_throws MethodError hull(bs...; dec = :auto)

    args = (interval(1, 2), interval(-3, 0), interval(5, 6), interval(-1, 8),
        interval(0, 1), interval(-2, 2), interval(4, 7), interval(-5, 5))
    for dec ∈ (:default, :auto, trv, def, com)
        for k ∈ 3:8
            xs = args[1:k]
            @test isequal_interval(hull(xs...; dec = dec), reduce((a, b) -> hull(a, b; dec = dec), xs))
            @test decoration(hull(xs...; dec = dec)) == decoration(reduce((a, b) -> hull(a, b; dec = dec), xs))
            @test isequal_interval(intersect_interval(xs...; dec = dec), reduce((a, b) -> intersect_interval(a, b; dec = dec), xs))
            @test decoration(intersect_interval(xs...; dec = dec)) == decoration(reduce((a, b) -> intersect_interval(a, b; dec = dec), xs))
        end
    end

    ng = convert(Interval{Float64}, 1)

    @test !isguaranteed(hull(x, ng))
    @test !isguaranteed(hull(x, y, ng))
    @test !isguaranteed(hull(x, y, x, ng))
    @test isguaranteed(hull(x, y, x))
    @test !isguaranteed(intersect_interval(x, y, ng))
    @test !isguaranteed(intersect_interval(x, ng))
    @test isguaranteed(intersect_interval(x, y))

    @test numtype(hull(interval(Float32, 1, 2), interval(Float64, 3, 4))) === Float64
    @test numtype(hull(interval(Float32, 1, 2), interval(Float32, 0, 1), interval(Float64, 3, 4))) === Float64
    @test numtype(intersect_interval(interval(Float32, 1, 2), interval(Float32, 0, 3), interval(Float64, 1, 4))) === Float64

    @test inf(hull(interval(0, 1), interval(2, 3))) === -0.0
    @test inf(intersect_interval(interval(0, 1), interval(-1, 3))) === -0.0
end

@testset "complex hull and intersect_interval" begin
    a = complex(interval(0), interval(1))
    b = complex(interval(3), interval(4))
    c = complex(interval(-1, 4), interval(0, 2))

    @test isequal_interval(hull(a, b), complex(interval(0, 3), interval(1, 4)))
    @test isequal_interval(intersect_interval(c, hull(a, b)), complex(interval(0, 3), interval(1, 2)))
    @test isempty_interval(intersect_interval(a, b))
    @test isequal_interval(intersect_interval(a, b), complex(emptyinterval(), emptyinterval()))

    @test isequal_interval(hull(interval(1, 2), complex(interval(3, 4), interval(5, 6))), complex(interval(1, 4), interval(0, 6)))
    @test isequal_interval(hull(complex(interval(3, 4), interval(5, 6)), interval(1, 2)), complex(interval(1, 4), interval(0, 6)))
    @test isequal_interval(intersect_interval(interval(0, 2), complex(interval(1, 3), interval(-1, 1))), complex(interval(1, 2), interval(0)))
    @test isempty_interval(intersect_interval(interval(0, 2), complex(interval(1, 3), interval(1, 2))))
    @test isequal_interval(intersect_interval(complex(interval(1, 3), interval(-1, 1)), interval(0, 2)), complex(interval(1, 2), interval(0)))
end

@testset "interiordiff of intervals" begin
    e = emptyinterval(BareInterval{Float64})
    @test all(isequal_interval.(interiordiff(bareinterval(1, 4), bareinterval(2, 3)), [bareinterval(1, 2), bareinterval(3, 4)]))
    @test all(isequal_interval.(interiordiff(bareinterval(1, 4), bareinterval(1, 4)), [bareinterval(1, 1), bareinterval(4, 4)]))
    @test isequal_interval(only(interiordiff(bareinterval(1, 4), bareinterval(0, 3))), bareinterval(3, 4))
    @test isequal_interval(only(interiordiff(bareinterval(1, 4), bareinterval(2, 5))), bareinterval(1, 2))
    @test isempty(interiordiff(bareinterval(1, 4), bareinterval(0, 5)))
    @test isequal_interval(only(interiordiff(bareinterval(1, 2), bareinterval(3, 4))), bareinterval(1, 2))
    @test isempty(interiordiff(e, bareinterval(1, 2)))
    @test isequal_interval(only(interiordiff(bareinterval(1, 2), e)), bareinterval(1, 2))
    @test interiordiff(bareinterval(Float32, 1, 4), bareinterval(2.0, 3.0)) isa Vector{BareInterval{Float64}}

    for (x, y) ∈ ((bareinterval(1, 4), bareinterval(2, 3)), (bareinterval(1, 4), bareinterval(0, 3)),
                  (bareinterval(1, 4), bareinterval(2, 5)), (bareinterval(1, 2), bareinterval(3, 4)),
                  (bareinterval(1, 4), bareinterval(1, 4)))
        pieces = interiordiff(x, y)
        @test issubset_interval(x, reduce(hull, [pieces; [intersect_interval(x, y)]]))
    end

    x = interval(2, 4)
    y = interval(3, 5)
    @test typeof(interiordiff(x, y)) == Vector{Interval{Float64}}
    @test interiordiff(interval(Float32, 2, 4), interval(3.0, 5.0)) isa Vector{Interval{Float64}}
    @test all(isequal_interval.(interiordiff(x, x), [interval(2), interval(4)]))
    @test isequal_interval(only(interiordiff(x, emptyinterval(x))), x)
    @test isequal_interval(only(interiordiff(x, y)), interval(2, 3))
    @test isequal_interval(only(interiordiff(y, x)), interval(4, 5))
    y = interval(2, 5)
    @test isequal_interval(only(interiordiff(x, y)), interval(2))
    @test all(isequal_interval.(interiordiff(y, x), [interval(2), interval(4, 5)]))
    @test all(isequal_interval.(interiordiff(interval(2, 5), interval(3, 4)), [interval(2, 3), interval(4, 5)]))
    @test interiordiff(interval(1, 3), interval(0, 5)) == Interval{Float64}[]
    @test all(isequal_interval.(interiordiff(interval(0, 5), interval(1, 3)), [interval(0, 1), interval(3, 5)]))

    dtrv = interiordiff(interval(1, 4), interval(2, 3))
    @test (length(dtrv) == 2) && all(d -> d == trv, decoration.(dtrv))
    dauto = interiordiff(interval(1, 4), interval(2, 3); dec = :auto)
    @test (length(dauto) == 2) && all(d -> d == com, decoration.(dauto))
    ddef = interiordiff(interval(1, 4), interval(2, 3); dec = def)
    @test (length(ddef) == 2) && all(d -> d == def, decoration.(ddef))
    dcom = interiordiff(interval(1, 4), interval(2, 3); dec = com)
    @test (length(dcom) == 2) && all(d -> d == com, decoration.(dcom))
    @test (length(dtrv) == 2) && all(isguaranteed, dtrv)
    ngdiff = interiordiff(interval(1, 4), convert(Interval{Float64}, 2))
    @test (length(ngdiff) == 2) && all(z -> !isguaranteed(z), ngdiff)
    @test isempty(interiordiff(convert(Interval{Float64}, 2), interval(1, 4)))

    r = interiordiff(nai(), interval(1, 2))
    @test (length(r) == 1) && isnai(r[1])
    r = interiordiff(interval(1, 2), nai())
    @test (length(r) == 1) && isnai(r[1])

    v = Interval{Float64}[]
    @test interiordiff!(v, interval(1, 4), interval(2, 3)) === v
    @test all(isequal_interval.(v, [interval(1, 2), interval(3, 4)]))
    @test interiordiff!(v, interval(1, 4), interval(0, 5)) === v
    @test isempty(v)
    @test interiordiff!(v, interval(Float32, 1, 4), interval(2.0, 3.0)) === v
    @test all(isequal_interval.(v, [interval(1, 2), interval(3, 4)]))
end

@testset "_interiordiff" begin
    h₁, h₂, inter = IntervalArithmetic._interiordiff(bareinterval(1, 2), bareinterval(3, 4), nothing)
    @test isequal_interval(h₁, bareinterval(1, 2)) & isempty_interval(h₂) & isempty_interval(inter)
    h₁, h₂, inter = IntervalArithmetic._interiordiff(bareinterval(2, 3), bareinterval(1, 4), nothing)
    @test isempty_interval(h₁) & isempty_interval(h₂) & isequal_interval(inter, bareinterval(2, 3))
    h₁, h₂, inter = IntervalArithmetic._interiordiff(bareinterval(1, 4), bareinterval(1, 4), nothing)
    @test isequal_interval(h₁, bareinterval(1, 1)) & isequal_interval(h₂, bareinterval(4, 4)) & isequal_interval(inter, bareinterval(1, 4))
    h₁, h₂, inter = IntervalArithmetic._interiordiff(bareinterval(1, 4), bareinterval(1, 3), nothing)
    @test isequal_interval(h₁, bareinterval(3, 4)) & isempty_interval(h₂) & isequal_interval(inter, bareinterval(1, 3))
    h₁, h₂, inter = IntervalArithmetic._interiordiff(bareinterval(1, 4), bareinterval(2, 4), nothing)
    @test isequal_interval(h₁, bareinterval(1, 2)) & isempty_interval(h₂) & isequal_interval(inter, bareinterval(2, 4))
    h₁, h₂, inter = IntervalArithmetic._interiordiff(bareinterval(1, 4), bareinterval(2, 3), nothing)
    @test isequal_interval(h₁, bareinterval(1, 2)) & isequal_interval(h₂, bareinterval(3, 4)) & isequal_interval(inter, bareinterval(2, 3))
end

@testset "interiordiff of boxes" begin
    X = [interval(2, 4), interval(3, 5)]
    Y = [interval(3, 5), interval(4, 6)]
    @test sameset(
        interiordiff(X, Y),
        [ [interval(3, 4), interval(3, 4)],
          [interval(2, 3), interval(3, 5)] ])

    X = [interval(2, 5), interval(3, 6)]
    Y = [interval(-10, 10), interval(4, 5)]
    @test sameset(
        interiordiff(X, Y),
        [ [interval(2, 5), interval(3, 4)],
          [interval(2, 5), interval(5, 6)] ])

    X = [interval(2, 5), interval(3, 6)]
    Y = [interval(4, 6), interval(4, 5)]
    @test sameset(
        interiordiff(X, Y),
        [ [interval(4, 5), interval(3, 4)],
          [interval(4, 5), interval(5, 6)],
          [interval(2, 4), interval(3, 6)] ])

    X = [interval(2, 5), interval(3, 6)]
    Y = [interval(3, 4), interval(4, 5)]
    @test sameset(
        interiordiff(X, Y),
        [ [interval(3, 4), interval(3, 4)],
          [interval(3, 4), interval(5, 6)],
          [interval(2, 3), interval(3, 6)],
          [interval(4, 5), interval(3, 6)] ])

    X = [interval(2, 5), interval(3, 6)]
    Y = [interval(2, 4), interval(10, 20)]
    r = interiordiff(X, Y)
    @test sameset(r, typeof(X)[X])
    @test r[1] !== X

    X = [interval(2, 5), interval(3, 6)]
    Y = [interval(-10, 10), interval(-10, 10)]
    @test sameset(interiordiff(X, Y), typeof(X)[])

    X = [interval(1, 4), interval(3, 6), interval(7, 10)]
    Y = [interval(2, 3), interval(4, 5), interval(8, 9)]
    @test sameset(
        interiordiff(X, Y),
        [ [interval(2, 3), interval(4, 5), interval(7, 8)],
          [interval(2, 3), interval(4, 5), interval(9, 10)],
          [interval(2, 3), interval(3, 4), interval(7, 10)],
          [interval(2, 3), interval(5, 6), interval(7, 10)],
          [interval(1, 2), interval(3, 6), interval(7, 10)],
          [interval(3, 4), interval(3, 6), interval(7, 10)] ])

    X = [interval(-Inf, Inf), interval(1, 2)]
    Y = [interval(1, 2), interval(-1, 1.5)]
    @test sameset(
        interiordiff(X, Y),
        [ [interval(-Inf, 1), interval(1, 2)],
          [interval(2, Inf), interval(1, 2)],
          [interval(1, 2), interval(1.5, 2)] ])

    r = interiordiff([bareinterval(0, 2), bareinterval(0, 2)], [bareinterval(1, 3), bareinterval(1, 3)])
    @test length(r) == 2
    @test all(isequal_interval.(r[1], [bareinterval(0, 1), bareinterval(0, 2)]))
    @test all(isequal_interval.(r[2], [bareinterval(1, 2), bareinterval(0, 1)]))
    @test all(box -> !any(z -> isempty_interval(z) | isnai(z), box), r)

    r = interiordiff([interval(0, 2), interval(0, 2)], [interval(1, 3), interval(1, 3)])
    @test decoration.(r[1]) == [trv, com]
    @test decoration.(r[2]) == [trv, trv]
    r = interiordiff([interval(0, 2), interval(0, 2)], [interval(1, 3), interval(1, 3)]; dec = :auto)
    @test all(box -> all(d -> d == com, decoration.(box)), r)

    @test_throws DimensionMismatch interiordiff([interval(1, 2)], [interval(1, 2), interval(3, 4)])

    v = Vector{Vector{Interval{Float64}}}(undef, 0)
    @test interiordiff!(v, [interval(2, 5), interval(3, 6)], [interval(-10, 10), interval(-10, 10)]) === v
    @test isempty(v)
end

@testset "interval_diff" begin
    A, B = interval_diff(interval(1, 10), interval(2, 5))
    @test isequal_interval(A, interval(1, 2))
    @test isequal_interval(B, interval(5, 10))

    @test isequal_interval(
        only(interval_diff(interval(1, 10), interval(1, 5))),
        interval(5, 10)
    )
    @test isequal_interval(
        only(interval_diff(interval(1, 10), interval(7, 12))),
        interval(1, 7)
    )

    @test isequal_interval(only(interval_diff(interval(1, 10), interval(20, 30))), interval(1, 10))
    @test interval_diff(interval(1, 10), interval(-1, 14)) == []
    @test interval_diff(interval(1, 10), interval(1, 10)) == []
    @test interval_diff(interval(1, 10), interval(-1, 14)) isa Vector{Interval{Float64}}

    r = interval_diff(interval(1, 4), interval(2, 3))
    @test all(isequal_interval.(r, [interval(1, 2), interval(3, 4)]))
    @test all(d -> d == com, decoration.(r))
end
