defmodule AbirCounter.MixProject do
  use Mix.Project

  def project do
    [
      app: :abir_counter,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    token = System.get_env "TOKEN", ""
    # user_id = System.get_env "USER_ID"
    app_id = System.get_env "APP_ID", "0"
    db_password = System.get_env "DB_PASSWORD", "4213qwer"
    [
      extra_applications: [:logger],
      mod: { AbirCounter, [
        token: token,
        app_id: String.to_integer(app_id),
        password: db_password
      ] }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      { :httpoison, "~> 1.8" },
      { :json, "~> 1.4.1" },
      { :websockex, "~> 0.4.3" },
      { :myxql, "~> 0.6.2" }
    ]
  end
end
