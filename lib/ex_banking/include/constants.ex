defmodule Constants do
  @moduledoc false

  defmacro evt_success, do: "success"
  defmacro evt_fail, do: "fail"

  defmacro type_deposit, do: "deposit"
  defmacro type_withdraw, do: "withdraw"
end
