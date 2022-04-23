defmodule ExBanking.Account do
  @moduledoc false

  use GenServer

  def start_link(user_name) do
    GenServer.start_link(__MODULE__,user_name,name: String.to_atom(user_name))
  end

  def init(user_name) do
    IO.puts user_name
    {:ok, %{}}
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end
end