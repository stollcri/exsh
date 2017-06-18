defmodule Exsh.Messages do
	
  defmacro __using__(_) do
    quote do
      import Exsh.Messages
    end
  end

  @doc """
  Display the help message

  ## Options

  - prompt -- command prompt string

  ## Examples

    Exsh.help(%{:prompt => "> "})

  """
  def help(options) do
    """
    exsh, #{options[:version]}
    https://github.com/stollcri/exsh

    exsh [options] [commands]
      options:
        -h, --help          Print this help
            --nosymbols     Do not use symbol table
        -q, --quiet         Supress standard output
        -x, --exit          Exit after running command

      Built-in shell commands:
        help          Print this help
        vars          Print symbol table
        exit          Exit the shell
    """
    |> String.trim
  end

end
