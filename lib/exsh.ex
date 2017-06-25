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
  Parse the passed in arguments to build options and symbol maps

  Returns `{options, symbols, commands}`

  ## Examples

    iex> Exsh.parse_args(["-s", "a=a", "--symbol", "b=b", "--exit", "symbols"])
    { \
      %{ \
        exit: true, \
        help: false, \
        noise: 0, \
        nosymbols: false, \
        prompt: "\e[32m> \e[0m", \
        version: "mk II, rev 1, no 1"}, \
      %{ \
        "a" => "a", \
        "b" => "b" \
      }, \
      ["symbols"] \
    }

  """
  def parse_args(args) do
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
    {options_input, commands, _} = OptionParser.parse(args,
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
    options = Enum.into(options_input, options_default)
    symbols = symbols_from_options(options_input)

    # let's not deal with both loud and quiet everywhere
    # the noise option should be used to get verbosity
    noise = options[:loud] - options[:quiet]
    options = Map.merge(options, %{:noise => noise})

    # drop options which are no longer needed
    options = Map.drop(options, [:loud, :symbol, :quiet])

    if options[:help] do
      {Enum.into(options, [:exit, :true]), symbols, ["help"]}
    else
      {options, symbols, commands}
    end
  end

  defp symbols_from_options(options) do
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
    if elem(option, 0) == :symbol do
      [var | tail] = String.split(elem(option, 1), "=")
      [val | _] = tail
      %{var => val}
    else
      %{}
    end
  end

  defp parse_settings({options, symbols, commands}) do
    hard_coded_symbols = %{
      "alias" => "vars",
      "env" => "vars",
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
