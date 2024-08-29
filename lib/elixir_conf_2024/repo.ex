defmodule ElixirConf2024.Repo do
  use Ecto.Repo,
    otp_app: :elixir_conf_2024,
    adapter: Ecto.Adapters.Postgres
end
