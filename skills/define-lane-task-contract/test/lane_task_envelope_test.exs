ExUnit.start()

# lane_task_envelope.exs exits 2 when its own CLI sees zero or surplus
# operands. Suppress that guard while requiring it as a library; the
# subprocess tests below start a fresh `elixir` process, so this
# BEAM-application-env flag never reaches them.
Application.put_env(:lane_task_contract, :cli_suppressed, true)
Code.require_file(Path.join([__DIR__, "..", "scripts", "lane_task_envelope.exs"]))

defmodule LaneTaskEnvelopeTest do
  use ExUnit.Case, async: true

  @fixture Path.join([__DIR__, "..", "examples", "task-envelope.json"])
  @valid JSON.decode!(File.read!(@fixture))

  defp errors(envelope) do
    case LaneTaskEnvelope.validate(envelope) do
      :ok -> []
      {:error, errors} -> errors
    end
  end

  test "accepts the shipped example envelope" do
    assert :ok == LaneTaskEnvelope.validate(@valid)
  end

  describe "the CLI entry point (subprocess)" do
    @envelope_script Path.join([__DIR__, "..", "scripts", "lane_task_envelope.exs"])

    test "exits 2 with zero operands" do
      {output, exit_code} = System.cmd("elixir", [@envelope_script], stderr_to_stdout: true)
      assert exit_code == 2
      assert output =~ "usage:"
    end

    test "exits 2 with surplus operands" do
      {output, exit_code} =
        System.cmd("elixir", [@envelope_script, @fixture, "extra-operand"],
          stderr_to_stdout: true
        )

      assert exit_code == 2
      assert output =~ "usage:"
    end

    test "exits 0 and prints valid with exactly one operand" do
      # A real envelope pointing at this repository's actual worktree and
      # branch would make this assertion depend on this repository's live
      # merge base with main — genuinely different before and after this
      # branch is integrated (merge-base(branch, main) becomes the
      # branch's own tip once main contains it), so the exact same test
      # would start failing the moment integration lands, for no reason
      # related to the CLI itself. An isolated temporary repository with a
      # merge base computed fresh, right here, is deterministic regardless
      # of this repository's own history.
      repo = init_temp_repo()
      envelope = temp_repo_envelope(repo, repo.merge_base)
      path = write_temp_envelope(envelope)

      {output, exit_code} = System.cmd("elixir", [@envelope_script, path], stderr_to_stdout: true)
      assert exit_code == 0
      assert output =~ "valid"
    end
  end

  describe "the CLI entry point also runs the live integration-head check (temporary repository)" do
    @envelope_script Path.join([__DIR__, "..", "scripts", "lane_task_envelope.exs"])

    # git! raises with the full output on any non-zero exit, so a broken
    # fixture fails loudly with a diagnosable message instead of a bare
    # MatchError. env is System.cmd's :env option, passed straight
    # through: absent (the default) it is pure inheritance, identical to
    # the previous behavior; the hostile-git-config test below is the only
    # caller that supplies one, and only for that one call chain.
    defp git!(dir, args, env) do
      case System.cmd("git", args, cd: dir, env: env, stderr_to_stdout: true) do
        {output, 0} -> output
        {output, status} -> raise "git #{Enum.join(args, " ")} failed (#{status}): #{output}"
      end
    end

    defp git_add_and_commit!(dir, file, message, env) do
      git!(dir, ["add", file], env)
      git!(dir, ["commit", "-q", "-m", message], env)
    end

    defp init_temp_repo(env \\ []) do
      dir =
        Path.join(
          System.tmp_dir!(),
          "lane-task-contract-cli-repo-#{System.unique_integer([:positive])}"
        )

      # System.unique_integer/1 resets per BEAM VM launch, so a name built
      # from it alone can collide with a directory a previous `elixir
      # test.exs` invocation left behind (this test does not otherwise run
      # inside a fixture that cleans itself up between separate process
      # launches). rm_rf before use guarantees a fresh repo regardless;
      # on_exit removes it again so these don't accumulate across runs.
      File.rm_rf!(dir)
      File.mkdir_p!(dir)
      ExUnit.Callbacks.on_exit(fn -> File.rm_rf!(dir) end)

      git!(dir, ["init", "-q"], env)

      # Hardens every commit this fixture makes against a developer's own
      # global git configuration — commit.gpgSign (which can prompt or
      # fail depending on what's configured), core.hooksPath, and any
      # hook `git init` just copied in from init.templateDir — regardless
      # of what env does or doesn't override. Local repo config always
      # wins over global/system config, so this neutralizes all three
      # vectors even when env is the default (real ambient config) and
      # not just under the hostile-config test above. An empty,
      # fixture-owned hooks directory is not merely "no hooks configured"
      # (which would still fall back to whatever a hostile init.templateDir
      # copied into .git/hooks/) — core.hooksPath overrides that fallback
      # outright, so nothing in .git/hooks/ can run either.
      fixture_hooks_dir = Path.join(dir, ".fixture-empty-hooks")
      File.mkdir_p!(fixture_hooks_dir)
      git!(dir, ["config", "commit.gpgSign", "false"], env)
      git!(dir, ["config", "core.hooksPath", fixture_hooks_dir], env)

      git!(dir, ["config", "user.email", "test@example.com"], env)
      git!(dir, ["config", "user.name", "Test"], env)

      File.write!(Path.join(dir, "seed.txt"), "seed\n")
      git_add_and_commit!(dir, "seed.txt", "seed", env)

      main_branch = dir |> git!(["branch", "--show-current"], env) |> String.trim()
      work_branch = "feat/cx/example-work"

      git!(dir, ["checkout", "-q", "-b", work_branch], env)
      File.write!(Path.join(dir, "work.txt"), "work\n")
      git_add_and_commit!(dir, "work.txt", "work", env)

      merge_base = dir |> git!(["merge-base", work_branch, main_branch], env) |> String.trim()

      git!(dir, ["checkout", "-q", main_branch], env)
      File.write!(Path.join(dir, "trunk-advance.txt"), "advance\n")
      git_add_and_commit!(dir, "trunk-advance.txt", "trunk advances", env)
      main_head_after_advance = dir |> git!(["rev-parse", main_branch], env) |> String.trim()

      %{
        dir: dir,
        main_branch: main_branch,
        work_branch: work_branch,
        merge_base: merge_base,
        main_head_after_advance: main_head_after_advance
      }
    end

    defp temp_repo_envelope(repo, base_head) do
      @valid
      |> Map.put("worktree", repo.dir)
      |> Map.put("branch", repo.work_branch)
      |> put_in(["required_initial_state", "branch"], repo.work_branch)
      |> put_in(["integration", "target"], repo.main_branch)
      |> put_in(["integration", "base_head"], base_head)
    end

    defp write_temp_envelope(envelope) do
      path =
        Path.join(
          System.tmp_dir!(),
          "lane-task-contract-cli-envelope-#{System.unique_integer([:positive])}.json"
        )

      File.write!(path, JSON.encode!(envelope))
      ExUnit.Callbacks.on_exit(fn -> File.rm(path) end)
      path
    end

    test "rejects an unknown integration.base_head" do
      repo = init_temp_repo()
      envelope = temp_repo_envelope(repo, String.duplicate("0", 40))
      path = write_temp_envelope(envelope)

      {output, exit_code} = System.cmd("elixir", [@envelope_script, path], stderr_to_stdout: true)

      assert exit_code == 1
      assert output =~ "does not exist in the worktree"
    end

    test "rejects a stale integration.base_head that exists but is not the merge base" do
      repo = init_temp_repo()
      envelope = temp_repo_envelope(repo, repo.main_head_after_advance)
      path = write_temp_envelope(envelope)

      {output, exit_code} = System.cmd("elixir", [@envelope_script, path], stderr_to_stdout: true)

      assert exit_code == 1
      assert output =~ "does not match the merge base"
    end
  end

  describe "temporary repository commits are isolated from developer git configuration" do
    # Builds a fake "global" git configuration under a throwaway directory
    # and returns it as System.cmd :env overrides — GIT_CONFIG_GLOBAL,
    # GIT_CONFIG_SYSTEM, and HOME are process-scoped to whichever specific
    # subprocess calls receive this env list. This never writes to, reads
    # a fallback from, or otherwise touches this machine's real global or
    # system git configuration (~/.gitconfig, /etc/gitconfig): every path
    # here lives under a fresh System.tmp_dir!() directory this test owns
    # and removes on exit.
    #
    # The fake global config turns on all three vectors the review named:
    # commit.gpgSign (forces a signing attempt; gpg.program is pinned to
    # the real `false` binary so a broken/absent signing setup fails fast
    # and deterministically instead of ever blocking on an interactive
    # passphrase prompt), core.hooksPath (a hook that always rejects the
    # commit), and init.templateDir (a template whose hooks/ directory
    # `git init` copies into every new repository's .git/hooks/, so even
    # a repo that never touches core.hooksPath itself inherits a rejecting
    # hook from template copying alone).
    defp build_hostile_git_env do
      fixture_home =
        Path.join(
          System.tmp_dir!(),
          "lane-task-contract-hostile-home-#{System.unique_integer([:positive])}"
        )

      File.rm_rf!(fixture_home)
      File.mkdir_p!(fixture_home)
      ExUnit.Callbacks.on_exit(fn -> File.rm_rf!(fixture_home) end)

      hostile_hooks_dir = Path.join(fixture_home, "hostile-hooks")
      File.mkdir_p!(hostile_hooks_dir)
      write_rejecting_hook!(Path.join(hostile_hooks_dir, "pre-commit"))

      hostile_template_dir = Path.join(fixture_home, "hostile-template")
      hostile_template_hooks_dir = Path.join(hostile_template_dir, "hooks")
      File.mkdir_p!(hostile_template_hooks_dir)
      write_rejecting_hook!(Path.join(hostile_template_hooks_dir, "pre-commit"))

      global_config = Path.join(fixture_home, "gitconfig")

      File.write!(global_config, """
      [commit]
      \tgpgSign = true
      [gpg]
      \tprogram = false
      [core]
      \thooksPath = #{hostile_hooks_dir}
      [init]
      \ttemplateDir = #{hostile_template_dir}
      """)

      [
        {"GIT_CONFIG_GLOBAL", global_config},
        {"GIT_CONFIG_SYSTEM", "/dev/null"},
        {"HOME", fixture_home}
      ]
    end

    defp write_rejecting_hook!(path) do
      File.write!(path, "#!/bin/sh\nexit 1\n")
      File.chmod!(path, 0o755)
    end

    test "init_temp_repo commits succeed under a hostile global git config (gpgSign, hooksPath, template hooks)" do
      hostile_env = build_hostile_git_env()
      repo = init_temp_repo(hostile_env)

      assert File.dir?(repo.dir)
      assert repo.merge_base =~ ~r/^[0-9a-f]{40}$/
    end
  end

  describe "resolve_integration_head/1 (live git verification, not part of validate/1)" do
    # These two use an isolated temporary repository, not this repository's
    # own worktree/branch: this repository's real merge-base with main
    # moves the moment this branch is integrated (merge-base(branch, main)
    # becomes the branch's own tip once main contains it), which would
    # make a fixture built from @valid's real worktree/branch pass or fail
    # depending on integration state rather than on what this function
    # actually does. A fresh repository with a merge base computed right
    # here stays correct regardless of what happens to this branch.
    test "accepts when integration.base_head matches the real merge base in the declared worktree" do
      repo = init_temp_repo()
      envelope = temp_repo_envelope(repo, repo.merge_base)
      assert :ok == LaneTaskEnvelope.resolve_integration_head(envelope)
    end

    test "rejects when integration.base_head does not match the actual merge base" do
      repo = init_temp_repo()
      envelope = temp_repo_envelope(repo, repo.main_head_after_advance)
      assert {:error, [error]} = LaneTaskEnvelope.resolve_integration_head(envelope)
      assert error =~ "does not match the merge base"
    end

    test "rejects when integration.base_head does not exist in the worktree" do
      envelope = put_in(@valid, ["integration", "base_head"], String.duplicate("0", 40))
      assert {:error, [error]} = LaneTaskEnvelope.resolve_integration_head(envelope)
      assert error =~ "does not exist in the worktree"
    end

    test "rejects when the declared worktree does not exist" do
      envelope = Map.put(@valid, "worktree", "/nonexistent/worktree/path")
      assert {:error, [error]} = LaneTaskEnvelope.resolve_integration_head(envelope)
      assert error =~ "worktree does not exist"
    end
  end

  describe "resolve_writer_paths/1 (live, symlink-aware filesystem check; not part of validate/1)" do
    defp init_temp_worktree_with_symlink do
      worktree =
        Path.join(
          System.tmp_dir!(),
          "lane-task-contract-symlink-worktree-#{System.unique_integer([:positive])}"
        )

      outside =
        Path.join(
          System.tmp_dir!(),
          "lane-task-contract-symlink-outside-#{System.unique_integer([:positive])}"
        )

      File.rm_rf!(worktree)
      File.rm_rf!(outside)
      File.mkdir_p!(worktree)
      File.mkdir_p!(outside)
      File.write!(Path.join(outside, "secret.txt"), "secret\n")
      File.mkdir_p!(Path.join(worktree, "skills/example"))
      File.ln_s!(outside, Path.join(worktree, "escape-link"))

      ExUnit.Callbacks.on_exit(fn ->
        File.rm_rf!(worktree)
        File.rm_rf!(outside)
      end)

      %{worktree: worktree, outside: outside}
    end

    test "rejects a writer path that lexically stays inside the worktree but escapes through a symlink" do
      ctx = init_temp_worktree_with_symlink()

      envelope =
        @valid
        |> Map.put("worktree", ctx.worktree)
        |> Map.put("writers", [%{"path" => "escape-link/secret.txt", "owner" => "lane-a"}])

      # The pure, lexical validate/1 check cannot see the symlink and
      # accepts this path — that gap is exactly what resolve_writer_paths/1
      # exists to close.
      assert :ok == LaneTaskEnvelope.validate(envelope)

      assert {:error, [error]} = LaneTaskEnvelope.resolve_writer_paths(envelope)
      assert error =~ "must not escape the worktree"
    end

    test "still accepts a normal writer path with no symlink involved" do
      ctx = init_temp_worktree_with_symlink()

      envelope =
        @valid
        |> Map.put("worktree", ctx.worktree)
        |> Map.put("writers", [%{"path" => "skills/example", "owner" => "lane-a"}])

      assert :ok == LaneTaskEnvelope.resolve_writer_paths(envelope)
    end

    test "still accepts a writer path with a resolvable .. segment and no symlink" do
      ctx = init_temp_worktree_with_symlink()
      File.mkdir_p!(Path.join(ctx.worktree, "skills/other"))

      envelope =
        @valid
        |> Map.put("worktree", ctx.worktree)
        |> Map.put("writers", [%{"path" => "skills/other/../example", "owner" => "lane-a"}])

      assert :ok == LaneTaskEnvelope.resolve_writer_paths(envelope)
    end

    test "rejects when the declared worktree does not exist" do
      envelope = Map.put(@valid, "worktree", "/nonexistent/worktree/path")
      assert {:error, [error]} = LaneTaskEnvelope.resolve_writer_paths(envelope)
      assert error =~ "worktree does not exist"
    end
  end

  describe "the CLI entry point also runs the writer-path symlink check (temporary repository)" do
    @envelope_script Path.join([__DIR__, "..", "scripts", "lane_task_envelope.exs"])

    test "rejects a writer path that escapes the worktree through a symlink" do
      repo = init_temp_repo()

      outside =
        Path.join(
          System.tmp_dir!(),
          "lane-task-contract-cli-symlink-outside-#{System.unique_integer([:positive])}"
        )

      File.rm_rf!(outside)
      File.mkdir_p!(outside)
      ExUnit.Callbacks.on_exit(fn -> File.rm_rf!(outside) end)
      File.ln_s!(outside, Path.join(repo.dir, "escape-link"))

      envelope =
        repo
        |> temp_repo_envelope(repo.merge_base)
        |> Map.put("writers", [%{"path" => "escape-link/secret.txt", "owner" => "lane-a"}])

      path = write_temp_envelope(envelope)

      {output, exit_code} = System.cmd("elixir", [@envelope_script, path], stderr_to_stdout: true)

      assert exit_code == 1
      assert output =~ "must not escape the worktree"
    end
  end

  describe "digest" do
    test "is a stable sha256 digest of the envelope content" do
      digest = LaneTaskEnvelope.digest(@valid)
      assert String.starts_with?(digest, "sha256:")
      assert digest == LaneTaskEnvelope.digest(@valid)
    end

    test "changes when the envelope content changes" do
      modified = Map.put(@valid, "owner", "someone-else")
      refute LaneTaskEnvelope.digest(@valid) == LaneTaskEnvelope.digest(modified)
    end
  end

  test "rejects an envelope that is not a map" do
    assert {:error, errors} = LaneTaskEnvelope.validate("not a map")
    assert errors == ["the envelope must be a JSON object"]
  end

  test "rejects an unsupported top-level field" do
    envelope = Map.put(@valid, "extra_field", "nope")
    assert "extra_field is not a permitted envelope field" in errors(envelope)
  end

  for field <- [
        "role",
        "owner",
        "issue",
        "branch",
        "worktree",
        "parent_task",
        "parent_agent",
        "result_path",
        "notification_state",
        "graph_depth",
        "panes",
        "delegation_allowed",
        "required_initial_state",
        "integration",
        "affects_runtime",
        "feature_test_inventory_path",
        "inputs",
        "outputs",
        "observable_goal",
        "red_tests",
        "green_commands",
        "repository_gates",
        "post_integration_tests",
        "deletion_decisions",
        "stop_conditions",
        "protected_actions",
        "writers",
        "agent"
      ] do
    test "rejects a missing #{field}" do
      envelope = Map.delete(@valid, unquote(field))
      assert Enum.any?(errors(envelope), &String.starts_with?(&1, unquote(field)))
    end
  end

  test "role must be lane" do
    envelope = Map.put(@valid, "role", "coordinator")
    assert "role must be \"lane\"" in errors(envelope)
  end

  test "owner must be a non-empty string" do
    envelope = Map.put(@valid, "owner", "")
    assert "owner must be a non-empty string" in errors(envelope)
  end

  test "issue must match an ORG-123 issue key" do
    envelope = Map.put(@valid, "issue", "nak452")
    assert "issue must match an ORG-123 issue key format" in errors(envelope)
  end

  test "branch must start with an accepted Conventional Commit type prefix" do
    envelope = Map.put(@valid, "branch", "nak-452-no-prefix")

    assert "branch must start with an accepted Conventional Commit type prefix" in errors(
             envelope
           )
  end

  test "branch accepts every Conventional Commit type prefix" do
    for type <- ~w(feature feat fix docs refactor test build ci chore perf style revert) do
      branch = "#{type}/cx/nak-452-example"

      envelope =
        @valid
        |> Map.put("branch", branch)
        |> put_in(["required_initial_state", "branch"], branch)

      assert [] == errors(envelope), "expected #{type}/ branch prefix to be accepted"
    end
  end

  test "worktree must be an absolute path" do
    envelope = Map.put(@valid, "worktree", "relative/path")
    assert "worktree must be an absolute path" in errors(envelope)
  end

  test "parent_task must be a non-empty string" do
    envelope = Map.put(@valid, "parent_task", "")
    assert "parent_task must be a non-empty string" in errors(envelope)
  end

  test "parent_agent must match the herdr agent name pattern" do
    envelope = Map.put(@valid, "parent_agent", "Not Valid")

    assert "parent_agent must match the herdr agent name pattern ^[a-z][a-z0-9_-]{0,31}$" in errors(
             envelope
           )
  end

  test "result_path must be relative" do
    envelope = Map.put(@valid, "result_path", "/absolute/results.json")
    assert "result_path must be a relative path" in errors(envelope)
  end

  test "result_path must not traverse out of the worktree" do
    envelope = Map.put(@valid, "result_path", "../escape.json")
    assert "result_path must not contain a parent directory segment" in errors(envelope)
  end

  test "notification_state must be a known state" do
    envelope = Map.put(@valid, "notification_state", "sent-ish")

    assert "notification_state must be one of: pending, sent, acknowledged" in errors(
             envelope
           )
  end

  test "graph_depth must be an integer from 0 through 2" do
    envelope = Map.put(@valid, "graph_depth", 3)
    assert "graph_depth must be an integer from 0 through 2" in errors(envelope)
  end

  test "panes must be an integer from 1 through 4" do
    envelope = Map.put(@valid, "panes", 5)
    assert "panes must be an integer from 1 through 4" in errors(envelope)
  end

  test "panes rejects zero panes" do
    envelope = Map.put(@valid, "panes", 0)
    assert "panes must be an integer from 1 through 4" in errors(envelope)
  end

  describe "delegation_allowed and leaf commands" do
    test "must be a boolean" do
      envelope = Map.put(@valid, "delegation_allowed", "no")
      assert "delegation_allowed must be a boolean" in errors(envelope)
    end

    test "must be false when graph_depth is 2 (a leaf task must not delegate further)" do
      envelope =
        @valid
        |> Map.put("graph_depth", 2)
        |> Map.put("delegation_allowed", true)

      assert "delegation_allowed must be false when graph_depth is 2 (a leaf task must not delegate further)" in errors(
               envelope
             )
    end

    test "permits true when graph_depth is under the cap" do
      envelope = @valid |> Map.put("graph_depth", 1) |> Map.put("delegation_allowed", true)
      assert [] == errors(envelope)
    end

    test "rejects an attempted herdr agent start delegation when delegation_allowed is false" do
      envelope =
        @valid
        |> Map.put("delegation_allowed", false)
        |> Map.put("green_commands", [
          %{
            "command" => ["herdr", "agent", "start", "child", "--kind", "claude", "--pane", "p1"],
            "timeout_ms" => 5000
          }
        ])

      assert "green_commands[0].command must not start or delegate to another herdr agent when delegation_allowed is false" in errors(
               envelope
             )
    end

    test "rejects an attempted herdr agent prompt delegation when delegation_allowed is false" do
      envelope =
        @valid
        |> Map.put("delegation_allowed", false)
        |> Map.put("green_commands", [
          %{"command" => ["herdr", "agent", "prompt", "child", "do-work"], "timeout_ms" => 5000}
        ])

      assert "green_commands[0].command must not start or delegate to another herdr agent when delegation_allowed is false" in errors(
               envelope
             )
    end

    test "permits herdr agent start when delegation_allowed is true" do
      envelope =
        @valid
        |> Map.put("delegation_allowed", true)
        |> Map.put("green_commands", [
          %{
            "command" => ["herdr", "agent", "start", "child", "--kind", "claude", "--pane", "p1"],
            "timeout_ms" => 5000
          }
        ])

      assert [] == errors(envelope)
    end

    test "rejects a herdr agent start delegation wrapped in env" do
      envelope =
        @valid
        |> Map.put("delegation_allowed", false)
        |> Map.put("green_commands", [
          %{
            "command" => ["env", "HERDR_ENV=1", "herdr", "agent", "start", "child"],
            "timeout_ms" => 5000
          }
        ])

      assert "green_commands[0].command must not start or delegate to another herdr agent when delegation_allowed is false" in errors(
               envelope
             )
    end

    test "rejects a herdr agent start delegation wrapped in mise exec --" do
      envelope =
        @valid
        |> Map.put("delegation_allowed", false)
        |> Map.put("green_commands", [
          %{
            "command" => ["mise", "exec", "--", "herdr", "agent", "start", "child"],
            "timeout_ms" => 5000
          }
        ])

      assert "green_commands[0].command must not start or delegate to another herdr agent when delegation_allowed is false" in errors(
               envelope
             )
    end

    test "rejects a path-qualified herdr agent start delegation" do
      envelope =
        @valid
        |> Map.put("delegation_allowed", false)
        |> Map.put("green_commands", [
          %{"command" => ["/usr/local/bin/herdr", "agent", "start", "child"], "timeout_ms" => 5000}
        ])

      assert "green_commands[0].command must not start or delegate to another herdr agent when delegation_allowed is false" in errors(
               envelope
             )
    end

    test "rejects a path-qualified herdr agent start delegation wrapped in mise exec --" do
      envelope =
        @valid
        |> Map.put("delegation_allowed", false)
        |> Map.put("green_commands", [
          %{
            "command" => ["mise", "exec", "--", "/usr/local/bin/herdr", "agent", "prompt", "child", "go"],
            "timeout_ms" => 5000
          }
        ])

      assert "green_commands[0].command must not start or delegate to another herdr agent when delegation_allowed is false" in errors(
               envelope
             )
    end
  end

  describe "required_initial_state" do
    test "must include branch, clean_worktree, and base_ref" do
      envelope = Map.put(@valid, "required_initial_state", %{})

      state_errors = errors(envelope)
      assert Enum.any?(state_errors, &String.starts_with?(&1, "required_initial_state"))
    end

    test "branch must match the envelope branch" do
      envelope =
        Map.put(@valid, "required_initial_state", %{
          "branch" => "feat/cx/nak-000-other",
          "clean_worktree" => true,
          "base_ref" => "main"
        })

      assert "required_initial_state.branch must equal the envelope branch" in errors(envelope)
    end

    test "clean_worktree must be true" do
      envelope =
        Map.put(@valid, "required_initial_state", %{
          "branch" => @valid["branch"],
          "clean_worktree" => false,
          "base_ref" => "main"
        })

      assert "required_initial_state.clean_worktree must be true" in errors(envelope)
    end
  end

  test "inputs must be a non-empty list of non-empty strings" do
    envelope = Map.put(@valid, "inputs", [])
    assert "inputs must be a non-empty list of non-empty strings" in errors(envelope)
  end

  test "outputs must be a non-empty list of non-empty strings" do
    envelope = Map.put(@valid, "outputs", [""])
    assert "outputs must be a non-empty list of non-empty strings" in errors(envelope)
  end

  test "observable_goal must be a non-empty string" do
    envelope = Map.put(@valid, "observable_goal", "")
    assert "observable_goal must be a non-empty string" in errors(envelope)
  end

  test "observable_goal must be a single line" do
    envelope = Map.put(@valid, "observable_goal", "line one\nline two")
    assert "observable_goal must not contain a newline" in errors(envelope)
  end

  describe "command lists" do
    for field <- ["red_tests", "green_commands", "repository_gates", "post_integration_tests"] do
      test "#{field} must be a non-empty list" do
        envelope = Map.put(@valid, unquote(field), [])

        assert "#{unquote(field)} must be a non-empty list of command objects" in errors(
                 envelope
               )
      end

      test "#{field} rejects a shell string instead of an argv list" do
        envelope =
          Map.put(@valid, unquote(field), [
            %{"command" => "mix test", "timeout_ms" => 1000}
          ])

        assert "#{unquote(field)}[0].command must be an argv list, not a shell string" in errors(
                 envelope
               )
      end

      test "#{field} rejects shell metacharacters in an argv token" do
        envelope =
          Map.put(@valid, unquote(field), [
            %{"command" => ["mix", "test && rm -rf /"], "timeout_ms" => 1000}
          ])

        assert "#{unquote(field)}[0].command contains an argv token with unsupported characters" in errors(
                 envelope
               )
      end

      test "#{field} rejects a manual database lifecycle command" do
        envelope =
          Map.put(@valid, unquote(field), [
            %{"command" => ["dropdb", "app_dev"], "timeout_ms" => 1000}
          ])

        assert "#{unquote(field)}[0].command must not run a manual database lifecycle command" in errors(
                 envelope
               )
      end

      test "#{field} rejects a wait over 60000 ms" do
        envelope =
          Map.put(@valid, unquote(field), [
            %{"command" => ["mix", "test"], "timeout_ms" => 60_001}
          ])

        assert "#{unquote(field)}[0].timeout_ms must be an integer from 1 through 60000" in errors(
                 envelope
               )
      end

      test "#{field} rejects a manual database lifecycle command wrapped in env" do
        envelope =
          Map.put(@valid, unquote(field), [
            %{
              "command" => ["env", "DATABASE_URL=x", "dropdb", "app_dev"],
              "timeout_ms" => 1000
            }
          ])

        assert "#{unquote(field)}[0].command must not run a manual database lifecycle command" in errors(
                 envelope
               )
      end

      test "#{field} rejects a manual database lifecycle command wrapped in mise exec --" do
        envelope =
          Map.put(@valid, unquote(field), [
            %{"command" => ["mise", "exec", "--", "dropdb", "app_dev"], "timeout_ms" => 1000}
          ])

        assert "#{unquote(field)}[0].command must not run a manual database lifecycle command" in errors(
                 envelope
               )
      end

      test "#{field} rejects a manual database lifecycle command wrapped in sh -c" do
        envelope =
          Map.put(@valid, unquote(field), [
            %{"command" => ["sh", "-c", "dropdb"], "timeout_ms" => 1000}
          ])

        assert "#{unquote(field)}[0].command must not run a manual database lifecycle command" in errors(
                 envelope
               )
      end

      test "#{field} rejects a manual database lifecycle command wrapped in bash -c" do
        envelope =
          Map.put(@valid, unquote(field), [
            %{"command" => ["bash", "-c", "dropdb"], "timeout_ms" => 1000}
          ])

        assert "#{unquote(field)}[0].command must not run a manual database lifecycle command" in errors(
                 envelope
               )
      end

      test "#{field} permits an env-wrapped command that is not a database lifecycle command" do
        envelope =
          Map.put(@valid, unquote(field), [
            %{"command" => ["env", "MIX_ENV=test", "mix", "test"], "timeout_ms" => 1000}
          ])

        refute Enum.any?(errors(envelope), &String.contains?(&1, "database lifecycle"))
      end
    end
  end

  describe "repository_gates handoff cadence" do
    test "each repository gate must declare when: handoff" do
      envelope =
        Map.put(@valid, "repository_gates", [
          %{"command" => ["mise", "run", "verify:quick"], "timeout_ms" => 60_000}
        ])

      assert "repository_gates[0].when must equal \"handoff\"" in errors(envelope)
    end

    test "a repository gate must not declare a per-commit cadence" do
      envelope =
        Map.put(@valid, "repository_gates", [
          %{
            "command" => ["mise", "run", "verify:quick"],
            "timeout_ms" => 60_000,
            "when" => "every-commit"
          }
        ])

      assert "repository_gates[0].when must equal \"handoff\"" in errors(envelope)
    end
  end

  describe "integration" do
    test "must include target, base_head, and branch_lifecycle" do
      envelope = Map.put(@valid, "integration", %{})

      integration_errors = errors(envelope)
      assert Enum.any?(integration_errors, &String.starts_with?(&1, "integration"))
    end

    test "target must be a non-empty string" do
      envelope = put_in(@valid, ["integration", "target"], "")
      assert "integration.target must be a non-empty string" in errors(envelope)
    end

    test "base_head must be a full 40-character lowercase commit sha" do
      envelope = put_in(@valid, ["integration", "base_head"], "main")

      assert "integration.base_head must be a full 40-character lowercase commit sha" in errors(
               envelope
             )
    end

    test "branch_lifecycle must be short-lived" do
      envelope = put_in(@valid, ["integration", "branch_lifecycle"], "long-lived")
      assert "integration.branch_lifecycle must be \"short-lived\"" in errors(envelope)
    end

    test "rejects an unsupported integration field" do
      envelope = put_in(@valid, ["integration", "extra"], "nope")
      assert "integration.extra is not a permitted field" in errors(envelope)
    end
  end

  describe "affects_runtime and live_smoke" do
    test "affects_runtime must be a boolean" do
      envelope = Map.put(@valid, "affects_runtime", "yes")
      assert "affects_runtime must be a boolean" in errors(envelope)
    end

    test "live_smoke is required when affects_runtime is true and absent" do
      envelope = Map.put(@valid, "affects_runtime", true)
      assert "live_smoke is required when affects_runtime is true" in errors(envelope)
    end

    test "live_smoke must be absent when affects_runtime is false" do
      envelope =
        Map.put(@valid, "live_smoke", %{
          "endpoint" => %{"url" => "http://localhost:4000/health", "expect_status" => 200},
          "timeout_ms" => 5000
        })

      assert "live_smoke must be absent when affects_runtime is false" in errors(envelope)
    end

    # live_smoke.command was removed entirely, not narrowed to an
    # allow-list: an allow-list keyed on a resolved executable's basename
    # still trusted the string a lane declared. A relative path
    # (./tools/curl), an absolute path outside any trusted location
    # (/tmp/curl — world-writable on most systems), or an env-wrapped PATH
    # override (PATH=./tools) can all point "curl" at an attacker-planted
    # binary while still passing a basename check, and none of curl, wget,
    # nc, ncat, or grpc_health_probe has one absolute path that is the same
    # across this project's Linux, macOS, and Windows runners — so there is
    # no portable location to trust even for a literal, unwrapped
    # ["curl", ...]. live_smoke.endpoint carries no executable at all and
    # closes the whole class of bypass; command is simply not a permitted
    # field any more, regardless of form.
    not_permitted_message = "live_smoke.command is not a permitted field"

    for {label, command} <- [
          {"a plain, previously allow-listed probe name", ["curl", "http://localhost:4000/health"]},
          {"a relative path", ["./tools/curl", "http://localhost:4000/health"]},
          {"an untrusted absolute path", ["/tmp/curl", "http://localhost:4000/health"]},
          {"a PATH override wrapped in env",
           ["env", "PATH=./tools", "curl", "http://localhost:4000/health"]},
          {"a relative path wrapped in mise exec --",
           ["mise", "exec", "--", "./tools/curl", "http://localhost:4000/health"]},
          {"an untrusted absolute path wrapped in sh -c", ["sh", "-c", "/tmp/curl"]}
        ] do
      test "live_smoke rejects #{label} — command is not a permitted field" do
        envelope =
          @valid
          |> Map.put("affects_runtime", true)
          |> Map.put("live_smoke", %{
            "command" => unquote(command),
            "timeout_ms" => 1000
          })

        assert unquote(not_permitted_message) in errors(envelope)
      end
    end

    test "declared endpoint health contract is the only permitted live_smoke shape" do
      envelope =
        @valid
        |> Map.put("affects_runtime", true)
        |> Map.put("live_smoke", %{
          "endpoint" => %{"url" => "http://localhost:4000/health", "expect_status" => 200},
          "timeout_ms" => 5000
        })

      assert [] == errors(envelope)
    end

    test "live_smoke.endpoint is required" do
      envelope =
        @valid
        |> Map.put("affects_runtime", true)
        |> Map.put("live_smoke", %{"timeout_ms" => 5000})

      assert "live_smoke.endpoint is required" in errors(envelope)
    end

    test "live_smoke.endpoint requires a non-empty url" do
      envelope =
        @valid
        |> Map.put("affects_runtime", true)
        |> Map.put("live_smoke", %{
          "endpoint" => %{"url" => "", "expect_status" => 200},
          "timeout_ms" => 5000
        })

      assert "live_smoke.endpoint.url must be a non-empty string" in errors(envelope)
    end

    test "live_smoke.endpoint requires expect_status to be a valid HTTP status integer" do
      envelope =
        @valid
        |> Map.put("affects_runtime", true)
        |> Map.put("live_smoke", %{
          "endpoint" => %{"url" => "http://localhost:4000/health", "expect_status" => 999},
          "timeout_ms" => 5000
        })

      assert "live_smoke.endpoint.expect_status must be an integer from 100 through 599" in errors(
               envelope
             )
    end
  end

  test "feature_test_inventory_path must be a non-empty relative path" do
    envelope = Map.put(@valid, "feature_test_inventory_path", "/absolute/inventory.md")
    assert "feature_test_inventory_path must be a relative path" in errors(envelope)
  end

  describe "deletion_decisions" do
    test "an empty list is valid" do
      envelope = Map.put(@valid, "deletion_decisions", [])
      assert [] == errors(envelope)
    end

    test "must reject deletion_decisions that is not a list" do
      envelope = Map.put(@valid, "deletion_decisions", "none")
      assert "deletion_decisions must be a list of {target, replacement_decision} objects" in errors(
               envelope
             )
    end

    test "each entry must have a non-empty target and replacement_decision" do
      envelope = Map.put(@valid, "deletion_decisions", [%{"target" => "old_field.ex"}])

      assert "deletion_decisions[0] must have a non-empty target and replacement_decision" in errors(
               envelope
             )
    end
  end

  test "stop_conditions must be a non-empty list of non-empty strings" do
    envelope = Map.put(@valid, "stop_conditions", [])
    assert "stop_conditions must be a non-empty list of non-empty strings" in errors(envelope)
  end

  describe "protected_actions" do
    test "must be a non-empty list" do
      envelope = Map.put(@valid, "protected_actions", [])
      assert "protected_actions must be a non-empty list" in errors(envelope)
    end

    test "must be drawn from the protected action vocabulary" do
      envelope = Map.put(@valid, "protected_actions", ["make-coffee"])

      assert "protected_actions[0] must be one of: credential-changes, deploy, force-push, merge, production-effects, public-ingress, push, release" in errors(
               envelope
             )
    end

    test "must not repeat an action" do
      envelope = Map.put(@valid, "protected_actions", ["merge", "merge"])
      assert "protected_actions must not repeat an action" in errors(envelope)
    end
  end

  describe "writers" do
    test "rejects duplicate writer ownership of the same path" do
      envelope =
        Map.put(@valid, "writers", [
          %{"path" => "skills/define-lane-task-contract/", "owner" => "lane-a"},
          %{"path" => "skills/define-lane-task-contract/", "owner" => "lane-b"}
        ])

      assert "writers must not assign more than one owner to the same path" in errors(envelope)
    end

    test "normalizes a trailing slash before comparing paths" do
      envelope =
        Map.put(@valid, "writers", [
          %{"path" => "skills/define-lane-task-contract/", "owner" => "lane-a"},
          %{"path" => "skills/define-lane-task-contract", "owner" => "lane-b"}
        ])

      assert "writers must not assign more than one owner to the same path" in errors(envelope)
    end

    test "rejects an ancestor-descendant overlap" do
      envelope =
        Map.put(@valid, "writers", [
          %{"path" => "skills/define-lane-task-contract", "owner" => "lane-a"},
          %{"path" => "skills/define-lane-task-contract/scripts", "owner" => "lane-b"}
        ])

      assert "writers must not assign more than one owner to the same path" in errors(envelope)
    end

    test "permits disjoint sibling paths" do
      envelope =
        Map.put(@valid, "writers", [
          %{"path" => "skills/define-lane-task-contract/scripts", "owner" => "lane-a"},
          %{"path" => "skills/define-lane-task-contract/test", "owner" => "lane-b"}
        ])

      assert [] == errors(envelope)
    end

    test "canonicalizes an embedded . segment before comparing" do
      envelope =
        Map.put(@valid, "writers", [
          %{"path" => "skills/./define-lane-task-contract", "owner" => "lane-a"},
          %{"path" => "skills/define-lane-task-contract", "owner" => "lane-b"}
        ])

      assert "writers must not assign more than one owner to the same path" in errors(envelope)
    end

    test "canonicalizes a resolvable .. segment before comparing" do
      envelope =
        Map.put(@valid, "writers", [
          %{"path" => "skills/other-skill/../define-lane-task-contract", "owner" => "lane-a"},
          %{"path" => "skills/define-lane-task-contract", "owner" => "lane-b"}
        ])

      assert "writers must not assign more than one owner to the same path" in errors(envelope)
    end

    test "rejects a writer path that escapes the worktree" do
      envelope =
        Map.put(@valid, "writers", [
          %{"path" => "../../etc/passwd", "owner" => "lane-a"}
        ])

      assert "writers[0].path must not escape the worktree" in errors(envelope)
    end

    test "rejects a deeply nested writer path that escapes the worktree" do
      envelope =
        Map.put(@valid, "writers", [
          %{"path" => "skills/../../../../etc/passwd", "owner" => "lane-a"}
        ])

      assert "writers[0].path must not escape the worktree" in errors(envelope)
    end

    test "rejects an absolute writer path outside the worktree" do
      envelope =
        Map.put(@valid, "writers", [
          %{"path" => "/etc/passwd", "owner" => "lane-a"}
        ])

      assert "writers[0].path must not escape the worktree" in errors(envelope)
    end
  end

  describe "agent" do
    test "kind and mode must be non-empty strings" do
      envelope = Map.put(@valid, "agent", %{"kind" => "", "mode" => "auto"})
      assert "agent.kind must be a non-empty string" in errors(envelope)
    end

    test "a claude auto contract requires a current supported model" do
      envelope =
        put_in(@valid, ["agent", "model"], "claude-2")

      assert "agent.model must be a currently supported Claude model" in errors(envelope)
    end

    test "a claude auto contract requires permission_mode auto" do
      envelope = put_in(@valid, ["agent", "permission_mode"], "manual")
      assert "agent.permission_mode must be \"auto\"" in errors(envelope)
    end

    test "a claude auto contract requires visible startup verification" do
      envelope = put_in(@valid, ["agent", "startup_verification"], "silent")
      assert "agent.startup_verification must be \"visible\"" in errors(envelope)
    end

    test "a non-auto claude agent does not require the auto contract fields" do
      envelope =
        @valid
        |> put_in(["agent", "mode"], "supervised")
        |> Map.update!(
          "agent",
          &Map.drop(&1, ["model", "permission_mode", "startup_verification", "effort", "routing_reason"])
        )

      assert [] == errors(envelope)
    end

    # Model routing (NAK-482): model and effort are separate choices, and
    # every automated Claude or Codex lane must say which model, which
    # effort, and why. See references/model-routing.md.
    test "a claude auto contract requires an effort" do
      envelope = Map.update!(@valid, "agent", &Map.delete(&1, "effort"))
      assert "agent.effort must be one of auto, low, medium, high, xhigh, max for a Claude agent" in errors(envelope)
    end

    test "a claude auto contract rejects the Codex-only effort none" do
      envelope = put_in(@valid, ["agent", "effort"], "none")
      assert "agent.effort must be one of auto, low, medium, high, xhigh, max for a Claude agent" in errors(envelope)
    end

    for effort <- ~w(auto low medium high xhigh max) do
      test "a claude auto contract accepts effort #{effort}" do
        envelope = put_in(@valid, ["agent", "effort"], unquote(effort))
        assert [] == errors(envelope)
      end
    end

    test "a claude auto contract requires a routing_reason" do
      envelope = Map.update!(@valid, "agent", &Map.delete(&1, "routing_reason"))
      assert "agent.routing_reason must be a non-empty string after trimming whitespace" in errors(envelope)
    end

    test "a claude auto contract rejects an empty routing_reason" do
      envelope = put_in(@valid, ["agent", "routing_reason"], "")
      assert "agent.routing_reason must be a non-empty string after trimming whitespace" in errors(envelope)
    end

    for {model, effort} <- [
          {"claude-fable-5", "auto"},
          {"claude-sonnet-5", "auto"},
          {"claude-opus-5", "auto"},
          {"claude-haiku-4-5-20251001", "not-supported"}
        ] do
      test "a claude auto contract accepts the current model #{model} with effort #{effort}" do
        envelope =
          @valid
          |> put_in(["agent", "model"], unquote(model))
          |> put_in(["agent", "effort"], unquote(effort))

        assert [] == errors(envelope)
      end
    end

    # Effort sets are model-specific. Haiku 4.5 does not support effort at
    # all, so the only honest value for it is the explicit sentinel
    # "not-supported"; an ordinary effort level on Haiku is a lie the
    # runtime would silently ignore, and is rejected.
    @haiku "claude-haiku-4-5-20251001"
    @haiku_effort_error "agent.effort must be \"not-supported\" for claude-haiku-4-5-20251001, which does not support effort"

    for effort <- ~w(auto low medium high xhigh max) do
      test "a claude auto contract rejects ordinary effort #{effort} for Haiku" do
        envelope =
          @valid
          |> put_in(["agent", "model"], @haiku)
          |> put_in(["agent", "effort"], unquote(effort))

        assert @haiku_effort_error in errors(envelope)
      end
    end

    test "a claude auto contract requires an effort for Haiku too" do
      envelope =
        @valid
        |> put_in(["agent", "model"], @haiku)
        |> Map.update!("agent", &Map.delete(&1, "effort"))

      assert @haiku_effort_error in errors(envelope)
    end

    for model <- ~w(claude-fable-5 claude-sonnet-5 claude-opus-5) do
      test "a claude auto contract rejects the Haiku sentinel not-supported for #{model}" do
        envelope =
          @valid
          |> put_in(["agent", "model"], unquote(model))
          |> put_in(["agent", "effort"], "not-supported")

        assert "agent.effort must be one of auto, low, medium, high, xhigh, max for a Claude agent" in errors(envelope)
      end
    end

    test "a claude auto contract rejects a whitespace-only routing_reason" do
      envelope = put_in(@valid, ["agent", "routing_reason"], " \t\n ")
      assert "agent.routing_reason must be a non-empty string after trimming whitespace" in errors(envelope)
    end

    test "a claude auto contract accepts a routing_reason with surrounding whitespace" do
      envelope = put_in(@valid, ["agent", "routing_reason"], "  measured rework on this task shape  ")
      assert [] == errors(envelope)
    end

    @codex_auto %{
      "kind" => "codex",
      "mode" => "auto",
      "command" => ["codex", "app-server", "-c", "check_for_update_on_startup=false"],
      "model" => "gpt-5.6-terra",
      "effort" => "medium",
      "routing_reason" => "balanced default for a bounded refactor with no measured quality need"
    }

    test "an automated codex role template with model, effort, and routing_reason is accepted" do
      envelope = Map.put(@valid, "agent", @codex_auto)
      assert [] == errors(envelope)
    end

    test "an automated codex role template requires a current supported model" do
      envelope = Map.put(@valid, "agent", Map.delete(@codex_auto, "model"))
      assert "agent.model must be a currently supported Codex model" in errors(envelope)
    end

    test "an automated codex role template rejects a Claude model" do
      envelope = Map.put(@valid, "agent", Map.put(@codex_auto, "model", "claude-fable-5"))
      assert "agent.model must be a currently supported Codex model" in errors(envelope)
    end

    for model <- ~w(gpt-5.6-sol gpt-5.6-terra gpt-5.6-luna) do
      test "an automated codex role template accepts the current model #{model}" do
        envelope = Map.put(@valid, "agent", Map.put(@codex_auto, "model", unquote(model)))
        assert [] == errors(envelope)
      end
    end

    test "an automated codex role template requires an effort" do
      envelope = Map.put(@valid, "agent", Map.delete(@codex_auto, "effort"))
      assert "agent.effort must be one of none, low, medium, high, xhigh, max for a Codex agent" in errors(envelope)
    end

    test "an automated codex role template rejects the Haiku-only sentinel not-supported" do
      # The sentinel exists only for a Claude model with no effort control.
      # Every Codex model supports effort, so "not-supported" on a Codex
      # lane is a false statement and must be rejected like any other value
      # outside the Codex set.
      envelope = Map.put(@valid, "agent", Map.put(@codex_auto, "effort", "not-supported"))
      assert "agent.effort must be one of none, low, medium, high, xhigh, max for a Codex agent" in errors(envelope)
    end

    test "an automated codex role template rejects the Claude-only effort auto" do
      envelope = Map.put(@valid, "agent", Map.put(@codex_auto, "effort", "auto"))
      assert "agent.effort must be one of none, low, medium, high, xhigh, max for a Codex agent" in errors(envelope)
    end

    for effort <- ~w(none low medium high xhigh max) do
      test "an automated codex role template accepts effort #{effort}" do
        envelope = Map.put(@valid, "agent", Map.put(@codex_auto, "effort", unquote(effort)))
        assert [] == errors(envelope)
      end
    end

    test "an automated codex role template requires a routing_reason" do
      envelope = Map.put(@valid, "agent", Map.delete(@codex_auto, "routing_reason"))
      assert "agent.routing_reason must be a non-empty string after trimming whitespace" in errors(envelope)
    end

    test "an automated codex role template rejects a whitespace-only routing_reason" do
      envelope = Map.put(@valid, "agent", Map.put(@codex_auto, "routing_reason", "   "))
      assert "agent.routing_reason must be a non-empty string after trimming whitespace" in errors(envelope)
    end

    test "a non-auto codex agent does not require model, effort, or routing_reason" do
      envelope = Map.put(@valid, "agent", %{"kind" => "codex", "mode" => "supervised"})
      assert [] == errors(envelope)
    end

    # The Codex CLI's check_for_update_on_startup can pop an interactive
    # global update prompt on startup, which an unattended agent can never
    # answer. Every command that starts codex — anywhere it is validated —
    # and the role template for an automated codex agent must disable it
    # with -c check_for_update_on_startup=false.
    test "a command that starts codex without the update-prompt guard is rejected" do
      envelope =
        Map.put(@valid, "green_commands", [
          %{"command" => ["codex", "exec", "do-thing"], "timeout_ms" => 5000}
        ])

      assert "green_commands[0].command must include -c check_for_update_on_startup=false to avoid an interactive Codex update prompt" in errors(
               envelope
             )
    end

    test "a command that starts codex with the update-prompt guard is accepted" do
      envelope =
        Map.put(@valid, "green_commands", [
          %{
            "command" => [
              "codex",
              "exec",
              "-c",
              "check_for_update_on_startup=false",
              "do-thing"
            ],
            "timeout_ms" => 5000
          }
        ])

      assert [] == errors(envelope)
    end

    test "an automated codex role template requires a command" do
      envelope = Map.put(@valid, "agent", %{"kind" => "codex", "mode" => "auto"})
      assert "agent.command is required" in errors(envelope)
    end

    test "an automated codex role template requires the update-prompt guard" do
      envelope =
        Map.put(@valid, "agent", %{
          "kind" => "codex",
          "mode" => "auto",
          "command" => ["codex", "app-server"]
        })

      assert "agent.command must include -c check_for_update_on_startup=false to avoid an interactive Codex update prompt" in errors(
               envelope
             )
    end

    test "an automated codex role template with the update-prompt guard is accepted" do
      envelope =
        Map.put(@valid, "agent", %{
          "kind" => "codex",
          "mode" => "auto",
          "model" => "gpt-5.6-luna",
          "effort" => "low",
          "routing_reason" => "efficient high-volume fixture for a startup-command test",
          "command" => ["codex", "app-server", "-c", "check_for_update_on_startup=false"]
        })

      assert [] == errors(envelope)
    end

    test "an automated codex role template accepts a path-qualified codex executable" do
      envelope =
        Map.put(@valid, "agent", %{
          "kind" => "codex",
          "mode" => "auto",
          "model" => "gpt-5.6-luna",
          "effort" => "low",
          "routing_reason" => "efficient high-volume fixture for a startup-command test",
          "command" => ["/usr/local/bin/codex", "app-server", "-c", "check_for_update_on_startup=false"]
        })

      assert [] == errors(envelope)
    end

    test "an automated codex role template accepts an env-wrapped codex executable" do
      envelope =
        Map.put(@valid, "agent", %{
          "kind" => "codex",
          "mode" => "auto",
          "model" => "gpt-5.6-luna",
          "effort" => "low",
          "routing_reason" => "efficient high-volume fixture for a startup-command test",
          "command" => [
            "env",
            "CODEX_HOME=/tmp/codex",
            "codex",
            "app-server",
            "-c",
            "check_for_update_on_startup=false"
          ]
        })

      assert [] == errors(envelope)
    end

    test "an automated codex role template accepts a mise-exec---wrapped codex executable" do
      envelope =
        Map.put(@valid, "agent", %{
          "kind" => "codex",
          "mode" => "auto",
          "model" => "gpt-5.6-luna",
          "effort" => "low",
          "routing_reason" => "efficient high-volume fixture for a startup-command test",
          "command" => [
            "mise",
            "exec",
            "--",
            "codex",
            "app-server",
            "-c",
            "check_for_update_on_startup=false"
          ]
        })

      assert [] == errors(envelope)
    end

    test "an automated codex role template resolves a shell-wrapped codex executable" do
      # sh -c can only carry a single bare word as its script, so this form
      # can never also carry the two-token update-prompt guard and is
      # rejected for that separate, expected reason — but the executable
      # check specifically must still resolve "codex" here, not treat the
      # wrapper as if it named no executable at all.
      envelope =
        Map.put(@valid, "agent", %{
          "kind" => "codex",
          "mode" => "auto",
          "command" => ["sh", "-c", "codex"]
        })

      refute "agent.command must resolve to the codex executable" in errors(envelope)
    end

    # unwrap_command returns [] for a wrapper with no executable at all —
    # bare env, env with only flags, mise exec -- with nothing after it,
    # and any supported shell wrapper's -c with no script. The executable
    # check must fail closed on that empty resolution: agent.command that
    # resolves to no command at all does not start codex, and must not be
    # treated as if it did.
    for {label, command} <- [
          {"env", ["env"]},
          {"env -i", ["env", "-i"]},
          {"mise exec --", ["mise", "exec", "--"]},
          {"sh -c", ["sh", "-c"]},
          {"bash -c", ["bash", "-c"]},
          {"zsh -c", ["zsh", "-c"]},
          {"dash -c", ["dash", "-c"]},
          {"ksh -c", ["ksh", "-c"]}
        ] do
      test "an automated codex role template rejects wrapper-only agent.command with no executable (#{label})" do
        envelope =
          Map.put(@valid, "agent", %{
            "kind" => "codex",
            "mode" => "auto",
            "command" => unquote(command)
          })

        assert "agent.command must resolve to the codex executable" in errors(envelope)
      end
    end

    # agent.command satisfying the update-prompt guard was not enough on
    # its own: nothing required it to actually start codex, so it could
    # start herdr (or anything else) while still carrying the flag, and it
    # was not scanned by the leaf-delegation check that applies to every
    # other command field.
    for {label, command} <- [
          {"bare", ["herdr", "agent", "start", "child", "-c", "check_for_update_on_startup=false"]},
          {"path-qualified",
           ["/usr/local/bin/herdr", "agent", "start", "child", "-c",
            "check_for_update_on_startup=false"]},
          {"wrapped in env",
           ["env", "FOO=bar", "herdr", "agent", "start", "child", "-c",
            "check_for_update_on_startup=false"]},
          {"wrapped in mise exec --",
           ["mise", "exec", "--", "herdr", "agent", "start", "child", "-c",
            "check_for_update_on_startup=false"]}
        ] do
      test "an automated codex role template rejects agent.command that starts a different executable (#{label})" do
        envelope =
          Map.put(@valid, "agent", %{
            "kind" => "codex",
            "mode" => "auto",
            "command" => unquote(command)
          })

        assert "agent.command must resolve to the codex executable" in errors(envelope)
      end
    end

    test "an automated codex role template's agent.command is scanned by the leaf-delegation check" do
      envelope =
        @valid
        |> Map.put("delegation_allowed", false)
        |> Map.put("agent", %{
          "kind" => "codex",
          "mode" => "auto",
          "command" => ["herdr", "agent", "start", "child", "-c", "check_for_update_on_startup=false"]
        })

      assert "agent.command must not start or delegate to another herdr agent when delegation_allowed is false" in errors(
               envelope
             )
    end

    test "an automated codex role template's agent.command permits herdr agent start when delegation_allowed is true" do
      # This still fails the "must resolve to codex" check above — proving
      # the delegation scan and the executable check are independent
      # controls, neither one a substitute for the other.
      envelope =
        @valid
        |> Map.put("delegation_allowed", true)
        |> Map.put("agent", %{
          "kind" => "codex",
          "mode" => "auto",
          "command" => ["herdr", "agent", "start", "child", "-c", "check_for_update_on_startup=false"]
        })

      refute "agent.command must not start or delegate to another herdr agent when delegation_allowed is false" in errors(
               envelope
             )

      assert "agent.command must resolve to the codex executable" in errors(envelope)
    end
  end
end
