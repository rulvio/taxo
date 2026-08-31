# Credo configuration.
#
# Everything not mentioned here keeps its default, so this file is only the
# places where the default is wrong *for this codebase* — and each of them says
# why. `strict: true` is set, so `mix credo` and `mix credo --strict` agree.
%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "test/"],
        excluded: [~r"/_build/", ~r"/deps/"]
      },
      plugins: [],
      requires: [],
      strict: true,
      parse_timeout: 5000,
      color: true,
      checks: %{
        extra: [],
        disabled: [
          # `is_a?/3` ports Clojure's `isa?`. The name states the relationship it
          # tests ("child is-a parent"), not a boolean flag, so the usual "is"
          # prefix complaint does not apply here.
          {Credo.Check.Readability.PredicateFunctionNames, []}
        ]
      }
    }
  ]
}
