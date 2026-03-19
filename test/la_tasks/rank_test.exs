defmodule LaTasks.Tasks.RankTest do
  use ExUnit.Case, async: true

  alias LaTasks.Tasks.Rank

  describe "between/2" do
    test "returns a starting rank when both sides are nil" do
      rank = Rank.between(nil, nil)

      assert is_binary(rank)
      assert rank != ""
    end

    test "returns a rank before the right rank" do
      rank = Rank.between(nil, "U")

      assert rank < "U"
    end

    test "returns a rank after the left rank" do
      rank = Rank.between("U", nil)

      assert "U" < rank
    end

    test "returns a rank strictly between two ranks" do
      rank = Rank.between("U", "V")

      assert "U" < rank
      assert rank < "V"
    end

    test "works for very tight gaps" do
      rank = Rank.between("a", "aU")

      assert "a" < rank
      assert rank < "aU"
    end

    test "raises when left is not less than right" do
      assert_raise ArgumentError, fn ->
        Rank.between("Z", "A")
      end

      assert_raise ArgumentError, fn ->
        Rank.between("A", "A")
      end
    end
  end
end
