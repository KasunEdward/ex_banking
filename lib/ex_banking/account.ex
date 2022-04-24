defmodule ExBanking.Account do
  @moduledoc false

  use GenServer

  @state %{user: "", ops_count: 0}

  def start_link(user_name) do
    GenServer.start_link(__MODULE__, user_name, name: String.to_atom(user_name))
  end

  def init(user_name) do
    IO.puts user_name
    state = @state
    {:ok, %{state | user: user_name}}
  end

  def handle_call({:deposit, amount, currency}, _from, state) do
    IO.puts("Amount - #{amount}, Currency - #{currency}")
    [{_, balance}] = :ets.lookup(:user_account, state.user)
    new_balance_for_currency = case balance[currency] do
      nil ->
        amount
      current_balance_for_currency ->
        amount + current_balance_for_currency
    end
    new_balance = Map.put(balance, currency, new_balance_for_currency)
    :ets.insert(:user_account, {state.user, new_balance})

    {:reply, new_balance_for_currency, state}
  end

# update user ops_count. If ops_count ==MAX_OPS_COUNT then return :not_ok
  def handle_call({:update_counter}, _from, state) do
    current_ops_count = state.ops_count
    if(current_ops_count == 3) do
      {:reply, :not_ok, state}
      else
      {:reply, :ok, %{state|ops_count: current_ops_count+1}}
    end

    end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end
end