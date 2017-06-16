defmodule Exsh do
  @moduledoc """
  Documentation for Exsh.

  mix escript.build; ./exsh "x | y=aa | 'bb (ls cc) dd'||ee(ff 'alias' gg)hh" --exit
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
        vars          Print symbol table
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
    symbol_map = %{
      "alias" => "vars",
      "env" => "vars"
    }
    input = read(options, command_string)
    {stdout, stderr, exitcode} = eval(options, symbol_map, input)
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

    iex> Exsh.eval([], [], "exit")
    {"", "", -1}

  """
  def eval(_, _, "exit") do
    {"", "", -1}
  end
  def eval(options, symbols, command_string) do
    case command_string do
      "help" -> {help_message(options), "", 0}
      "vars" -> {get_symbols_as_string(symbols), "", 0}
      _ -> eval_command(options, symbols, command_string)
    end
  end
  def eval_command(options, symbols, command_string) do
    stdout = command_string
    |> tokenize
    |> parse
    |> evaluate(symbols)
    stderr = ""
    exitcode = 0
    {stdout, stderr, exitcode}
  end
  def get_symbols_as_string(symbols) do
    get_symbols_as_list(symbols)
    |> Enum.join("\n")
  end
  def get_symbols_as_list(symbols) do
    for {key, val} <- symbols, into: [], do: "#{key} = #{val}"
  end

  @doc """
  Print command output given in the `stdout` and `stderr`
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
    # tmp = scan(raw_string, "", [], [])
    # tmp2 = tmp
    # |> Enum.join(", ")
    # IO.puts "TOKENS: #{tmp2}"
    # tmp
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
    iex> Exsh.scan("", "", ["x", "=", :field_delimiter_begin, "pwd"], ["="])
    ["x", "=", :field_delimiter_begin, "pwd", :field_delimiter_end]
    iex> Exsh.scan("", "", ["pwd", "/tmp"], [])
    ["pwd", "/tmp"]

  """
  def scan("", "", tokens, []) do
    tokens
  end
  def scan("", "", tokens, delimiters) do
    [_ | delimiters_tail] = delimiters
    scan("", "", tokens ++ [:field_delimiter_end], delimiters_tail)
  end
  def scan("", lexeme, tokens, delimiters) do
    {new_tokens, lexeme, _, prepend} = lex(lexeme, " ", [])
    tokens = prepend ++ tokens ++ new_tokens
    scan("", lexeme, tokens, delimiters)
  end
  def scan(raw_string, lexeme, tokens, delimiters) do
    # TODO: implement look-back to merge subsequent field delimiters (e.g. ["|", "|"] -> ["||"])
    character = String.slice(raw_string, 0..0)
    remainder = String.slice(raw_string, 1..-1)
    {new_tokens, lexeme, delimiters, prepend} = lex(lexeme, character, delimiters)
    tokens = prepend ++ tokens ++ new_tokens
    scan(remainder, lexeme, tokens, delimiters)
  end

  @doc """
  Create tokens from the `lexeme` (when `character` is a delimiter, while considering `delimiters`)
  
  Returns `{[tokens], "lexeme", [delimiters], [pre-pend_tokens]}`
  
  ## Examples

    iex> Exsh.lex("pwd", "'", [])
    {["pwd", :field_delimiter_begin], "", ["'"], []}
    iex> Exsh.lex("", "'", [])
    {[:field_delimiter_begin], "", ["'"], []}
    iex> Exsh.lex("pwd a", "'", ["'"])
    {["pwd a", :field_delimiter_end], "", [], []}
    iex> Exsh.lex("", "'", ["'"])
    {[:field_delimiter_end], "", [], []}
    iex> Exsh.lex("pwd", " ", [])
    {["pwd"], "", [], []}
    iex> Exsh.lex("pwd", " ", ["'"])
    {["pwd"], "", ["'"], []}
    iex> Exsh.lex("pw", "d", [])
    {[], "pwd", [], []}
    iex> Exsh.lex("", "=", [])
    {[:field_delimiter_end, "=", :field_delimiter_begin], "", ["="], [:field_delimiter_begin]}

  """
  def lex(lexeme, character, delimiters) do
    {character_category, delimiters} = categorize_character(character, delimiters)
    case character_category do
      :field_delimiter_hard when lexeme != "" ->
        {["#{lexeme}", :field_delimiter_end, character, :field_delimiter_begin], "", delimiters, [:field_delimiter_begin]}
      :field_delimiter_hard ->
        {[:field_delimiter_end, character, :field_delimiter_begin], "", delimiters, [:field_delimiter_begin]}
      :field_delimiter_begin when lexeme != "" -> {[lexeme, :field_delimiter_begin], "", delimiters, []}
      :field_delimiter_begin -> {[:field_delimiter_begin], "", delimiters, []}
      :field_delimiter_end when lexeme != "" -> {[lexeme, :field_delimiter_end], "", delimiters, []}
      :field_delimiter_end -> {[:field_delimiter_end], "", delimiters, []}
      :field_delimiter when lexeme != "" -> {[lexeme, character], "", delimiters, []}
      :field_delimiter -> {[character], "", delimiters, []}
      :word_delimiter when lexeme != "" -> {[lexeme], "", delimiters, []}
      :word_delimiter -> {[], "", delimiters, []}
      _ -> {[], "#{lexeme}#{character}", delimiters, []}
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
      :field_delimiter_hard -> {:field_delimiter_hard, [character] ++ delimiters}
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
      "|" -> :field_delimiter
      "=" -> :field_delimiter_hard
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
    [["a", ["bb"], "ccc"]]
    iex> Exsh.parse("a", [], [:field_delimiter_begin, "bb", :field_delimiter_end, "ccc"])
    ["a", ["bb"], "ccc"]
    iex> Exsh.parse(["a", :field_delimiter_begin, :field_delimiter_begin, \
    "bb", :field_delimiter_end, "ccc", :field_delimiter_end])
    [["a", [["bb"], "ccc"]]]

  """
  def parse(raw_tokens) do
    wrapped_tokens = [:field_delimiter_begin] ++ raw_tokens ++ [:field_delimiter_end]
    [raw_tokens_head | raw_tokens_tail] = wrapped_tokens
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
    # build_command(parse_tree, symbol_table, "")
    build_command(parse_tree, symbol_table, [])
    # |> Enum.join("")
    # |> process_command
  end

  def build_command([], _, command) do
    command
  end
  def build_command(parse_tree, symbol_table, command) do
    [token | remaining_tokens] = parse_tree
    new_command = expand_token(token, symbol_table)
    if command == [] do
      build_command(remaining_tokens, symbol_table, [new_command])
    else
      build_command(remaining_tokens, symbol_table, command ++ [new_command])
    end
  end
  def expand_token(token, symbol_table) do
    if is_list(token) do
      build_command(token, symbol_table, [])
      |> execute_command
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

  def execute_command(command_list) do
    [command | arguments] = command_list
    # {result, exit_code} = System.cmd(command, arguments)
    # result

    command_string = command_list
    |> Enum.join("/")
    |> String.to_char_list
    |> :os.cmd
  end

end
