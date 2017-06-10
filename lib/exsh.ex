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
    tokenize(command_string)
    |> pall
    read()
  end

  def pall(tokens) do
    for x <- tokens, do: IO.puts " #{x}"
  end

  def print() do end
  def print("") do end
  def print(output) do
    IO.puts " (#{output})"
  end

  @doc """
  Creates tokens from the `raw_string`

  Returns `[tokens]`

  ## Examples

    iex> Exsh.tokenize("pwd")
    ["pwd"]
    iex> Exsh.tokenize("pwd /tmp")
    ["pwd", "/tmp"]

  """
  def tokenize(raw_string) do
    tokenize(raw_string, "", [])
  end
  defp tokenize("", token_string, tokens) do
    {new_tokens, _} = make_token(token_string, " ")
    tokens ++ new_tokens
  end
  defp tokenize(raw_string, token_string, tokens) do
    character = String.slice(raw_string, 0..0)
    remainder = String.slice(raw_string, 1..-1)
    {new_tokens, token_string} = make_token(token_string, character)
    tokens = tokens ++ new_tokens
    tokenize(remainder, token_string, tokens)
  end

  @doc """
  Creates a token from the `token_string` if the `character` is a delimiter

  Returns `{[token], "token_string"}`

  ## Examples

    iex> Exsh.make_token("pw", "d")
    {[], "pwd"}
    iex> Exsh.make_token("pwd", " ")
    {["pwd"], ""}

  """
  def make_token(token_string, character) do
    case character do
      " " -> {[token_string], ""}
      _ -> {[], "#{token_string}#{character}"}
    end
  end

end
