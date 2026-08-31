defmodule TaxoTest do
  use ExUnit.Case

  doctest Taxo

  test "create new taxonomy" do
    result = Taxo.new()
    assert result == %Taxo{descendants: %{}, ancestors: %{}, parents: %{}}
  end

  test "is_a? helper returns true when parent is an ancestor of child" do
    assert Taxo.new()
           |> Taxo.derive(:monkey, :mammal)
           |> Taxo.derive(:mammal, :vertebrate)
           |> Taxo.is_a?(:monkey, :vertebrate) == true
  end

  test "is_a? helper returns false when parent is not an ancestor of child" do
    assert Taxo.new()
           |> Taxo.derive(:monkey, :mammal)
           |> Taxo.derive(:mammal, :vertebrate)
           |> Taxo.is_a?(:vertebrate, :monkey) == false
  end

  test "return descendants" do
    assert Taxo.new()
           |> Taxo.derive(:monkey, :mammal)
           |> Taxo.descendants(:mammal) == MapSet.new([:monkey])
  end

  test "return ancestors" do
    assert Taxo.new()
           |> Taxo.derive(:monkey, :mammal)
           |> Taxo.ancestors(:monkey) == MapSet.new([:mammal])
  end

  test "return parents" do
    assert Taxo.new()
           |> Taxo.derive(:monkey, :mammal)
           |> Taxo.parents(:monkey) == MapSet.new([:mammal])
  end

  test "derive child parent relationship in taxonomy" do
    taxonomy = %Taxo{
      ancestors: %{
        mammal: MapSet.new([:vertebrate]),
        monkey: MapSet.new([:mammal, :vertebrate])
      },
      descendants: %{
        mammal: MapSet.new([:monkey]),
        vertebrate: MapSet.new([:monkey, :mammal])
      },
      parents: %{
        mammal: MapSet.new([:vertebrate]),
        monkey: MapSet.new([:mammal])
      }
    }

    result =
      Taxo.new()
      |> Taxo.derive(:monkey, :mammal)
      |> Taxo.derive(:mammal, :vertebrate)

    assert result == taxonomy
  end

  test "underive child parent relationship in taxonomy" do
    taxonomy = %Taxo{
      ancestors: %{
        mammal: MapSet.new([:vertebrate]),
        monkey: MapSet.new([:mammal, :vertebrate])
      },
      descendants: %{
        mammal: MapSet.new([:monkey]),
        vertebrate: MapSet.new([:monkey, :mammal])
      },
      parents: %{
        mammal: MapSet.new([:vertebrate]),
        monkey: MapSet.new([:mammal])
      }
    }

    result =
      taxonomy
      |> Taxo.underive(:monkey, :mammal)

    assert result == Taxo.new() |> Taxo.derive(:mammal, :vertebrate)
  end

  test "underive is a no-op when the relationship never existed" do
    taxo = Taxo.new() |> Taxo.derive(:monkey, :mammal)

    assert Taxo.underive(taxo, :monkey, :vertebrate) == taxo
  end

  test "derive is idempotent when the relationship already exists" do
    once = Taxo.new() |> Taxo.derive(:monkey, :mammal)
    twice = once |> Taxo.derive(:monkey, :mammal)

    assert once == twice
  end

  test "derive raises ArgumentError when child and parent are the same" do
    assert_raise ArgumentError, fn ->
      Taxo.new() |> Taxo.derive(:monkey, :monkey)
    end
  end

  test "derive raises ArgumentError when child or parent is nil" do
    assert_raise ArgumentError, fn ->
      Taxo.new() |> Taxo.derive(nil, :mammal)
    end

    assert_raise ArgumentError, fn ->
      Taxo.new() |> Taxo.derive(:monkey, nil)
    end
  end

  test "derive raises FunctionClauseError when given a non-Taxo taxonomy" do
    assert_raise FunctionClauseError, fn ->
      Taxo.derive(%{}, :monkey, :mammal)
    end
  end

  test "derive raises Taxo.CyclicDerivationError when the new edge would create a cycle" do
    taxo = Taxo.new() |> Taxo.derive(:monkey, :mammal)

    error =
      assert_raise Taxo.CyclicDerivationError, fn ->
        taxo |> Taxo.derive(:mammal, :monkey)
      end

    assert error.child == :mammal
    assert error.parent == :monkey
  end

  test "supports multiple parents (diamond inheritance)" do
    taxo =
      Taxo.new()
      |> Taxo.derive(:mammal, :animal)
      |> Taxo.derive(:pet, :animal)
      |> Taxo.derive(:dog, :mammal)
      |> Taxo.derive(:dog, :pet)

    assert Taxo.parents(taxo, :dog) == MapSet.new([:mammal, :pet])
    assert Taxo.ancestors(taxo, :dog) == MapSet.new([:mammal, :pet, :animal])
    assert Taxo.descendants(taxo, :animal) == MapSet.new([:mammal, :pet, :dog])
    assert Taxo.is_a?(taxo, :dog, :animal)
  end
end
