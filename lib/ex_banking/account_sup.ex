defmodule ExBanking.AccountSup do
  @moduledoc false
  


  use DynamicSupervisor

  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    IO.puts "Starting AccountSup"
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end