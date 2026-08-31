defmodule Taxo.CyclicDerivationError do
  @moduledoc """
  `Taxo.derive/3` raises this error when a new parent/child relationship
  would create a cycle in the taxonomy.
  """

  defexception [:message, :child, :parent]

  @type t :: %__MODULE__{message: String.t(), child: Taxo.tag(), parent: Taxo.tag()}

  @impl true
  @spec exception(keyword()) :: t()
  def exception(opts) do
    child = Keyword.fetch!(opts, :child)
    parent = Keyword.fetch!(opts, :parent)

    %__MODULE__{
      child: child,
      parent: parent,
      message:
        "cyclic derivation: #{inspect(parent)} already has #{inspect(child)} as an ancestor"
    }
  end
end
