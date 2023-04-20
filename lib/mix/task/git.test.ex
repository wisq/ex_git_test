defmodule Mix.Tasks.Git.Test do
  @shortdoc "Run `mix test` using current git staged changes"
  @moduledoc """
  Runs `mix test` on the latest git commit, plus any staged changes.

  Performs the following steps:

    1. Creates a temporary directory (in the standard system location).

    2. Runs `git diff --cached` (in the local tree) to extract staged changes.

    3. Clones the local tree into the temporary directory.

    4. Applies the changes extracted in step 2.

    5. Symlinks dependencies from the local `deps` to the cloned `deps`.
      * This avoids needing to recompile dependencies, which aren't part of the check-in anyway.

    6. Runs `mix test`, capturing the output (both stdout and stderr).
      * If it passes, great!
      * If it fails, dumps the captured output and exits with a non-zero status.

    7. Cleans up the temporary directory on exit.

  This is intended to be used as part of a pre-commit hook, to help protect
  against forgetting to add new files, doing partial commits where some
  committed changes depend on changes not staged for commit, etc.

  See the `git.test.install` task for details on installing the hook.
  """

  use Mix.Task

  def run([]), do: git_test()

  def run(_) do
    Mix.raise("git.test does not accept arguments")
  end

  defp git_test do
    cwd = File.cwd!()
    tmpdir = create_tmpdir()

    status("Getting local changes ...")
    diff_file = Path.join(tmpdir, "apply.patch")
    quiet_cmd("sh", ["-c", "git diff --cached --binary > \"#{diff_file}\""])

    status("Cloning tree ...")
    tree = Path.join(tmpdir, "tree")
    quiet_cmd("git", ["clone", cwd, tree])

    if (size = File.stat!(diff_file).size) > 0 do
      status("Applying changes (#{size} bytes) ...")
      quiet_cmd("git", ["apply", "../apply.patch"], cd: tree)
    end

    deps = ["deps" | dependency_build_dirs()]
    status("Linking #{Enum.count(deps)} dependencies ...")
    deps |> Enum.each(&symlink(&1, cwd, tree))

    status("Running tests ...")

    System.cmd("sh", ["-c", "exec 2>&1; MIX_ENV=test exec mix test --color"],
      cd: tree,
      into: IO.stream(:stdio, :line)
    )
    |> check_cmd_result("mix test")

    status("All tests passed.")
  end

  defp status(text) do
    IO.puts([IO.ANSI.light_green(), "* ", text, IO.ANSI.reset()])
  end

  defp create_tmpdir do
    {:ok, _started} = Application.ensure_all_started(:briefly)
    {:ok, tmpdir} = Briefly.create(directory: true)
    tmpdir
  end

  defp symlink(item, from, to) do
    source = Path.join(from, item)
    target = Path.join(to, item)

    Path.dirname(target) |> File.mkdir_p!()
    File.ln_s!(source, target)
  end

  defp dependency_build_dirs do
    lib = Path.join(Mix.Project.build_path(), "lib")

    lib
    |> File.ls!()
    |> Enum.map(&Path.join(lib, &1))
    |> Enum.filter(&File.dir?/1)
    |> List.delete(Mix.Project.app_path())
    |> Enum.map(&Path.relative_to_cwd/1)
  end

  defp quiet_cmd(bin, args, opts \\ []) do
    opts = Keyword.merge([stderr_to_stdout: true], opts)

    System.cmd(bin, args, opts)
    |> check_cmd_result([bin | args] |> Enum.join(" "))
  end

  defp check_cmd_result({_output, 0}, _cmd), do: :ok

  defp check_cmd_result({%IO.Stream{}, code}, cmd) do
    Mix.raise("Command #{inspect(cmd)} exited with status #{code}")
  end

  defp check_cmd_result({output, code}, cmd) do
    IO.puts([
      IO.ANSI.light_red(),
      "---OUTPUT---\n",
      output |> String.trim(),
      "\n---OUTPUT---",
      IO.ANSI.reset()
    ])

    Mix.raise("Command #{inspect(cmd)} exited with status #{code}")
  end
end
