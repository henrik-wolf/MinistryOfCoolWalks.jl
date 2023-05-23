function early_stopping_dijkstra(g, s, distmx=weights(g))
end


"""

    to_SimpleWeightedDiGraph(g, distmx)

converts directed graph `g` with weights in `distmx` into `SimpleWeightedDiGraph` with weights from distmx.
Due to the way we construct it here, edges with zero length are kept as structural nonzeros in the SWG.
"""
function to_SimpleWeightedDiGraph(g, distmx=weights(g))
    if is_directed(g)
        s = src.(edges(g))
        d = dst.(edges(g))
    else
        throw(ArgumentError("$(typeof(g)) is not directed. Can not convert to SimpleWeightedDiGraph."))
    end
    ws = [distmx[s, d] for (s, d) in zip(s, d)]
    SimpleWeightedDiGraph(s, d, ws)
end

#### Our own, low budget implementation of the johnson_shortest_paths because we can not subtract ShadowWeights.
"""

    Graphs.johnson_shortest_paths(g::AbstractGraph{U}, distmx::AbstractMatrix{T}) where {U<:Integer,T<:ShadowWeight}

version of `johnson_shortest_paths` for `distmx` with `ShadowWeight` as entries, since we can not subtract these.
Converts the graph and weights to `SimpleWeightedDiGraph` (while making sure that zero length edges are not dropped (see `to_SimpleWeightedDiGraph`)),
to speed up the calculation and abstract away the complexity.
(In reality, this is just a bunch of `dijkstra_shortest_paths`, wrapped to return a `JohnsonState`).
"""
function Graphs.johnson_shortest_paths(g::AbstractGraph{U}, distmx::AbstractMatrix{T}) where {U<:Integer,T<:ShadowWeight}
    g = to_SimpleWeightedDiGraph(g, distmx)
    nvg = nv(g)
    dists = Matrix{T}(undef, nvg, nvg)
    parents = Matrix{U}(undef, nvg, nvg)
    @showprogress 1 "johnson_shortest_paths" for v in vertices(g)
        dijk_state = dijkstra_shortest_paths(g, v)
        dists[v, :] = dijk_state.dists
        parents[v, :] = dijk_state.parents
    end
    return Graphs.JohnsonState(dists, parents)
end