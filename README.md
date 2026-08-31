# Taxo

[![Elixir CI](https://github.com/rulvio/taxo/actions/workflows/elixir.yml/badge.svg)](https://github.com/rulvio/taxo/actions/workflows/elixir.yml)

Taxo builds and queries tag hierarchies in Elixir. It ports the `derive` and
`underive` functions from Clojure's hierarchy system.

Use it wherever you need "this is a kind of that" relationships between
tags: categories, roles, event types, or fact types in a rules engine. Taxo
does not depend on any of those. It knows nothing but tags and the links
between them.

```elixir
Taxo.new()
|> Taxo.derive(:online_order, :order)
|> Taxo.is_a?(:online_order, :order)
#=> true
```

## Installation

```elixir
def deps do
  [
    {:taxo, "~> 0.2.0"}
  ]
end
```

Documentation: <https://hexdocs.pm/taxo>. For how the three internal maps
stay in sync, see [docs/hierarchies.md](docs/hierarchies.md).

## How a taxonomy works

A taxonomy holds tags and the parent/child links between them. `derive/3`
adds a link. `underive/3` removes one.

Every link you add also updates two derived views:

* **ancestors** — every tag reachable by following parent links up from a
  tag, not just its direct parents
* **descendants** — the same relationship, read from the other direction

Query these views with `parents/2`, `ancestors/2`, `descendants/2`, and
`is_a?/3`. You never compute them yourself. Taxo keeps them correct after
every `derive/3` and `underive/3` call.

## A worked example

```elixir
taxo =
  Taxo.new()
  |> Taxo.derive(:monkey, :mammal)
  |> Taxo.derive(:mammal, :animal)
  |> Taxo.derive(:pet, :animal)
  |> Taxo.derive(:dog, :mammal)
  |> Taxo.derive(:dog, :pet)

Taxo.ancestors(taxo, :monkey)
#=> MapSet.new([:mammal, :animal])

Taxo.ancestors(taxo, :dog)
#=> MapSet.new([:mammal, :pet, :animal])

Taxo.descendants(taxo, :animal)
#=> MapSet.new([:monkey, :mammal, :pet, :dog])

Taxo.is_a?(taxo, :dog, :animal)
#=> true
```

`:dog` has two direct parents, `:mammal` and `:pet`. Both trace back to
`:animal`, so `:dog`'s ancestors include `:animal` only once.

Removing a link updates the same views:

```elixir
taxo = Taxo.underive(taxo, :dog, :pet)

Taxo.parents(taxo, :dog)
#=> MapSet.new([:mammal])

Taxo.is_a?(taxo, :dog, :animal)
#=> true, still true through :mammal
```

Deriving a link that would create a cycle raises an error instead of
corrupting the taxonomy:

```elixir
Taxo.new()
|> Taxo.derive(:monkey, :mammal)
|> Taxo.derive(:mammal, :monkey)
#=> ** (Taxo.CyclicDerivationError) cyclic derivation: :monkey already has :mammal as an ancestor
```

## What is public

| Function | Purpose |
|---|---|
| `Taxo.new/0` | Creates an empty taxonomy |
| `Taxo.derive/3` | Adds a parent/child link |
| `Taxo.underive/3` | Removes a parent/child link |
| `Taxo.is_a?/3` | Checks whether one tag is, or descends from, another |
| `Taxo.parents/2` | Returns the direct parents of a tag |
| `Taxo.ancestors/2` | Returns every ancestor of a tag |
| `Taxo.descendants/2` | Returns every descendant of a tag |
| `Taxo.CyclicDerivationError` | Raised by `derive/3` when a link would create a cycle |

Every function takes and returns a `%Taxo{}` struct. There is no hidden
state and no process behind it.

## Limitations

* **A tag can be any term.** Taxo does not check that every tag in a
  taxonomy is the same type. Mixing atoms, strings, and tuples as tags in
  one taxonomy is allowed, but it is on you to keep that consistent.
* **`underive/3` rebuilds the whole taxonomy on every call.** Its cost
  depends on the size of the taxonomy, not on the size of the link removed.
  See [docs/hierarchies.md](docs/hierarchies.md) for why.
* **One taxonomy is one hierarchy.** There is no built-in way to merge two
  `%Taxo{}` values, or to scope one taxonomy inside another.

## Development

```bash
mix deps.get
mix test
mix format --check-formatted
mix dialyzer
```

CI runs the same commands on every push and pull request.

## Acknowledgements

Taxo ports the semantics of Clojure's `derive`, `underive`, and `isa?`
functions to Elixir.

**[rete](https://github.com/rulvio/rete)**, a forward-chaining rules engine
for Elixir, uses Taxo for the type hierarchy behind its own `derive` and
`underive`.

## Licence

Apache-2.0. See [LICENSE](LICENSE).
