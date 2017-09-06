# Exsh

## Reference

- [Write a Shell in C](https://brennan.io/2015/01/16/write-a-shell-in-c/)
- [HexDocs - Port](https://hexdocs.pm/elixir/Port.html)
- [Writing a C port that can talk directly to your Elixir system](https://github.com/knewter/complex)
- [Writing a command line application in Elixir](http://asquera.de/blog/2015-04-10/writing-a-commandline-app-in-elixir/)

### Other Elixir Things to Use

- use OptionParser to parse args
- use IO.ANSI for color
- use System.halt(code) to exit with an error code
- use ExUnit.CaptureIO to capture terminal output for testing

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `exsh` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:exsh, "~> 0.1.0"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/exsh](https://hexdocs.pm/exsh).

