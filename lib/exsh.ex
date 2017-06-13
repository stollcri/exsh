defmodule Exsh do
  @moduledoc """
  Documentation for Exsh.
  """

  def main(_) do
    repl()
    # read()
  end

  def repl() do
    # read()
    IO.puts "a 'bb (ccc d) e' | f|g(h'i'j k)"
    "a 'bb (ccc d) e' | f|g(h'i'j k)"
    |> eval
    |> print
    # repl()
  end

  def read() do
    IO.gets("> ")
    |> String.trim
  end

  def eval("exit") do end
  def eval(command_string) do
    lex(command_string)
  end

  def print() do end
  def print("") do end
  def print(output) do
    # IO.puts " (#{output})"
    # for x <- output, do: IO.puts " #{x}"
    # IO.inspect output
    Enum.take(output)
  end

  def lex(command_string) do
    command_string
    |> scan
    |> evaluate
  end

  @doc """
  Creates tokens from the `raw_string`

  Returns `[tokens]`

  ## Examples

    iex> Exsh.scan("pwd")
    ["pwd"]
    iex> Exsh.scan("pwd /tmp")
    ["pwd", "/tmp"]
    iex> Exsh.scan("pwd '/tmp /temp'")
    ["pwd", :field_delimiter_begin, "/tmp", "/temp", :field_delimiter_end]

  """
  def scan(raw_string) do
    scan(raw_string, "", [], [])
  end
  defp scan("", "", tokens, _) do
    tokens
  end
  defp scan("", token_string, tokens, field_delimiters) do
    {new_tokens, _, _} = make_token(token_string, " ", field_delimiters)
    tokens ++ new_tokens
  end
  defp scan(raw_string, token_string, tokens, field_delimiters) do
    character = String.slice(raw_string, 0..0)
    remainder = String.slice(raw_string, 1..-1)
    {new_tokens, token_string, field_delimiters} = make_token(token_string, character, field_delimiters)
    tokens = tokens ++ new_tokens
    scan(remainder, token_string, tokens, field_delimiters)
  end

  @doc """
  Creates a token from the `token_string` if the `character` is a delimiter, considering the `delimiter_list`
  
  Returns `{[token], "token_string", [delimiter_list]}`
  
  ## Examples

    iex> Exsh.make_token("pwd", "'", [])
    {["pwd", :field_delimiter_begin], "", ["'"]}
    iex> Exsh.make_token("", "'", [])
    {[:field_delimiter_begin], "", ["'"]}
    iex> Exsh.make_token("pwd a", "'", ["'"])
    {["pwd a", :field_delimiter_end], "", []}
    iex> Exsh.make_token("", "'", ["'"])
    {[:field_delimiter_end], "", []}
    iex> Exsh.make_token("pwd", " ", [])
    {["pwd"], "", []}
    iex> Exsh.make_token("pwd", " ", ["'"])
    {["pwd"], "", ["'"]}
    iex> Exsh.make_token("pw", "d", [])
    {[], "pwd", []}

  """
  def make_token(token_string, character, delimiter_list) do
    {character_category, delimiter_list} = categorize_character(character, delimiter_list)
    case character_category do
      :field_delimiter_begin when token_string != "" -> {[token_string, :field_delimiter_begin], "", delimiter_list}
      :field_delimiter_begin -> {[:field_delimiter_begin], "", delimiter_list}
      :field_delimiter_end when token_string != "" -> {[token_string, :field_delimiter_end], "", delimiter_list}
      :field_delimiter_end -> {[:field_delimiter_end], "", delimiter_list}
      :field_delimiter when token_string != "" -> {[token_string, character], "", delimiter_list}
      :field_delimiter -> {[character], "", delimiter_list}
      :word_delimiter when token_string != "" -> {[token_string], "", delimiter_list}
      :word_delimiter -> {[], "", delimiter_list}
      _ -> {[], "#{token_string}#{character}", delimiter_list}
    end
  end

  @doc """
  Categorize a `character` considering the `delimiter_list`
  
  Returns {character_category_atom, delimiter_list}

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
  def categorize_character(character, delimiter_list) do
    character_category = categorize_character(character)
    delimiter_list_head = Enum.slice(delimiter_list, 0..0)
    delimiter_list_tail = Enum.slice(delimiter_list, 1..-1)
    case character_category do
      :field_delimiter_paired when [character] == delimiter_list_head ->
        {:field_delimiter_end, delimiter_list_tail}
      :field_delimiter_paired ->
        {:field_delimiter_begin, [character] ++ delimiter_list}
      _ -> {character_category, delimiter_list}
    end
  end
  @doc """
  Categorize a `character`
  
  Returns character_category atom

  ## Examples

    iex> Exsh.categorize_character(" ")
    :word_delimiter
    iex> Exsh.categorize_character("|")
    :field_delimiter
    iex> Exsh.categorize_character("'")
    :field_delimiter_paired
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
      "|" -> :field_delimiter
      "'" -> :field_delimiter_paired
      "(" -> :field_delimiter_begin
      ")" -> :field_delimiter_end
      ";" -> :line_delimiter
      _ -> :character
    end
  end


  def evaluate(raw_tokens) do
    [raw_tokens_head | raw_tokens_tail] = raw_tokens
    evaluate(raw_tokens_head, [], [], raw_tokens_tail)
  end
  def evaluate(_, pending_tokens, merged_tokens, []) do
    merge_tokens(merged_tokens, pending_tokens, [])
  end
  def evaluate(current_token, pending_tokens, merged_tokens, unmerged_tokens) do
    {pending_tokens, newly_merged_tokens, delimiter_token} = evaluate_next(current_token, pending_tokens)
    [unmerged_tokens_head | unmerged_tokens_tail] = unmerged_tokens
    evaluate(unmerged_tokens_head, pending_tokens, merge_tokens(merged_tokens, newly_merged_tokens, delimiter_token), unmerged_tokens_tail)
  end
  def evaluate_next(current_token, pending_tokens) do
    pending_token_string = Enum.join(pending_tokens, " ")
    IO.puts "X: #{current_token} (#{pending_token_string})"
    case current_token do
      :field_delimiter_begin -> {pending_tokens, [], []}
      :field_delimiter_end -> {pending_tokens, [], []}
      :line_delimiter -> {pending_tokens, [], []}
      "|" -> {[], pending_tokens, [current_token]}
      _ -> {pending_tokens ++ [current_token], [], []}
    end
  end

  def merge_tokens(existing, new, delimiter) do
    case new do
      [] -> existing
      _ when delimiter != [] -> existing ++ [new] ++ [delimiter]
      _ -> existing ++ [new]
    end
  end

end
