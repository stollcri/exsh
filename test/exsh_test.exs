defmodule ExshTest do
  use ExUnit.Case
  doctest Exsh
  doctest Exsh.Messages
  doctest Exsh.Repl
  doctest Exsh.Repl.Eval
  doctest Exsh.Repl.Print
  doctest Exsh.Repl.Read

  test "the truth" do
    assert 1 + 1 == 2
  end
end
