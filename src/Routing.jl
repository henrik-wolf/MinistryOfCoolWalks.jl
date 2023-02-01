"""

    ShadowWeight(a::Float64, shade::Float64, sun::Float64) <: Real

Typ representing the weight on one edge.
- `a` represents the preference for shadow or sun, where `a==0.0` signifies indifference, `a ∈ (0.0, 1.0]` favours shaded edges,
and `a ∈ [-1.0, 0.0)` favours sunny edges. Value must be in `[-1.0, 1.0]`, otherwise, an Error is thrown.
- `shade` represents the (real world) length of the edge in shade. Has to be non-negative, otherwise, an Error is thrown.
- `sun` represents the (real world) length of the edge in the sun. Has to be non-negative, otherwise, an Error is thrown.
This also means, that `shade+sun=real_world_street_length`.
"""
struct ShadowWeight <: Real
    # TODO: Is it dodgy to put a Float64 Value into the type to get rid of all problems where a is not equal?
    # TODO: Or we just allow values of a in (-1.0, 1.0)?
    a::Float64
    shade::Float64
    sun::Float64
    ShadowWeight(a, sun, shade) =
        -1.0 <= a <= 1.0 && 0.0 <= sun && 0.0 <= shade ?
        new(a, sun, shade) :
        error("a can only be in [-1, 1] (currently: $a), sun and shade can not be negative (currently $sun and $shade)")
end

"""

    zero(x::ShadowWeight)
    zero(::Type{ShadowWeight})

returns the zero value associated with the `ShadowWeight` Real. Equivalent to `ShadowWeight(0.0, 0.0, 0.0)`.
"""
Base.zero(x::ShadowWeight) = zero(typeof(x))
Base.zero(::Type{ShadowWeight}) = ShadowWeight(0.0, 0.0, 0.0)


"""

    typemax(x::ShadowWeight) = typemax(typeof(x))
    typemax(::Type{ShadowWeight})

returns the maximum value associated with the `ShadowWeight` Real. Equivalent to `ShadowWeight(0.0, Inf, Inf)`
"""
Base.typemax(x::ShadowWeight) = typemax(typeof(x))
Base.typemax(::Type{ShadowWeight}) = ShadowWeight(0.0, Inf, Inf)

"""

    real_length(w::ShadowWeight)

returns the real length of a `ShadowWeight`. (That is: `sun+shade`).
"""
real_length(w::ShadowWeight) = w.sun + w.shade

"""

    felt_length(w::ShadowWeight)

returns the felt length of a `ShadowWeight`. It is defined as:
- `(1 - a) * shade + (1 + a) * sun` for `a ∈ (-1.0, 1.0)`
- `2 * sun` for `a==1.0`
- `2 * shade` for `a==-1.0`
This added complexity is needed, to prevent some edgecases in the comparison to values which identify to infinity.
"""
function felt_length(w::ShadowWeight)
    b = w.a + 1.0
    if 0.0 < b < 2.0
        return (2.0 - b) * w.shade + b * w.sun
    elseif b == 0.0
        return 2.0 * w.shade
    else
        return 2.0 * w.sun
    end
end

"""

    ==(a::ShadowWeight, b::ShadowWeight)

Two `ShadowWeight`s are the considered equal, if their `felt_length`s are the same.
"""
Base.:(==)(a::ShadowWeight, b::ShadowWeight) = felt_length(a) == felt_length(b)

"""

    <(a::ShadowWeight, b::ShadowWeight)

a `ShadowWeight` is less than another, if its `felt_length` is less than the one of the other.
"""
Base.:<(a::ShadowWeight, b::ShadowWeight) = felt_length(a) < felt_length(b)

"""

    +(a::ShadowWeight, b::ShadowWeight)

Two general `ShadowWeight`s are addable, if their `a` fields match. The result is a new `ShadowWeight`
with the same `a` value and the sum of the `sun` and `shadow` fields of both `ShadowWeights`.

Special care has to be taken when adding values which identify with either zero or infinity. In this case,
we ignore the condition of the `a` fields having to be the same and return just the appropriate input.

This does give problematic results for the extreme cases of `a==1.0` and `a==-1.0`, since we might drop needed length
in either the shade or the sun when we are currently only "feeling" the oposite... Not sure how we might be able to
remedy this problem... (maybe add a as type parameter for the weights?)
"""
function Base.:+(a::ShadowWeight, b::ShadowWeight)
    # TODO: FIX THIS IN ARCHITECHTURE, NOT IN IF CASES!
    felt_length(a) == 0.0 && real_length(a) == 0 && return b
    felt_length(b) == 0.0 && real_length(b) == 0 && return a
    felt_length(a) == Inf && return a
    felt_length(b) == Inf && return b
    @assert a.a == b.a "cant add ShadowWeight s if a is not the same a.a=$(a.a), b.a=$(b.a)"
    return ShadowWeight(a.a, a.shade + b.shade, a.sun + b.sun)
end


"""

    ShadowWeights{T<:Integer,U<:Real} <: AbstractMatrix{ShadowWeight}

Abstract Matrix type of `ShadowWeight`s, usable as weights in graph-algorithms.
"""
struct ShadowWeights{T<:Integer,U<:Real} <: AbstractMatrix{ShadowWeight}
    a::Float64
    full_weights::MetaGraphs.MetaWeights{T,U}
    shadow_weights::MetaGraphs.MetaWeights{T,U}

    function ShadowWeights(a, full_weights::I, shadow_weights::I) where {T<:Integer,U<:Real,I<:MetaGraphs.MetaWeights{T,U}}
        if -1.0 <= a <= 1.0
            return new{T,U}(a, full_weights, shadow_weights)
        else
            error("a can only be in [-1, 1] (currently: $a)")
        end
    end
end


"""

    ShadowWeights(a, full_weights::I, shadow_weights::I) where {T<:Integer,U<:Real,I<:MetaGraphs.MetaWeights{T,U}}

Base constructor for `ShadowWeights`. `a` has to be in `[-1.0, 1.0]`, otherwise an error will be thrown.
`full_weights` and `shadow_weights` are the full lengths of the edges and the length of these edges in shadow, respectively.
Make sure that `all(shadow_weights .<= full_weights) == true`, otherwise, the results might not be what you expect.

If there exists at least one edge/street either fully in the sun or fully in the shade, the resulting `real_length`s at `a==-1.0` and `a==1.0` might not
be the same as the ones calculated by adding every `full_length` along this path, since, adding only looks at `felt_length`, and will drop everything
where this value is zero instead of adding the needed parts of the real lengths.

A fix for this behaviour is to not use values of exactly `1.0 and -1.0`, but rather to think about `lim a -> 1.0` and `lim a -> -1.0`.

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
"""
function Base.getindex(w::ShadowWeights, u::Integer, v::Integer)
    full_length = w.full_weights[u, v]
    shadow_length = w.shadow_weights[u, v]
    return ShadowWeight(w.a, shadow_length, abs(full_length - shadow_length))
end


"""

    get_path_length(path, weights)

function to calculate the length of a path given by a vector of node ids in a externally supplied weight matrix. (Not exported, mainly used in Testing.)
"""
get_path_length(path, weights) = length(path) > 0 ? mapreduce((s, d) -> weights[s, d], +, @view(path[1:end-1]), @view(path[2:end]); init=zero(eltype(weights))) : typemax(eltype(weights))

"""

    reevaluate_distances(state, weights)

recalculates the lengths of the paths encoded in `state` using the supplied `weights` matrix. (Not exported, mainly used in Testing, since very slow.)
"""
function reevaluate_distances(state, weights)
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

function sp_reeval(state, distmx)
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
=#

#=
begin
	struct ShadowWeights{T <: Integer,U <: Real} <: AbstractMatrix{U}
	    a::Float64
		geom_weights::MetaGraphs.MetaWeights{T, U}
		shadow_weights::MetaGraphs.MetaWeights{T, U}
	end
	function ShadowWeights(g, a)
		gw = weights(g)
		sw = @set gw.weightfield = :shadowed_length
		return ShadowWeights(a, gw, sw)
	end
	Base.show(io::IO, x::ShadowWeights) = print(io, "shadowweight")
	Base.show(io::IO, z::MIME"text/plain", x::ShadowWeights) = show(io, x)
end

function Base.getindex(w::ShadowWeights{T,U}, u::Integer, v::Integer)::U where T <: Integer where U <: Real
	shadow_length = w.shadow_weights[u, v]
	sun_length = abs(w.geom_weights[u, v] - shadow_length)

	weight = (1-w.a) * shadow_length + (w.a) * sun_length

    return U(2 * weight)
end

Base.size(x::ShadowWeights) = MetaGraphs.size(x.geom_weights)
=#