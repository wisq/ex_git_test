defmodule ExGitTest.InstallTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO
  import Bitwise, only: [&&&: 2]

  test "creates executable .git/commit/pre-commit hook" do
    {tmpdir, _, pre_commit} = setup_hooks()

    assert out = run_task(tmpdir)
    assert out =~ IO.ANSI.light_green()
    assert out =~ "Created: #{pre_commit}"

    assert File.exists?(pre_commit)
    assert File.read!(pre_commit) =~ "mix git.test"
    assert (File.stat!(pre_commit).mode &&& 0o111) == 0o111
  end

  test "fails gracefully if hooks directory does not exist" do
    tmpdir = create_tmpdir()

    # No .git directory
    assert_raise Mix.Error, fn -> run_task(tmpdir) end

    hooks_dir = create_hooks_dir(tmpdir)
    File.rmdir!(hooks_dir)

    # No .git/hooks directory
    assert_raise Mix.Error, fn -> run_task(tmpdir) end
  end

  test "will not overwrite existing pre-commit hook" do
    {tmpdir, _, pre_commit} = setup_hooks()

    File.write!(pre_commit, "something else")

    assert out = run_task(tmpdir)
    assert out =~ IO.ANSI.light_red()
    assert out =~ "File exists: #{pre_commit}"
    assert out =~ "does not appear to run"

    assert File.read!(pre_commit) == "something else"
  end

  test "will report if hook contains `mix git.test`" do
    {tmpdir, _, pre_commit} = setup_hooks()

    File.write!(pre_commit, "something something mix git.test something")

    assert out = run_task(tmpdir)
    assert out =~ IO.ANSI.light_yellow()
    assert out =~ "File exists: #{pre_commit}"
    assert out =~ "does appear to mention"

    assert File.read!(pre_commit) == "something something mix git.test something"
  end

  test "will not touch non-regular files - symlink to existing file" do
    {tmpdir, _, pre_commit} = setup_hooks()

    File.ln_s!("existing", pre_commit)
    File.write!(pre_commit, "content")

    assert out = run_task(tmpdir)
    assert out =~ IO.ANSI.light_red()
    assert out =~ "Not a regular file: #{pre_commit}"
  end

  test "will not touch non-regular files - dangling symlink" do
    {tmpdir, _, pre_commit} = setup_hooks()

    File.ln_s!("dangling", pre_commit)

    assert out = run_task(tmpdir)
    assert out =~ IO.ANSI.light_red()
    assert out =~ "Not a regular file: #{pre_commit}"
  end

  defp setup_hooks do
    tmpdir = create_tmpdir()
    hooks_dir = create_hooks_dir(tmpdir)
    pre_commit = Path.join(hooks_dir, "pre-commit")

    {tmpdir, hooks_dir, pre_commit}
  end

  defp create_tmpdir do
    {:ok, _started} = Application.ensure_all_started(:briefly)
    {:ok, tmpdir} = Briefly.create(directory: true)
    tmpdir
  end

  defp create_hooks_dir(dir) do
    Path.join([dir, ".git"]) |> File.mkdir!()
    (hooks = Path.join([dir, ".git", "hooks"])) |> File.mkdir!()
    hooks
  end

  defp run_task(cwd) do
    capture_io(fn -> Mix.Tasks.Git.Test.Install.git_test_install(cwd) end)
  end
end
