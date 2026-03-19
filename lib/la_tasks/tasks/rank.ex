defmodule LaTasks.Tasks.Rank do
  @default_gap Decimal.new("1048576")

  def between(left, right) do
    left_value = left || Decimal.new(0)
    right_value = right || default_right(left_value)

    cond do
      Decimal.compare(left_value, right_value) != :lt ->
        raise ArgumentError, "left rank must be less than right rank"

      true ->
        left_value
        |> Decimal.add(right_value)
        |> Decimal.div(Decimal.new(2))
        |> Decimal.normalize()
    end
  end

  def default_gap, do: @default_gap

  defp default_right(left_value) do
    Decimal.add(left_value, @default_gap)
  end
end
