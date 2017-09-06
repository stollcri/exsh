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
        -h, --help               Show this help
        -l, --loud               Show more information
        -q, --quiet              Show less information
        -s, --symbol NAME=VALUE  Assign a variable
        -x, --exit               Exit after running command
            --nosymbols          Do not use symbol table

      Built-in shell commands:
        help          Print this help
        symbols       Print symbol table
        exit          Exit the shell
    """
    |> String.trim
  end

end
