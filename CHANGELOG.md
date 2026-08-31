This is a history of changes to rulvio/taxo

## 0.2.0 (2026-08-31)
* `Taxo.CyclicDerivationError`, raised by `derive/3` in place of a bare `RuntimeError`.
  Carries `:child` and `:parent`, so a caller can inspect what would have cycled instead
  of parsing a message.
* Every public function now requires a `%Taxo{}` struct and raises `FunctionClauseError`
  otherwise, rather than treating a bare map as an empty taxonomy.
* `@type t/0` and `@type tag/0`, and `@spec` on every public function.
* CI now runs on a version matrix (the declared floor, Elixir 1.18/OTP 27, and
  the current release, 1.20/29), plus a `quality` job that runs
  `mix format --check-formatted`, `mix credo --strict`, `mix deps.unlock
  --check-unused`, and `mix dialyzer`. The workflow moved from
  `.github/workflows/elixir.yml` to `ci.yml`.
* Added `credo`, with a strict `.credo.exs`, and tracked `mix.lock` so CI
  dependency versions are reproducible.
* `is_a?/3` now returns `true` when `child` and `parent` are the same tag, matching
  Clojure's `isa?`. Previously it only checked ancestry, so a tag was not `is_a?`
  itself.
* New README and `docs/hierarchies.md`, and clearer docs and comments throughout
  `lib/taxo.ex`.

## 0.1.0 (2025-03-17)
* Initial release
