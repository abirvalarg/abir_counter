defmodule AbirCounter do
  def start _type, [ token: token, app_id: app_id, password: password] do
    children = [
      { MyXQL, hostname: "localhost", username: "abir_counter", password: password, database: "abir_counter"},
      { AbirCounter.Discord.SessionAgent, token: token, app_id: app_id },
      { AbirCounter.Discord, [] }
    ]

    :ok = init_commands commands(), token, app_id

    Supervisor.start_link children, strategy: :one_for_one
  end

  @spec init_commands([%{atom => any}], binary, binary) :: :ok | :err
  defp init_commands [], _, _ do
    :ok
  end

  defp init_commands [ cmd | tail ], token, app_id do
    cmd = JSON.encode! cmd
    resp = HTTPoison.post! "https://discord.com/api/v10/applications/#{app_id}/commands",
      cmd, [ "Authorization": "Bot #{token}", "Content-Type": "application/json" ]

    if resp.status_code >= 300 do
      IO.puts "status code: #{resp.status_code}"
      IO.puts resp.body

      :err
    else
      init_commands tail, token, app_id
    end
  end

  @spec commands :: [%{atom => any}]
  defp commands do
    [
      %{
        name: "start_here",
        description: "Start counting in this channel",
        default_member_permissions: "0"
      }
    ]
  end
end
