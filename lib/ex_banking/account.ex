defmodule ExBanking.Account do
  @moduledoc false
  require Utils

  use GenServer

  @state %{
    user: "",
    ops_count: 0.0,
    max_ops_count: Application.get_env(:ex_banking, :max_ops_count)
  }

  def start_link(user_name) do
    GenServer.start_link(__MODULE__, user_name, name: String.to_atom(user_name))
  end

  def init(user_name) do
    state = @state
    {:ok, %{state | user: user_name}}
  end

  def handle_call({:deposit, amount, currency}, _from, state) do
    ops_count = state.ops_count
    [{_, balance}] = :ets.lookup(:user_account, state.user)
    new_balance_for_currency = case balance[currency] do
      nil ->
        Utils.format_value(amount)
      current_balance_for_currency ->
        Utils.format_value(amount + current_balance_for_currency)
    end

    if(new_balance_for_currency < 0) do
      {:reply, {:not_ok, :not_enough_money}, %{state | ops_count: ops_count - 1}}
    else
      new_balance = Map.put(balance, currency, new_balance_for_currency)
      :ets.insert(:user_account, {state.user, new_balance})

      {:reply, {:ok, new_balance_for_currency}, %{state | ops_count: ops_count - 1}}
    end
  end
  def handle_call({:get_balance, currency}, _from, state) do
    ops_count = state.ops_count
    [{_, balance}] = :ets.lookup(:user_account, state.user)
    balance_for_currency = case balance[currency] do
      nil ->
        0
      current_balance_for_currency ->
        current_balance_for_currency
    end
    {:reply, {:ok, balance_for_currency}, %{state | ops_count: ops_count - 1}}
  end

  # update user ops_count. If ops_count ==MAX_OPS_COUNT then return :not_ok
  def handle_call({:update_counter}, _from, state) do
    current_ops_count = state.ops_count
    if(current_ops_count == state.max_ops_count) do
      {:reply, :not_ok, state}
    else
      {:reply, :ok, %{state | ops_count: current_ops_count + 1}}
    end
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end
end