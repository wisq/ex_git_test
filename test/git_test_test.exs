defmodule ExGitTest.Test do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  test "runs tests in test env, even if MIX_ENV is set" do
    case git_test(MIX_ENV: :dev) do
      :inside ->
        assert Mix.env() == :test

      {:outside, _output} ->
        :ok
    end
  end

  test "captures both stdout and stderr" do
    case git_test() do
      :inside ->
        IO.puts("message to stdout")
        IO.puts(:stderr, "message to stderr")

      {:outside, output} ->
        assert output =~ "message to stdout"
        assert output =~ "message to stderr"
    end
  end

  @env_var "RUNNING_GIT_TEST_TESTS"
  @env_value "yes"

  defp git_test(env \\ []) do
    case System.get_env(@env_var) do
      @env_value -> :inside
      nil -> {:outside, run_git_test(env)}
    end
  end

  defp run_git_test(env) do
    try do
      System.put_env(@env_var, @env_value)
      Enum.each(env, fn {k, v} -> System.put_env("#{k}", "#{v}") end)

      capture_io(fn -> Mix.Tasks.Git.Test.run([]) end)
    after
      System.delete_env(@env_var)
      Enum.each(env, fn {k, _} -> System.delete_env("#{k}") end)
    end
  end
end
