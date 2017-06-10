defmodule Exsh do
  @moduledoc """
  Documentation for Exsh.
  """

  def main(args) do
    read()
  end

  def read() do
    IO.gets("> ")
    |> String.trim
    |> eval
  end

  def eval("exit") do end
  def eval(command) do
    print(command)
    read()
  end

  def print("") do end
  def print(output) do
    IO.puts " (#{output})"
  end

end
