defmodule AbirCounter.Discord.SessionAgent do
  use Agent

  defstruct session: nil, seq: nil, token: nil, app_id: nil

  def start_link [ token: token, app_id: app_id ] do
    Agent.start_link fn -> %__MODULE__{ token: token, app_id: app_id } end, name: __MODULE__
  end

  def token, do: Agent.get(__MODULE__, &(&1.token))

  def app_id, do: Agent.get(__MODULE__, &(&1.app_id))

  def session do
    Agent.get __MODULE__, &(&1.session)
  end

  def seq do
    Agent.get __MODULE__, &(&1.seq)
  end

  def update_session session do
    Agent.update __MODULE__, fn state -> %__MODULE__{ state | session: session } end
  end

  def update_seq seq do
    Agent.update __MODULE__, fn state -> %__MODULE__{ state | seq: seq } end
  end
end
