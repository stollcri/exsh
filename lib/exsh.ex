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
      :nosymbols => false,
      :quiet => :false,
      :exit => :false
    }
    {options_input, command_strings, _} = OptionParser.parse(args,
      strict: [
        help: :boolean,
        nosymbols: :boolean,
        quiet: :boolean,
        exit: :boolean
      ],
      aliases: [
        h: :help,
        q: :quiet,
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
end
