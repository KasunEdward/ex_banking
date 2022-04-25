defmodule ExBankingTest do
  use ExUnit.Case
  doctest ExBanking

  test "create user Kasun" do
    assert ExBanking.create_user("Kasun") == :ok
#    assert ExBanking.deposit("Kasun", 100.56, "USD") == {:ok, 100.56}
  end
  test "create user Kasun duplicate" do
    assert ExBanking.create_user("Kasun") == {:error, :user_already_exists}
  end
  test "create user Alex" do
    assert ExBanking.create_user("Alex") == :ok
  end
  test "deposit 100.56 USD to Kasun" do
    assert ExBanking.deposit("Kasun", 100.56, "USD") == {:ok, 100.56}
  end
  test "deposit 100.678 USD to Kasun" do
    assert ExBanking.deposit("Kasun", 100.678, "USD") == {:ok, 201.24}
  end
  test "deposit 100.678 USD to Ben(should return error)" do
    assert ExBanking.deposit("Ben", 100.678, "USD") == {:error, :user_does_not_exist}
  end
  test "deposit 200 USD to Alex" do
    assert ExBanking.deposit("Alex", 200, "USD") == {:ok, 200}
  end
  test "withdraw 10.57 USD from Alex" do
    assert ExBanking.withdraw("Alex", 10.57, "USD") == {:ok, 189.43}
  end
  test "send 20.756 USD from Kasun to Alex" do
    assert ExBanking.send("Kasun","Alex", 20.756, "USD") == {:ok, 180.48, 210.19}
  end
end
