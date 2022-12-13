var documenterSearchIndex = {"docs":
[{"location":"ShadowIntersection/#Shadow-Itersection","page":"Shadow intersections","title":"Shadow Itersection","text":"","category":"section"},{"location":"ShadowIntersection/#Introduction","page":"Shadow intersections","title":"Introduction","text":"","category":"section"},{"location":"ShadowIntersection/","page":"Shadow intersections","title":"Shadow intersections","text":"After moving around the ways, we now evaluate the effect of the shadows of the buildings, trees... on the ways in the network. Here we not only present the functionality to do so, but also a tool we build to clean up the result.","category":"page"},{"location":"ShadowIntersection/#API","page":"Shadow intersections","title":"API","text":"","category":"section"},{"location":"ShadowIntersection/","page":"Shadow intersections","title":"Shadow intersections","text":"Pages = [\"ShadowIntersection.md\"]","category":"page"},{"location":"ShadowIntersection/","page":"Shadow intersections","title":"Shadow intersections","text":"Modules = [MinistryOfCoolWalks]\nPages = [\"ShadowIntersection.jl\"]","category":"page"},{"location":"ShadowIntersection/#MinistryOfCoolWalks.add_shadow_intervals!-Tuple{Any, Any}","page":"Shadow intersections","title":"MinistryOfCoolWalks.add_shadow_intervals!","text":"add_shadow_intervals!(g, shadows)\n\nadds the intersection of the polygons in dataframe shadows with metadata \"center_lon\" and \"center_lat\" and the geometry in the edgeprop :edgegeom of graph g to g. This operation can be repeated on the same graph with various shadows.\n\nAfter this operation, all non-helper edges will have the additional property of ':shadowed_length'. This value is zero, if there is no shadow cast on the edge. If there is a shadow cast on the edge, the edge will have an additional property, ':shadowgeom', representing the geometry of the street in the shadow.\n\n\n\n\n\n","category":"method"},{"location":"ShadowIntersection/#MinistryOfCoolWalks.combine_along_tree-NTuple{4, Any}","page":"Shadow intersections","title":"MinistryOfCoolWalks.combine_along_tree","text":"combine_along_tree(tree, start_node, lines, min_dist)\n\nrecursively combines the lines at leafs in tree with the nodes one order up,  starting (as in, the recursion starts here. This node gets combined last) at the root start_node. The min_dist is needed to figure out how the lines should be combined. (This dependency could maybe be removed...)\n\n\n\n\n\n","category":"method"},{"location":"ShadowIntersection/#MinistryOfCoolWalks.combine_lines-Tuple{Any, Any, Any}","page":"Shadow intersections","title":"MinistryOfCoolWalks.combine_lines","text":"combine_lines(a, b, min_dist)\n\ncombines two lines a and b at the ends where they are closer than min_dist apart.\n\nIf a ⊂ b, returns b, if b ⊂ a returns a. Otherwise, returns all nodes of a, concatenated with all nodes of b, which are further away from a than min_dist.\n\n\n\n\n\n","category":"method"},{"location":"ShadowIntersection/#MinistryOfCoolWalks.get_length_by_buffering-NTuple{4, Any}","page":"Shadow intersections","title":"MinistryOfCoolWalks.get_length_by_buffering","text":"get_length_by_buffering(geom, buffer, points, edge)\n\napproximates the \"non overlapping\" length of overlapping linestrings by buffering geom with a buffer of size buffer and points points, specifying how many points should be used to approximate bends of 90 degrees. After buffering, we calculate the area and divide by the twice the buffer width (buffer is radius), after subtracting the area of the endcaps. (This function is currently not in use.)\n\n\n\n\n\n","category":"method"},{"location":"ShadowIntersection/#MinistryOfCoolWalks.rebuild_lines-Tuple{ArchGDAL.IGeometry{ArchGDAL.wkbLineString}, Any}","page":"Shadow intersections","title":"MinistryOfCoolWalks.rebuild_lines","text":"rebuild_lines(line::ArchGDAL.IGeometry{ArchGDAL.wkbLineString}, min_dist)\n\ncalculates the union of lines in a (multi) linestring, merging lines which are closer than min_dist to one another. This particular function just returns line, as a single line allready is the union\n\nrebuild_lines(lines::ArchGDAL.IGeometry{ArchGDAL.wkbMultiLineString}, min_dist)::EdgeGeomType\nrebuild_lines(lines, min_dist)::EdgeGeomType\n\nWe calculate the adjacency matrix of all lines, build a network with edges where the distance between edges < min_dist, calculate a dfs tree for each connected component and recursively combine the linestrings at the leafs with the linestrings one level up.\n\n\n\n\n\n","category":"method"},{"location":"","page":"Home","title":"Home","text":"CurrentModule = MinistryOfCoolWalks","category":"page"},{"location":"#MinistryOfCoolWalks","page":"Home","title":"MinistryOfCoolWalks","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for MinistryOfCoolWalks.","category":"page"},{"location":"#Constants","page":"Home","title":"Constants","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Pages = [\"index.md\"]","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [MinistryOfCoolWalks]\nPages = [\"MinistryOfCoolWalks.jl\"]","category":"page"},{"location":"#MinistryOfCoolWalks.DEFAULT_LANES_ONEWAY","page":"Home","title":"MinistryOfCoolWalks.DEFAULT_LANES_ONEWAY","text":"DEFAULT_LANES_ONEWAY\n\ndefault number of lanes in one direction of the street, by highway type. Used when there is no data available in the tags.\n\n\n\n\n\n","category":"constant"},{"location":"#MinistryOfCoolWalks.HIGHWAYS_NOT_OFFSET","page":"Home","title":"MinistryOfCoolWalks.HIGHWAYS_NOT_OFFSET","text":"HIGHWAYS_NOT_OFFSET\n\nlist of highways, which should not be offset, usually because they can allready considered the center of a bikepath/sidewalk/footpath...\n\n\n\n\n\n","category":"constant"},{"location":"#MinistryOfCoolWalks.HIGHWAYS_OFFSET","page":"Home","title":"MinistryOfCoolWalks.HIGHWAYS_OFFSET","text":"HIGHWAYS_OFFSET\n\nlist of highways, which should be offset to the edge of the street.\n\n\n\n\n\n","category":"constant"},{"location":"CenterlineCorrection/#Centerline-Correction","page":"Centerline correction","title":"Centerline Correction","text":"","category":"section"},{"location":"CenterlineCorrection/#Introduction","page":"Centerline correction","title":"Introduction","text":"","category":"section"},{"location":"CenterlineCorrection/","page":"Centerline correction","title":"Centerline correction","text":"The ways as given by OSM denote, by convention, the center of the streets, which usually is not the place where we see pedestrians walking. To get a more accurate picture of how much shadow there is on the sidewalks, we need to offset the ways to where pedestrians would usually walk. This procedure, including estimating the width of the street is handled here.","category":"page"},{"location":"CenterlineCorrection/#API","page":"Centerline correction","title":"API","text":"","category":"section"},{"location":"CenterlineCorrection/","page":"Centerline correction","title":"Centerline correction","text":"Pages = [\"CenterlineCorrection.md\"]","category":"page"},{"location":"CenterlineCorrection/","page":"Centerline correction","title":"Centerline correction","text":"Modules = [MinistryOfCoolWalks]\nPages = [\"CenterlineCorrection.jl\"]","category":"page"},{"location":"CenterlineCorrection/#MinistryOfCoolWalks.check_building_intersection-Tuple{Any, Any}","page":"Centerline correction","title":"MinistryOfCoolWalks.check_building_intersection","text":"check_building_intersection(building_tree, offset_linestring)\n\nchecks if the linestring offset_linestring interescts with any of the buildings saved in the building_tree, which is assumend to be an RTree of the same structure as generated by build_rtree. Returns the offending geometry, or an empty list, if there are no intersections.\n\n\n\n\n\n","category":"method"},{"location":"CenterlineCorrection/#MinistryOfCoolWalks.correct_centerlines!","page":"Centerline correction","title":"MinistryOfCoolWalks.correct_centerlines!","text":"correct_centerlines!(g, buildings, assumed_lane_width=3.5)\n\noffsets the centerlines of streets (edges in g) stored in the edge prop :edgegeom, to the estimated edge of the street, using information available in the edgeprops :tags and parsing_direction. If it is not possible to find the offset using these props, the assumed_lane_width is used in conjunction with the gloabal dicts DEFAULT_LANES_ONEWAY, HIGHWAYS_OFFSET and HIGHWAYS_NOT_OFFSET, to figure out, how far the edge should be offset.\n\nIf the highway is in HIGHWAYS_NOT_OFFSET, it is not going to be moved, no matter the contents of its tags. For the full reasoning and implementations see the source of guess_offset_distance.\n\nWe check if the offset line does intersect more buildings than the original line, to make sure that the assumend foot/bike path does lead through a building. If there have new intersections arrisen, we retry the offsetting with 0.9, 0.8, 0.7... times the guessed offset, while checking and, if true breaking, whether the additional intersections vanish.\n\nWe also update the locations of the helper nodes, to reflect the offset lines, as well as the \":full_length\" prop, to reflect the possible change in length.\n\n\n\n\n\n","category":"function"},{"location":"CenterlineCorrection/#MinistryOfCoolWalks.guess_offset_distance","page":"Centerline correction","title":"MinistryOfCoolWalks.guess_offset_distance","text":"\"\n\nguess_offset_distance(g, edge::Edge, assumed_lane_width=3.5)\n\nestimates the the distance an edge of graph g has to be offset. Uses the props of the edge, the assumed_lane_width, used as a fallback in case the information can not be found solely in the props, as well as the global constants of DEFAULT_LANES_ONEWAY, HIGHWAYS_OFFSET and HIGHWAYS_NOT_OFFSET. This function calls:\n\nguess_offset_distance(edge_tags, parsing_direction, assumed_lane_width=3.5)\n\nestimates the distance the edge with the tags edge_tags, which has been parse in the direction of parsing_direction. (That is, if we had to go forwards or backwards through the OSM way in order to generate the edgeometry for this linestring. This is nessecary, due to the existence of the reverseway tags and possible asymetries, where streets have more lanes in one direction, than in the other.)\n\n\n\n\n\n","category":"function"},{"location":"CenterlineCorrection/#MinistryOfCoolWalks.offset_line-Tuple{Any, Any}","page":"Centerline correction","title":"MinistryOfCoolWalks.offset_line","text":"offset_line(line, distance)\n\ncreates new ArchGDAL linestring where all segments are offset parallel to the original segment of line, with a distance of distance. Looking down the line (from the first segment to the second...), a positive distance moves the line to the right, a negative distance to the left. The line is expected to be in a projected coordinate system, which is going to be applied to the new, offset line as well.\n\n\n\n\n\n","category":"method"},{"location":"RTreeBuilding/#RTree-Building","page":"Polygon RTrees","title":"RTree Building","text":"","category":"section"},{"location":"RTreeBuilding/#Introduction","page":"Polygon RTrees","title":"Introduction","text":"","category":"section"},{"location":"RTreeBuilding/","page":"Polygon RTrees","title":"Polygon RTrees","text":"Just two little functions to build an RTree out of ArchGDAL polygons.","category":"page"},{"location":"RTreeBuilding/#API","page":"Polygon RTrees","title":"API","text":"","category":"section"},{"location":"RTreeBuilding/","page":"Polygon RTrees","title":"Polygon RTrees","text":"Pages = [\"RTreeBuilding.md\"]","category":"page"},{"location":"RTreeBuilding/","page":"Polygon RTrees","title":"Polygon RTrees","text":"Modules = [MinistryOfCoolWalks]\nPages = [\"RTreeBuilding.jl\"]","category":"page"},{"location":"RTreeBuilding/#MinistryOfCoolWalks.build_rtree-Tuple{Any}","page":"Polygon RTrees","title":"MinistryOfCoolWalks.build_rtree","text":"build_rtree(geo_arr)\n\nbuilds SpatialIndexing.RTree{Float64, 2} from an array containing ArchGDAL.wkbPolygons. The value of an entry in the RTree is a named tuple with: (orig=original_geometry,prep=prepared_geometry). orig is just the original object, an element from geo_arr, where prep is the prepared geometry, derived from orig. The latter one can be used in a few ArchGDAL functions to get higher performance, for example in intersection testing, because relevant values get precomputed and cashed in the prepared geometry, rather than precomputed on every test.\n\n\n\n\n\n","category":"method"},{"location":"RTreeBuilding/#MinistryOfCoolWalks.rect_from_geom-Tuple{Any}","page":"Polygon RTrees","title":"MinistryOfCoolWalks.rect_from_geom","text":"rect_from_geom(geom)\n\nbuilds SpatialIndexing.Rect with the extent of the geomerty geom.\n\n\n\n\n\n","category":"method"}]
}
