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
end
