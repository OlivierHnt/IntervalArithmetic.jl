using Test
using IntervalArithmetic
import Makie
import Makie.GeometryBasics as GeometryBasics

@testset "Plot types" begin
    box2 = [interval(0, 1), interval(2, 4)]
    box3 = [interval(0, 1), interval(2, 4), interval(5, 9)]
    @test Makie.plottype(box2) == Makie.Poly
    @test Makie.plottype(box3) == Makie.Mesh
    @test Makie.plottype([box2, box2]) == Makie.Poly
    @test Makie.plottype([box3, box3]) == Makie.Mesh
    @test Makie.plottype([box2, box3]) == Makie.Poly
end

@testset "Poly conversion" begin
    box2 = [interval(0, 1), interval(2, 4)]
    box3 = [interval(0, 1), interval(2, 4), interval(5, 9)]
    rect = GeometryBasics.Rect2{Float64}(GeometryBasics.Vec2(0.0, 2.0), GeometryBasics.Vec2(1.0, 2.0))
    @test Makie.convert_arguments(Makie.Poly, box2) == (rect,)
    @test Makie.convert_arguments(Makie.Poly, [box2, box2]) == ([rect, rect],)
    @test_throws ArgumentError Makie.convert_arguments(Makie.Poly, box3)
    @test_throws ArgumentError Makie.convert_arguments(Makie.Poly, [interval(0, 1)])
end

@testset "Mesh conversion" begin
    box2 = [interval(0, 1), interval(2, 4)]
    box3 = [interval(0, 1), interval(2, 4), interval(5, 9)]
    mesh3, = Makie.convert_arguments(Makie.Mesh, box3)
    coords = GeometryBasics.coordinates(mesh3)
    @test length(coords) == 24 # vertices are duplicated per face for flat shading
    @test length(GeometryBasics.faces(mesh3)) == 12
    @test extrema(p -> p[1], coords) == (0, 1)
    @test extrema(p -> p[2], coords) == (2, 4)
    @test extrema(p -> p[3], coords) == (5, 9)
    mesh2, = Makie.convert_arguments(Makie.Mesh, box2)
    @test length(GeometryBasics.coordinates(mesh2)) == 4
    merged, = Makie.convert_arguments(Makie.Mesh, [box3, box3 .+ interval(10)])
    @test length(GeometryBasics.coordinates(merged)) == 48
    @test extrema(p -> p[1], GeometryBasics.coordinates(merged)) == (0, 11)
end

@testset "Wireframe conversion" begin
    box3 = [interval(0, 1), interval(2, 4), interval(5, 9)]
    wireframe, = Makie.convert_arguments(Makie.Wireframe, box3)
    @test eltype(GeometryBasics.faces(wireframe)) == GeometryBasics.QuadFace{Int}
    @test length(GeometryBasics.faces(wireframe)) == 6
    @test length(GeometryBasics.coordinates(wireframe)) == 8
    @test extrema(p -> p[3], GeometryBasics.coordinates(wireframe)) == (5, 9)
    merged, = Makie.convert_arguments(Makie.Wireframe, [box3, box3 .+ interval(10)])
    @test length(GeometryBasics.coordinates(merged)) == 16
end

@testset "Band conversion" begin
    x = [1.0, 2.0]
    y = [interval(0, 1), interval(2, 4)]
    lower, upper = Makie.convert_arguments(Makie.Band, x, y)
    @test lower == [GeometryBasics.Point2(1.0, 0.0), GeometryBasics.Point2(2.0, 2.0)]
    @test upper == [GeometryBasics.Point2(1.0, 1.0), GeometryBasics.Point2(2.0, 4.0)]
    @test_throws ArgumentError Makie.convert_arguments(Makie.Band, y, y)
end
