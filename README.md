# ExGitTest

Automatically run `mix test` before committing.

## Clean and reliable testing

We've all had those moments where we push a commit that breaks the test suite.

Maybe you even ran the test suite first (and passed), but you added a new file and forgot to `git add` it.  Or maybe you're intentionally doing a partial commit, and you thought you got all the relevant changes, but one of them slipped through.  Or maybe you've got local `.gitignore`d files that your build accidentally relies on.

`ExGitTest` aims to solve this by (efficiently) cloning your work tree to a temporary directory, applying only the specific changes you're planning on committing, running the test suite there, and seeing if your tests pass on a "clean" build.  It's meant to be included in a git `pre-commit` hook, to automatically run every commit, and abort the commit if an error occurs.

### Decently fast (for small projects, anyway)

To keep this quick, we take one major shortcut — the cloned tree's dependencies will be symbolic links to the working tree's dependencies, to avoid recompiling them.  While this doesn't normally cause any issues, you'll want to keep this in mind if you're doing anything weird like directly editing your `deps` tree.

That said, you're still looking at however long it takes to do a full compile and run your test suite.  If you've got a massive project that takes several minutes to compile and test, you'll probably want to give this library a pass!

## Setup

First, add `ex_git_test` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_git_test, github: "wisq/ex_git_test", tag: "main", only: :test, runtime: false}
  ]
end
```

The `:only` and `:runtime` options are optional, but you only need ExGitTest in your `test` environment anyway, and it will start its own runtime dependencies as needed.

Now fetch your dependencies with `mix deps.get`, and then test things with `MIX_ENV=test mix git.test`.  Hopefully everything passes.  (If it has issues with the state of your tree, try committing your existing changes first.)

Next, set up your pre-commit hook.  See the [hooks/pre-commit](hooks/pre-commit) file for an example, or just copy it from `deps/ex_git_test/hooks/pre-commit`.  However you choose to customise your hooks, the most important thing is just to make sure you run it in `MIX_ENV=test` (it won't run otherwise), and to make sure that it passes up its exit value (hence the `exec`).
