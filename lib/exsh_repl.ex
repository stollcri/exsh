defmodule Exsh.Repl do
  use Exsh.Repl.Read
  use Exsh.Repl.Eval
  use Exsh.Repl.Print

  defmacro __using__(_) do
    quote do
      import Exsh.Repl
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
end
