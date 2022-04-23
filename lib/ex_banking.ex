defmodule ExBanking do

  def create_user(user) do
    case :ets.insert_new(:user_account, {user, %{}}) do
      true ->
        start_spec = {ExBanking.Account, user}
        DynamicSupervisor.start_child(ExBanking.AccountSup, start_spec)
        :ok
      _ ->
        :user_already_exists
    end
  end
end
