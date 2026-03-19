defmodule LaTasks.Tasks.RankTest do
  use ExUnit.Case, async: true

  alias Decimal
  alias LaTasks.Tasks.Rank

  describe "between/2" do
    test "returns a starting rank when both sides are nil" do
      rank = Rank.between(nil, nil)

      assert match?(%Decimal{}, rank)
      assert Decimal.equal?(rank, Decimal.new("524288"))
    end

    test "returns a rank before the right rank" do
      right = Decimal.new("1048576")
      rank = Rank.between(nil, right)

      assert Decimal.compare(rank, right) == :lt
      assert Decimal.equal?(rank, Decimal.new("524288"))
    end

    test "returns a rank after the left rank" do
      left = Decimal.new("1048576")
      rank = Rank.between(left, nil)

      assert Decimal.compare(left, rank) == :lt
      assert Decimal.equal?(rank, Decimal.new("1572864"))
    end

    test "returns a rank strictly between two ranks" do
      left = Decimal.new("100")
      right = Decimal.new("200")
      rank = Rank.between(left, right)

      assert Decimal.compare(left, rank) == :lt
      assert Decimal.compare(rank, right) == :lt
      assert Decimal.equal?(rank, Decimal.new("150"))
    end

    test "works for very tight gaps" do
      left = Decimal.new("1")
      right = Decimal.new("1.0002")
      rank = Rank.between(left, right)

      assert Decimal.compare(left, rank) == :lt
      assert Decimal.compare(rank, right) == :lt
      assert Decimal.equal?(rank, Decimal.new("1.0001"))
    end

    test "uses the default gap when right is nil" do
      left = Decimal.new("10")
      rank = Rank.between(left, nil)

      assert Decimal.compare(left, rank) == :lt
      assert Decimal.equal?(rank, Decimal.new("524298"))
    end

    test "exposes the default gap" do
      assert Decimal.equal?(Rank.default_gap(), Decimal.new("1048576"))
    end

    test "raises when left is not less than right" do
      assert_raise ArgumentError, fn ->
        Rank.between(Decimal.new("10"), Decimal.new("5"))
      end

      assert_raise ArgumentError, fn ->
        Rank.between(Decimal.new("10"), Decimal.new("10"))
      end
    end
  end
end
