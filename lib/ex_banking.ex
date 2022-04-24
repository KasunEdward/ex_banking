defmodule ExBanking do
  @retry_count 5
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
      case do_transaction(user, amount, currency) do
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
      case do_transaction(user, -amount, currency) do
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
      case get_user_balance(user, currency) do
        {:ok, balance} ->
          {:ok, balance}
        {:not_ok, error} ->
          throw error
      end
    catch
      error -> {:error, error}
    end
  end

  @spec send(from_user :: String.t, to_user :: String.t, amount :: number, currency :: String.t) :: {
                                                                                                      :ok,
                                                                                                      from_user_balance :: number,
                                                                                                      to_user_balance :: number
                                                                                                    } | {
                                                                                                      :error,
                                                                                                      :wrong_arguments | :not_enough_money | :sender_does_not_exist | :receiver_does_not_exist | :too_many_requests_to_sender | :too_many_requests_to_receiver
                                                                                                    }
  def send(from_user, to_user, amount, currency) do
    try do
      #      validate arguments
      if(
        !is_binary(from_user) || !is_binary(to_user) || !(is_integer(amount) || is_float(amount))
        || amount < 0 || !is_binary(currency)
      ) do
        throw :wrong_arguments
      end
      #      check if from_user exists
      if(:ets.lookup(:user_account, from_user) == []) do
        throw :sender_does_not_exist
      end
      #      check if to_user exists
      if(:ets.lookup(:user_account, to_user) == []) do
        throw :receiver_does_not_exist
      end
      #      check from_user throttle. If throttle exceeds throws error
      if(check_user_throttle(from_user) == :not_ok) do
        throw :too_many_requests_to_sender
      end

      #      :deposit gen_sever call for particular user
      case do_transaction(from_user, -amount, currency) do
        {:ok, from_user_balance} ->
          case check_user_throttle(to_user) do
            :ok ->
              {:ok, to_user_balance} = do_transaction(to_user, amount, currency)
              {:ok, from_user_balance, to_user_balance}
            :not_ok ->
              spawn(revert_transaction(from_user, amount, currency, @retry_count))
              throw :too_many_requests_to_reveiver
          end
        {:not_ok, error} ->
          throw error
      end
    catch
      error -> {:error, error}
    end
  end

  #  private function to do transaction (deposit-> +amount | withdraw-> -amount)
  defp do_transaction(user, amount, currency) do
    case GenServer.call(String.to_atom(user), {:deposit, amount, currency}) do
      {:ok, new_balance} ->
        {:ok, new_balance}
      {:not_ok, error} ->
        {:not_ok, error}
    end
  end

  #private function to get balance
  defp get_user_balance(user, currency) do
    case GenServer.call(String.to_atom(user), {:get_balance, currency}) do
      {:ok, balance} ->
        {:ok, balance}
      {:not_ok, error} ->
        throw error
    end
  end

  #  private function to check user throttle
  defp check_user_throttle(user) do
    case GenServer.call(String.to_atom(user), {:update_counter}) do
      :ok ->
        :ok
      :not_ok ->
        :not_ok
    end
  end

  #  private function to revert transaction
  defp revert_transaction(_user, _amount, _currency, 0) do
    IO.puts("error")
  end

  defp revert_transaction(user, amount, currency, retry_count) do
    case check_user_throttle(user) do
      :ok ->
        {:ok, balance} = do_transaction(user, amount, currency)
        IO.puts("revert transaction. user-#{user}, currency-#{currency}, amount-#{amount}")
      :not_ok ->
        revert_transaction(user, amount, currency, retry_count - 1)
    end
  end
end


