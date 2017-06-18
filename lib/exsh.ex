defmodule Exsh do
  @moduledoc """
  Documentation for Exsh.

  mix escript.build; ./exsh "x | y=aa | 'bb (ls cc) dd'||ee(ff 'alias' gg)hh" --exit
  """
  use Exsh.Repl

  def main(args) do
    args
    |> parse_args
    |> repl
  end

  defp parse_args(args) do
    options_default = %{
      :version => Application.get_env(:exsh, :version),
      :prompt => IO.ANSI.green <> "> " <> IO.ANSI.reset,
      :help => :false,
      :loud => 0,
      :noise => 0,
      :nosymbols => :false,
      :quiet => 0,
      :symbols => [],
      :exit => :false
    }
    {options_input, command_strings, _} = OptionParser.parse(args,
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
    IO.inspect options_input
    options = Enum.into(options_input, options_default)
    IO.inspect options

    # let's not deal with both loud and quiet everywhere
    # the noise option should be used to get verbosity
    noise = options[:loud] - options[:quiet]
    options = Enum.into(%{:noise => noise}, options)

    if options[:help] do
      {Enum.into(%{:exit => :true}, options), ["help"]}
    else
      {options, command_strings}
    end
  end
end
