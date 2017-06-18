defmodule Exsh.Repl.Read do
  
  defmacro __using__(_) do
    quote do
      import Exsh.Repl.Read
    end
  end

  @doc """
  Read user input -- gather interactively or use `command_string` considering `options`

  Returns `command_string`

  ## Examples

    iex> Exsh.read(%{:prompt => "> "}, " pwd ")
    "pwd"

  """
  def read(options, command_string) do
    if command_string == "" do
      IO.gets(options[:prompt])
    else
      command_string
    end
    |> String.trim
  end

end
