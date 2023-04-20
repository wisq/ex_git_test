defmodule Mix.Tasks.Git.Test.Install do
  use Mix.Task
  import Bitwise

  @moduledoc false

  def run([]) do
    File.cwd!()
    |> git_test_install()
  end

  def run(_) do
    Mix.raise("git.test.install does not accept arguments")
  end

  def git_test_install(cwd) do
    path = get_hooks_path(cwd)

    install(path, "pre-commit", pre_commit_contents())
  end

  defp get_hooks_path(cwd) do
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

    case File.lstat(path) do
      {:error, :enoent} ->
        File.write!(path, contents)
        make_executable(path)
        puts(:light_green, "* Created: #{path}")

      {:ok, %File.Stat{type: :regular}} ->
        check_contents(path, contents)

      {:ok, %File.Stat{}} ->
        puts(:light_red, "* Not a regular file: #{path}")
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
      if(mode &&& 0o040, do: 0o010, else: 0),
      # other executable if other readable
      if(mode &&& 0o004, do: 0o001, else: 0)
    ]
    |> Enum.reduce(&Bitwise.|||/2)
    |> then(&File.chmod!(path, &1))
  end

  defp check_contents(path, expected) do
    contents = File.read!(path)
 
    cond do
      contents == expected ->
        make_executable(path)
        puts(:light_green, "* Up-to-date: #{path}")

      contents =~ "mix git.test" ->
        puts(:light_yellow, "* File exists: #{path}")

        puts(
          :light_yellow,
          "* The existing hook does appear to mention `mix git.test`, " <>
            "but this task cannot verify if it is set up correctly."
        )

      true ->
        puts(:light_red, "* File exists: #{path}")
        puts(:light_red, "* The existing hook does not appear to run `mix git.test`.")
    end
  end
 
  defp pre_commit_contents do
    """
    #!/bin/sh

    exec mix git.test
    """
  end
end
