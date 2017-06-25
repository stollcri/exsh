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
  def repl({options, symbols, []}) do
    repl(options, symbols, "")
  end
  def repl({options, symbols, [command_string | _]}) do
    # TODO: loop over tail of command_string list to process subsequent commands
    repl(options, symbols, command_string)
  end
  def repl(options, symbols, command_string) do
    input = read(options, command_string)
    {stdout, stderr, exitcode} = eval(options, symbols, input)
    if exitcode != -1 do
      print(options, stdout, stderr)

      if options[:exit] do
        System.halt(exitcode)
      else
        repl(options, symbols, "")
      end
    end
  end
end
