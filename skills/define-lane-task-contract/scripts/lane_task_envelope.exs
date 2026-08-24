defmodule LaneTaskEnvelope do
  @moduledoc """
  Dependency-free validator for a lane task contract envelope.

  Uses only the Elixir standard library, including the stdlib `JSON`
  module (Elixir 1.18+), so this script has no Mix project and no
  external dependency.
  """

  @allowed_fields ~w(
    role owner issue branch worktree parent_task parent_agent result_path
    notification_state graph_depth panes delegation_allowed
    required_initial_state integration
    affects_runtime live_smoke feature_test_inventory_path inputs
    outputs observable_goal red_tests green_commands repository_gates
    post_integration_tests deletion_decisions stop_conditions
    protected_actions writers agent
  )

  @required_initial_state_fields ~w(branch clean_worktree base_ref)
  @integration_fields ~w(target base_head branch_lifecycle)
  @branch_lifecycles ~w(short-lived)
  @gate_cadences ~w(handoff)

  @notification_states ~w(pending sent acknowledged)

  @branch_type_prefixes ~w(feature feat fix docs refactor test build ci chore perf style revert)

  @issue_pattern ~r/^[A-Z]{2,10}-[0-9]+$/
  @branch_pattern ~r{^(#{Enum.join(@branch_type_prefixes, "|")})/[a-z0-9][a-z0-9/-]*$}
  @parent_agent_pattern ~r/^[a-z][a-z0-9_-]{0,31}$/
  @argv_token_pattern ~r{^[A-Za-z0-9_./:=,@-]+$}
  @sha_pattern ~r/^[0-9a-f]{40}$/

  @db_lifecycle_binaries MapSet.new(~w(
    pg_ctl pg_ctlcluster initdb createdb dropdb createuser dropuser
    mysqladmin mysqld mongod mongosh redis-server redis-cli sqlite3
  ))

  @shell_wrappers MapSet.new(~w(sh bash zsh dash ksh))

  @non_probe_binaries MapSet.new(~w(
    elixir mix python python3 pytest npm yarn node cargo go rspec jest ruby bundle
  ))

  @protected_action_vocabulary MapSet.new(~w(
    merge push force-push release deploy production-effects
    credential-changes public-ingress
  ))

  @supported_claude_models MapSet.new(~w(
    claude-fable-5 claude-opus-5 claude-sonnet-5 claude-haiku-4-5-20251001
  ))

  @command_fields ~w(red_tests green_commands repository_gates post_integration_tests)
  @gated_command_fields ~w(repository_gates)

  def supported_claude_models, do: @supported_claude_models
  def protected_action_vocabulary, do: @protected_action_vocabulary

  @doc """
  Live git verification that `integration.base_head` exists and matches
  the actual merge base of `branch` and `integration.target`, resolved in
  the declared `worktree`. This is deliberately separate from `validate/1`,
  which stays pure JSON-schema validation with no filesystem or process
  I/O: `validate/1` alone does NOT prove the envelope's integration claim
  is real, only that it is well-formed. Call this before trusting
  `integration.base_head` for anything, and never claim `validate/1` alone
  covers it.
  """
  @spec resolve_integration_head(map()) :: :ok | {:error, [String.t()]}
  def resolve_integration_head(envelope) do
    worktree = envelope["worktree"]
    branch = envelope["branch"]
    target = get_in(envelope, ["integration", "target"])
    base_head = get_in(envelope, ["integration", "base_head"])

    cond do
      not is_binary(worktree) or not File.dir?(worktree) ->
        {:error, ["worktree does not exist: #{inspect(worktree)}"]}

      not commit_exists?(worktree, base_head) ->
        {:error, ["integration.base_head #{base_head} does not exist in the worktree"]}

      true ->
        verify_merge_base(worktree, branch, target, base_head)
    end
  end

  defp commit_exists?(worktree, sha) do
    case System.cmd("git", ["-C", worktree, "cat-file", "-e", sha <> "^{commit}"],
           stderr_to_stdout: true
         ) do
      {_output, 0} -> true
      {_output, _status} -> false
    end
  end

  defp verify_merge_base(worktree, branch, target, base_head) do
    case System.cmd("git", ["-C", worktree, "merge-base", branch, target],
           stderr_to_stdout: true
         ) do
      {output, 0} ->
        actual = String.trim(output)

        if actual == base_head do
          :ok
        else
          {:error,
           [
             "integration.base_head #{base_head} does not match the merge base of #{branch} and #{target} (#{actual})"
           ]}
        end

      {output, _status} ->
        {:error,
         ["could not compute the merge base of #{branch} and #{target}: #{String.trim(output)}"]}
    end
  end

  @doc """
  A stable content digest of an envelope, for binding a notify_parent
  event to the exact coordinator-owned envelope it reports against.

  Elixir/OTP maps with at most 32 keys ("flatmaps") are stored sorted by
  key term order regardless of insertion order, so two maps with equal
  content produce byte-identical JSON here without a custom canonical
  encoder. Every object in this envelope's shape stays under that limit;
  if a future field pushes any object past 32 keys, this digest would
  need an explicit canonicalizing encoder to stay order-independent.
  """
  @spec digest(map()) :: String.t()
  def digest(envelope) do
    hash =
      envelope
      |> JSON.encode!()
      |> then(&:crypto.hash(:sha256, &1))
      |> Base.encode16(case: :lower)

    "sha256:" <> hash
  end

  @spec validate(term()) :: :ok | {:error, [String.t()]}
  def validate(envelope) when is_map(envelope) do
    errors =
      []
      |> collect(unsupported_field_errors(envelope))
      |> collect(scalar_field_errors(envelope))
      |> collect(required_initial_state_errors(envelope))
      |> collect(integration_errors(envelope))
      |> collect(affects_runtime_errors(envelope))
      |> collect(live_smoke_errors(envelope))
      |> collect(relative_path_field_errors(envelope, "feature_test_inventory_path"))
      |> collect(string_list_errors(envelope, "inputs"))
      |> collect(string_list_errors(envelope, "outputs"))
      |> collect(observable_goal_errors(envelope))
      |> collect(command_list_errors(envelope))
      |> collect(delegation_allowed_errors(envelope))
      |> collect(delegation_command_errors(envelope))
      |> collect(deletion_decision_errors(envelope))
      |> collect(string_list_errors(envelope, "stop_conditions"))
      |> collect(protected_action_errors(envelope))
      |> collect(writer_errors(envelope))
      |> collect(agent_errors(envelope))

    case errors do
      [] -> :ok
      errors -> {:error, errors}
    end
  end

  def validate(_not_a_map), do: {:error, ["the envelope must be a JSON object"]}

  defp collect(errors, more), do: errors ++ more

  defp unsupported_field_errors(envelope) do
    for key <- Map.keys(envelope), key not in @allowed_fields do
      "#{key} is not a permitted envelope field"
    end
  end

  defp scalar_field_errors(envelope) do
    []
    |> collect(missing(envelope, "role"))
    |> collect(if Map.has_key?(envelope, "role") and envelope["role"] != "lane" do
      ["role must be \"lane\""]
    else
      []
    end)
    |> collect(non_empty_string_field(envelope, "owner"))
    |> collect(issue_errors(envelope))
    |> collect(branch_errors(envelope))
    |> collect(worktree_errors(envelope))
    |> collect(non_empty_string_field(envelope, "parent_task"))
    |> collect(parent_agent_errors(envelope))
    |> collect(result_path_errors(envelope))
    |> collect(notification_state_errors(envelope))
    |> collect(integer_range_field(envelope, "graph_depth", 0, 2))
    |> collect(integer_range_field(envelope, "panes", 1, 4))
  end

  defp missing(envelope, field) do
    if Map.has_key?(envelope, field), do: [], else: ["#{field} is required"]
  end

  defp non_empty_string_field(envelope, field) do
    case Map.fetch(envelope, field) do
      :error -> ["#{field} is required"]
      {:ok, value} when is_binary(value) and value != "" -> []
      {:ok, _value} -> ["#{field} must be a non-empty string"]
    end
  end

  defp integer_range_field(envelope, field, minimum, maximum) do
    case Map.fetch(envelope, field) do
      :error ->
        ["#{field} is required"]

      {:ok, value} when is_integer(value) and value >= minimum and value <= maximum ->
        []

      {:ok, _value} ->
        ["#{field} must be an integer from #{minimum} through #{maximum}"]
    end
  end

  defp issue_errors(envelope) do
    case Map.fetch(envelope, "issue") do
      :error -> ["issue is required"]
      {:ok, value} when is_binary(value) -> issue_pattern_errors(value)
      {:ok, _value} -> ["issue must match an ORG-123 issue key format"]
    end
  end

  defp issue_pattern_errors(value) do
    if Regex.match?(@issue_pattern, value) do
      []
    else
      ["issue must match an ORG-123 issue key format"]
    end
  end

  defp branch_errors(envelope) do
    case Map.fetch(envelope, "branch") do
      :error -> ["branch is required"]
      {:ok, value} when is_binary(value) -> branch_pattern_errors(value)
      {:ok, _value} -> ["branch must start with an accepted Conventional Commit type prefix"]
    end
  end

  defp branch_pattern_errors(value) do
    if Regex.match?(@branch_pattern, value) do
      []
    else
      ["branch must start with an accepted Conventional Commit type prefix"]
    end
  end

  defp worktree_errors(envelope) do
    case Map.fetch(envelope, "worktree") do
      :error -> ["worktree is required"]
      {:ok, value} when is_binary(value) -> worktree_path_errors(value)
      {:ok, _value} -> ["worktree must be an absolute path"]
    end
  end

  defp worktree_path_errors(value) do
    if String.starts_with?(value, "/") and value != "" do
      []
    else
      ["worktree must be an absolute path"]
    end
  end

  defp parent_agent_errors(envelope) do
    case Map.fetch(envelope, "parent_agent") do
      :error ->
        ["parent_agent is required"]

      {:ok, value} when is_binary(value) ->
        if Regex.match?(@parent_agent_pattern, value) do
          []
        else
          [
            "parent_agent must match the herdr agent name pattern ^[a-z][a-z0-9_-]{0,31}$"
          ]
        end

      {:ok, _value} ->
        ["parent_agent must match the herdr agent name pattern ^[a-z][a-z0-9_-]{0,31}$"]
    end
  end

  defp result_path_errors(envelope), do: relative_path_field_errors(envelope, "result_path")

  defp relative_path_field_errors(envelope, field) do
    case Map.fetch(envelope, field) do
      :error ->
        ["#{field} is required"]

      {:ok, value} when is_binary(value) and value != "" ->
        cond do
          String.starts_with?(value, "/") -> ["#{field} must be a relative path"]
          ".." in Path.split(value) -> ["#{field} must not contain a parent directory segment"]
          true -> []
        end

      {:ok, _value} ->
        ["#{field} must be a non-empty string"]
    end
  end

  defp notification_state_errors(envelope) do
    case Map.fetch(envelope, "notification_state") do
      :error ->
        ["notification_state is required"]

      {:ok, value} when value in @notification_states ->
        []

      {:ok, _value} ->
        ["notification_state must be one of: #{Enum.join(@notification_states, ", ")}"]
    end
  end

  defp required_initial_state_errors(envelope) do
    case Map.fetch(envelope, "required_initial_state") do
      :error ->
        ["required_initial_state is required"]

      {:ok, state} when is_map(state) ->
        required_initial_state_map_errors(state, envelope["branch"])

      {:ok, _value} ->
        ["required_initial_state must be a JSON object"]
    end
  end

  defp required_initial_state_map_errors(state, branch) do
    []
    |> collect(
      for key <- Map.keys(state), key not in @required_initial_state_fields do
        "required_initial_state.#{key} is not a permitted field"
      end
    )
    |> collect(
      for field <- @required_initial_state_fields, not Map.has_key?(state, field) do
        "required_initial_state.#{field} is required"
      end
    )
    |> collect(required_initial_state_branch_errors(state, branch))
    |> collect(required_initial_state_clean_worktree_errors(state))
    |> collect(required_initial_state_base_ref_errors(state))
  end

  defp required_initial_state_branch_errors(state, branch) do
    case Map.fetch(state, "branch") do
      {:ok, value} when is_binary(value) and value == branch ->
        []

      {:ok, _mismatch} ->
        ["required_initial_state.branch must equal the envelope branch"]

      :error ->
        []
    end
  end

  defp required_initial_state_clean_worktree_errors(state) do
    case Map.fetch(state, "clean_worktree") do
      {:ok, true} -> []
      {:ok, _other} -> ["required_initial_state.clean_worktree must be true"]
      :error -> []
    end
  end

  defp required_initial_state_base_ref_errors(state) do
    case Map.fetch(state, "base_ref") do
      {:ok, value} when is_binary(value) and value != "" -> []
      {:ok, _other} -> ["required_initial_state.base_ref must be a non-empty string"]
      :error -> []
    end
  end

  defp integration_errors(envelope) do
    case Map.fetch(envelope, "integration") do
      :error ->
        ["integration is required"]

      {:ok, integration} when is_map(integration) ->
        integration_map_errors(integration)

      {:ok, _value} ->
        ["integration must be a JSON object"]
    end
  end

  defp integration_map_errors(integration) do
    []
    |> collect(
      for key <- Map.keys(integration), key not in @integration_fields do
        "integration.#{key} is not a permitted field"
      end
    )
    |> collect(
      for field <- @integration_fields, not Map.has_key?(integration, field) do
        "integration.#{field} is required"
      end
    )
    |> collect(integration_target_errors(integration))
    |> collect(integration_base_head_errors(integration))
    |> collect(integration_branch_lifecycle_errors(integration))
  end

  defp integration_target_errors(integration) do
    case Map.fetch(integration, "target") do
      {:ok, value} when is_binary(value) and value != "" -> []
      {:ok, _value} -> ["integration.target must be a non-empty string"]
      :error -> []
    end
  end

  defp integration_base_head_errors(integration) do
    case Map.fetch(integration, "base_head") do
      {:ok, value} when is_binary(value) ->
        if Regex.match?(@sha_pattern, value) do
          []
        else
          ["integration.base_head must be a full 40-character lowercase commit sha"]
        end

      {:ok, _value} ->
        ["integration.base_head must be a full 40-character lowercase commit sha"]

      :error ->
        []
    end
  end

  defp integration_branch_lifecycle_errors(integration) do
    case Map.fetch(integration, "branch_lifecycle") do
      {:ok, value} when value in @branch_lifecycles -> []
      {:ok, _value} -> ["integration.branch_lifecycle must be \"short-lived\""]
      :error -> []
    end
  end

  defp affects_runtime_errors(envelope) do
    case Map.fetch(envelope, "affects_runtime") do
      :error -> ["affects_runtime is required"]
      {:ok, value} when is_boolean(value) -> []
      {:ok, _value} -> ["affects_runtime must be a boolean"]
    end
  end

  defp live_smoke_errors(envelope) do
    affects_runtime = Map.get(envelope, "affects_runtime")
    has_live_smoke = Map.has_key?(envelope, "live_smoke")

    cond do
      affects_runtime == true and not has_live_smoke ->
        ["live_smoke is required when affects_runtime is true"]

      affects_runtime == true and has_live_smoke ->
        live_smoke = Map.get(envelope, "live_smoke")

        command_object_errors_with_prefix("live_smoke", live_smoke) ++
          live_smoke_probe_errors(live_smoke)

      affects_runtime != true and has_live_smoke ->
        ["live_smoke must be absent when affects_runtime is false"]

      true ->
        []
    end
  end

  defp live_smoke_probe_errors(%{"command" => command}) when is_list(command) and command != [] do
    case unwrap_command(command) do
      [executable | _rest] ->
        basename = executable |> Path.basename() |> String.downcase()

        cond do
          basename == "true" ->
            ["live_smoke.command must be an observable probe, not a no-op like \"true\""]

          MapSet.member?(@non_probe_binaries, basename) ->
            ["live_smoke.command must be an observable probe, not a unit-test runner"]

          true ->
            []
        end

      [] ->
        []
    end
  end

  defp live_smoke_probe_errors(_live_smoke), do: []

  defp deletion_decision_errors(envelope) do
    case Map.fetch(envelope, "deletion_decisions") do
      :error ->
        ["deletion_decisions is required"]

      {:ok, decisions} when is_list(decisions) ->
        decisions
        |> Enum.with_index()
        |> Enum.flat_map(fn {decision, index} -> deletion_decision_object_errors(index, decision) end)

      {:ok, _value} ->
        ["deletion_decisions must be a list of {target, replacement_decision} objects"]
    end
  end

  defp deletion_decision_object_errors(index, decision) when is_map(decision) do
    has_target = is_binary(Map.get(decision, "target")) and Map.get(decision, "target") != ""

    has_replacement_decision =
      is_binary(Map.get(decision, "replacement_decision")) and
        Map.get(decision, "replacement_decision") != ""

    if has_target and has_replacement_decision do
      []
    else
      ["deletion_decisions[#{index}] must have a non-empty target and replacement_decision"]
    end
  end

  defp deletion_decision_object_errors(index, _decision) do
    ["deletion_decisions[#{index}] must be an object with target and replacement_decision"]
  end

  defp string_list_errors(envelope, field) do
    case Map.fetch(envelope, field) do
      :error ->
        ["#{field} is required"]

      {:ok, list} when is_list(list) ->
        if list != [] and Enum.all?(list, &(is_binary(&1) and &1 != "")) do
          []
        else
          ["#{field} must be a non-empty list of non-empty strings"]
        end

      {:ok, _value} ->
        ["#{field} must be a non-empty list of non-empty strings"]
    end
  end

  defp observable_goal_errors(envelope) do
    case Map.fetch(envelope, "observable_goal") do
      :error ->
        ["observable_goal is required"]

      {:ok, value} when is_binary(value) and value != "" ->
        if String.contains?(value, "\n") do
          ["observable_goal must not contain a newline"]
        else
          []
        end

      {:ok, _value} ->
        ["observable_goal must be a non-empty string"]
    end
  end

  defp command_list_errors(envelope) do
    Enum.flat_map(@command_fields, fn field -> command_list_field_errors(envelope, field) end)
  end

  defp command_list_field_errors(envelope, field) do
    gated = field in @gated_command_fields

    case Map.fetch(envelope, field) do
      :error ->
        ["#{field} is required"]

      {:ok, list} when is_list(list) and list != [] ->
        list
        |> Enum.with_index()
        |> Enum.flat_map(fn {command, index} ->
          command_object_errors("#{field}[#{index}]", command, gated)
        end)

      {:ok, _value} ->
        ["#{field} must be a non-empty list of command objects"]
    end
  end

  defp command_object_errors_with_prefix(prefix, command), do: command_object_errors(prefix, command, false)

  defp command_object_errors(prefix, command, gated) when is_map(command) do
    []
    |> collect(argv_errors(prefix, Map.get(command, "command")))
    |> collect(timeout_errors(prefix, Map.get(command, "timeout_ms")))
    |> collect(if gated, do: cadence_errors(prefix, Map.get(command, "when")), else: [])
  end

  defp command_object_errors(prefix, _command, _gated) do
    ["#{prefix} must be a command object with command and timeout_ms"]
  end

  defp cadence_errors(_prefix, value) when value in @gate_cadences, do: []
  defp cadence_errors(prefix, _value), do: ["#{prefix}.when must equal \"handoff\""]

  defp argv_errors(prefix, command) when is_binary(command) do
    ["#{prefix}.command must be an argv list, not a shell string"]
  end

  defp argv_errors(prefix, command) when is_list(command) and command != [] do
    cond do
      not Enum.all?(command, &is_binary/1) ->
        ["#{prefix}.command must be an argv list of strings"]

      not Enum.all?(command, &Regex.match?(@argv_token_pattern, &1)) ->
        ["#{prefix}.command contains an argv token with unsupported characters"]

      db_lifecycle_command?(command) ->
        ["#{prefix}.command must not run a manual database lifecycle command"]

      true ->
        []
    end
  end

  defp argv_errors(prefix, _command) do
    ["#{prefix}.command must be an argv list, not a shell string"]
  end

  defp db_lifecycle_command?(command) do
    Enum.any?(command, &lifecycle_binary?/1) or
      case unwrap_command(command) do
        [executable | _rest] -> lifecycle_binary?(executable)
        [] -> false
      end
  end

  defp lifecycle_binary?(token) do
    token
    |> Path.basename()
    |> String.downcase()
    |> then(&MapSet.member?(@db_lifecycle_binaries, &1))
  end

  # Resolves through env, mise exec --, and shell -c wrappers to find the
  # command a wrapper would actually execute, so a wrapped invocation cannot
  # smuggle a manual database lifecycle command past the denylist above.
  defp unwrap_command([]), do: []

  defp unwrap_command([token | rest]) do
    base = token |> Path.basename() |> String.downcase()

    cond do
      base == "env" ->
        rest
        |> Enum.drop_while(&env_passthrough_token?/1)
        |> unwrap_command()

      base == "mise" and List.first(rest) == "exec" ->
        case Enum.drop_while(tl(rest), &(&1 != "--")) do
          ["--" | cmd] -> unwrap_command(cmd)
          [] -> []
        end

      MapSet.member?(@shell_wrappers, base) and List.first(rest) == "-c" ->
        case rest do
          [_c, script | _] -> unwrap_command(String.split(script, " ", trim: true))
          _ -> []
        end

      true ->
        [token | rest]
    end
  end

  defp env_passthrough_token?(token) do
    String.starts_with?(token, "-") or Regex.match?(~r/^[A-Za-z_][A-Za-z0-9_]*=/, token)
  end

  defp herdr_delegation_command?(command) do
    case unwrap_command(command) do
      [executable | rest] ->
        executable |> Path.basename() |> String.downcase() |> then(&(&1 == "herdr")) and
          herdr_delegation_subcommand?(rest)

      [] ->
        false
    end
  end

  defp herdr_delegation_subcommand?(["agent", action | _rest]) when action in ["start", "prompt"],
    do: true

  defp herdr_delegation_subcommand?(_rest), do: false

  defp timeout_errors(prefix, timeout_ms) when is_integer(timeout_ms) do
    if timeout_ms >= 1 and timeout_ms <= 60_000 do
      []
    else
      ["#{prefix}.timeout_ms must be an integer from 1 through 60000"]
    end
  end

  defp timeout_errors(prefix, _timeout_ms) do
    ["#{prefix}.timeout_ms must be an integer from 1 through 60000"]
  end

  defp delegation_allowed_errors(envelope) do
    case Map.fetch(envelope, "delegation_allowed") do
      :error ->
        ["delegation_allowed is required"]

      {:ok, value} when is_boolean(value) ->
        if Map.get(envelope, "graph_depth") == 2 and value != false do
          [
            "delegation_allowed must be false when graph_depth is 2 (a leaf task must not delegate further)"
          ]
        else
          []
        end

      {:ok, _value} ->
        ["delegation_allowed must be a boolean"]
    end
  end

  defp delegation_command_errors(envelope) do
    if Map.get(envelope, "delegation_allowed") == false do
      envelope
      |> all_command_entries()
      |> Enum.flat_map(fn {prefix, command} ->
        if is_list(command) and herdr_delegation_command?(command) do
          [
            "#{prefix}.command must not start or delegate to another herdr agent when delegation_allowed is false"
          ]
        else
          []
        end
      end)
    else
      []
    end
  end

  defp all_command_entries(envelope) do
    field_entries =
      Enum.flat_map(@command_fields, fn field ->
        case Map.get(envelope, field) do
          list when is_list(list) ->
            list
            |> Enum.with_index()
            |> Enum.filter(fn {command, _index} -> is_map(command) end)
            |> Enum.map(fn {command, index} -> {"#{field}[#{index}]", Map.get(command, "command")} end)

          _other ->
            []
        end
      end)

    live_smoke_entry =
      case Map.get(envelope, "live_smoke") do
        %{"command" => command} -> [{"live_smoke", command}]
        _other -> []
      end

    field_entries ++ live_smoke_entry
  end

  defp protected_action_errors(envelope) do
    case Map.fetch(envelope, "protected_actions") do
      :error ->
        ["protected_actions is required"]

      {:ok, []} ->
        ["protected_actions must be a non-empty list"]

      {:ok, actions} when is_list(actions) ->
        protected_action_list_errors(actions)

      {:ok, _value} ->
        ["protected_actions must be a non-empty list"]
    end
  end

  defp protected_action_list_errors(actions) do
    vocabulary_errors =
      actions
      |> Enum.with_index()
      |> Enum.flat_map(fn {action, index} ->
        if is_binary(action) and MapSet.member?(@protected_action_vocabulary, action) do
          []
        else
          [
            "protected_actions[#{index}] must be one of: #{@protected_action_vocabulary |> Enum.sort() |> Enum.join(", ")}"
          ]
        end
      end)

    duplicate_errors =
      if Enum.uniq(actions) == actions do
        []
      else
        ["protected_actions must not repeat an action"]
      end

    vocabulary_errors ++ duplicate_errors
  end

  defp writer_errors(envelope) do
    worktree = Map.get(envelope, "worktree")

    case Map.fetch(envelope, "writers") do
      :error ->
        ["writers is required"]

      {:ok, writers} when is_list(writers) ->
        writer_shape_errors(writers) ++ writer_path_errors(worktree, writers)

      {:ok, _value} ->
        ["writers must be a list of {path, owner} objects"]
    end
  end

  defp writer_shape_errors(writers) do
    writers
    |> Enum.with_index()
    |> Enum.flat_map(fn {writer, index} -> writer_object_errors(index, writer) end)
  end

  defp writer_object_errors(index, writer) when is_map(writer) do
    has_path = is_binary(Map.get(writer, "path")) and Map.get(writer, "path") != ""
    has_owner = is_binary(Map.get(writer, "owner")) and Map.get(writer, "owner") != ""

    if has_path and has_owner do
      []
    else
      ["writers[#{index}] must have a non-empty path and owner"]
    end
  end

  defp writer_object_errors(index, _writer) do
    ["writers[#{index}] must be an object with path and owner"]
  end

  defp writer_path_errors(worktree, writers) when is_binary(worktree) do
    resolved =
      writers
      |> Enum.with_index()
      |> Enum.filter(fn {writer, _index} -> is_map(writer) and is_binary(Map.get(writer, "path")) end)
      |> Enum.map(fn {writer, index} ->
        {index, resolve_writer_path(worktree, Map.get(writer, "path"))}
      end)

    escape_errors =
      for {index, {:error, :escape}} <- resolved do
        "writers[#{index}].path must not escape the worktree"
      end

    canonical_paths = for {_index, {:ok, path}} <- resolved, do: path

    overlapping? =
      canonical_paths
      |> unique_pairs()
      |> Enum.any?(fn {a, b} -> paths_overlap?(a, b) end)

    overlap_errors =
      if overlapping? do
        ["writers must not assign more than one owner to the same path"]
      else
        []
      end

    escape_errors ++ overlap_errors
  end

  defp writer_path_errors(_worktree, _writers), do: []

  # Resolves a writer path relative to the worktree, dropping every "."
  # and ".." segment (Path.expand/2's normal semantics) before comparing.
  # A path that resolves outside the worktree is rejected as an escape;
  # anything that resolves inside it is canonicalized to a worktree-
  # relative path for the overlap check below.
  defp resolve_writer_path(worktree, path) do
    expanded = Path.expand(path, worktree)

    cond do
      expanded == worktree -> {:ok, ""}
      String.starts_with?(expanded, worktree <> "/") -> {:ok, String.trim_leading(expanded, worktree <> "/")}
      true -> {:error, :escape}
    end
  end

  defp paths_overlap?(a, b) do
    a == b or String.starts_with?(b, a <> "/") or String.starts_with?(a, b <> "/")
  end

  defp unique_pairs(items) do
    for {a, index_a} <- Enum.with_index(items),
        {b, index_b} <- Enum.with_index(items),
        index_a < index_b,
        do: {a, b}
  end

  defp agent_errors(envelope) do
    case Map.fetch(envelope, "agent") do
      :error -> ["agent is required"]
      {:ok, agent} when is_map(agent) -> agent_map_errors(agent)
      {:ok, _value} -> ["agent must be a JSON object"]
    end
  end

  defp agent_map_errors(agent) do
    []
    |> collect(agent_string_field_errors(agent, "kind"))
    |> collect(agent_string_field_errors(agent, "mode"))
    |> collect(claude_auto_contract_errors(agent))
  end

  defp agent_string_field_errors(agent, field) do
    case Map.fetch(agent, field) do
      :error -> ["agent.#{field} is required"]
      {:ok, value} when is_binary(value) and value != "" -> []
      {:ok, _value} -> ["agent.#{field} must be a non-empty string"]
    end
  end

  defp claude_auto_contract_errors(%{"kind" => "claude", "mode" => "auto"} = agent) do
    []
    |> collect(claude_model_errors(agent))
    |> collect(claude_permission_mode_errors(agent))
    |> collect(claude_startup_verification_errors(agent))
  end

  defp claude_auto_contract_errors(_agent), do: []

  defp claude_model_errors(agent) do
    case Map.fetch(agent, "model") do
      {:ok, model} when is_binary(model) ->
        if MapSet.member?(@supported_claude_models, model) do
          []
        else
          ["agent.model must be a currently supported Claude model"]
        end

      _other ->
        ["agent.model must be a currently supported Claude model"]
    end
  end

  defp claude_permission_mode_errors(agent) do
    if Map.get(agent, "permission_mode") == "auto" do
      []
    else
      ["agent.permission_mode must be \"auto\""]
    end
  end

  defp claude_startup_verification_errors(agent) do
    if Map.get(agent, "startup_verification") == "visible" do
      []
    else
      ["agent.startup_verification must be \"visible\""]
    end
  end
end

unless Application.get_env(:lane_task_contract, :cli_suppressed, false) do
  case System.argv() do
    [path] ->
      envelope =
        path
        |> File.read!()
        |> JSON.decode!()

      case LaneTaskEnvelope.validate(envelope) do
        :ok ->
          case LaneTaskEnvelope.resolve_integration_head(envelope) do
            :ok ->
              IO.puts("lane task envelope: valid (#{path})")

            {:error, errors} ->
              Enum.each(errors, fn error -> IO.puts(:stderr, "lane task envelope: #{error}") end)
              System.halt(1)
          end

        {:error, errors} ->
          Enum.each(errors, fn error -> IO.puts(:stderr, "lane task envelope: #{error}") end)
          System.halt(1)
      end

    _other ->
      IO.puts(:stderr, "usage: elixir lane_task_envelope.exs <envelope.json>")
      System.halt(2)
  end
end
