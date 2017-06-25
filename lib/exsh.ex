defmodule Exsh do
  @moduledoc """
  Documentation for Exsh.

  mix escript.build; ./exsh "x | y=aa | 'bb (ls cc) dd'||ee(ff 'alias' gg)hh" --exit
  mix escript.build; ./exsh -s a=a --symbol b=b --exit symbols
  """
  use Exsh.Repl

  def main(args) do
    args
    |> parse_args
    |> parse_settings
    |> repl
  end

  @doc """
  Parse the command line `arguments` to build an option map, a symbol map, and a command list

  Returns `{options, symbols, commands}`
  """
  def parse_args(arguments) do
    options_default = %{
      :version => Application.get_env(:exsh, :version),
      :prompt => IO.ANSI.green <> "> " <> IO.ANSI.reset,
      :help => :false,
      :loud => 0,
      :noise => 0,
      :nosymbols => :false,
      :quiet => 0,
      :exit => :false
    }
    {options_input, commands, _} = OptionParser.parse(arguments,
      strict: [
        help: :boolean,
        loud: :count,
        quiet: :count,
        symbol: :keep,
        exit: :boolean,
        nosymbols: :boolean
      ],
      aliases: [
        h: :help,
        l: :loud,
        q: :quiet,
        s: :symbol,
        x: :exit
      ]
    )

    # set symbols and options based upon command line arguments
    options = options_from_options(options_input, options_default)
    symbols = symbols_from_options(options_input)

    if options[:help] do
      {Enum.into(options, [:exit, :true]), symbols, ["help"]}
    else
      {options, symbols, commands}
    end
  end

  @doc """
  Get application options from command line `options` or `defaults`

  Returns `{options}`

  ## Examples

    iex> Exsh.options_from_options([], %{loud: 0, quiet: 0})
    %{:noise => 0}
    iex> Exsh.options_from_options([exit: true], %{exit: false, loud: 0, quiet: 0})
    %{:exit => true, :noise => 0}
    iex> Exsh.options_from_options([symbol: "a=a", exit: true], %{exit: false, loud: 0, quiet: 0})
    %{:exit => true, :noise => 0}

  """
  def options_from_options(options, defaults) do
    # set options given command line arguments and defaults
    options = Enum.into(options, defaults)

    # let's not deal with both loud and quiet everywhere
    # the noise option should be used to get verbosity
    noise = options[:loud] - options[:quiet]
    options = Map.merge(options, %{:noise => noise})

    # drop options which are no longer needed
    options = Map.drop(options, [:loud, :symbol, :quiet])

    options
  end

  @doc """
  Get application symbols from command line `options`

  Returns `{symbols}`

  ## Examples

    iex> Exsh.symbols_from_options([symbol: "a=a"])
    %{"a" => "a"}
    iex> Exsh.symbols_from_options([symbol: "a=a", symbol: "b=b"])
    %{"a" => "a", "b" => "b"}
    iex> Exsh.symbols_from_options([quiet: 1, symbol: "a=a", symbol: "b=b", exit: true])
    %{"a" => "a", "b" => "b"}
    iex> Exsh.symbols_from_options([quiet: 1])
    %{}
    iex> Exsh.symbols_from_options([symbol: "a"])
    %{}
    iex> Exsh.symbols_from_options([symbol: "a", symbol: "b=b"])
    %{"b" => "b"}

  """
  def symbols_from_options(options) do
    symbols_from_options(options, %{})
  end
  defp symbols_from_options([], symbols) do
    symbols
  end
  defp symbols_from_options(options, symbols) do
    [option | remaining_options] = options
    new_symbol = symbol_from_option(option)
    new_symbols = Map.merge(symbols, new_symbol)
    symbols_from_options(remaining_options, new_symbols)
  end

  defp symbol_from_option(option) do
    symbol_from_option(elem(option, 0), elem(option, 1))
  end
  defp symbol_from_option(:symbol, symbol_expression) do
    [var | val_list] = String.split(symbol_expression, "=")
    symbol_from_symbol_expression(var, val_list)
  end
  defp symbol_from_option(_, _) do
    %{}
  end

  defp symbol_from_symbol_expression(_, []) do
    %{}
  end
  defp symbol_from_symbol_expression(var, val_list) do
    [val | _] = val_list
    %{var => val}
  end

  @doc """
  Adjust options and symbols based upon other settings
  (presently only adds hard coded values)

  Returns `{options, symbols, commands}`
  """
  def parse_settings({options, symbols, commands}) do
    hard_coded_symbols = %{
      "alias" => "symbols",
      "env" => "symbols",
      "l" => "/bin/ls -CF",
      "la" => "/bin/ls -AG",
      "ll" => "/bin/ls -AGhl",
      "df" => "/bin/df -h",
      "grep" => "/usr/bin/grep --color=auto",
      "egrep" => "/usr/bin/egrep --color=auto",
      "fgrep" => "/usr/bin/fgrep --color=auto",
      "dirsize" => "ls | du -chd 1 | sort"
    }
    symbols = Map.merge(hard_coded_symbols, symbols)
    {options, symbols, commands}
  end
end
