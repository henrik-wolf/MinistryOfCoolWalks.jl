# MinistryOfCoolWalks.jl

this is the heart of the whole operation. Here I will put all the code which deals with networks and buildings (and later trees as well.). Currently we have a few functions related to calculating the suns position at different times and a (rudimentary) function to calculate the shadows of buildings passed in as a dataframe from `CompositeBuildings.jl`.

In the next days I will probably add plotting support for networks, buildings, shadows and so on.


# alternative project title
Since we are probably not going to use temperature data to inform our decisions, we might need to change the name of this project to something more ... appropriate... below I compile a list of alternative titles.

- ShadedWalks
- VampireSightSeeing
- 50 shades of walk
- shade happens.
- routing in the shade (Adele)


# Centerline correction: thoughts
in osm, there exist a bunch of tags from which we might be able to infer something about the width of the street and whether we are dealing with the centerline or with explicitly mapped bikeways. In this section, I want to collect and discuss a hierachy of which keys to use, in what order and how to procede from there.

But first, lets quickly talk about how the offsetting works in general. Given an ordered list with the coordinates from start to finish, we find the vector orthogonal to every edge segement, pointing to the right of the line, if one where to traverse it in order. (This is so that a positive offset adheres to european standards)
next, we offset the endpoints along the direction of their neighbouring segments. The non-endpoints are offest in a similar fashion, but this time along the sum of the (normalised) orthogonal directions of the neighbouring segments.

Now, on to the tags. Out of the 52 unique tags of the edges of the network I am currently looking at there exist a few which might be of interest. These are:
("cycleway:both", ["no"])
("source:alt_name", ["NROSH"])
("cycleway:right", ["lane"])
("cycleway:right:width", ["1.25", "1.75"])
("cycleway:left", ["yes", "lane", "track", "no", "share_busway"])
("note", ["preliminary work started August 2012", "Left cycle lane is actually a shared bus/cycle lane", "maxspeed not marked, but implicit"])
("highway", ["residential", "trunk", "trunk_link", "tertiary", "unclassified", "living_street"])
("direction", ["clockwise"])
("foot", ["yes", "no"])
("bicycle", ["yes"])
("lcn", ["yes"])
("oneway", Bool[0, 1])
("lanes", Int8[4, 2, 3, 1])
("bridge", ["yes"])
("reverseway", Bool[0])
("operator", ["National Highways"])
("cycleway:left:width", ["1.25", "1.75"])
("lanes:backward", ["1", "2"])
("motor_vehicle", ["yes"])
("lanes:forward", ["1", "2"])
("shoulder", ["left", "no"])
("sidewalk", ["left", "right", "both", "no"])
("cycleway:right:lane", ["advisory"])
("turn:lanes", ["through|right|right", "through|through;right", "through|through|right", "left|through|through", "through;right|right", "left;through|through|right", "left|through", "|merge_to_left"])
("cycleway", ["lane"])
("junction", ["circular", "roundabout"])


I guess all the streets will have a "highway"tag of some capacity. So we should probably start with that one.
There also exists a width tag, which would be the most apropriate thing to use, if it wheren't used so sparingly.
We first need to decide whether the mapped way in our network is a bikepath or a street with some data attached to it.
I should just download a bike or footpath network and see what I can do...