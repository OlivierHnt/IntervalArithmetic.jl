"""
    Domain{L,R}(lo, hi)

Domain of a real function. The type parameters `L` and `R` must be `:open` or
`:closed`, and determine whether the corresponding endpoint belongs to the
domain. A domain is empty whenever `hi < lo`, or `hi == lo` with an open
endpoint.
"""
struct Domain{L,R,T,S}
    lo :: T
    hi :: S

    function Domain{L,R,T,S}(lo::T, hi::S) where {L,R,T,S}
        (L ∈ (:open, :closed) && R ∈ (:open, :closed)) ||
            return throw(ArgumentError("Domain bound must be either :open or :closed, got $L and $R instead"))
        return new{L,R,T,S}(lo, hi)
    end
end

Domain{L,R}(lo::T, hi::S) where {L,R,T,S} = Domain{L,R,T,S}(lo, hi)
Domain((lo, L)::Tuple, (hi, R)::Tuple) = Domain{L,R}(lo, hi)
Domain(x::Interval) = Domain{:closed,:closed}(inf(x), sup(x))
Domain() = Domain{:open,:open}(Inf, -Inf)

lowerbound(d::Domain{L,R}) where {L,R} = (d.lo, L)
upperbound(d::Domain{L,R}) where {L,R} = (d.hi, R)

inf(d::Domain) = d.lo
sup(d::Domain) = d.hi

rightof(x::Real, (val, bound)::Tuple) = ifelse(bound === :closed, val ≤ x, val < x)

leftof(x::Real, (val, bound)::Tuple) = ifelse(bound === :closed, x ≤ val, x < val)

function leftof(d1::Domain, d2::Domain)
    val1, bound1 = upperbound(d1)
    val2, bound2 = lowerbound(d2)
    val1 == val2 && return !(bound1 === bound2 === :closed)
    return val1 < val2
end

in_domain(x::Real, d::Domain) = rightof(x, lowerbound(d)) && leftof(x, upperbound(d))

function isempty_domain(d::Domain{L,R}) where {L,R}
    d.lo == d.hi && return !(L === R === :closed)
    return d.hi < d.lo
end

function intersect_domain(d1::Domain, d2::Domain)
    lo, L = _innermost(lowerbound(d1), lowerbound(d2), >)
    hi, R = _innermost(upperbound(d1), upperbound(d2), <)
    d = Domain{L,R}(lo, hi)
    return isempty_domain(d) ? Domain() : d
end
# tightest of two like bounds; at equal values an open bound excludes the endpoint
function _innermost((val1, bound1)::Tuple, (val2, bound2)::Tuple, isinner)
    val1 == val2 && return (val1, ifelse(bound1 === bound2, bound1, :open))
    return isinner(val1, val2) ? (val1, bound1) : (val2, bound2)
end

"""
    Constant(value)

Constant function compatible with interval arithmetic: it returns an interval
enclosing `value` for an interval input, and `value` itself otherwise. In
contrast, `Returns(value)` from Base outputs `value` even for an interval
input, which shortcircuits the propagation of intervals and loses the
associated guarantee of correctness.

```jldoctest
julia> using IntervalArithmetic

julia> setdisplay(:full);

julia> c = Constant(1.2)
Constant{Float64}(1.2)

julia> c(22.2)
1.2

julia> c(interval(0, 1.3))
Interval{Float64}(1.2, 1.2, com, true)
```
"""
struct Constant{T}
    value :: T
end

function (constant::Constant)(x::Interval)
    y = interval(constant.value)
    return _unsafe_interval(bareinterval(y), decoration(y), isguaranteed(x))
end

(constant::Constant)(::Real) = constant.value

"""
    Piecewise(pairs::Pair...; continuity = ntuple(i -> -1, length(pairs) - 1))

Function defined by pieces, each pair mapping a [`Domain`](@ref) to a function.
Support both real and interval inputs. The domains must be ordered and
pairwise disjoint. For constant pieces, use [`Constant`](@ref) to preserve the
guarantee of correctness of interval inputs.

The `k`-th element of `continuity` gives the regularity of the function at the
junction between the `k`-th and `(k+1)`-th domains:
- `-1`: discontinuous;
- `n ≥ 0`: `n` times continuously differentiable; only relevant beyond `0` when
  differentiating via ForwardDiff.jl.
It determines the decoration of an interval input spanning a junction; a
junction with a gap between the domains is always treated as discontinuous.

An interval input not contained in the union of the domains yields the `trv`
decoration, and one disjoint from it yields the empty interval. A real input
outside every domain throws a `DomainError`.

```jldoctest
julia> using IntervalArithmetic

julia> setdisplay(:full);

julia> myabs = Piecewise(
          Domain{:open,:closed}(-Inf, 0) => x -> -x,
          Domain{:open,:open}(0, Inf) => identity
       );

julia> myabs(-22.3)
22.3

julia> myabs(interval(-5, 5))
Interval{Float64}(0.0, 5.0, def, true)
```
"""
struct Piecewise{N,M,D<:NTuple{N,Domain},F<:NTuple{N,Any},S<:NTuple{M,Real}}
    domains       :: D
    fs            :: F
    continuity    :: NTuple{M, Int}
    singularities :: S

    function Piecewise(
            domains::NTuple{N,Domain},
            fs::NTuple{N,Any},
            continuity::NTuple{M,Int},
            singularities::NTuple{M,Real}) where {N,M}

        N != M+1 && throw(ArgumentError(
                "a Piecewise function with N pieces must have N - 1 singularities, got $N pieces and $M singularities."))

        return new{N,M,typeof(domains),typeof(fs),typeof(singularities)}(domains, fs, continuity, singularities)
    end
end

function Piecewise(
        domains::NTuple{Nd,Domain},
        fs::NTuple{Nf,Any},
        continuity::NTuple{M,Integer} = ntuple(i -> -1, Val(Nd-1))) where {Nd,Nf,M}

    Nd != Nf && return throw(ArgumentError("the number of domains and the number of functions don't match"))

    Nd-1 != M  && return throw(ArgumentError("$M junction points but $(Nd - 1) are expected based on the number of domains $Nd"))

    for k ∈ 1:Nd-1
        leftof(domains[k], domains[k+1]) || return throw(ArgumentError("domains are either not ordered or not disjoint"))
    end

    return Piecewise(domains, fs, continuity, sup.(domains[1:Nd-1]))
end

Piecewise(pairs::Vararg{Pair,N}; continuity = ntuple(i -> -1, Val(N-1))) where {N} =
    Piecewise(first.(pairs), last.(pairs), Tuple(continuity))

domains(piecewise::Piecewise) = piecewise.domains
pieces(piecewise::Piecewise) = zip(domains(piecewise), piecewise.fs)

discontinuities(piecewise::Piecewise, order::Integer = 0) =
    [s for (s, C) ∈ zip(piecewise.singularities, piecewise.continuity) if C < order]

#

function (piecewise::Piecewise)(x::Real)
    for (domain, f) ∈ pieces(piecewise)
        in_domain(x, domain) && return f(x)
    end
    return throw(DomainError(x, "piecewise function was called outside of its domain $(domain_string(piecewise))"))
end

function (piecewise::Piecewise)(X::Interval{T}) where {T}
    input_domain = Domain(X)
    t = isguaranteed(X)
    overlap_domain(input_domain, piecewise) || return _unsafe_interval(emptyinterval(BareInterval{T}), trv, t)

    if !in_domain(input_domain, piecewise)
        dec = trv
    elseif any(s -> in_domain(s, input_domain), discontinuities(piecewise))
        dec = def
    else
        dec = com
    end

    outputs = Interval{T}[]
    for (piece_domain, f) ∈ pieces(piecewise)
        piece_input = intersect_domain(input_domain, piece_domain)
        isempty_domain(piece_input) && continue
        push!(outputs, f(_unsafe_interval(bareinterval(inf(piece_input), sup(piece_input)), decoration(X), t)))
    end

    dec = min(dec, minimum(decoration, outputs))
    return setdecoration(reduce(hull, outputs), dec)
end

#

# whether `domain` is contained in the union of the (ordered) domains of `piecewise`
function in_domain(domain, piecewise)
    v, b = lowerbound(domain)
    hv, hb = upperbound(domain)
    for piece ∈ domains(piecewise)
        pv, pb = upperbound(piece)
        (pv < v || (pv == v && !(b === pb === :closed))) && continue
        plv, plb = lowerbound(piece)
        (plv < v || (plv == v && (plb === :closed || b === :open))) || return false
        (hv < pv || (hv == pv && (pb === :closed || hb === :open))) && return true
        v, b = pv, ifelse(pb === :closed, :open, :closed)
    end
    return false
end

overlap_domain(domain, piecewise) =
    any(d -> !isempty_domain(intersect_domain(domain, d)), domains(piecewise))

#

function Base.show(io::IO, ::MIME"text/plain", piecewise::Piecewise)
    print(io, "Piecewise function with $(length(domains(piecewise))) pieces:")
    for (domain, f) ∈ pieces(piecewise)
        println(io)
        print(io, "  $(domain_string(domain)) -> $(repr(f))")
    end
end

function domain_string(d::Domain{L,R}) where {L,R}
    left  = ifelse(L === :closed, '[', '(')
    right = ifelse(R === :closed, ']', ')')
    return "$left$(d.lo), $(d.hi)$right"
end

domain_string(piecewise::Piecewise) = join(domain_string.(domains(piecewise)), " ∪ ")
