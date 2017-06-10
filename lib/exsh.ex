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
  def eval(command_string) do
    # print(command_string)
    tokenize(command_string)
    |> pall
    read()
  end

  def pall(tokens) do
    IO.puts ">>>"
    for x <- tokens, do: IO.puts " #{x}"
    IO.puts "<<<"
  end

  def print() do end
  def print("") do end
  def print(output) do
    IO.puts " (#{output})"
  end

  def tokenize(raw_string) do
    # BEGIN
    tokenize(raw_string, "", [])
  end
  def tokenize("", token_string, tokens) do
    # BASE CASE
    {new_tokens, _} = make_token(token_string, " ")
    tokens ++ new_tokens
  end
  def tokenize(raw_string, token_string, tokens) do
    character = String.slice(raw_string, 0..0)
    remainder = String.slice(raw_string, 1..-1)
    
    {new_tokens, token_string} = make_token(token_string, character)
    tokens = tokens ++ new_tokens

    tokenize(remainder, token_string, tokens)
  end

  def make_token(token_string, character) do
    case character do
      " " -> {[token_string], ""}
      _ -> {[], "#{token_string}#{character}"}
    end
  end

end
