"""

    early_stopping_dijkstra(g::AbstractGraph, s::U, distmx::AbstractMatrix{T}=weights(g); max_length::T=typemax(T)) where {T<:Real,U<:Integer}

Calculates dijkstras shortest paths, but treats edges which would make the shortest path longer than `max_length` as non-existent.

Nearly all of this code was taken from the [Graphs.jl dijkstra implementation](https://github.com/JuliaGraphs/Graphs.jl/blob/a10ca671a209011f268d0770d36202dbae3029f7/src/shortestpaths/dijkstra.jl#L70).

Behaves like `dijkstra_shortest_paths(g, i; trackvertices=true)`, if all other arguments are omitted.
"""
function early_stopping_dijkstra(g::AbstractGraph, s::U, distmx::AbstractMatrix{T}=weights(g); max_length::T=typemax(T)) where {T<:Real,U<:Integer}
    nvg = nv(g)
    dists = fill(typemax(T), nvg)
    parents = zeros(U, nvg)
    visited = zeros(Bool, nvg)

    pathcounts = zeros(nvg)
    preds = fill(Vector{U}(), nvg)
    H = PriorityQueue{U,T}()
    # fill creates only one array.

    dists[s] = zero(T)
    visited[s] = true
    pathcounts[s] = one(Float64)
    H[s] = zero(T)

    closest_vertices = Vector{U}()  # Maintains vertices in order of distances from source
    sizehint!(closest_vertices, nvg)

    while !isempty(H)
        u = dequeue!(H)

        push!(closest_vertices, u)

        d = dists[u] # Cannot be typemax if `u` is in the queue
        for v in outneighbors(g, u)
            alt = d + distmx[u, v]
            alt > max_length && continue

            if !visited[v]
                visited[v] = true
                dists[v] = alt
                parents[v] = u

                pathcounts[v] += pathcounts[u]
                H[v] = alt
            elseif alt < dists[v]
                dists[v] = alt
                parents[v] = u
                #615
                pathcounts[v] = pathcounts[u]
                H[v] = alt
            elseif alt == dists[v]
                pathcounts[v] += pathcounts[u]
            end
        end
    end

    for s in vertices(g)
        if !visited[s]
            push!(closest_vertices, s)
        end
    end

    pathcounts[s] = one(Float64)
    parents[s] = 0
    empty!(preds[s])

    return Graphs.DijkstraState{T,U}(parents, dists, preds, pathcounts, closest_vertices)
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

"""

    betweenness_centralities(state, start)

Calculates the node and edge betweennesses encoded in the dijkstra `state`, with shortest paths from `s`.
Assumes all paths to be unique (does not use to `state.predecessors`) field.
Does not include the endpoints, and is not normalised.
Most of this code was taken from the [Graphs.jl betweenness_centrality implementation](https://github.com/JuliaGraphs/Graphs.jl/blob/a10ca671a209011f268d0770d36202dbae3029f7/src/centrality/betweenness.jl#L45).
"""
function betweenness_centralities(state::Graphs.DijkstraState, s::T) where {T<:Integer}
    n_v = length(state.parents) # this is the ttl number of vertices
    vertex_betweenness = spzeros(n_v)
    edge_betweenness = spzeros(n_v, n_v)

    δ = zeros(n_v)
    P = state.parents

    # make sure the source index has no parents.
    P[s] = 0
    # we need to order the source vertices by decreasing distance for this to work.
    S = reverse(state.closest_vertices) #Replaced sortperm with this
    for w in S
        coeff = (1.0 + δ[w])
        v = P[w]
        if v > 0
            δ[v] += coeff
            edge_betweenness[v, w] += coeff
        end
        if w != s
            vertex_betweenness[w] += δ[w]
        end
    end
    return vertex_betweenness, edge_betweenness
end