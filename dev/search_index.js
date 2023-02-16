var documenterSearchIndex = {"docs":
[{"location":"Routing/#Routing","page":"Routing","title":"Routing","text":"","category":"section"},{"location":"Routing/#Introduction","page":"Routing","title":"Introduction","text":"","category":"section"},{"location":"Routing/","page":"Routing","title":"Routing","text":"It might be interesting to look shortest paths in out network, using different weights for each edge, based on the length in shade and sun, as well as an external parameter, which essentially weights the length of sunny parts against the length of shaded parts along every edge. Therefore, we introduce our own Real subtype, together with a MetaGraphs.MetaWeights based Weight-Matrix, which should just work in every Graphs.jl algorithm, which takes a Weight Matrix.","category":"page"},{"location":"Routing/#ShadowWeight-and-conditions-on-addition-comparison","page":"Routing","title":"ShadowWeight and conditions on addition comparison","text":"","category":"section"},{"location":"Routing/","page":"Routing","title":"Routing","text":"To calculate shortest paths, we need a non negative edge weight, a less-than and an addition operation with a (or possibly multiple) zero elements.","category":"page"},{"location":"Routing/","page":"Routing","title":"Routing","text":"we use:","category":"page"},{"location":"Routing/","page":"Routing","title":"Routing","text":"felt_length(w) = (1-w.a) * w.shade + (1+w.a) * sun","category":"page"},{"location":"Routing/","page":"Routing","title":"Routing","text":"and","category":"page"},{"location":"Routing/","page":"Routing","title":"Routing","text":"real_length(w) = w.shade + w.sun","category":"page"},{"location":"Routing/","page":"Routing","title":"Routing","text":"Since we want to be able to reconstruct the real_length from the number w which has been used in the shortest path with the felt_length function, we additionally need the addition with zero to be invariant under both length operations (this needs to hold for every operation you might want to do on the results from routing with a custom felt_length). That is:","category":"page"},{"location":"Routing/","page":"Routing","title":"Routing","text":"felt_length(w + zero) == felt_length(w) => real_length(w + zero) == real_length(w)","category":"page"},{"location":"Routing/","page":"Routing","title":"Routing","text":"we archieve this by constraining a in (-1.0, 1.0), rather than a in [-1.0, 1.0]. In this way, a zero is of length 0 under both operations.","category":"page"},{"location":"Routing/","page":"Routing","title":"Routing","text":"Applying this constraint can be argued in multiple ways: (here in German. TODO: translate this...)","category":"page"},{"location":"Routing/","page":"Routing","title":"Routing","text":"Das Problem betrachtend: dieses a skaliert die relative länge der schatten zu den sonnenwegen. Bedeutet in meiner Story fühlt sich Schatten (1-a)/(1+a) länger an als Sonne. Und für a = 1 bedeutet dass, das sich Schatten 0 mal länger anfühlt, und für a=-1 ist das ding nicht mal definiert, aber bedeutet sowas wie, das sich Schatten unendlich viel länger anfühlt als Sonne, was, gegeben die Problemstellung, irgendwie nicht wirklich Sinn ergibt. In beiden Fällen würde das bedeuten, das es dir egal ist wie weit du läufst, wenn du dich zwischen verschiedenen kanten mit nur sonne oder nur schatten entscheiden musst. Und das ist irgendwie nicht sinnvoll. (besser wäre es, grenzwerte lim a -> 1.0 und lim a -> -1.0 zu betrachten.)\nAlgorithmisch: wenn ich die wahl zwischen verschiedenen strecken die nur in der sonne oder nur im schatten sind, (die jeweils eine gefühlte länge von null haben), dann ist es von der implementation abhängig, welchen dieser wege ich nehme. Die Tatsächliche Länge die ich aus diesen pfaden ausrechnen kann, ist also nicht sehr aussagekräftig, weil ich nicht weiß welche der (sehr tatsächlich sehr unterschiedlich langen) strecken mit gefühlter länge der algorithmus genommen hat. (sprich: wenn viele kanten gefühlte länge null haben, dann gibt es viele “kürzeste wege”, und ich bekomme halt nur einen davon, und welcher ist random)\nMathematisch: für kürzesten pfad brauche ich die beiden funktionen (min, +), und + muss ein nullelement haben. Wenn ich -1 und 1 zulasse, dann gibt es aber für diese werte sehr viele nullelemente für die addition (unter der gefühlten länge), was erstmal kein problem ist, aber, wenn ich dann die reale länge ausrechne, dann sind die halt nicht mehr alle nullelemente. Und dann ist es wieder abhängig vom algorithmus, wie oft ich (gefühlte) nullen addiere, was ich für eine reale länge bekomme.","category":"page"},{"location":"Routing/","page":"Routing","title":"Routing","text":"Und die dinge gehen alle weg, wenn ich einfach a in (-1.0, 1.0) fordere.","category":"page"},{"location":"Routing/#ShadowWeightsLight","page":"Routing","title":"ShadowWeightsLight","text":"","category":"section"},{"location":"Routing/","page":"Routing","title":"Routing","text":"faster, but less flexible version of a custom weight matrix. Used in the same way as ShadowWeights, but the resulting PathState only gives the distances in felt lengths. To get the lengths in shadow an in the sun, we need to reevaluate_distances with a user supplied weight matrix. (Usually weights(g)) will work here. This gives the lengths of the paths in real world lengths. If we need to calculate the distances in shade and sun, we can either reevaluate the distances at a different values of a and solve the different felt weights for shade and sun, or we simply reevaluate the distances twice, once with a weightmatrix where only the shadows are weights, and once where only the sunny parts are weights.","category":"page"},{"location":"Routing/#API","page":"Routing","title":"API","text":"","category":"section"},{"location":"Routing/","page":"Routing","title":"Routing","text":"Pages = [\"Routing.md\"]","category":"page"},{"location":"Routing/","page":"Routing","title":"Routing","text":"Modules = [MinistryOfCoolWalks]\nPages = [\"Routing.jl\"]","category":"page"},{"location":"Routing/#MinistryOfCoolWalks.ShadowWeight","page":"Routing","title":"MinistryOfCoolWalks.ShadowWeight","text":"ShadowWeight(a::Float64, shade::Float64, sun::Float64) <: Real\n\nTyp representing the weight on one edge.\n\na represents the preference for shadow or sun, where a==0.0 signifies indifference, a ∈ (0.0, 1.0) favours shaded edges,\n\nand a ∈ (-1.0, 0.0) favours sunny edges. Value must be in (-1.0, 1.0), otherwise, an Error is thrown.\n\nshade represents the (real world) length of the edge in shade. Has to be non-negative, otherwise, an Error is thrown.\nsun represents the (real world) length of the edge in the sun. Has to be non-negative, otherwise, an Error is thrown.\nif shade or sun is Inf, the other value has to be Inf as well, otherwise, an error is thrown.\n\nThis also means, that shade+sun=real_world_street_length.\n\nunsafe_ShadowWeight(a, shade, sun)\n\nunsafe constructor for ShadowWeight, does not validate the inputs, used internally when we know that all conditions are fulfilled.\n\n\n\n\n\n","category":"type"},{"location":"Routing/#MinistryOfCoolWalks.ShadowWeights","page":"Routing","title":"MinistryOfCoolWalks.ShadowWeights","text":"ShadowWeights{T<:Integer,U<:Real} <: AbstractMatrix{ShadowWeight}\n\nAbstract Matrix type of ShadowWeights, usable as weights in graph-algorithms.\n\n\n\n\n\n","category":"type"},{"location":"Routing/#MinistryOfCoolWalks.ShadowWeights-Tuple{MetaGraphs.AbstractMetaGraph, Any}","page":"Routing","title":"MinistryOfCoolWalks.ShadowWeights","text":"ShadowWeights(a, full_weights::I, shadow_weights::I) where {T<:Integer,U<:Real,I<:MetaGraphs.MetaWeights{T,U}}\n\nBase constructor for ShadowWeights. a has to be in (-1.0, 1.0), otherwise an error will be thrown. full_weights and shadow_weights are the full lengths of the edges and the length of these edges in shadow, respectively. Make sure that all(shadow_weights .<= full_weights) == truefor all edges which exist, otherwise, the results might not be what you expect. Constructor checks thatmaximum(shadowweights)<typemax(U)andmaximum(fullweights)<typemax(U)`. (TODO: Maybe there is a faster way of doing this?)\n\nShadowWeights(g::AbstractMetaGraph, a; shadow_source=:shadowed_length)\n\nConstructs the ShadowWeights from a MetaGraph and the a value. (See the docs of ShadowWeight for an explanation of the parameter.)\n\nAssumes that weightfield(g) encodes the full length of each edge. Additionally, it is possible to set the field from which the length of the shadows will be extracted. The default value is :shadowed_length.\n\n\n\n\n\n","category":"method"},{"location":"Routing/#MinistryOfCoolWalks.ShadowWeightsLight","page":"Routing","title":"MinistryOfCoolWalks.ShadowWeightsLight","text":"ShadowWeightsLight{T<:Integer,U<:Real} <: AbstractMatrix{U}\n\nAbstractMatrix type, usable in graph algorithms, alternative approach to using ShadowWeights.\n\n\n\n\n\n","category":"type"},{"location":"Routing/#MinistryOfCoolWalks.ShadowWeightsLight-Tuple{MetaGraphs.AbstractMetaGraph, Any}","page":"Routing","title":"MinistryOfCoolWalks.ShadowWeightsLight","text":"ShadowWeightsLight(a, geom_weights::I, shadow_weights::I) where {T<:Integer,U<:Real,I<:MetaGraphs.MetaWeights{T,U}}\n\nBase constructor for ShadowWeightsLight. a has to be in (-1.0, 1.0), otherwise an error will be thrown. geom_weights and shadow_weights are the full lengths of the edges and the length of these edges in shadow, respectively. Make sure that all(shadow_weights .<= geom_weights) == true, otherwise, the results might not be what you expect. Constructor checks that maximum(shadow_weights)<typemax(U) and maximum(full_weights)<typemax(U). (TODO: Maybe there is a faster way of doing this?)\n\nShadowWeightsLight(g::AbstractMetaGraph, a; shadow_source=:shadowed_length)\n\nConstructs the ShadowWeightsLight from a MetaGraph and the a value. (See getindex(m::ShadowWeightsLight, ...) for an explanation of this parameter.)\n\nAssumes that weightfield(g) encodes the full length of each edge. Additionally, it is possible to set the field from which the length of the shadows will be extracted. The default value is :shadowed_length.\n\n\n\n\n\n","category":"method"},{"location":"Routing/#Base.:+-Tuple{MinistryOfCoolWalks.ShadowWeight, MinistryOfCoolWalks.ShadowWeight}","page":"Routing","title":"Base.:+","text":"+(a::ShadowWeight, b::ShadowWeight)\n\nTwo general ShadowWeights are addable, if their a fields match. The result is a new ShadowWeight with the same a value and the sum of the sun and shadow fields of both ShadowWeights. The return value is generated using unsafe_ShadowWeight due to performance considerations. Make sure that you only input valid ShadowWeights.\n\nSpecial care has to be taken when adding values which identify with either zero or infinity. In this case, we ignore the condition of the a fields having to be the same and return just the appropriate input.\n\n\n\n\n\n","category":"method"},{"location":"Routing/#Base.:<-Tuple{MinistryOfCoolWalks.ShadowWeight, MinistryOfCoolWalks.ShadowWeight}","page":"Routing","title":"Base.:<","text":"<(a::ShadowWeight, b::ShadowWeight)\n\na ShadowWeight is less than another, if its felt_length is less than the one of the other.\n\n\n\n\n\n","category":"method"},{"location":"Routing/#Base.:==-Tuple{MinistryOfCoolWalks.ShadowWeight, MinistryOfCoolWalks.ShadowWeight}","page":"Routing","title":"Base.:==","text":"==(a::ShadowWeight, b::ShadowWeight)\n\nTwo ShadowWeights are the considered equal, if their felt_lengths are the same.\n\n\n\n\n\n","category":"method"},{"location":"Routing/#Base.getindex-Tuple{ShadowWeights, Integer, Integer}","page":"Routing","title":"Base.getindex","text":"getindex(w::ShadowWeights, u::Integer, v::Integer)\n\nGet the ShadowWeight at index u,v. The length in the sun is calculated as abs(full_length-shadow_length), to account for numerical deviations where the edge might be slightly shorter than the shadow covering it. If the length in the shade is systematically longer than the full edge, this will not Error, but fail silently. Since we check the maximum values on construction, we can use unsafe_ShadowWeight to create the return value.\n\n\n\n\n\n","category":"method"},{"location":"Routing/#Base.getindex-Union{Tuple{T}, Tuple{U}, Tuple{ShadowWeightsLight{T, U}, Integer, Integer}} where {U<:Real, T<:Integer}","page":"Routing","title":"Base.getindex","text":"getindex(w::ShadowWeightsLight{T,U}, u::Integer, v::Integer)::U where {T<:Integer} where {U<:Real}\n\nGet the length of an edge from u to v in the felt_length, defined as:\n\n(1 - w.a) * shadow_length + (1 + w.a) * sun_length. a represents the preference for shadow or sun, where a==0.0 signifies indifference, a ∈ (0.0, 1.0) favours shaded edges, and a ∈ (-1.0, 0.0) favours sunny edges.\n\n\n\n\n\n","category":"method"},{"location":"Routing/#Base.size-Tuple{ShadowWeightsLight}","page":"Routing","title":"Base.size","text":"size(x::ShadowWeightsLight)\n\nsize of ShadowWeightsLight is size of geometry weights contained.\n\n\n\n\n\n","category":"method"},{"location":"Routing/#Base.size-Tuple{ShadowWeights}","page":"Routing","title":"Base.size","text":"size(x::ShadowWeights)\n\nThe size of a ShadowWeights is the size of the full_weights field.\n\n\n\n\n\n","category":"method"},{"location":"Routing/#Base.typemax-Tuple{MinistryOfCoolWalks.ShadowWeight}","page":"Routing","title":"Base.typemax","text":"typemax(x::ShadowWeight) = typemax(typeof(x))\ntypemax(::Type{ShadowWeight})\n\nreturns the maximum value associated with the ShadowWeight Real. Equivalent to ShadowWeight(0.0, Inf, Inf)\n\n\n\n\n\n","category":"method"},{"location":"Routing/#Base.zero-Tuple{MinistryOfCoolWalks.ShadowWeight}","page":"Routing","title":"Base.zero","text":"zero(x::ShadowWeight)\nzero(::Type{ShadowWeight})\n\nreturns the zero value associated with the ShadowWeight Real. Equivalent to ShadowWeight(0.0, 0.0, 0.0).\n\n\n\n\n\n","category":"method"},{"location":"Routing/#MinistryOfCoolWalks.felt_length-Tuple{MinistryOfCoolWalks.ShadowWeight}","page":"Routing","title":"MinistryOfCoolWalks.felt_length","text":"felt_length(w::ShadowWeight)\n\nreturns the felt length of a ShadowWeight. It is defined as: (1 - a) * shade + (1 + a) * sun\n\n\n\n\n\n","category":"method"},{"location":"Routing/#MinistryOfCoolWalks.get_path_length-Tuple{Any, Any}","page":"Routing","title":"MinistryOfCoolWalks.get_path_length","text":"get_path_length(path, weights)\n\nfunction to calculate the length of a path given by a vector of node ids in a externally supplied weight matrix. (Not exported, mainly used in Testing.)\n\n\n\n\n\n","category":"method"},{"location":"Routing/#MinistryOfCoolWalks.real_length-Tuple{MinistryOfCoolWalks.ShadowWeight}","page":"Routing","title":"MinistryOfCoolWalks.real_length","text":"real_length(w::ShadowWeight)\n\nreturns the real length of a ShadowWeight. (That is: sun+shade).\n\n\n\n\n\n","category":"method"},{"location":"Routing/#MinistryOfCoolWalks.reevaluate_distances-Tuple{Any, Any}","page":"Routing","title":"MinistryOfCoolWalks.reevaluate_distances","text":"reevaluate_distances(state, weights)\n\nreevaluates the shortest paths in state with the given weight matrix. This function is neccessary  since the approach with ShadowWeightsLight weights only returns the felt lengths. To make these values comparable, we need the path lengths under the same weight matrix. This algorithm works only for FloydWarshallStates, as it uses a modified floyd warshall algorithm to do so.\n\nPlease note that the results from this algorithm might vary from the results which can be obtained from other implementations of this reevaluation (mainly reevaluate_distances_slow), if there exist multiple shortest paths in the felt measure. In this, faster implementation, the one that ends up getting picked for the real length depends on the order in which the nodes are checked. But the routing output does so as well, so on average, we should be fine.\n\n\n\n\n\n","category":"method"},{"location":"Routing/#MinistryOfCoolWalks.reevaluate_distances_slow-Tuple{Any, Any}","page":"Routing","title":"MinistryOfCoolWalks.reevaluate_distances_slow","text":"reevaluate_distances_slow(state, weights)\n\nrecalculates the lengths of the paths encoded in state using the supplied weights matrix. (Not exported, mainly used in Testing, since very slow.)\n\n\n\n\n\n","category":"method"},{"location":"ShadowIntersection/#Shadow-Itersection","page":"Shadow intersections","title":"Shadow Itersection","text":"","category":"section"},{"location":"ShadowIntersection/#Introduction","page":"Shadow intersections","title":"Introduction","text":"","category":"section"},{"location":"ShadowIntersection/","page":"Shadow intersections","title":"Shadow intersections","text":"After moving around the ways, we now evaluate the effect of the shadows of the buildings, trees... on the ways in the network. Here we not only present the functionality to do so, but also a tool we build to clean up the result.","category":"page"},{"location":"ShadowIntersection/#API","page":"Shadow intersections","title":"API","text":"","category":"section"},{"location":"ShadowIntersection/","page":"Shadow intersections","title":"Shadow intersections","text":"Pages = [\"ShadowIntersection.md\"]","category":"page"},{"location":"ShadowIntersection/","page":"Shadow intersections","title":"Shadow intersections","text":"Modules = [MinistryOfCoolWalks]\nPages = [\"ShadowIntersection.jl\"]","category":"page"},{"location":"ShadowIntersection/#MinistryOfCoolWalks.add_shadow_intervals!-Tuple{Any, Any}","page":"Shadow intersections","title":"MinistryOfCoolWalks.add_shadow_intervals!","text":"add_shadow_intervals!(g, shadows; clear_old_shadows=false)\n\nadds the intersection of the polygons in dataframe shadows with metadata \"center_lon\" and \"center_lat\" and the geometry in the edgeprop :edgegeom of graph g to g. This operation can be repeated on the same graph with various shadows.\n\nIf clear_old_shadows is true, all possible, preexisting effects of previous executions of this function are reset. This way, a once loaded graph can be reused for all experiments.\n\nAfter this operation, all non-helper edges will have the additional property of ':shadowed_length'. This value is zero, if there is no shadow cast on the edge. If there is a shadow cast on the edge, the edge will have an additional property, ':shadowgeom', representing the geometry of the street in the shadow.\n\n\n\n\n\n","category":"method"},{"location":"ShadowIntersection/#MinistryOfCoolWalks.all_less_than-Tuple{Any, Any}","page":"Shadow intersections","title":"MinistryOfCoolWalks.all_less_than","text":"all_less_than(angles, max_angle)\n\nchecks if all values in angles are less than max_angle.\n\n\n\n\n\n","category":"method"},{"location":"ShadowIntersection/#MinistryOfCoolWalks.angles_in-Tuple{Any}","page":"Shadow intersections","title":"MinistryOfCoolWalks.angles_in","text":"angles_in(line)\nangles_in(::MultiLineStringTrait, lines)\nangles_in(::LineStringTrait, line)\n\ncalculates all angles between segments in line. Result in radians.\n\n\n\n\n\n","category":"method"},{"location":"ShadowIntersection/#MinistryOfCoolWalks.check_shadow_angle_integrity-Tuple{Any, Any}","page":"Shadow intersections","title":"MinistryOfCoolWalks.check_shadow_angle_integrity","text":"checkshadowangleintegrity(g, maxangle)\n\nchecks, if all angles in shadows in g are less than max_angle (in radians). If not, prints a warning. Used to test if the shadow joining works as intended.\n\n\n\n\n\n","category":"method"},{"location":"ShadowIntersection/#MinistryOfCoolWalks.combine_along_tree-NTuple{4, Any}","page":"Shadow intersections","title":"MinistryOfCoolWalks.combine_along_tree","text":"combine_along_tree(tree, start_node, lines, min_dist)\n\nrecursively combines the lines at leafs in tree with the nodes one order up,  starting (as in, the recursion starts here. This node gets combined last) at the root start_node. The min_dist is needed to figure out how the lines should be combined. (This dependency could maybe be removed...)\n\n\n\n\n\n","category":"method"},{"location":"ShadowIntersection/#MinistryOfCoolWalks.combine_lines-Tuple{Any, Any, Any}","page":"Shadow intersections","title":"MinistryOfCoolWalks.combine_lines","text":"combine_lines(a, b, min_dist)\n\ncombines two lines a and b at the ends where they are closer than min_dist apart. This assumes, that a and b are (much) longer than min_dist. If not, weird edge cases may arrise.\n\nIf a ⊂ b, returns b, if b ⊂ a returns a. Otherwise, returns all nodes of a, concatenated with all nodes of b, which are further away from a than min_dist. If a and b form a circle, special care is taken to not mess up the order.\n\n\n\n\n\n","category":"method"},{"location":"ShadowIntersection/#MinistryOfCoolWalks.get_length_by_buffering-NTuple{4, Any}","page":"Shadow intersections","title":"MinistryOfCoolWalks.get_length_by_buffering","text":"get_length_by_buffering(geom, buffer, points, edge)\n\napproximates the \"non overlapping\" length of overlapping linestrings by buffering geom with a buffer of size buffer and points points, specifying how many points should be used to approximate bends of 90 degrees. After buffering, we calculate the area and divide by the twice the buffer width (buffer is radius), after subtracting the area of the endcaps. (This function is currently not in use.)\n\n\n\n\n\n","category":"method"},{"location":"ShadowIntersection/#MinistryOfCoolWalks.join_shadow_without_union!-Tuple{Any, ArchGDAL.IGeometry{ArchGDAL.wkbLineString}}","page":"Shadow intersections","title":"MinistryOfCoolWalks.join_shadow_without_union!","text":"join_shadow_without_union!(full_shadow, new_shadow::ArchGDAL.IGeometry{ArchGDAL.wkbLineString})\njoin_shadow_without_union!(full_shadow, new_shadow::ArchGDAL.IGeometry{ArchGDAL.wkbMultiLineString})\n\nadds new_shadow to full_shadow, skipping empty linestrings.\n\n\n\n\n\n","category":"method"},{"location":"ShadowIntersection/#MinistryOfCoolWalks.npoints-Tuple{Any}","page":"Shadow intersections","title":"MinistryOfCoolWalks.npoints","text":"npoints(line)\nnpoints(::LineStringTrait, line)\nnpoints(::MultiLineStringTrait, line)\n\ncalculates the number of points in a line or multiline.\n\n\n\n\n\n","category":"method"},{"location":"ShadowIntersection/#MinistryOfCoolWalks.rebuild_lines-Tuple{ArchGDAL.IGeometry{ArchGDAL.wkbMultiLineString}, Any}","page":"Shadow intersections","title":"MinistryOfCoolWalks.rebuild_lines","text":"rebuild_lines(lines::ArchGDAL.IGeometry{ArchGDAL.wkbMultiLineString}, min_dist)::EdgeGeomType\nrebuild_lines(lines, min_dist)::EdgeGeomType\n\ncalculates the union of lines in a (multi) linestring, merging lines which are closer than min_dist to one another.\n\nWe calculate the adjacency matrix of all lines, build a network with edges where the distance between edges < min_dist, calculate a dfs tree for each connected component and recursively combine the linestrings at the leafs with the linestrings one level up.\n\n\n\n\n\n","category":"method"},{"location":"","page":"Home","title":"Home","text":"CurrentModule = MinistryOfCoolWalks","category":"page"},{"location":"#MinistryOfCoolWalks","page":"Home","title":"MinistryOfCoolWalks","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for MinistryOfCoolWalks.","category":"page"},{"location":"#Constants","page":"Home","title":"Constants","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Pages = [\"index.md\"]","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [MinistryOfCoolWalks]\nPages = [\"MinistryOfCoolWalks.jl\"]","category":"page"},{"location":"#MinistryOfCoolWalks.DEFAULT_LANES_ONEWAY","page":"Home","title":"MinistryOfCoolWalks.DEFAULT_LANES_ONEWAY","text":"DEFAULT_LANES_ONEWAY\n\ndefault number of lanes in one direction of the street, by highway type. Used when there is no data available in the tags.\n\n\n\n\n\n","category":"constant"},{"location":"#MinistryOfCoolWalks.HIGHWAYS_NOT_OFFSET","page":"Home","title":"MinistryOfCoolWalks.HIGHWAYS_NOT_OFFSET","text":"HIGHWAYS_NOT_OFFSET\n\nlist of highways, which should not be offset, usually because they can allready considered the center of a bikepath/sidewalk/footpath...\n\n\n\n\n\n","category":"constant"},{"location":"#MinistryOfCoolWalks.HIGHWAYS_OFFSET","page":"Home","title":"MinistryOfCoolWalks.HIGHWAYS_OFFSET","text":"HIGHWAYS_OFFSET\n\nlist of highways, which should be offset to the edge of the street.\n\n\n\n\n\n","category":"constant"},{"location":"CenterlineCorrection/#Centerline-Correction","page":"Centerline correction","title":"Centerline Correction","text":"","category":"section"},{"location":"CenterlineCorrection/#Introduction","page":"Centerline correction","title":"Introduction","text":"","category":"section"},{"location":"CenterlineCorrection/","page":"Centerline correction","title":"Centerline correction","text":"The ways as given by OSM denote, by convention, the center of the streets, which usually is not the place where we see pedestrians walking. To get a more accurate picture of how much shadow there is on the sidewalks, we need to offset the ways to where pedestrians would usually walk. This procedure, including estimating the width of the street is handled here.","category":"page"},{"location":"CenterlineCorrection/#API","page":"Centerline correction","title":"API","text":"","category":"section"},{"location":"CenterlineCorrection/","page":"Centerline correction","title":"Centerline correction","text":"Pages = [\"CenterlineCorrection.md\"]","category":"page"},{"location":"CenterlineCorrection/","page":"Centerline correction","title":"Centerline correction","text":"Modules = [MinistryOfCoolWalks]\nPages = [\"CenterlineCorrection.jl\"]","category":"page"},{"location":"CenterlineCorrection/#MinistryOfCoolWalks.check_building_intersection-Tuple{Any, Any}","page":"Centerline correction","title":"MinistryOfCoolWalks.check_building_intersection","text":"check_building_intersection(building_tree, offset_linestring)\n\nchecks if the linestring offset_linestring interescts with any of the buildings saved in the building_tree, which is assumend to be an RTree of the same structure as generated by build_rtree. Returns the offending geometry, or an empty list, if there are no intersections.\n\n\n\n\n\n","category":"method"},{"location":"CenterlineCorrection/#MinistryOfCoolWalks.correct_centerlines!","page":"Centerline correction","title":"MinistryOfCoolWalks.correct_centerlines!","text":"correct_centerlines!(g, buildings, assumed_lane_width=3.5, scale_factor=1.0)\n\noffsets the centerlines of streets (edges in g) stored in the edge prop :edgegeom_base, to the estimated edge of the street and stores the result in :edgegeom.\n\nRepeated application of this function deletes all edgeprops added after loading the graph, or the last application of correct_centerline, apart from [:osm_id, :tags, :edgegeom, :edgegeom_base, :full_length, :parsing_direction, :helper].\n\nThe information available in the edgeprops :tags and parsing_direction is used to estimate the width of the street.  If it is not possible to find the offset using these props, the assumed_lane_width is used in conjunction with the gloabal dicts DEFAULT_LANES_ONEWAY, HIGHWAYS_OFFSET and HIGHWAYS_NOT_OFFSET, to figure out, how far the edge should be offset. This guess is then multiplied by the scale_factor, to get the final distance by wich we then offset the line.\n\nIf the highway is in HIGHWAYS_NOT_OFFSET, it is not going to be moved, no matter the contents of its tags. For the full reasoning and implementations see the source of guess_offset_distance.\n\nWe check if the offset line does intersect more buildings than the original line, to make sure that the assumend foot/bike path does lead through a building. If there have new intersections arrisen, we retry the offsetting with 0.9, 0.8, 0.7... times the guessed offset, while checking and, if true breaking, whether the additional intersections vanish.\n\nWe also update the locations of the helper nodes, to reflect the offset lines, as well as the \":full_length\" prop, to reflect the possible change in length.\n\n\n\n\n\n","category":"function"},{"location":"CenterlineCorrection/#MinistryOfCoolWalks.guess_offset_distance","page":"Centerline correction","title":"MinistryOfCoolWalks.guess_offset_distance","text":"\"\n\nguess_offset_distance(g, edge::Edge, assumed_lane_width=3.5)\n\nestimates the the distance an edge of graph g has to be offset. Uses the props of the edge, the assumed_lane_width, used as a fallback in case the information can not be found solely in the props, as well as the global constants of DEFAULT_LANES_ONEWAY, HIGHWAYS_OFFSET and HIGHWAYS_NOT_OFFSET. This function calls:\n\nguess_offset_distance(edge_tags, parsing_direction, assumed_lane_width=3.5)\n\nestimates the distance the edge with the tags edge_tags, which has been parse in the direction of parsing_direction. (That is, if we had to go forwards or backwards through the OSM way in order to generate the edgeometry for this linestring. This is nessecary, due to the existence of the reverseway tags and possible asymetries, where streets have more lanes in one direction, than in the other.)\n\n\n\n\n\n","category":"function"},{"location":"CenterlineCorrection/#MinistryOfCoolWalks.node_directions-Tuple{Any, Any}","page":"Centerline correction","title":"MinistryOfCoolWalks.node_directions","text":"node_directions(x, y)\n\ncalculates the (scaled) direction in which the nodes given by 'x' and 'y' coordinates need to be offset, such that the connections between the nodes remain parallel to the original connections. Returns array of 2d vectors.\n\n\n\n\n\n","category":"method"},{"location":"CenterlineCorrection/#MinistryOfCoolWalks.offset_line-Tuple{Any, Any}","page":"Centerline correction","title":"MinistryOfCoolWalks.offset_line","text":"offset_line(line, distance)\n\ncreates new ArchGDAL linestring where all segments are offset parallel to the original segment of line, with a distance of distance. Looking down the line (from the first segment to the second...), a positive distance moves the line to the right, a negative distance to the left. The line is expected to be in a projected coordinate system, which is going to be applied to the new, offset line as well. If, continious offsetting the length of a line segment where to reach a length of 0, the two adjacent points are automatically merged and offsetting is continued using the new configuration.\n\n\n\n\n\n","category":"method"},{"location":"RTreeBuilding/#RTree-Building","page":"Polygon RTrees","title":"RTree Building","text":"","category":"section"},{"location":"RTreeBuilding/#Introduction","page":"Polygon RTrees","title":"Introduction","text":"","category":"section"},{"location":"RTreeBuilding/","page":"Polygon RTrees","title":"Polygon RTrees","text":"Just two little functions to build an RTree out of ArchGDAL polygons.","category":"page"},{"location":"RTreeBuilding/#API","page":"Polygon RTrees","title":"API","text":"","category":"section"},{"location":"RTreeBuilding/","page":"Polygon RTrees","title":"Polygon RTrees","text":"Pages = [\"RTreeBuilding.md\"]","category":"page"},{"location":"RTreeBuilding/","page":"Polygon RTrees","title":"Polygon RTrees","text":"Modules = [MinistryOfCoolWalks]\nPages = [\"RTreeBuilding.jl\"]","category":"page"},{"location":"RTreeBuilding/#MinistryOfCoolWalks.build_rtree-Tuple{Any}","page":"Polygon RTrees","title":"MinistryOfCoolWalks.build_rtree","text":"build_rtree(geo_arr)\n\nbuilds SpatialIndexing.RTree{Float64, 2} from an array containing ArchGDAL.wkbPolygons. The value of an entry in the RTree is a named tuple with: (orig=original_geometry,prep=prepared_geometry). orig is just the original object, an element from geo_arr, where prep is the prepared geometry, derived from orig. The latter one can be used in a few ArchGDAL functions to get higher performance, for example in intersection testing, because relevant values get precomputed and cashed in the prepared geometry, rather than precomputed on every test.\n\n\n\n\n\n","category":"method"},{"location":"RTreeBuilding/#MinistryOfCoolWalks.rect_from_geom-Tuple{Any}","page":"Polygon RTrees","title":"MinistryOfCoolWalks.rect_from_geom","text":"rect_from_geom(geom)\n\nbuilds SpatialIndexing.Rect with the extent of the geomerty geom.\n\n\n\n\n\n","category":"method"}]
}
