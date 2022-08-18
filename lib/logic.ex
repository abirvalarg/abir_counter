defmodule AbirCounter.Logic do
  alias AbirCounter.Discord.SessionAgent

  def new_msg channel, _user, msg_id, content do
    if content =~ ~r/\d+/ do
      IO.puts "new number #{content} in #{channel}"
      resp = HTTPoison.put! "https://discord.com/api/v10/channels/#{channel}/messages/#{msg_id}/reactions/✅/@me", "",
        [ "Authorization": "Bot " <> SessionAgent.token() ]
      if resp.status_code >= 300 do
        IO.puts "status code #{resp.status_code}"
        IO.puts resp.body
      end
    end
  end

  @spec start_in_channel(integer, integer, binary) :: :ok
  def start_in_channel channel, int_id, token do
    MyXQL.query :myxql, "INSERT INTO channel (id) VALUES (?)", [channel]
    :ok
  end
end
