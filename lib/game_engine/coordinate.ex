defmodule GameEngine.Coordinates do
  @board_range 1..500

  def validate_coordinate({col, row}) when row in @board_range and col in @board_range do
    {:ok, {col, row}}
  end

  def validate_coordinate({_col, _row}), do: {:error, :invalid_coordinate}
end
