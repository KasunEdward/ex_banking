defmodule ExBanking do

  def create_user(user) do
    case :ets.insert_new(:user_account, {user, %{}}) do
      true ->
        :ok
      _ ->
        :user_already_exists
    end
  end
end
