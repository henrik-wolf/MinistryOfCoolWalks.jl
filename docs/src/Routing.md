# Routing
## Introduction
It might be interesting to look shortest paths in out network, using different weights for each edge, based on the length in shade and sun, as well as an external parameter, which essentially weights the length of sunny parts against the length of shaded parts along every edge. Therefore, we introduce our own `Real` subtype, together with a `MetaGraphs.MetaWeights` based Weight-Matrix, which should just work in every `Graphs.jl` algorithm, which takes a Weight Matrix.

## ShadowWeight and conditions on addition comparison
To calculate shortest paths, we need a non negative edge weight, a less-than and an addition operation with a (or possibly multiple) `zero` elements.

we use:

`felt_length(w) = (1-w.a) * w.shade + (1+w.a) * sun`

and

`real_length(w) = w.shade + w.sun`

Since we want to be able to reconstruct the `real_length` from the number `w` which has been used in the shortest path with the `felt_length` function, we additionally need the addition with zero to be invariant under both length operations (this needs to hold for every operation you might want to do on the results from routing with a custom `felt_length`). That is:

`felt_length(w + zero) == felt_length(w) => real_length(w + zero) == real_length(w)`

we archieve this by constraining `a in (-1.0, 1.0)`, rather than `a in [-1.0, 1.0]`. In this way, a `zero` is of length 0 under both operations.

Applying this constraint can be argued in multiple ways: (here in German. TODO: translate this...)
1. Das Problem betrachtend: dieses a skaliert die relative länge der schatten zu den sonnenwegen. Bedeutet in meiner Story fühlt sich Schatten (1-a)/(1+a) länger an als Sonne. Und für a = 1 bedeutet dass, das sich Schatten 0 mal länger anfühlt, und für a=-1 ist das ding nicht mal definiert, aber bedeutet sowas wie, das sich Schatten unendlich viel länger anfühlt als Sonne, was, gegeben die Problemstellung, irgendwie nicht wirklich Sinn ergibt. In beiden Fällen würde das bedeuten, das es dir egal ist wie weit du läufst, wenn du dich zwischen verschiedenen kanten mit nur sonne oder nur schatten entscheiden musst. Und das ist irgendwie nicht sinnvoll. (besser wäre es, grenzwerte `lim a -> 1.0` und `lim a -> -1.0` zu betrachten.)
2. Algorithmisch: wenn ich die wahl zwischen verschiedenen strecken die nur in der sonne oder nur im schatten sind, (die jeweils eine gefühlte länge von null haben), dann ist es von der implementation abhängig, welchen dieser wege ich nehme. Die Tatsächliche Länge die ich aus diesen pfaden ausrechnen kann, ist also nicht sehr aussagekräftig, weil ich nicht weiß welche der (sehr tatsächlich sehr unterschiedlich langen) strecken mit gefühlter länge der algorithmus genommen hat. (sprich: wenn viele kanten gefühlte länge null haben, dann gibt es viele “kürzeste wege”, und ich bekomme halt nur einen davon, und welcher ist random)
3. Mathematisch: für kürzesten pfad brauche ich die beiden funktionen (min, +), und + muss ein nullelement haben. Wenn ich -1 und 1 zulasse, dann gibt es aber für diese werte sehr viele nullelemente für die addition (unter der gefühlten länge), was erstmal kein problem ist, aber, wenn ich dann die reale länge ausrechne, dann sind die halt nicht mehr alle nullelemente. Und dann ist es wieder abhängig vom algorithmus, wie oft ich (gefühlte) nullen addiere, was ich für eine reale länge bekomme.
Und die dinge gehen alle weg, wenn ich einfach a in (-1.0, 1.0) fordere.

## ShadowWeightsLight
faster, but less flexible version of a custom weight matrix. Used in the same way as `ShadowWeights`, but the resulting `PathState` only gives the distances in felt lengths. To get the lengths in shadow an in the sun, we need to `reevaluate_distances` with a user supplied weight matrix. (Usually `weights(g)`) will work here. This gives the lengths of the paths in real world lengths. If we need to calculate the distances in shade and sun, we can either reevaluate the distances at a different values of a and solve the different felt weights for shade and sun, or we simply reevaluate the distances twice, once with a weightmatrix where only the shadows are weights, and once where only the sunny parts are weights.

## API

```@index
Pages = ["Routing.md"]
```

```@autodocs
Modules = [MinistryOfCoolWalks]
Pages = ["Routing.jl"]
```