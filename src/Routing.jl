"""

    ShadowWeight(a::Float64, shade::Float64, sun::Float64) <: Real

Typ representing the weight on one edge.
- `a` represents the preference for shadow or sun, where `a==1.0` signifies indifference, `a ∈ (1.0, Inf)` favours shaded edges,
and `a ∈ (0.0, 1.0)` favours sunny edges. Value must be in `(0.0, Inf)`, otherwise, an Error is thrown.
- `shade` represents the (real world) length of the edge in shade. Has to be non-negative, otherwise, an Error is thrown.
- `sun` represents the (real world) length of the edge in the sun. Has to be non-negative, otherwise, an Error is thrown.
- if shade or sun is `Inf`, the other value has to be `Inf` as well, otherwise, an error is thrown.
This also means, that `shade+sun=real_world_street_length`.

    unsafe_ShadowWeight(a, shade, sun)

unsafe constructor for `ShadowWeight`, does not validate the inputs, used internally when we know that all conditions are fulfilled.
"""
struct ShadowWeight <: Real
    a::Float64
    shade::Float64
    sun::Float64
    function ShadowWeight(a, shade, sun)
        if 0.0 < a < Inf
            if 0.0 <= sun < Inf && 0.0 <= shade < Inf || sun == shade == Inf
                return unsafe_ShadowWeight(a, shade, sun)
            else
                error("shade and sun have to be non negative and finite or both Inf. (currently $shade and $sun)")
            end
        else
            error("a can only be in (0, Inf) (currently: $a)")
        end
    end
    global unsafe_ShadowWeight(a, shade, sun) = new(a, shade, sun)
end

"""

    zero(x::ShadowWeight)
    zero(::Type{ShadowWeight})

returns the zero value associated with the `ShadowWeight` Real. Equivalent to `ShadowWeight(0.0, 0.0, 0.0)`.
"""
Base.zero(x::ShadowWeight) = zero(typeof(x))
Base.zero(::Type{ShadowWeight}) = unsafe_ShadowWeight(1.0, 0.0, 0.0)


"""

    typemax(x::ShadowWeight) = typemax(typeof(x))
    typemax(::Type{ShadowWeight})

returns the maximum value associated with the `ShadowWeight` Real. Equivalent to `ShadowWeight(0.0, Inf, Inf)`
"""
Base.typemax(x::ShadowWeight) = typemax(typeof(x))
Base.typemax(::Type{ShadowWeight}) = unsafe_ShadowWeight(1.0, Inf, Inf)

"""

    real_length(w::ShadowWeight)

returns the real length of a `ShadowWeight`. (That is: `sun+shade`).
"""
real_length(w::ShadowWeight) = w.sun + w.shade

"""

    felt_length(w::ShadowWeight)

returns the felt length of a `ShadowWeight`. It is defined as: `a * sun + shade`
"""
@inline felt_length(w::ShadowWeight) = w.a * w.sun + w.shade

"""

    ==(a::ShadowWeight, b::ShadowWeight)

Two `ShadowWeight`s are the considered equal, if their `felt_length`s are the same.
"""
@inline Base.:(==)(a::ShadowWeight, b::ShadowWeight) = felt_length(a) == felt_length(b)

"""

    <(a::ShadowWeight, b::ShadowWeight)

a `ShadowWeight` is less than another, if its `felt_length` is less than the one of the other.
"""
@inline Base.:<(a::ShadowWeight, b::ShadowWeight) = felt_length(a) < felt_length(b)

"""

    +(a::ShadowWeight, b::ShadowWeight)

Two general `ShadowWeight`s are addable, if their `a` fields match. The result is a new `ShadowWeight`
with the same `a` value and the sum of the `sun` and `shadow` fields of both `ShadowWeights`.
The return value is generated using `unsafe_ShadowWeight` due to performance considerations. Make sure
that you only input valid `ShadowWeight`s.

Special care has to be taken when adding values which identify with either zero or infinity. In this case,
we ignore the condition of the `a` fields having to be the same and return just the appropriate input.
"""
@inline function Base.:+(a::ShadowWeight, b::ShadowWeight)
    # for some reason, routing is a lot faster if we use felt_length (if you have any idea why, let me know...)
    fla = felt_length(a)
    flb = felt_length(b)
    fla == 0.0 && return b
    flb == 0.0 && return a
    fla == Inf && return a
    flb == Inf && return b
    # this also takes some time, not sure if we want to leave it out though...
    @assert a.a == b.a "cant add ShadowWeight s if a is not the same a.a=$(a.a), b.a=$(b.a)"
    return unsafe_ShadowWeight(a.a, a.shade + b.shade, a.sun + b.sun)
end

"""

    *(a::ShadowWeight, b::Bool)
    *(a::Bool, b::ShadowWeight)

Multiplication with Boolean. Returns `a` if `b` is true, otherwise `zero(ShadowWeight)`.
"""
Base.:*(a::ShadowWeight, b::Bool) = b ? a : zero(ShadowWeight)
Base.:*(a::Bool, b::ShadowWeight) = b * a

Base.:*(a::AbstractFloat, b::ShadowWeight) = ShadowWeight(b.a, a * b.shade, a * b.sun)
Base.:*(a::ShadowWeight, b::AbstractFloat) = b * a
Base.:*(a::Integer, b::ShadowWeight) = ShadowWeight(b.a, a * b.shade, a * b.sun)
Base.:*(a::ShadowWeight, b::Integer) = b * a



"""

    ShadowWeights{T<:Integer,U<:Real} <: AbstractMatrix{ShadowWeight}

Abstract Matrix type of `ShadowWeight`s, usable as weights in graph-algorithms.
"""
struct ShadowWeights{T<:Integer,U<:Real} <: AbstractMatrix{ShadowWeight}
    a::Float64
    full_weights::MetaGraphs.MetaWeights{T,U}
    shadow_weights::MetaGraphs.MetaWeights{T,U}

    function ShadowWeights(a, full_weights::I, shadow_weights::I) where {T<:Integer,U<:Real,I<:MetaGraphs.MetaWeights{T,U}}
        max_U = typemax(U)
        max_full = mapreduce(<(max_U), &, full_weights; init=true)
        max_shade = mapreduce(<(max_U), &, shadow_weights; init=true)
        if 0.0 < a < Inf && max_full && max_shade
            return new{T,U}(a, full_weights, shadow_weights)
        else
            error("a can only be in (0.0, Inf) (currently: $a), weights have to be less than typemax($U)")
        end
    end
end


"""

    ShadowWeights(a, full_weights::I, shadow_weights::I) where {T<:Integer,U<:Real,I<:MetaGraphs.MetaWeights{T,U}}

Base constructor for `ShadowWeights`. `a` has to be in `(0.0, Inf)`, otherwise an error will be thrown.
`full_weights` and `shadow_weights` are the full lengths of the edges and the length of these edges in shadow, respectively.
Make sure that `all(shadow_weights .<= full_weights`) == true` for all edges which exist, otherwise, the results might not be what you expect.
Constructor checks that `maximum(shadow_weights)<typemax(U)` and `maximum(full_weights)<typemax(U)`. (TODO: Maybe there is a faster way of doing this?)

    ShadowWeights(g::AbstractMetaGraph, a; shadow_source=:shadowed_length)

Constructs the `ShadowWeights` from a `MetaGraph` and the `a` value. (See the docs of `ShadowWeight` for an explanation of the parameter.)

Assumes that `weightfield(g)` encodes the full length of each edge. Additionally, it is possible to set the field from which the length of the shadows
will be extracted. The default value is `:shadowed_length`.
"""
function ShadowWeights(g::AbstractMetaGraph, a; shadow_source=:shadowed_length)
    full_weights = weights(g)
    shadow_weights = @set full_weights.weightfield = shadow_source
    ShadowWeights(a, full_weights, shadow_weights)
end

"""

    size(x::ShadowWeights)

The size of a `ShadowWeights` is the size of the `full_weights` field.
"""
Base.size(x::ShadowWeights) = size(x.full_weights)

"""

    getindex(w::ShadowWeights, u::Integer, v::Integer)

Get the `ShadowWeight` at index `u,v`. The length in the sun is calculated as `abs(full_length-shadow_length)`,
to account for numerical deviations where the edge might be slightly shorter than the shadow covering it.
If the length in the shade is systematically longer than the full edge, this will not Error, but fail silently.
Since we check the maximum values on construction, we can use `unsafe_ShadowWeight` to create the return value.
"""
@inline function Base.getindex(w::ShadowWeights, u::Integer, v::Integer)
    full_length = w.full_weights[u, v]
    shadow_length = w.shadow_weights[u, v]
    return unsafe_ShadowWeight(w.a, shadow_length, abs(full_length - shadow_length))
end

#### Hereafter, we build a different approach, not using a custom real, but rather a more elaborate getindex method.

"""

    ShadowWeightsLight{T<:Integer,U<:Real} <: AbstractMatrix{U}

AbstractMatrix type, usable in graph algorithms, alternative approach to using `ShadowWeights`.
"""
struct ShadowWeightsLight{T<:Integer,U<:Real} <: AbstractMatrix{U}
    a::Float64
    geom_weights::MetaGraphs.MetaWeights{T,U}
    shadow_weights::MetaGraphs.MetaWeights{T,U}
    function ShadowWeightsLight(a, geom_weights::I, shadow_weights::I) where {T<:Integer,U<:Real,I<:MetaGraphs.MetaWeights{T,U}}
        max_U = typemax(U)
        max_full = mapreduce(<(max_U), &, geom_weights; init=true)
        max_shade = mapreduce(<(max_U), &, shadow_weights; init=true)
        if 0.0 < a < Inf && max_full && max_shade
            return new{T,U}(a, geom_weights, shadow_weights)
        else
            error("a can only be in (0.0, Inf) (currently: $a), weights have to be less than typemax($U)")
        end
    end
end


"""

    ShadowWeightsLight(a, geom_weights::I, shadow_weights::I) where {T<:Integer,U<:Real,I<:MetaGraphs.MetaWeights{T,U}}

Base constructor for `ShadowWeightsLight`. `a` has to be in `(0.0, Inf)`, otherwise an error will be thrown.
`geom_weights` and `shadow_weights` are the full lengths of the edges and the length of these edges in shadow, respectively.
Make sure that `all(shadow_weights .<= geom_weights) == true`, otherwise, the results might not be what you expect.
Constructor checks that `maximum(shadow_weights)<typemax(U)` and `maximum(full_weights)<typemax(U)`. (TODO: Maybe there is a faster way of doing this?)

    ShadowWeightsLight(g::AbstractMetaGraph, a; shadow_source=:shadowed_length)

Constructs the `ShadowWeightsLight` from a `MetaGraph` and the `a` value. (See `getindex(m::ShadowWeightsLight, ...)` for an explanation of this parameter.)

Assumes that `weightfield(g)` encodes the full length of each edge. Additionally, it is possible to set the field from which the length of the shadows
will be extracted. The default value is `:shadowed_length`.
"""
function ShadowWeightsLight(g::AbstractMetaGraph, a; shadow_source=:shadowed_length)
    full_weights = weights(g)
    shadow_weights = @set full_weights.weightfield = shadow_source
    ShadowWeightsLight(a, full_weights, shadow_weights)
end

Base.show(io::IO, x::ShadowWeightsLight) = print(io, "ShadowWeightsLight with a=$(x.a)")
Base.show(io::IO, z::MIME"text/plain", x::ShadowWeightsLight) = show(io, x)

"""

    getindex(w::ShadowWeightsLight{T,U}, u::Integer, v::Integer)::U where {T<:Integer} where {U<:Real}

Get the length of an edge from u to v in the `felt_length`, defined as:

`a * sun_length + shadow_length`. `a` represents the preference for shadow or sun,
where `a==1.0` signifies indifference, `a ∈ (0.0, Inf)` favours shaded edges, and `a ∈ (0.0, 1.0)` favours sunny edges.
"""
function Base.getindex(w::ShadowWeightsLight{T,U}, u::Integer, v::Integer)::U where {T<:Integer} where {U<:Real}
    shadow_length = w.shadow_weights[u, v]
    sun_length = abs(w.geom_weights[u, v] - shadow_length)

    weight = shadow_length + w.a * sun_length
    return U(weight)
end


"""

    size(x::ShadowWeightsLight)

size of `ShadowWeightsLight` is size of geometry weights contained.
"""
Base.size(x::ShadowWeightsLight) = MetaGraphs.size(x.geom_weights)

"""

    reevaluate_distances(state, weights)

reevaluates the shortest paths in state with the given weight matrix. This function is neccessary 
since the approach with `ShadowWeightsLight` weights only returns the felt lengths. To make these values comparable,
we need the path lengths under the same weight matrix. This algorithm works only for `FloydWarshallState`s, as it uses
a modified floyd warshall algorithm to do so.

Please note that the results from this algorithm might vary from the results which can be obtained from other implementations
of this reevaluation (mainly `reevaluate_distances_slow`), if there exist multiple shortest paths in the felt measure.
In this, faster implementation, the one that ends up getting picked for the real length depends on the order in which
the nodes are checked. But the routing output does so as well, so on average, we should be fine.
"""
function reevaluate_distances(state, distmx)
    T = eltype(distmx)
    U = eltype(state.dists)
    nvg = size(state.dists)[1]
    # if we do checkbounds here, we can use @inbounds later
    checkbounds(distmx, Base.OneTo(nvg), Base.OneTo(nvg))
    checkbounds(state.dists, Base.OneTo(nvg), Base.OneTo(nvg))
    checkbounds(state.parents, Base.OneTo(nvg), Base.OneTo(nvg))

    dists = fill(typemax(T), (Int(nvg), Int(nvg)))

    for v in 1:nvg
        dists[v, v] = zero(T)
    end
    for e in (i for i in CartesianIndices(state.parents) if state.parents[i] == i[1])
        d = distmx[e]
        dists[e] = min(d, dists[e])
    end
    for pivot in 1:nvg
        # Relax dists[u, v] = min(dists[u, v], dists[u, pivot]+dists[pivot, v]) for all u, v
        for v in 1:nvg
            d_old = state.dists[pivot, v]
            d = dists[pivot, v]
            d == typemax(T) && continue
            for u in 1:nvg
                ans = (dists[u, pivot] == typemax(T) ? typemax(T) : dists[u, pivot] + d)
                ans_old = (state.dists[u, pivot] == typemax(U) ? typemax(U) : state.dists[u, pivot] + d_old)
                if ans_old == state.dists[u, v] && ans != typemax(T)
                    dists[u, v] = ans
                end
            end
        end
    end
    fws = Graphs.FloydWarshallState(dists, state.parents)
    return fws
end


#### this is testing stuff
"""

    get_path_length(path, weights)

function to calculate the length of a path given by a vector of node ids in a externally supplied weight matrix. (Not exported, mainly used in Testing.)
"""
get_path_length(path, weights) = length(path) > 0 ? mapreduce((s, d) -> weights[s, d], +, @view(path[1:end-1]), @view(path[2:end]); init=zero(eltype(weights))) : typemax(eltype(weights))

"""

    reevaluate_distances_slow(state, weights)

recalculates the lengths of the paths encoded in `state` using the supplied `weights` matrix. (Not exported, mainly used in Testing, since very slow.)
"""
function reevaluate_distances_slow(state, weights)
    new_dists = similar(state.dists, eltype(weights))
    new_dists .= typemax(eltype(weights))
    @showprogress 1 "reevaluating distances" for start_from in enumerate_paths(state)
        for path in start_from
            length(path) == 0 && continue
            new_dists[path[1], path[end]] = get_path_length(path, weights)
        end
    end
    for i in axes(new_dists, 1)
        new_dists[i, i] = 0.0
    end
    return Graphs.FloydWarshallState(new_dists, state.parents)
end

#=
function myenumerate!(store, iter::Graphs.FloydWarshallState, s, d)
	if iter.parents[s, d] == 0
		for i in eachindex(store)
			store[i] = 0
		end
		return @view store[2:1:1]
	else
		store[1] = d
		pl = 2
		while d != s
			d = iter.parents[s,d]
			store[pl] = d
			pl += 1
		end
		return @view store[pl-1:-1:1]
	end	
end

function Base.iterate(iter::Graphs.FloydWarshallState)
	pc = Vector{Int64}(undef, size(iter.dists)[1])
	pview = myenumerate!(pc, iter, 1, 1)
	state = (source=1, destination=1, pathcontainer=pc)
	return pview, state
end

function Base.iterate(iter::Graphs.FloydWarshallState, state)
	a1 = axes(iter.dists, 1)
	s, d, pc = state
	if d+1 in a1
		d += 1
	elseif s+1 in a1
		s += 1
		d = 1
	else
		return nothing
	end
	pview = myenumerate!(pc, iter, s, d)
	return pview, (source=s, destination=d, pathcontainer=pc)
end

Base.IteratorSize(::Graphs.FloydWarshallState) = Base.HasShape{2}()

Base.size(iter::Graphs.FloydWarshallState) = size(iter.dists)

Base.collect(iter::Graphs.FloydWarshallState) = permutedims([collect(i) for i in iter])
=#

#=
function reevaluate_distances_iter(state, weights)
	new_dists = similar(state.dists, eltype(weights))
	new_dists .= typemax(eltype(weights))
	for path in state
		length(path) == 0 && continue
		new_dists[path[1], path[end]] = get_path_length(path, weights)
	end
	for i in axes(new_dists, 1)
		new_dists[i,i] = 0.0
	end
	return Graphs.FloydWarshallState(new_dists, state.parents)
end
=#