defmodule Taxo do
  @moduledoc """
  Taxo builds and queries tag hierarchies.

  It ports the `derive` and `underive` functions from Clojure's hierarchy
  system.
  """

  defstruct ancestors: %{}, parents: %{}, descendants: %{}

  @typedoc "A node in a taxonomy. A tag can be any term, because Taxo stores it as a map key."
  @type tag :: term()

  @type t :: %__MODULE__{
          ancestors: %{tag() => MapSet.t(tag())},
          parents: %{tag() => MapSet.t(tag())},
          descendants: %{tag() => MapSet.t(tag())}
        }

  @doc """
  Creates a new, empty taxonomy.

  Use `derive/3` to add parent/child relationships to it.

  ## Examples

      iex> Taxo.new
      %Taxo{ancestors: %{}, parents: %{}, descendants: %{}}
  """
  @spec new() :: t()
  def new do
    %Taxo{}
  end

  @doc """
  Returns true if `child` and `parent` are equal.
  Returns true if `child` is a direct or indirect descendant of `parent`.
  Returns false otherwise.

  ## Examples

      iex> Taxo.new |> Taxo.is_a?(:monkey, :monkey)
      true

      iex> Taxo.new |> Taxo.derive(:monkey, :mammal) |> Taxo.derive(:mammal, :vertebrate) |> Taxo.is_a?(:monkey, :vertebrate)
      true

      iex> Taxo.new |> Taxo.derive(:monkey, :mammal) |> Taxo.derive(:mammal, :vertebrate) |> Taxo.is_a?(:vertebrate, :monkey)
      false

  """
  @spec is_a?(t(), tag(), tag()) :: boolean()
  def is_a?(%Taxo{} = taxo, child, parent) do
    child == parent or
      taxo.ancestors
      |> Map.get(child, MapSet.new())
      |> MapSet.member?(parent)
  end

  @doc """
  Returns the descendants of `child` in `taxo`.

  ## Examples

      iex> Taxo.new |> Taxo.derive(:monkey, :mammal) |> Taxo.descendants(:mammal)
      MapSet.new([:monkey])
  """
  @spec descendants(t(), tag()) :: MapSet.t(tag())
  def descendants(%Taxo{} = taxo, child) do
    Map.get(taxo.descendants, child, MapSet.new())
  end

  @doc """
  Returns the ancestors of `child` in `taxo`.

  ## Examples

      iex> Taxo.new |> Taxo.derive(:monkey, :mammal) |> Taxo.ancestors(:monkey)
      MapSet.new([:mammal])
  """
  @spec ancestors(t(), tag()) :: MapSet.t(tag())
  def ancestors(%Taxo{} = taxo, child) do
    Map.get(taxo.ancestors, child, MapSet.new())
  end

  @doc """
  Returns the direct parents of `child` in `taxo`.

  ## Examples

      iex> Taxo.new |> Taxo.derive(:monkey, :mammal) |> Taxo.parents(:monkey)
      MapSet.new([:mammal])

  """
  @spec parents(t(), tag()) :: MapSet.t(tag())
  def parents(%Taxo{} = taxo, child) do
    Map.get(taxo.parents, child, MapSet.new())
  end

  @doc """
  Adds a parent/child relationship between `child` and `parent` in `taxo`.

  This updates `:parents` directly, then updates `:ancestors` and
  `:descendants` for every tag the change affects: `child`, `parent`, and
  all their existing relatives.

  Raises `Taxo.CyclicDerivationError` if `parent` is already a descendant of
  `child`. Adding the relationship would otherwise create a cycle.

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
  Removes a parent/child relationship between `child` and `parent` in `taxo`.

  This drops the `child`/`parent` link, then rebuilds the whole taxonomy
  from the pairs that remain, calling `derive/3` on each pair in turn.

  The rebuild cost depends on the size of the whole taxonomy, not on the
  size of the link removed. `underive/3` is not a cheap operation on a
  large hierarchy.

  ## Examples

      iex> Taxo.new |> Taxo.derive(:monkey, :mammal) |> Taxo.underive(:monkey, :mammal)
      %Taxo{ancestors: %{}, parents: %{}, descendants: %{}}

  """
  @spec underive(t(), tag(), tag()) :: t()
  def underive(%Taxo{} = taxo, child, parent) do
    do_validate_input(child, parent)

    # Remove `parent` from `child`'s direct parents.
    child_parents =
      taxo.parents
      |> Map.get(child, MapSet.new())
      |> MapSet.delete(parent)

    # Update `child`'s parents, or remove `child` if it has none left.
    new_parents =
      if MapSet.size(child_parents) > 0 do
        Map.put(taxo.parents, child, child_parents)
      else
        Map.delete(taxo.parents, child)
      end

    # List every remaining {child, parent} pair.
    derive_pairs =
      new_parents
      |> Enum.flat_map(fn {c, parent_set} ->
        Enum.map(parent_set, fn p -> {c, p} end)
      end)

    if taxo.parents
       |> Map.get(child, MapSet.new())
       |> MapSet.member?(parent) do
      # The link existed. Rebuild the taxonomy from an empty one, adding
      # each remaining pair back with derive/3.
      Enum.reduce(derive_pairs, Taxo.new(), fn {c, p}, acc ->
        derive(acc, c, p)
      end)
    else
      # The link never existed. Return taxo unchanged.
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
