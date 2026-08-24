using Test
using IntervalArithmetic
import RecipesBase

@testset "Extension loading" begin
    @test Base.get_extension(IntervalArithmetic, :IntervalArithmeticRecipesBaseExt) !== nothing
end

@testset "Vector of 2 intervals" begin
    rd = RecipesBase.apply_recipe(Dict{Symbol,Any}(), [interval(1, 2), interval(3, 4)])
    @test length(rd) == 1
    @test rd[1].plotattributes[:seriestype] === :shape
    @test rd[1].plotattributes[:seriesalpha] == 0.5
    @test rd[1].args == ([1.0, 2.0, 2.0, 1.0, 1.0], [3.0, 3.0, 4.0, 4.0, 3.0])

    forced = RecipesBase.apply_recipe(Dict{Symbol,Any}(:seriestype => :path), [interval(1, 2), interval(3, 4)])
    @test forced[1].plotattributes[:seriestype] === :shape
    defaulted = RecipesBase.apply_recipe(Dict{Symbol,Any}(:seriesalpha => 0.9), [interval(1, 2), interval(3, 4)])
    @test defaulted[1].plotattributes[:seriesalpha] == 0.9

    vw = RecipesBase.apply_recipe(Dict{Symbol,Any}(), view([interval(1, 2), interval(3, 4), interval(5, 6)], 1:2))
    @test vw[1].args == ([1.0, 2.0, 2.0, 1.0, 1.0], [3.0, 3.0, 4.0, 4.0, 3.0])

    f32 = RecipesBase.apply_recipe(Dict{Symbol,Any}(), [interval(Float32, 1, 2), interval(Float32, 3, 4)])
    @test f32[1].args == ([1.0, 2.0, 2.0, 1.0, 1.0], [3.0, 3.0, 4.0, 4.0, 3.0])
    big = RecipesBase.apply_recipe(Dict{Symbol,Any}(), [interval(BigFloat, 1, 2), interval(BigFloat, 3, 4)])
    @test big[1].args == ([1.0, 2.0, 2.0, 1.0, 1.0], [3.0, 3.0, 4.0, 4.0, 3.0])

    u = RecipesBase.apply_recipe(Dict{Symbol,Any}(), [interval(1, Inf), interval(0, 1)])
    @test u[1].args == ([1.0, Inf, Inf, 1.0, 1.0], [0.0, 0.0, 1.0, 1.0, 0.0])
    e = RecipesBase.apply_recipe(Dict{Symbol,Any}(), [emptyinterval(), interval(0, 1)])
    @test e[1].args == ([Inf, -Inf, -Inf, Inf, Inf], [0.0, 0.0, 1.0, 1.0, 0.0])
end

@testset "Vector of 3 intervals" begin
    rd = RecipesBase.apply_recipe(Dict{Symbol,Any}(), [interval(0, 1), interval(0, 2), interval(0, 3)])
    @test length(rd) == 2

    path = rd[1]
    @test path.plotattributes[:seriestype] === :path
    @test path.plotattributes[:linecolor] === :gray
    @test path.plotattributes[:linewidth] == 0.5
    @test all(a -> length(a) == 17, path.args)
    @test path.args[1] == [0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0]
    @test path.args[2] == [0, 0, 0, 0, 0, 2, 2, 0, 0, 2, 2, 0, 2, 2, 0, 2, 2]
    @test path.args[3] == [0, 0, 3, 3, 0, 0, 3, 3, 0, 0, 0, 0, 0, 3, 3, 3, 3]

    mesh = rd[2]
    @test mesh.plotattributes[:seriestype] === :mesh3d
    @test mesh.plotattributes[:primary] === false
    @test mesh.plotattributes[:proj_type] === :persp
    @test mesh.plotattributes[:seriesalpha] == 0.5
    @test mesh.plotattributes[:linewidth] == -1.0
    @test mesh.plotattributes[:connections] == [(1,2,3), (4,2,3), (4,7,8), (7,5,6), (2,4,7), (1,6,2), (2,7,6), (7,8,5), (4,8,5), (4,5,3), (1,6,3), (6,3,5)]
    @test mesh.args == ([0, 0, 0, 0, 1, 1, 1, 1], [0, 2, 0, 2, 0, 0, 2, 2], [0, 0, 3, 3, 3, 0, 0, 3])
end

@testset "Invalid lengths" begin
    for n ∈ (0, 1, 4)
        @test_throws ArgumentError RecipesBase.apply_recipe(Dict{Symbol,Any}(), fill(interval(0, 1), n))
    end
    @test_throws ArgumentError RecipesBase.apply_recipe(Dict{Symbol,Any}(), [[interval(0, 1), interval(0, 2)], [interval(0, 1), interval(0, 2), interval(0, 3)]])
    @test_throws ArgumentError RecipesBase.apply_recipe(Dict{Symbol,Any}(), [fill(interval(0, 1), 4), fill(interval(0, 1), 4)])
end

@testset "Function enclosure over a grid" begin
    x = [1.0, 2.0]
    y = [interval(1, 2), interval(3, 4)]
    rd = RecipesBase.apply_recipe(Dict{Symbol,Any}(), x, y)
    @test length(rd) == 1
    @test rd[1].plotattributes[:fillrange] == [2.0, 4.0]
    @test rd[1].plotattributes[:fillalpha] == 0.5
    @test rd[1].plotattributes[:linewidth] == 0
    @test rd[1].args == ([1.0, 2.0], [1.0, 3.0])

    xi = [interval(1, 2), interval(5, 6)]
    rd2 = RecipesBase.apply_recipe(Dict{Symbol,Any}(), xi, y)
    @test length(rd2) == 1
    boxes = rd2[1].args[1]
    @test length(boxes) == 2
    @test all(isequal_interval.(boxes[1], [interval(1, 2), interval(1, 2)]))
    @test all(isequal_interval.(boxes[2], [interval(5, 6), interval(3, 4)]))
end

@testset "Vector of 2D boxes" begin
    boxes = [[interval(1, 2), interval(3, 4)], [interval(5, 6), interval(7, 8)]]
    rd = RecipesBase.apply_recipe(Dict{Symbol,Any}(), boxes)
    @test length(rd) == 1
    @test rd[1].plotattributes[:seriestype] === :shape
    @test rd[1].plotattributes[:seriesalpha] == 0.5
    xs, ys = rd[1].args
    @test length(xs) == length(ys) == 6 * length(boxes)
    @test all(isnan, xs[6:6:end]) && all(isnan, ys[6:6:end])
    @test xs[1:5] == [1.0, 2.0, 2.0, 1.0, 1.0]
    @test ys[1:5] == [3.0, 3.0, 4.0, 4.0, 3.0]
    @test xs[7:11] == [5.0, 6.0, 6.0, 5.0, 5.0]
    @test ys[7:11] == [7.0, 7.0, 8.0, 8.0, 7.0]
    @test eltype(xs) === Float64
    f32 = RecipesBase.apply_recipe(Dict{Symbol,Any}(), [[interval(Float32, 1, 2), interval(Float32, 3, 4)]])
    @test eltype(f32[1].args[1]) === Float64
end

@testset "Vector of 3D boxes" begin
    boxes = [[interval(0, 1), interval(0, 2), interval(0, 3)], [interval(1, 2), interval(2, 3), interval(3, 4)]]
    rd = RecipesBase.apply_recipe(Dict{Symbol,Any}(), boxes)
    @test length(rd) == 2

    path = rd[1]
    @test path.plotattributes[:seriestype] === :path
    @test all(a -> a isa Vector{Float64} && length(a) == 17 * length(boxes), path.args)
    @test !any(isnan, path.args[1])
    @test path.args[1][1:17] == [0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0]

    mesh = rd[2]
    @test mesh.plotattributes[:seriestype] === :mesh3d
    @test mesh.plotattributes[:primary] === false
    xs, ys, zs = mesh.args
    @test xs isa Vector{Vector{Float64}} && length(xs) == length(boxes)
    @test xs[1] == [0, 0, 0, 0, 1, 1, 1, 1]
    @test ys[1] == [0, 2, 0, 2, 0, 0, 2, 2]
    @test zs[1] == [0, 0, 3, 3, 3, 0, 0, 3]
    @test xs[2] == [1, 1, 1, 1, 2, 2, 2, 2]
end
