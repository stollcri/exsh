defmodule Exsh.Repl.Print do
	
  defmacro __using__(_) do
    quote do
      import Exsh.Repl.Print
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
