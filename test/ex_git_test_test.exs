defmodule ExGitTestTest do
  use ExUnit.Case
  doctest ExGitTest

  test "greets the world" do
    assert ExGitTest.hello() == :world
  end
end
