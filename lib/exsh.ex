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
    tokenize(raw_string, "", [], [])
  end
  defp tokenize("", token_string, tokens, field_delimiters) do
    {new_tokens, _, _} = make_token(token_string, " ", field_delimiters)
    tokens ++ new_tokens
  end
  defp tokenize(raw_string, token_string, tokens, field_delimiters) do
    character = String.slice(raw_string, 0..0)
    remainder = String.slice(raw_string, 1..-1)
    {new_tokens, token_string, field_delimiters} = make_token(token_string, character, field_delimiters)
    tokens = tokens ++ new_tokens
    tokenize(remainder, token_string, tokens, field_delimiters)
  end

  # iex> use Bitwise
  # Bitwise
  # iex> mask = 0b0010
  # 2
  # iex> opt1 = 0b0001
  # 1
  # iex> opt1 &&& mask
  # 0
  # iex> opt2 = 0b0011
  # 3
  # iex> opt2 &&& mask
  # 2

  @doc """
  Creates a token from the `token_string` if the `character` is a delimiter
  
  Returns `{[token], "token_string", [field_delimiter_list]}`
  
  ## Examples

    iex> Exsh.make_token("pwd", "'", [])
    {["pwd"], "", ["'"]}
    iex> Exsh.make_token("", "'", [])
    {[], "", ["'"]}
    iex> Exsh.make_token("pwd a", "'", ["'"])
    {["pwd a"], "", []}
    iex> Exsh.make_token("pwd", " ", [])
    {["pwd"], "", []}
    iex> Exsh.make_token("pwd", " ", ["'"])
    {[], "pwd ", ["'"]}
    iex> Exsh.make_token("pw", "d", [])
    {[], "pwd", []}
    
  """
  def make_token(token_string, character, field_delimiter_list) do
    {character_category, field_delimiter_list} = categorize_character(character, field_delimiter_list)

    case character_category do
      :field_delimiter_begin when token_string != "" -> {[token_string], "", field_delimiter_list}
      :field_delimiter_begin -> {[], "", field_delimiter_list}
      :field_delimiter_end -> {[token_string], "", field_delimiter_list}
      :word_delimiter when field_delimiter_list == [] -> {[token_string], "", field_delimiter_list}
      :word_delimiter -> {[], "#{token_string}#{character}", field_delimiter_list}
      _ -> {[], "#{token_string}#{character}", field_delimiter_list}
    end
  end

  @doc """
  Categorize a `character` considering the `field_delimiter_list`
  
  Returns character_category atom

  ## Examples

    iex> Exsh.categorize_character("'", ["'"])
    {:field_delimiter_end, []}
    iex> Exsh.categorize_character("'", [])
    {:field_delimiter_begin, ["'"]}
    iex> Exsh.categorize_character("a", [])
    {:character, []}
    iex> Exsh.categorize_character("a", ["'"])
    {:character, ["'"]}

  """
  def categorize_character(character, field_delimiter_list) do
    character_category = categorize_character(character)

    field_delimiter_list_head = []
    field_delimiter_list_tail = []
    if field_delimiter_list != [] do
      [field_delimiter_list_head | field_delimiter_list_tail] = field_delimiter_list
    end
    
    case character_category do
      :field_delimiter when character == field_delimiter_list_head ->
        {:field_delimiter_end, field_delimiter_list_tail}
      :field_delimiter ->
        {:field_delimiter_begin, [character | field_delimiter_list]}
      _ -> {character_category, field_delimiter_list}
    end
  end
  @doc """
  Categorize a `character`
  
  Returns character_category atom

  ## Examples

    iex> Exsh.categorize_character(" ")
    :word_delimiter
    iex> Exsh.categorize_character("'")
    :field_delimiter
    iex> Exsh.categorize_character("(")
    :field_delimiter_begin
    iex> Exsh.categorize_character(")")
    :field_delimiter_end
    iex> Exsh.categorize_character(";")
    :line_delimiter
    iex> Exsh.categorize_character("a")
    :character
    iex> Exsh.categorize_character("0")
    :character

  """
  def categorize_character(character) do
    case character do
      " " -> :word_delimiter
      "'" -> :field_delimiter
      "(" -> :field_delimiter_begin
      ")" -> :field_delimiter_end
      ";" -> :line_delimiter
      _ -> :character
    end
  end

end
