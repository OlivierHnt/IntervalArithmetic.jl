using Test
using IntervalArithmetic
import SparseArrays
using SparseArrays: SparseMatrixCSC, sparse, spzeros, nnz, findnz, dropzeros, dropzeros!

@testset "Extension loading" begin
    @test Base.get_extension(IntervalArithmetic, :IntervalArithmeticSparseArraysExt) !== nothing
end

@testset "Structural zero predicates" begin
    @test SparseArrays._iszero(interval(0, 0))
    @test !SparseArrays._iszero(interval(-1, 1))
    @test !SparseArrays._iszero(interval(1, 2))
    @test SparseArrays._iszero(interval(-0.0, 0.0))
    @test !SparseArrays._iszero(emptyinterval())
    @test !SparseArrays._iszero(nai())
    @test !SparseArrays._iszero(entireinterval())
    for x ∈ (interval(0, 0), interval(-1, 1), interval(1, 2))
        @test SparseArrays._isnotzero(x) == !SparseArrays._iszero(x)
    end
    @test SparseArrays._iszero(interval(Float32, 0, 0))
    @test SparseArrays._iszero(interval(BigFloat, 0, 0))
    @test SparseArrays._iszero(interval(0//1, 0//1))
    @test SparseArrays._iszero(interval(0, 0) + 0)
    @test !isguaranteed(interval(0, 0) + 0)
    @test SparseArrays._iszero(complex(interval(0, 0), interval(0, 0)))
end

@testset "Sparse construction" begin
    A = [interval(0, 0) interval(1, 2) ; interval(-1, 1) interval(0.0)]
    S = sparse(A)
    @test nnz(S) == 2
    @test isequal_interval(S[2, 1], interval(-1, 1))
    @test isequal_interval(S[1, 2], interval(1, 2))
    v = sparse([interval(1, 2), interval(0, 0), interval(-1, 1)])
    @test nnz(v) == 2
    @test findnz(v)[1] == [1, 3]
    Z = spzeros(Interval{Float64}, 3, 3)
    @test nnz(Z) == 0
    @test all(x -> x === zero(Interval{Float64}), Matrix(Z))
    @test nnz(sparse(interval.(zeros(3, 3)))) == 0
    for T ∈ (Float32, BigFloat, Rational{Int})
        B = [interval(T, 0, 0) interval(T, 1, 2) ; interval(T, -1, 1) interval(T, 0, 0)]
        @test nnz(sparse(B)) == 2
    end
end

@testset "dropzeros" begin
    S = SparseMatrixCSC(2, 2, [1, 3, 3], [1, 2], [interval(0, 0), interval(-1, 1)])
    S2 = dropzeros(S)
    @test nnz(S) == 2
    @test nnz(S2) == 1
    dropzeros!(S)
    @test nnz(S) == 1
    @test isequal_interval(S[2, 1], interval(-1, 1))
end

@testset "Sparse arithmetic" begin
    A = [interval(1, 2) interval(0, 0) ; interval(3, 4) interval(-1, 1)]
    S = sparse(A)
    v = [interval(1), interval(2)]
    @test all(isequal_interval.(S * v, A * v))
    @test all(isequal_interval.(Matrix(S + S), A + A))
    @test all(isequal_interval.(Matrix(S - S), A - A))
    AA = [interval(1, 4) interval(0, 0) ; interval(-1, 12) interval(-1, 1)]
    @test all(issubset_interval.(AA, Matrix(S * S)))
    @test all(issubset_interval.(AA, A * A))
    @test all(isequal_interval.(S + A, A + A))
end
