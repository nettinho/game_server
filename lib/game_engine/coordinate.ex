defmodule GameEngine.Coordinate do
  alias __MODULE__

  @board_range 1..10

  def new(col, row) when row in @board_range and col in @board_range do
    {:ok, {col, row}}
  end

  def new(_col, _row), do: {:error, :invalid_coordinate}
end
