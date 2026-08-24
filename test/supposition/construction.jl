using Test
using IntervalArithmetic
using Supposition, Supposition.Data

degenerate(a) = interval(a) === interval(a, a)

@testset "Degenerate intervals" begin
    floatgen = Data.Floats()
    @check max_examples = 1000 degenerate(floatgen)

    intgen = Data.Integers(typemin(Int) + 1, typemax(Int)) # typemin(Int) overflows in `//`
    rationalgen = @composed function _rational(num = intgen, den = intgen)
        assume!(!(iszero(num) && iszero(den)))
        return num // den
    end
    @check max_examples = 1000 degenerate(rationalgen)
end
