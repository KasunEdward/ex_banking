defmodule Utils do
  @moduledoc false

  #fromat value to 2 decimal places
  def format_value(amount) do
    Float.round(amount*1.00, 2)
  end

end
