defmodule Mix.Tasks.Git.Test.Install do
  use Mix.Task
  import Bitwise

  @moduledoc false

  def run([]), do: git_test_install()

  def run(_) do
    Mix.raise("git.test.install does not accept arguments")
  end

  def git_test_install do
    path = get_hooks_path()

    install(path, "pre-commit", pre_commit_contents())
  end

  defp get_hooks_path do
    cwd = File.cwd!()
    hooks = [cwd, ".git", "hooks"] |> Path.join()

    cond do
      !File.exists?(hooks) ->
        Mix.raise("Path does not exist: #{hooks}")

      !File.dir?(hooks) ->
        Mix.raise("Not a directory: #{hooks}")

      true ->
        hooks
    end
  end

  defp install(hooks_path, file_name, contents) do
    path = Path.join(hooks_path, file_name)

    cond do
      !File.exists?(path) ->
        File.write!(path, contents)
        make_executable(path)
        puts(:light_green, "* Created: #{path}")

      File.lstat!(path).type != :regular ->
        puts(:light_red, "* Not a regular file: #{path}")

      File.read!(path) == contents ->
        make_executable(path)
        puts(:light_green, "* Up-to-date: #{path}")

      true ->
        puts(:light_yellow, "* Locally modified: #{path}")
    end
  end

  defp puts(colour, text) do
    ansi = apply(IO.ANSI, colour, [])
    IO.puts([ansi, text, IO.ANSI.reset()])
  end

  defp make_executable(path) do
    mode = File.stat!(path).mode

    [
      mode,
      # owner executable
      0o100,
      # group executable if group readable
      if(mode &&& 0o040, do: 0x010, else: 0),
      # other executable if other readable
      if(mode &&& 0o004, do: 0x001, else: 0)
    ]
    |> Enum.reduce(&Bitwise.|||/2)
    |> then(&File.chmod!(path, &1))
  end

  defp pre_commit_contents do
    """
    #!/bin/sh

    exec mix git.test
    """
  end
end
