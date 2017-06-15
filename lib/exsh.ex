defmodule Exsh do
  @moduledoc """
  Documentation for Exsh.

  mix escript.build; ./exsh "aa | 'bb (cc dd) ee'||ff(gg 'hh' ii)jj" --exit
  """

  def main(args) do
    args
    |> parse_args
    |> repl
  end

  defp parse_args(args) do
    options_default = %{
      :version => "0.0.1",
      :help => :false,
      :exit => :false
    }
    {options_input, command_strings, _} = OptionParser.parse(args,
      strict: [
        help: :boolean,
        exit: :boolean
      ],
      aliases: [
        h: :help,
        x: :exit
      ]
    )
    options = Enum.into(options_input, options_default)
    if options[:help] do
      {Enum.into(%{:exit => :true}, options), ["help"]}
    else
      {options, command_strings}
    end
  end

  def help_message(options) do
    """
    exsh, version #{options[:version]}
    https://github.com/stollcri/exsh

    exsh [options] [commands]
      options:
        -h, --help    Print this help
        -x, --exit    Exit after running command

      Built-in shell commands:
        help          Print this help
        exit          Exit the shell
    """
  end

  @doc """
  Read, Evaluate, Print, Loop
  """
  def repl({options, []}) do
    repl(options, "")
  end
  def repl({options, [command_string | _]}) do
    # TODO: loop over tail of command_string list to process subsequent commands
    repl(options, command_string)
  end
  def repl(options, command_string) do
    input = read(options, command_string)
    {stdout, stderr, exitcode} = eval(options, input)
    if exitcode != -1 do
      print(options, stdout, stderr)

      if options[:exit] do
        System.halt(exitcode)
      else
        repl(options, "")
      end
    end
  end

  @doc """
  Read user input -- gather interactively or use `command_string`
  The `options` are currently ignored

  Returns `command_string`

  ## Examples

    iex> Exsh.read([], " pwd ")
    "pwd"

  """
  def read(options, command_string) do
    if command_string == "" do
      IO.gets("> ")
    else
      command_string
    end
    |> String.trim
  end

  @doc """
  Evaluate user input given in the `command_string`
  The `options` are currently ignored

  Returns `{stdout, stderr, exitcode}`

  ## Examples

    iex> Exsh.eval([], "exit")
    {"", "", -1}

  """
  def eval(_, "exit") do
    {"", "", -1}
  end
  def eval(options, "help") do
    {help_message(options), "", 0}
  end
  def eval(options, command_string) do
    symbol_map = %{
      "ls" => "/bin/ls -AGhl",
      "dirsizes" => "ls | du -chd 1 | sort"
    }

    stdout = command_string
    |> tokenize
    |> parse
    |> evaluate(symbol_map)
    stderr = ""
    exitcode = 0
    {stdout, stderr, exitcode}
  end

  @doc """
  Print command outpu given in the `stdout` and `stderr`
  The `options` are currently ignored
  """
  def print() do end
  def print(_, "", "") do end
  def print(options, stdout, stderr) do
    if stdout != "" do
      IO.puts stdout
    end
    if stderr != "" do
      IO.puts :stderr, stderr
    end
  end



  @doc """
  Create tokens from a `raw_string`

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
    scan(raw_string, "", [], [])
  end

  @doc """
  Scan a `raw_string` and call the lexer

  Returns `[tokens]`

  ## Examples

    iex> Exsh.scan("pwd", "", [], [])
    ["pwd"]
    iex> Exsh.scan("d", "pw", [], [])
    ["pwd"]
    iex> Exsh.scan("(", "", ["pwd"], [])
    ["pwd", :field_delimiter_begin]
    iex> Exsh.scan("'", "", [:field_delimiter_begin, "pwd"], ["'"])
    [:field_delimiter_begin, "pwd", :field_delimiter_end]

  """
  def scan("", lexeme, tokens, delimiters) do
    {new_tokens, _, _} = lex(lexeme, " ", delimiters)
    tokens ++ new_tokens
  end
  def scan(raw_string, lexeme, tokens, delimiters) do
    # TODO: implement look-back to merge subsequent field delimiters (e.g. ["|", "|"] -> ["||"])
    character = String.slice(raw_string, 0..0)
    remainder = String.slice(raw_string, 1..-1)
    {new_tokens, lexeme, delimiters} = lex(lexeme, character, delimiters)
    tokens = tokens ++ new_tokens
    scan(remainder, lexeme, tokens, delimiters)
  end

  @doc """
  Create tokens from the `lexeme` (when `character` is a delimiter, while considering `delimiters`)
  
  Returns `{[tokens], "lexeme", [delimiters]}`
  
  ## Examples

    iex> Exsh.lex("pwd", "'", [])
    {["pwd", :field_delimiter_begin], "", ["'"]}
    iex> Exsh.lex("", "'", [])
    {[:field_delimiter_begin], "", ["'"]}
    iex> Exsh.lex("pwd a", "'", ["'"])
    {["pwd a", :field_delimiter_end], "", []}
    iex> Exsh.lex("", "'", ["'"])
    {[:field_delimiter_end], "", []}
    iex> Exsh.lex("pwd", " ", [])
    {["pwd"], "", []}
    iex> Exsh.lex("pwd", " ", ["'"])
    {["pwd"], "", ["'"]}
    iex> Exsh.lex("pw", "d", [])
    {[], "pwd", []}

  """
  def lex(lexeme, character, delimiters) do
    {character_category, delimiters} = categorize_character(character, delimiters)
    case character_category do
      :field_delimiter_begin when lexeme != "" -> {[lexeme, :field_delimiter_begin], "", delimiters}
      :field_delimiter_begin -> {[:field_delimiter_begin], "", delimiters}
      :field_delimiter_end when lexeme != "" -> {[lexeme, :field_delimiter_end], "", delimiters}
      :field_delimiter_end -> {[:field_delimiter_end], "", delimiters}
      :field_delimiter when lexeme != "" -> {[lexeme, character], "", delimiters}
      :field_delimiter -> {[character], "", delimiters}
      :word_delimiter when lexeme != "" -> {[lexeme], "", delimiters}
      :word_delimiter -> {[], "", delimiters}
      _ -> {[], "#{lexeme}#{character}", delimiters}
    end
  end

  @doc """
  Categorize a `character` while considering `delimiters`
  
  Returns {character_category_atom, delimiters}

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
  def categorize_character(character, delimiters) do
    character_category = categorize_character(character)
    delimiters_head = Enum.slice(delimiters, 0..0)
    delimiters_tail = Enum.slice(delimiters, 1..-1)
    case character_category do
      :field_delimiter_paired when [character] == delimiters_head ->
        {:field_delimiter_end, delimiters_tail}
      :field_delimiter_paired ->
        {:field_delimiter_begin, [character] ++ delimiters}
      _ -> {character_category, delimiters}
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
      "=" -> :field_delimiter
      ">" -> :field_delimiter
      "<" -> :field_delimiter
      "|" -> :field_delimiter
      "'" -> :field_delimiter_paired
      "(" -> :field_delimiter_begin
      ")" -> :field_delimiter_end
      ";" -> :line_delimiter
      _ -> :character
    end
  end

  @doc """
  Create parse tree from `raw_tokens`

  Returns `[parse_tree]`

  ## Examples

    iex> Exsh.parse(["a", :field_delimiter_begin, "bb", :field_delimiter_end, "ccc"])
    ["a", ["bb"], "ccc"]
    iex> Exsh.parse("a", [], [:field_delimiter_begin, "bb", :field_delimiter_end, "ccc"])
    ["a", ["bb"], "ccc"]
    iex> Exsh.parse(["a", :field_delimiter_begin, "bb", :field_delimiter_begin, "ccc", "d", :field_delimiter_end, \
    "e", :field_delimiter_end, "|", "f", "|", "g", :field_delimiter_begin, "h", :field_delimiter_begin, "i", \
    :field_delimiter_end, "j", "k", :field_delimiter_end])
    ["a", ["bb", ["ccc", "d"], "e"], "|", "f", "|", "g", ["h", ["i"], "j", "k"]]

  """
  def parse(raw_tokens) do
    [raw_tokens_head | raw_tokens_tail] = raw_tokens
    parse(raw_tokens_head, [], raw_tokens_tail)
  end
  def parse(current_token, pending_tokens, []) do
    parse_next(current_token, pending_tokens)
  end
  def parse(current_token, pending_tokens, unmerged_tokens) do
    pending_tokens = parse_next(current_token, pending_tokens)
    [unmerged_tokens_head | unmerged_tokens_tail] = unmerged_tokens
    parse(unmerged_tokens_head, pending_tokens, unmerged_tokens_tail)
  end
  @doc """
  Add the `current_token` to the `stack` or, if `current_token` is an end delimiter,
  create a group (new list) between here and the last begin delimiter and then add the group to the stack

  Returns `[stack]`

  ## Examples

    iex> Exsh.parse_next(:field_delimiter_end, ["a", :field_delimiter_begin, "b"])
    ["a", ["b"]]
    iex> Exsh.parse_next("b", ["a"])
    ["a", "b"]

  """
  def parse_next(current_token, stack) do
    case current_token do
      :field_delimiter_end -> group_tokens(stack)
      _ -> stack ++ [current_token]
    end
  end

  @doc """
  Create a group of tokens from the `stack`

  Pop elements off of the stack until a begin delimiter is found,
  place those elements into a list,
  and push the list onto the stack

  Returns `[stack]`

  ## Examples

    iex> Exsh.group_tokens(["a", :field_delimiter_begin, "b"])
    ["a", ["b"]]
    iex> Exsh.group_tokens(["a", "b"])
    ["a", "b"]

  """
  def group_tokens(stack) do
    group_tokens(stack, [])
  end
  def group_tokens([], poped) do
    poped
  end
  def group_tokens(stack, poped) do
    {stack, poped} = find_delimiter(stack, poped)
    group_tokens(stack, poped)
  end
  def find_delimiter(stack, poped) do
    stack_last = Enum.slice(stack, -1..-1)
    stack_fore = Enum.slice(stack, 0..-2)
    case stack_last do
      [:field_delimiter_begin] -> {[], stack_fore ++ [poped]}
      _ -> {stack_fore, stack_last ++ poped}
    end
  end



  def evaluate(parse_tree, symbol_table) do
    build_command(parse_tree, symbol_table, "")
  end

  def build_command([], _, command) do
    command
  end
  def build_command(parse_tree, symbol_table, command) do
    [token | remaining_tokens] = parse_tree
    new_command = expand_token(token, symbol_table)
    if command == "" do
      build_command(remaining_tokens, symbol_table, new_command)
    else
      build_command(remaining_tokens, symbol_table, "#{command} #{new_command}")
    end
  end
  def expand_token(token, symbol_table) do
    if is_list(token) do
      "(#{build_command(token, symbol_table, "")})"
    else
      symbol_table_lookup(token, symbol_table)
    end
  end
  def symbol_table_lookup(token, symbol_table) do
    if symbol_table[token] do
      symbol_table[token]
    else
      token
    end
  end

end
