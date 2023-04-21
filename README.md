# mix git.test

[![Hex.pm Version](https://img.shields.io/hexpm/v/ex_git_test.svg?style=flat-square)](https://hex.pm/packages/ex_git_test)

Automatically run `mix test` before committing, but **only** on your staged changes.

## Clean and reliable testing

We've all had those moments where we push a commit that breaks the test suite.

Maybe you even ran the test suite first (and passed), but you added a new file and forgot to `git add` it.  Or maybe you're intentionally doing a partial commit, and you thought you got all the relevant changes, but one of them slipped through.  Or maybe you've got local `.gitignore`d files that your build accidentally relies on.

`mix git.test` aims to solve this by (efficiently) cloning your work tree to a temporary directory, applying only the specific changes you're planning on committing, running the test suite there, and seeing if your tests pass on a "clean" build.  It's meant to be included in a git `pre-commit` hook, to automatically run every commit, and abort the commit if an error occurs.

### Decently fast (for small projects, anyway)

To keep this quick, we take one major shortcut — the cloned tree's dependencies will be symbolic links to the working tree's dependencies, to avoid recompiling them.  While this doesn't normally cause any issues, you'll want to keep this in mind if you're doing anything weird like directly editing your `deps` tree.

That said, you're still looking at however long it takes to do a full compile and run your test suite.  If you've got a massive project that takes several minutes to compile and test, you'll probably want to give this library a pass!

## Demo

![Screenshot](https://github.com/wisq/ex_git_test/blob/images/images/screenshot.png?raw=true)

## Setup

First, add `ex_git_test` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_git_test, "~> 0.1.1", only: [:dev, :test], runtime: false}
  ]
end
```

Now fetch your dependencies with `mix deps.get`, and then test things with `MIX_ENV=test mix git.test`.  Hopefully everything passes.  (If it has issues with the state of your tree, try committing your existing changes first.)

Next, run `mix git.test.install`.  This will create an executable `.git/hooks/pre-commit` file that runs `mix git.test` for you.  (This will **not** overwrite an existing pre-commit hook.  You can either move your existing hook out of the way, or just integrate `mix git.test` into your existing one.)

Feel free to customise your new hook however you want.  The most important thing is just to ensure that if `mix git.test` fails, then the hook exits with a non-zero status.  The default script uses `exec` for this, but you could also do the equivalent of `mix git.test || exit 1`.  (Make sure you test your hook by staging some changes that deliberately break the tests and seeing if git lets you commit them.)

## Documentation

Full documentation can be found at <https://hexdocs.pm/ex_git_test>.

Once installed, you can also run `mix help git.test` and `mix help git.test.install`.

## Legal stuff

Copyright © 2023, Adrian Irving-Beer.

`ex_git_test` is released under the [MIT license](https://github.com/wisq/ex_git_test/blob/main/LICENSE) and is provided with **no warranty**.
