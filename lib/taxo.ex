defmodule Taxo do
  @moduledoc """
  Taxo is an Elixir port of the Clojure hierarchies provided by `derive` and `underive`.
  """

  defstruct ancestors: %{}, parents: %{}, descendants: %{}

  @typedoc "A node in a taxonomy. Can be any term, and is used as a map key."
  @type tag :: term()

  @type t :: %__MODULE__{
          ancestors: %{tag() => MapSet.t(tag())},
          parents: %{tag() => MapSet.t(tag())},
          descendants: %{tag() => MapSet.t(tag())}
        }

  @doc """
  Create a new taxonomy to store the `:parents`, `:ancestors` and `:descendants` of
  parent/child relationships, updated via `derive` and `underive`.
  Updates `:parents`, then transitively updates `:ancestors` and `:descendants`.

  ## Examples

      iex> Taxo.new
      %Taxo{ancestors: %{}, parents: %{}, descendants: %{}}
  """
  @spec new() :: t()
  def new do
    %Taxo{}
  end

  @doc """
  Returns true if (= child parent), or child is directly or indirectly derived from parent.

  ## Examples

      iex> Taxo.new |> Taxo.derive(:monkey, :mammal) |> Taxo.derive(:mammal, :vertebrate) |> Taxo.is_a?(:monkey, :vertebrate)
      true

      iex> Taxo.new |> Taxo.derive(:monkey, :mammal) |> Taxo.derive(:mammal, :vertebrate) |> Taxo.is_a?(:vertebrate, :monkey)
      false

  """
  @spec is_a?(t(), tag(), tag()) :: boolean()
  def is_a?(%Taxo{} = taxo, child, parent) do
    taxo.ancestors
    |> Map.get(child, MapSet.new())
    |> MapSet.member?(parent)
  end

  @doc """
    Returns the descendants of a given `child` in the taxonomy `taxo`.

    ## Examples

        iex> Taxo.new |> Taxo.derive(:monkey, :mammal) |> Taxo.descendants(:mammal)
        MapSet.new([:monkey])
  """
  @spec descendants(t(), tag()) :: MapSet.t(tag())
  def descendants(%Taxo{} = taxo, child) do
    Map.get(taxo.descendants, child, MapSet.new())
  end

  @doc """
    Returns the ancestors of a given `child` in the taxonomy `taxo`.

    ## Examples

        iex> Taxo.new |> Taxo.derive(:monkey, :mammal) |> Taxo.ancestors(:monkey)
        MapSet.new([:mammal])
  """
  @spec ancestors(t(), tag()) :: MapSet.t(tag())
  def ancestors(%Taxo{} = taxo, child) do
    Map.get(taxo.ancestors, child, MapSet.new())
  end

  @doc """
    Returns the parents of a given `child` in the taxonomy `taxo`.

    ## Examples

        iex> Taxo.new |> Taxo.derive(:monkey, :mammal) |> Taxo.parents(:monkey)
        MapSet.new([:mammal])

  """
  @spec parents(t(), tag()) :: MapSet.t(tag())
  def parents(%Taxo{} = taxo, child) do
    Map.get(taxo.parents, child, MapSet.new())
  end

  @doc """
  Establish a parent/child relationship in `taxo` between `child` and `parent`.
  Updates `:parents`, then transitively updates `:ancestors` and `:descendants`.

  Raises `Taxo.CyclicDerivationError` if `parent` is already a descendant of
  `child`, since adding the relationship would create a cycle.

  ## Examples

      iex> Taxo.new |> Taxo.derive(:monkey, :mammal)
      %Taxo{
        ancestors: %{monkey: MapSet.new([:mammal])},
        parents: %{monkey: MapSet.new([:mammal])},
        descendants: %{mammal: MapSet.new([:monkey])}
      }
  """
  @spec derive(t(), tag(), tag()) :: t()
  def derive(%Taxo{} = taxo, child, parent) do
    do_validate_input(child, parent)

    if Taxo.is_a?(taxo, parent, child) do
      raise Taxo.CyclicDerivationError, child: child, parent: parent
    end

    if MapSet.member?(Map.get(taxo.parents, child, MapSet.new()), parent) do
      taxo
    else
      new_parents_for_child =
        taxo.parents
        |> Map.get(child, MapSet.new())
        |> MapSet.put(parent)

      new_parents = Map.put(taxo.parents, child, new_parents_for_child)

      new_ancestors =
        do_transform_derived(taxo.ancestors, child, taxo.descendants, parent, taxo.ancestors)

      new_descendants =
        do_transform_derived(taxo.descendants, parent, taxo.ancestors, child, taxo.descendants)

      %Taxo{parents: new_parents, ancestors: new_ancestors, descendants: new_descendants}
    end
  end

  @doc """
  Removes a parent/child relationship in `taxo` between `child` and `parent`.
  Updates `:parents`, then transitively updates `:ancestors` and `:descendants`.

  This works by dropping the `child`/`parent` edge and rebuilding the whole
  taxonomy from the remaining parent/child pairs, calling `derive/3` on each
  one in turn. Cost is proportional to the size of the taxonomy, not just to
  the edge being removed, so `underive/3` is not a cheap operation on a large
  hierarchy.

  ## Examples

      iex> Taxo.new |> Taxo.derive(:monkey, :mammal) |> Taxo.underive(:monkey, :mammal)
      %Taxo{ancestors: %{}, parents: %{}, descendants: %{}}

  """
  @spec underive(t(), tag(), tag()) :: t()
  def underive(%Taxo{} = taxo, child, parent) do
    do_validate_input(child, parent)

    # Remove `parent` from `child`'s set of direct parents.
    child_parents =
      taxo.parents
      |> Map.get(child, MapSet.new())
      |> MapSet.delete(parent)

    # Either update `child` → child_parents or remove `child` if empty
    new_parents =
      if MapSet.size(child_parents) > 0 do
        Map.put(taxo.parents, child, child_parents)
      else
        Map.delete(taxo.parents, child)
      end

    # Construct a list of {c, p} tuples from the new parent map
    derive_pairs =
      new_parents
      |> Enum.flat_map(fn {c, parent_set} ->
        Enum.map(parent_set, fn p -> {c, p} end)
      end)

    # Only rebuild if `(contains? (parent-map child) parent)` was true
    # i.e. the link actually existed
    if taxo.parents
       |> Map.get(child, MapSet.new())
       |> MapSet.member?(parent) do
      # Rebuild from an empty hierarchy, calling derive/3 on each pair
      Enum.reduce(derive_pairs, Taxo.new(), fn {c, p}, acc ->
        derive(acc, c, p)
      end)
    else
      # If the parent was never actually present, no change
      taxo
    end
  end

  @spec do_validate_input(tag(), tag()) :: :ok
  defp do_validate_input(child, parent) do
    if is_nil(child) or is_nil(parent) do
      raise ArgumentError, "expected non-nil child and parent"
    end

    if child == parent do
      raise ArgumentError, "child and parent cannot be the same"
    end

    :ok
  end

  @spec do_transform_derived(
          %{tag() => MapSet.t(tag())},
          tag(),
          %{tag() => MapSet.t(tag())},
          tag(),
          %{tag() => MapSet.t(tag())}
        ) :: %{tag() => MapSet.t(tag())}
  defp do_transform_derived(member_set, source, sources, target, targets) do
    keys =
      [source]
      |> Enum.concat(Map.get(sources, source, MapSet.new()) |> MapSet.to_list())

    Enum.reduce(keys, member_set, fn k, acc ->
      old_set = Map.get(targets, k, MapSet.new())

      expanded =
        MapSet.new([target])
        |> MapSet.union(Map.get(targets, target, MapSet.new()))

      new_set = MapSet.union(old_set, expanded)
      Map.put(acc, k, new_set)
    end)
  end
end
