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
    tokenize(command_string)
    # |> treeify
    |> nary_tree
  end

  def print() do end
  def print("") do end
  def print(output) do
    # IO.puts " (#{output})"
    # for x <- output, do: IO.puts " #{x}"
    # IO.inspect output
    Enum.take(output)
  end

  def treeify(tokens) do
    treeify(tokens, 0)
  end
  def treeify([], _) do end
  def treeify(tokens, indent) do
    [tokens_head | tokens_tail] = tokens
    new_indent = treeify_indent(tokens_head, indent)
    indention = String.duplicate("  ", new_indent)
    IO.puts "#{indention}#{tokens_head}"
    treeify(tokens_tail, new_indent)
  end
  def treeify_indent(token, indent) do
    case token do
      :field_delimiter_begin -> indent + 1
      :field_delimiter_end -> indent - 1
      _ -> indent
    end
  end

  def nary_tree(tokens) do
    token_string = Enum.join(tokens, ", ")
    IO.puts "A: nary_tree(tokens) -- #{token_string}"
    IO.puts ""

    nary_tree(tokens ++ [:end_of_input], [], [])
  end
  def nary_tree([], [], tree_list) do
    token_string = Enum.join(tree_list, ", ")
    IO.puts "B: nary_tree([], tree_list) -- #{token_string}"
    IO.puts ""

    tree_list
  end
  # [a, :field_delimiter_begin, bb, :field_delimiter_begin, ccc, :field_delimiter_end, :field_delimiter_end]
  def nary_tree(tokens, branch, tree) do
    token_string = Enum.join(tokens, ", ")
    branch_string = Enum.join(branch, ", ")
    tree_string = Enum.join(tree, ", ")
    # "a 'bb (ccc d) e' | f|g(h'i'j k)"
    IO.puts "C: nary_tree(tokens, branch, tree) -- #{token_string}"
    IO.puts "                                           -- #{branch_string}"
    IO.puts "                                           -- #{tree_string}"
    IO.puts ""

    [tokens_head | tokens_tail] = tokens
    {branch, tree} = nary_tree_node(tokens_head, branch, tree)

    nary_tree(tokens_tail, branch, tree)
  end

  def nary_tree_node(value, branch, tree) do
    branch_string = Enum.join(branch, ", ")
    tree_string = Enum.join(tree, ", ")
    IO.puts "D: nary_tree_node(value, branch, tree) -- #{value}"
    IO.puts "                                       -- #{branch_string}"
    IO.puts "                                       -- #{tree_string}"
    IO.puts ""

    case value do
      :field_delimiter_begin -> {[], tree ++ branch}
      :field_delimiter_end -> {[], tree ++ branch}
      :end_of_input -> {[], tree}
      _ -> {tree ++ [value], tree}
    end
  end

  @doc """
  Creates tokens from the `raw_string`

  Returns `[tokens]`

  ## Examples

    iex> Exsh.tokenize("pwd")
    ["pwd"]
    iex> Exsh.tokenize("pwd /tmp")
    ["pwd", "/tmp"]
    iex> Exsh.tokenize("pwd '/tmp /temp'")
    ["pwd", :field_delimiter_begin, "/tmp", "/temp", :field_delimiter_end]

  """
  def tokenize(raw_string) do
    tokenize(raw_string, "", [], [])
  end
  defp tokenize("", "", tokens, _) do
    tokens
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

  @doc """
  Creates a token from the `token_string` if the `character` is a delimiter, considering the `field_delimiter_list`
  
  Returns `{[token], "token_string", [field_delimiter_list]}`
  
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
  def make_token(token_string, character, field_delimiter_list) do
    {character_category, field_delimiter_list} = categorize_character(character, field_delimiter_list)
    case character_category do
      :field_delimiter_begin when token_string != "" -> {[token_string, :field_delimiter_begin], "", field_delimiter_list}
      :field_delimiter_begin -> {[:field_delimiter_begin], "", field_delimiter_list}
      :field_delimiter_end when token_string != "" -> {[token_string, :field_delimiter_end], "", field_delimiter_list}
      :field_delimiter_end -> {[:field_delimiter_end], "", field_delimiter_list}
      :field_delimiter when token_string != "" -> {[token_string, character], "", field_delimiter_list}
      :field_delimiter -> {[character], "", field_delimiter_list}
      :word_delimiter when token_string != "" -> {[token_string], "", field_delimiter_list}
      :word_delimiter -> {[], "", field_delimiter_list}
      _ -> {[], "#{token_string}#{character}", field_delimiter_list}
    end
  end

  @doc """
  Categorize a `character` considering the `field_delimiter_list`
  
  Returns {character_category_atom, field_delimiter_list}

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
    field_delimiter_list_head = Enum.slice(field_delimiter_list, 0..0)
    field_delimiter_list_tail = Enum.slice(field_delimiter_list, 1..-1)
    case character_category do
      :field_delimiter_paired when [character] == field_delimiter_list_head ->
        {:field_delimiter_end, field_delimiter_list_tail}
      :field_delimiter_paired ->
        {:field_delimiter_begin, [character] ++ field_delimiter_list}
      _ -> {character_category, field_delimiter_list}
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

end
