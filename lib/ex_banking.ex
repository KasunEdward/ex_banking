defmodule ExBanking do

  @spec create_user(user :: String.t) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) do
    try do

      if(!is_binary(user)) do
        throw :wrong_arguments
      end

      case :ets.insert_new(:user_account, {user, %{"USD" =>0}}) do
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
    end
  end
end
