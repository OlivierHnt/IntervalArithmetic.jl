struct Constant{T}
    value::T
end

(constant::Constant)(::Any) = constant.value
(constant::Constant)(::Interval) = interval(constant.value)

struct Piecewise{T <: Tuple}
    pieces::T 
    continuous::Bool
end

Piecewise(pairs... ; continuous = false) = Piecewise(pairs, continuous)

domain(piecewise::Piecewise) = reduce(hull, subdomains(piecewise))
subdomains(piecewise::Piecewise) = first.(piecewise.pieces)

intersecting(X::Interval, Y::Interval) = !isempty_interval(intersect_interval(X, Y))

function (piecewise::Piecewise)(X::Interval)
    intersections = intersecting.(X, subdomains(piecewise))
    dom = domain(piecewise)
    if !issubset_interval(X, dom)
        dec = trv
    elseif count(intersections) > 1
        if piecewise.continuous
            dec = dac
        else
            dec = def
        end
    else
        dec = com
    end

    used_pieces = filter(piece -> intersecting(X, piece[1]), piecewise.pieces)
    outputs = map(used_pieces) do (region, f)
        S = IntervalArithmetic.setdecoration(intersect_interval(X, region), decoration(X))
        @show S
        return f(S)
    end

    @show outputs

    dec = min(dec, minimum(decoration.(outputs)))
    return IntervalArithmetic.setdecoration(reduce(hull, outputs), dec)
end

function (piecewise::Piecewise)(x::Real)
    for (region, f) in piecewise.pieces
        in_interval(x, region) && return f(x)
    end
    throw(DomainError("piecewise function was called with $x which is outside of its domain $(domain(piecewise))"))
end