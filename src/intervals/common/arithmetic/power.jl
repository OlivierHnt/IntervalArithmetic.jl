# This file is part of the IntervalArithmetic.jl package; MIT licensed

#=  This file contains the functions described as "Power functions"
    in the IEEE Std 1788-2015 (sections 9.1) and required for set-based flavor
    in section 10.5.3, with addition of the `sqr` function.
=#

# Overwrite behaviour for literal integer powers
# Default transforms `a^-p` to `inv(a)^p` which is incorrect for intervals.
Base.literal_pow(::typeof(^), a::F, ::Val{p}) where {F <: AbstractFlavor, p} = a^p

# CRlibm does not contain a correctly-rounded ^ function for Float64
# Use the BigFloat version from MPFR instead, which is correctly-rounded.
"""
    ^(a::AbstractFlavor, b::AbstractFlavor)
    ^(a::AbstractFlavor, b)

Implement the `pow` function of the IEEE Std 1788-2015 (Table 9.1).
"""
^(a::F, b::F) where {F <: AbstractFlavor} = atomic(F, big53(a)^b)

# TODO come back to that once zero(T) vs 0 is solved
# TODO test todo stuff

# Write explicitly like this to avoid ambiguity warnings:
for T in (:Integer, :Rational, :Float64, :BigFloat)  # TODO check if :BigFloat is needed there
    @eval ^(a::F, x::$T) where {F <: AbstractFlavor} = atomic(F, big53(a)^x)
end

# TODO check flavor dependant corner cases
function ^(a::F, n::Integer) where {F <: AbstractFlavor{BigFloat}}
    isempty(a) && return a
    n == 0 && return one(F)
    n == 1 && return a
    n < 0 && iszero(a) && return emptyinterval(F)

    if isodd(n) # odd power
        isentire(a) && return a
        if n > 0
            iszero(a.lo) && return @round(0, a.hi^n)
            iszero(a.hi) && return @round(a.lo^n, 0)
            return @round(a.lo^n, a.hi^n)
        else
            if a.lo ≥ 0
                iszero(a.lo) && return @round(a.hi^n, Inf)
                return @round(a.hi^n, a.lo^n)

            elseif a.hi ≤ 0
                iszero(a.hi) && return @round(-Inf, a.lo^n)
                return @round(a.hi^n, a.lo^n)
            else
                return RR(a)  # TODO Check: is this 1/0 ?
            end
        end

    else # even power
        if n > 0
            if a.lo ≥ 0
                return @round(a.lo^n, a.hi^n)
            elseif a.hi ≤ 0
                return @round(a.hi^n, a.lo^n)
            else
                return @round(mig(a)^n, mag(a)^n)
            end

        else
            if a.lo ≥ 0
                return @round(a.hi^n, a.lo^n)
            elseif a.hi ≤ 0
                return @round(a.lo^n, a.hi^n)
            else
                return @round(mag(a)^n, mig(a)^n)
            end
        end
    end
end

^(a::F, x::AbstractFloat) where {F <: AbstractFlavor{BigFloat}} = a^big(x)

# Floating-point power of a BigFloat interval:
function ^(a::F, x::BigFloat) where {F <: AbstractFlavor{BigFloat}}

    domain = F(0, Inf)g

    if iszero(a)
        a = a ∩ domain
        x > zero(x) && return zero(a)
        return emptyinterval(a)
    end

    isinteger(x) && return a^(round(Int, x))
    x == 0.5 && return sqrt(a)

    a = a ∩ domain
    (isempty(x) || isempty(a)) && return emptyinterval(a)

    xx = atomic(Interval{BigFloat}, x)

    # @round() can't be used directly, because both arguments may
    # Inf or -Inf, which throws an error
    # lo = @round(a.lo^xx.lo, a.lo^xx.lo)
    lolod = @round_down(a.lo^xx.lo)
    lolou = @round_up(a.lo^xx.lo)
    lo = (lolod == Inf || lolou == -Inf) ?
        wideinterval(lolod) : Interval(lolod, lolou)

    # lo1 = @round(a.lo^xx.hi, a.lo^xx.hi)
    lohid = @round_down(a.lo^xx.hi)
    lohiu = @round_up(a.lo^xx.hi)
    lo1 = (lohid == Inf || lohiu == -Inf) ?
        wideinterval(lohid) : Interval(lohid, lohiu)

    # hi = @round(a.hi^xx.lo, a.hi^xx.lo)
    hilod = @round_down(a.hi^xx.lo)
    hilou = @round_up(a.hi^xx.lo)
    hi = (hilod == Inf || hilou == -Inf) ?
        wideinterval(hilod) : Interval(hilod, hilou)

    # hi1 = @round(a.hi^xx.hi, a.hi^xx.hi)
    hihid = @round_down(a.hi^xx.hi)
    hihiu = @round_up(a.hi^xx.hi)
    hi1 = (hihid == Inf || hihiu == -Inf) ?
        wideinterval(hihid) : Interval(hihid, hihiu)

    lo = hull(lo, lo1)
    hi = hull(hi, hi1)

    return hull(lo, hi)
end

function ^(a::Interval{Rational{T}}, x::AbstractFloat) where T<:Integer
    a = Interval(a.lo.num/a.lo.den, a.hi.num/a.hi.den)
    a = a^x
    atomic(Interval{Rational{T}}, a)
end

# Rational power
function ^(a::Interval{BigFloat}, r::Rational{S}) where S<:Integer
    T = BigFloat
    domain = Interval{T}(0, Inf)

    if a == zero(a)
        a = a ∩ domain
        r > zero(r) && return zero(a)
        return emptyinterval(a)
    end

    isinteger(r) && return atomic(Interval{T}, a^round(S,r))
    r == one(S)//2 && return sqrt(a)

    a = a ∩ domain
    (isempty(r) || isempty(a)) && return emptyinterval(a)

    y = atomic(Interval{BigFloat}, r)

    a^y
end

# Interval power of an interval:
function ^(a::Interval{BigFloat}, x::Interval)
    T = BigFloat
    domain = Interval{T}(0, Inf)

    a = a ∩ domain

    (isempty(x) || isempty(a)) && return emptyinterval(a)

    lo1 = a^x.lo
    lo2 = a^x.hi
    lo1 = hull(lo1, lo2)

    hi1 = a^x.lo
    hi2 = a^x.hi
    hi1 = hull(hi1, hi2)

    hull(lo1, hi1)
end

function sqr(a::Interval{T}) where T<:Real
    return a^2
end

"""
    pow(x::Interval, n::Integer)

A faster implementation of `x^n`, currently using `power_by_squaring`.
`pow(x, n)` will usually return an interval that is slightly larger than that
calculated by `x^n`, but is guaranteed to be a correct
enclosure when using multiplication with correct rounding.
"""
function pow(x::Interval, n::Integer)  # fast integer power

    isempty(x) && return x

    if iseven(n) && 0 ∈ x

        return hull(zero(x),
                    hull(Base.power_by_squaring(Interval(mig(x)), n),
                        Base.power_by_squaring(Interval(mag(x)), n))
            )

    else

      return hull( Base.power_by_squaring(Interval(x.lo), n),
                    Base.power_by_squaring(Interval(x.hi), n) )

    end

end

function pow(x::Interval, y)  # fast real power, including for y an Interval

    isempty(x) && return x

    return exp(y * log(x))

end




for f in (:exp, :expm1)
    @eval begin
        function ($f)(a::Interval{T}) where T
            isempty(a) && return a
            @round( ($f)(a.lo), ($f)(a.hi) )
        end
    end
end

for f in (:exp2, :exp10)

    @eval function ($f)(x::BigFloat, r::RoundingMode)  # add BigFloat functions with rounding:
            setrounding(BigFloat, r) do
                ($f)(x)
            end
        end

    @eval ($f)(a::Interval{Float64}) = atomic(Interval{Float64}, $f(big53(a)))  # no CRlibm version

    @eval function ($f)(a::Interval{BigFloat})
            isempty(a) && return a
            @round( ($f)(a.lo), ($f)(a.hi) )
        end
end


for f in (:log, :log2, :log10, :log1p)

    @eval function ($f)(a::Interval{T}) where T
            domain = Interval{T}(0, Inf)
            a = a ∩ domain

            (isempty(a) || a.hi ≤ zero(T)) && return emptyinterval(a)

            @round( ($f)(a.lo), ($f)(a.hi) )

        end
end
