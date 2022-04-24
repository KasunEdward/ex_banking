defmodule ExBanking do

  @spec create_user(user :: String.t) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) do
    try do

      if(!is_binary(user)) do
        throw :wrong_arguments
      end

      case :ets.insert_new(:user_account, {user, %{"USD" => 0}}) do
        true ->
          start_spec = {ExBanking.Account, user}
          DynamicSupervisor.start_child(ExBanking.AccountSup, start_spec)
          :ok
        _ ->
          throw :user_already_exists
      end
    catch
      error -> {:error, error}
    end
  end

  @spec deposit(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | {
    :error,
    :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user
  }
  def deposit(user, amount, currency) do
    try do
      #      validate arguments
      if(!is_binary(user) || !(is_integer(amount) || is_float(amount)) || amount < 0 || !is_binary(currency)) do
        throw :wrong_arguments
      end
      #      check if user exists
      if(:ets.lookup(:user_account, user) == []) do
        throw :user_does_not_exist
      end
      #      check user throttle. If throttle exceeds throws error
      if(check_user_throttle(user) == :not_ok) do
        throw :too_many_requests_to_user
      end
      #      :deposit gen_sever call for particular user
      case GenServer.call(String.to_atom(user), {:deposit, amount, currency}) do
        {:ok, new_balance} ->
          {:ok, new_balance}
        {:not_ok, error} ->
          throw error
      end
    catch
      error -> {:error, error}
    end
  end

  @spec withdraw(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | {
    :error,
    :wrong_arguments | :user_does_not_exist | :not_enough_money | :too_many_requests_to_user
  }
  def withdraw(user, amount, currency) do
    try do
      #      validate arguments
      if(!is_binary(user) || !(is_integer(amount) || is_float(amount)) || amount < 0 || !is_binary(currency)) do
        throw :wrong_arguments
      end
      #      check if user exists
      if(:ets.lookup(:user_account, user) == []) do
        throw :user_does_not_exist
      end
      #      check user throttle. If throttle exceeds throws error
      if(check_user_throttle(user) == :not_ok) do
        throw :too_many_requests_to_user
      end
      #      :deposit gen_sever call for particular user
      case GenServer.call(String.to_atom(user), {:deposit, -amount, currency}) do
        {:ok, new_balance} ->
          {:ok, new_balance}
        {:not_ok, error} ->
          throw error
      end
    catch
      error -> {:error, error}
    end
  end

  @spec get_balance(user :: String.t, currency :: String.t) :: {:ok, balance :: number} | {
    :error,
    :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user
  }
  def get_balance(user, currency) do
    try do
      #      validate arguments
      if(!is_binary(user) || !is_binary(currency)) do
        throw :wrong_arguments
      end
      #      check if user exists
      if(:ets.lookup(:user_account, user) == []) do
        throw :user_does_not_exist
      end
      #      check user throttle. If throttle exceeds throws error
      if(check_user_throttle(user) == :not_ok) do
        throw :too_many_requests_to_user
      end
      case GenServer.call(String.to_atom(user), {:get_balance, currency}) do
        {:ok, balance} ->
          {:ok, balance}
        {:not_ok, error} ->
          throw error
      end
    catch
      error -> {:error, error}
    end
  end

  #  private function to check user throttle
  defp check_user_throttle(user) do
    GenServer.call(String.to_atom(user), {:update_counter})
  end
end


