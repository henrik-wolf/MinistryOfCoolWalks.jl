using ArchGDAL
using Plots
function test_buffer_approach(buffer, distance)
    distance /= sqrt(2)
    l1 = ArchGDAL.createlinestring([distance, 1 + distance], [0.0, 1.0])
    l2 = ArchGDAL.createlinestring([0.5, 1.5], [0.5, 1.5])
    l3 = ArchGDAL.union(l1, l2)
    b3 = ArchGDAL.buffer(l3, buffer, 0)
    return (ArchGDAL.geomarea(b3) - 2*buffer^2) / 2buffer
end

buffers = range(1e-15, 1e-5, 100)
distances = range(1e-15, 1e-13, 100)
union_lengths = [test_buffer_approach(b, d) for b in buffers, d in distances]
begin
    buffer = 0.2
    distance = 0.1
    points = 1
    distance /= sqrt(2)  # diagonal offset...
    l1 = ArchGDAL.createlinestring([distance, 1 + distance], [-distance, 1 - distance])
    l2 = ArchGDAL.createlinestring([0.5, 1.5], [0.5, 1.5])
    b1 = ArchGDAL.buffer(l1, buffer, points)
    b2 = ArchGDAL.buffer(l2, buffer, points)
    l3 = ArchGDAL.union(l1, l2)
    b3 = ArchGDAL.buffer(l3, buffer, points)
    plot(ratio=1, framestyle=:box)
    for l in [l1, l2]
        plot!(l, ratio=1, lw=8, alpha=0.3, label="length=$(round(ArchGDAL.geomlength(l); digits=3))")
    end
    for b in [b1, b2, b3]
        area = 1/2 * 4*points * buffer^2 * sin(2π/(4*points))
        ngeoms = geomtrait(b) isa MultiPolygonTrait ? ngeom(b) : 1
        plot!(b, alpha=0.1, label="length=$(round((ArchGDAL.geomarea(b) - ngeoms * area)/2buffer; digits=3))")
    end
    plot!([0], [0], label="real_length=$(round(2 * sqrt(2) - sqrt(2)/2;digits=3))")
    p1 = plot!(legend=:bottomright)
    target = 2*sqrt(2) - sqrt(2)/2
    deviation = 0.00001
    p2 = heatmap(distances, buffers, union_lengths, xlabel="distance", ylabel="buffer", framestyle=:box, clim=(0.99target, 1.01target))
    contour!(p2, distances, buffers, union_lengths, levels=[2*sqrt(2)], c=:red, label="r")
    contour!(p2, distances, buffers, union_lengths, levels=[(1-deviation) * target, target, (1+deviation) * target], c=:green, label="g")
    plot(p1, p2, size=(1000, 500))
end

# code for drawing the distance matrix for overlapping lines
begin
    distances = [ArchGDAL.distance(l1, l2) for l1 in lines_normal, l2 in lines_normal]
    p1 = plot(ratio=1)
    plot!(p1, lines, label="linear", lw=16, alpha=0.2)
    for (i, line) in enumerate(lines_normal)
        plot!(p1, line, lw=8, alpha=0.6, label=i)
    end
    p2 = heatmap(1:6, 1:6, distances, transpose=false, yflip=true, clim=(0, 3))
    plot(p1, p2, size=(2000, 1000))
end