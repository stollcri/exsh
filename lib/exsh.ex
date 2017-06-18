defmodule Exsh do
  @moduledoc """
  Documentation for Exsh.

  mix escript.build; ./exsh "x | y=aa | 'bb (ls cc) dd'||ee(ff 'alias' gg)hh" --exit
  """
  use Exsh.Repl.Read
  use Exsh.Repl.Eval

  def main(args) do
    args
    |> parse_args
    |> repl
  end

  defp parse_args(args) do
    options_default = %{
      :version => "mk II, rev 1, no 1",
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
    symbols = %{
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
    input = read(options, command_string)
    {stdout, stderr, exitcode} = eval(options, symbols, input)
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
  Print command output given in the `stdout` and `stderr` considering `options`
  """
  def print() do end
  def print(_, "", "") do end
  def print(options, stdout, stderr) do
    if stdout != "" and not options[:quiet] do
      IO.puts stdout
    end
    if stderr != "" do
      stderr = IO.ANSI.red <> stderr <> IO.ANSI.reset
      IO.puts :stderr, stderr
    end
  end

end
