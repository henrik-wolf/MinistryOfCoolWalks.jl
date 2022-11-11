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

these work well if we actually call the "shadow importance" the "vampire factor":
- twilight (just twilight)
- what we do in the shadows (it's walking.)
- walk, we do in the shadows


# Centerline correction: thoughts
in osm, there exist a bunch of tags from which we might be able to infer something about the width of the street and whether we are dealing with the centerline or with explicitly mapped bikeways. In this section, I want to collect and discuss a hierachy of which keys to use, in what order and how to procede from there.

But first, lets quickly talk about how the offsetting works in general. Given an ordered list with the coordinates from start to finish, we find the vector orthogonal to every edge segement, pointing to the right of the line, if one where to traverse it in order. (This is so that a positive offset adheres to european standards)
next, we offset the endpoints along the direction of their neighbouring segments. The non-endpoints are offest in a similar fashion, but this time along the sum of the (normalised) orthogonal directions of the neighbouring segments. By scaling the offset distance by 1/cos(a) where a is the angle between the offset direction and the vertical on one of the neighbouring edges, we make sure that the offset lines are parallel to the original lines.

Now, on to the tags.
All the ways from osm have a "highway"tag of some capacity. So we start with that one.
First, we divide the different kinds of highways into two classes. Those who will be offset and those who will not be offset. This is du to individually mapped bikeways, footways, paths... are allready beeing mapped at the locations we want then to be. These are not going to be offset. The other streets however usually depict the center of the main road, a place, where pedestrians and bikes seldome find their way to. For that reason, we need to shift the centerlines sideways to where the bikeways or footpaths would be.
To do this, we use a bunch of tags which tend to be present with various probabilities.

These Tags are:
- highway
- oneway
- reverseway
- width
- lanes
- lanes:forward
- lanes:backward
- lanes:both_ways

to get the full overview on how exactly we arrive at the final result, please look into the implementation of `guess_offset_distance` in `centerline_correction.jl`


There also exists a width tag, which would be the most apropriate thing to use, if it wheren't used so sparingly.
We first need to decide whether the mapped way in our network is a bikepath or a street with some data attached to it.
I should just download a bike or footpath network and see what I can do...