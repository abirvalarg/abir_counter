defmodule AbirCounter.Discord do
  use WebSockex

  alias AbirCounter.Discord.SessionAgent

  import AbirCounter.Logic

  defstruct heartbeat_interval: nil, sequence: nil, await_ack: false, auth: false

  @type t :: %AbirCounter.Discord{
    heartbeat_interval: nil | integer,
    sequence: nil | integer,
    await_ack: boolean,
    auth: boolean
  }

  @spec start_link( [] ) :: { :error, any } | { :ok, pid }
  def start_link _args do
    token = SessionAgent.token()
    resp = HTTPoison.get! "https://discord.com/api/v10/gateway/bot", [ "Authorization": "Bot #{token}" ]
    %{ "url" => url } = JSON.decode! resp.body
    url = "#{url}?v=10&encoding=etf"
    WebSockex.start_link url, __MODULE__, %__MODULE__{}
  end

  def handle_frame { :binary, msg }, state do
    msg = :erlang.binary_to_term msg
    if msg.s do
      SessionAgent.update_seq msg.s
    end
    state = if msg.s, do: %__MODULE__{ state | sequence: msg.s }, else: state

    handle_op msg, state
  end

  defp handle_command %{ "data" => %{ "name" => "start_here", "type" => 1 } } = info, state do
    id = info["id"]
    token = info["token"]
    channel = info["channel_id"]
    start_in_channel channel, id, token
    { :ok, state }
  end

  defp handle_op %{ op: 0, t: :READY }, state do
    IO.puts "ready"
    { :ok, %__MODULE__{ state | auth: true } }
  end

  defp handle_op %{ op: 0, t: :MESSAGE_CREATE, d: info }, state do
    channel = info["channel_id"]
    user = info["author"]["id"]
    msg_id = info["id"]
    content = info["content"]
    new_msg channel, user, msg_id, content
    { :ok, state }
  end

  defp handle_op %{ op: 0, t: :INTERACTION_CREATE, d: info }, state do
    handle_command info, state
  end

  defp handle_op %{ op: 0, t: t }, state do
    inspect(t) |> IO.puts()
    { :ok, state }
  end

  # gateway hello
  defp handle_op %{ op: 10, d: %{ heartbeat_interval: interval } }, state do
    send self(), :heartbeat
    { :ok, %__MODULE__{ state | heartbeat_interval: interval } }
  end

  defp handle_op %{ op: 11 }, %{ auth: false } = state do
    state = %__MODULE__{ state | await_ack: false }
    session = SessionAgent.session()
    if session == nil do
      id_data = %{
        "token" => SessionAgent.token(),
        "intents" => 33280,
        "properties" => %{
          "os" => "linux",
          "browser" => "none",
          "device" => "pc"
        }
      }
      id_msg = %{
        "op" => 2,
        "d" => id_data
      }
      id_msg = :erlang.term_to_binary id_msg
      { :reply, { :binary, id_msg }, state }
    else
      IO.puts "resuming"
      SessionAgent.update_session nil
      res_data = %{
        "token" => SessionAgent.token(),
        "session" => session,
        "seq" => SessionAgent.seq()
      }
      res_msg = %{
        "op" => 6,
        "d" => res_data
      }
      res_msg = :erlang.term_to_binary res_msg
      { :reply, { :binary, res_msg }, state }
    end
  end

  defp handle_op %{ op: 11 }, state do
    { :ok, %__MODULE__{ state | await_ack: false } }
  end

  def handle_info :heartbeat, state do
    if state.await_ack do
      exit :no_ack
    end
    Process.send_after self(), :heartbeat, state.heartbeat_interval
    reply = :erlang.term_to_binary %{ "op" => 1, "d" => state.sequence }
    { :reply, { :binary, reply }, %__MODULE__{ state | await_ack: true } }
  end

  def terminate reason, _state do
    IO.puts "Terminating: #{inspect reason}"
  end
end
