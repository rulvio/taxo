defmodule Taxo do
  @moduledoc """
  Taxo is an Elixir port of the Clojure hierarchies provided by `derive` and `underive`.
  """

  defstruct ancestors: %{}, parents: %{}, descendants: %{}

  @doc """
  Create a new taxonomy to store the `:parents`, `:ancestors` and `:descendants` of
  parent/child relationships, updated via `derive` and `underive`.
  Updates `:parents`, then transitively updates `:ancestors` and `:descendants`.

  ## Examples

      iex> Taxo.new
      %Taxo{ancestors: %{}, parents: %{}, descendants: %{}}
  """
  def new do
    %Taxo{}
  end

  @doc """
  Returns true if (= child parent), or child is directly or indirectly derived from parent.

  ## Examples

      iex> Taxo.new |> Taxo.derive(:monkey, :mammal) |> Taxo.derive(:mammal, :vertebrate) |> Taxo.is_a?(:monkey, :vertebrate)
      true
  """
  def is_a?(taxo, child, parent) do
    Map.get(taxo, :ancestors, %{})
    |> Map.get(child, MapSet.new())
    |> MapSet.member?(parent)
  end

  @doc """
  Establish a parent/child relationship in `taxo` between `child` and `parent`.
  Updates `:parents`, then transitively updates `:ancestors` and `:descendants`.

  ## Examples

      iex> Taxo.new |> Taxo.derive(:monkey, :mammal)
      %Taxo{
        ancestors: %{monkey: MapSet.new([:mammal])},
        parents: %{monkey: MapSet.new([:mammal])},
        descendants: %{mammal: MapSet.new([:monkey])}
      }
  """
  def derive(taxo, child, parent) do
    do_validate_input(taxo, child, parent)

    if Taxo.is_a?(taxo, parent, child) do
      raise "Cyclic derivation: #{inspect(parent)} has #{inspect(child)} as ancestor"
    end

    tp = Map.get(taxo, :parents, %{})
    td = Map.get(taxo, :descendants, %{})
    ta = Map.get(taxo, :ancestors, %{})

    if Map.get(tp, child, MapSet.new()) |> MapSet.member?(parent) do
      taxo
    else
      new_parents_for_tag =
        tp
        |> Map.get(child, MapSet.new())
        |> MapSet.put(parent)

      new_parents = Map.put(tp, child, new_parents_for_tag)
      new_ancestors = do_transform_derived(ta, child, td, parent, ta)
      new_descendants = do_transform_derived(td, parent, ta, child, td)

      %Taxo{parents: new_parents, ancestors: new_ancestors, descendants: new_descendants}
    end
  end

  @doc """
  Removes a parent/child relationship in `taxo` between `child` and `parent`.
  Updates `:parents`, then transitively updates `:ancestors` and `:descendants`.

  ## Examples

      iex> Taxo.derive(%{}, :monkey, :mammal) |> Taxo.underive(:monkey, :mammal)
      %Taxo{ancestors: %{}, parents: %{}, descendants: %{}}

  """
  def underive(taxo, child, parent) do
    do_validate_input(taxo, child, parent)

    parent_map = Map.get(taxo, :parents, %{})

    # Remove `parent` from `child`'s set of direct parents.
    child_parents =
      parent_map
      |> Map.get(child, MapSet.new())
      |> MapSet.delete(parent)

    # Either update `child` → child_parents or remove `child` if empty
    new_parents =
      if MapSet.size(child_parents) > 0 do
        Map.put(parent_map, child, child_parents)
      else
        Map.delete(parent_map, child)
      end

    # Construct a list of {c, p} tuples from the new parent map
    derive_pairs =
      new_parents
      |> Enum.flat_map(fn {c, parent_set} ->
        Enum.map(parent_set, fn p -> {c, p} end)
      end)

    # Only rebuild if `(contains? (parent-map child) parent)` was true
    # i.e. the link actually existed
    if parent_map
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

  defp do_validate_input(taxo, child, parent) do
    if is_nil(taxo) or is_nil(child) or is_nil(parent) do
      raise ArgumentError, "expected non-nil taxo, child, and parent"
    end

    if child == parent do
      raise ArgumentError, "child and parent cannot be the same"
    end
  end

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
