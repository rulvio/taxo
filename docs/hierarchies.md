# How Taxo stores a hierarchy

Taxo stores every relationship in a `%Taxo{}` struct. The struct holds
three maps, and it keeps all three in sync on every change.

## Tags

A tag is a node in the hierarchy. A tag can be any Elixir term: an atom, a
string, a tuple, or anything else you use as a map key.

## Three maps, one invariant

| Map | Holds |
|---|---|
| `:parents` | The direct parents of a tag |
| `:ancestors` | Every parent, and every parent of those parents |
| `:descendants` | The inverse of `:ancestors`: every tag that has this tag as an ancestor |

`:ancestors` and `:descendants` always agree. `parent` is in
`ancestors(child)` only if `child` is in `descendants(parent)`, and the
other way round. Taxo keeps this true after every `derive/3` and
`underive/3` call, so a caller never checks both maps to be sure.

`:parents` is a subset of `:ancestors`. A direct parent is also an
ancestor.

## How derive/3 updates the hierarchy

Adding one link, `child -> parent`, can change many tags' ancestors and
descendants, not just `child`'s and `parent`'s.

Take this example: `:dog` is derived from `:mammal`, then `:mammal` is
derived from `:animal`. The second call must also add `:animal` to
`:dog`'s ancestors, even though that call only names `:mammal` and
`:animal`.

`derive/3` handles this on every call. It looks at every tag already
connected to `child` as a descendant, and every tag already connected to
`parent` as an ancestor. It updates `:ancestors` and `:descendants` for all
of those tags at once, not just for `child` and `parent`.

## Cycles

A hierarchy must stay acyclic. No tag can be its own ancestor. `derive/3`
checks this before it writes anything. If `parent` is already a descendant
of `child`, the new link would close a loop. `derive/3` raises
`Taxo.CyclicDerivationError` instead of applying the change.

## Why underive/3 rebuilds instead of subtracting

Removing a link can also shrink many tags' ancestor and descendant sets,
not just the two tags named in the link. Working out exactly which sets
shrink, and by how much, means checking whether some other path still
supports each entry.

`underive/3` sidesteps that check. It drops the named link, then rebuilds
the whole taxonomy from an empty one, calling `derive/3` on every link that
remains.

This is simple, and it is correct. But its cost grows with the size of the
whole taxonomy, not with the size of the link removed. Removing one link
from a large hierarchy is not a cheap call.
