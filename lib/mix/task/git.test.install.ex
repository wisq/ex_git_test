defmodule Mix.Tasks.Git.Test.Install do
  @pre_commit_contents """
  #!/bin/sh
  MIX_ENV=test exec mix git.test
  """

  @shortdoc "Installs a git pre-commit hook that runs `mix git.test`"
  @moduledoc """
  Installs a git pre-commit hook to ensure `mix git.test` passes before allowing a commit.

  The actual contents of the hook are incredibly simple:

  ```sh
  #{@pre_commit_contents}
  ```

  The hook will be installed as `.git/hooks/pre-commit`.  If that file already
  exists, it will **not** be overwritten; instead, this task will report
  whether the existing hook appears to contain `mix git.test` or not.
  """

  use Mix.Task
  import Bitwise

  @doc false
  def run([] = _args) do
    File.cwd!()
    |> git_test_install()
  end

  def run(_) do
    Mix.raise("git.test.install does not accept arguments")
  end

  @doc false
  def git_test_install(cwd) do
    path = get_hooks_path(cwd)

    install(path, "pre-commit", @pre_commit_contents)
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
end
