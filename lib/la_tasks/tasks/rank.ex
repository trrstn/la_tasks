defmodule LaTasks.Tasks.Rank do
  @alphabet "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
  @base byte_size(@alphabet)

  @spec between(String.t() | nil, String.t() | nil) :: String.t()
  def between(left, right) do
    cond do
      left != nil and right != nil and left >= right ->
        raise ArgumentError, "left rank must be less than right rank"

      true ->
        do_between(left || "", right || "", 0, [])
        |> IO.iodata_to_binary()
    end
  end

  defp do_between(left, right, pos, acc) do
    left_digit = digit_at(left, pos, :low)
    right_digit = digit_at(right, pos, :high)

    cond do
      right_digit - left_digit > 1 ->
        mid = div(left_digit + right_digit, 2)
        acc ++ [char_at(mid)]

      true ->
        next_acc =
          case left_digit do
            -1 -> acc
            digit -> acc ++ [char_at(digit)]
          end

        do_between(left, right, pos + 1, next_acc)
    end
  end

  defp digit_at(str, pos, side) do
    if pos < byte_size(str) do
      <<_::binary-size(pos), ch::utf8, _::binary>> = str
      index_of(<<ch::utf8>>)
    else
      case side do
        :low -> -1
        :high -> @base
      end
    end
  end

  defp index_of(char) do
    case :binary.match(@alphabet, char) do
      {idx, 1} -> idx
      :nomatch -> raise ArgumentError, "invalid rank character: #{inspect(char)}"
    end
  end

  defp char_at(idx) when idx >= 0 and idx < @base do
    binary_part(@alphabet, idx, 1)
  end
end
