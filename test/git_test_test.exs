defmodule ExGitTest.Test do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  @env_var "RUNNING_GIT_TEST_TEST"

  test "runs tests in test env, even if MIX_ENV is set" do
    case System.get_env(@env_var) do
      "1" ->
        assert Mix.env() == :test

      nil ->
        System.put_env(@env_var, "1")
        System.put_env("MIX_ENV", "dev")
        capture_io(fn -> Mix.Tasks.Git.Test.run([]) end)
    end
  end

  test "captures both stdout and stderr" do
    case System.get_env(@env_var) do
      "1" ->
        IO.puts("message to stdout")
        IO.puts(:stderr, "message to stderr")

      nil ->
        System.put_env(@env_var, "1")
        assert out = capture_io(fn -> Mix.Tasks.Git.Test.run([]) end)
        assert out =~ "message to stdout"
        assert out =~ "message to stderr"
    end
  end
end
