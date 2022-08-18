defmodule AbirCounter.Logic do
  alias AbirCounter.Discord.SessionAgent

  def new_msg channel, user, msg_id, content do
    if content =~ ~r/^\d+$/ do
      { success, res } = MyXQL.query :myxql, "SELECT last_user, next_number FROM channel WHERE id=?", [ channel ]
      if success == :ok and res.num_rows == 1 do
        [ [ last_user, next_number ] ] = res.rows
        if last_user != user and next_number == String.to_integer(content) do
          HTTPoison.put! "https://discord.com/api/v10/channels/#{channel}/messages/#{msg_id}/reactions/✅/@me", "",
            [ "Authorization": "Bot " <> SessionAgent.token() ]
          MyXQL.query :myxql, "UPDATE channel SET last_user=?, next_number=? WHERE id=?", [ user, next_number + 1, channel ]
        else
          HTTPoison.put! "https://discord.com/api/v10/channels/#{channel}/messages/#{msg_id}/reactions/❌/@me", "",
            [ "Authorization": "Bot " <> SessionAgent.token() ]
          MyXQL.query :myxql, "UPDATE channel SET last_user=NULL, next_number=1 WHERE id=?", [ channel ]
        end
      end
    end
  end

  @spec start_in_channel(integer, integer, binary) :: :ok
  def start_in_channel channel, int_id, token do
    { res, _ } = MyXQL.query :myxql, "INSERT INTO channel (id) VALUES (?)", [channel]
    msg_content = if res == :ok do
      "Started counter in this channel, start by sending `1`"
    else
      "I'm already counting here"
    end
    payload = JSON.encode! %{
      type: 4,
      data: %{
        content: msg_content
      }
    }
    HTTPoison.post! "https://discord.com/api/v10/interactions/#{int_id}/#{token}/callback", payload,
      [ "Authorization": "Bot " <> SessionAgent.token(), "Content-Type": "application/json" ]
    :ok
  end
end
