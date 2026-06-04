run "defaults" {
  command = plan

  variables {
    agent_id = "test-agent-id"
  }

  assert {
    condition     = !contains(keys(try(local.settings.mcpServers, {})), "coder")
    error_message = "settings should not configure the Coder MCP server"
  }

  assert {
    condition     = !contains(try(local.settings.permissions.allow, []), "mcp__coder__coder_report_task")
    error_message = "Qwen settings should not pre-allow coder_report_task"
  }

  assert {
    condition     = var.qwen_approval_mode == "yolo"
    error_message = "Qwen Code should default to yolo approval mode for unattended tasks"
  }

  assert {
    condition     = local.settings.modelProviders.openai[0].baseUrl == "http://host.docker.internal:11434/v1"
    error_message = "settings should use the default OpenAI-compatible base URL"
  }

  assert {
    condition     = var.agentapi_version == "v0.12.2"
    error_message = "AgentAPI should default to a version that supports state persistence"
  }

  assert {
    condition     = var.enable_state_persistence == true
    error_message = "AgentAPI state persistence should be enabled by default"
  }

  assert {
    condition     = strcontains(local.agentapi_start_script, "--approval-mode yolo") && strcontains(local.agentapi_start_script, "--prompt")
    error_message = "start script should run Qwen Code in yolo mode for headless tasks"
  }

  assert {
    condition     = !strcontains(local.agentapi_start_script, "--append-system-prompt") && !strcontains(local.agentapi_start_script, "--system-prompt")
    error_message = "start script should not inject a system prompt"
  }
}

run "custom_provider" {
  command = plan

  variables {
    agent_id             = "test-agent-id"
    qwen_model           = "qwen/qwen3-coder"
    qwen_base_url        = "https://openrouter.ai/api/v1"
    qwen_api_key_env_var = "OPENROUTER_API_KEY"
    qwen_api_key         = "test-key"
  }

  assert {
    condition     = local.settings.model.name == "qwen/qwen3-coder"
    error_message = "settings should use the configured model"
  }

  assert {
    condition     = local.settings.modelProviders.openai[0].envKey == "OPENROUTER_API_KEY"
    error_message = "settings should point at the configured API key env var"
  }
}

run "custom_settings_object" {
  command = plan

  variables {
    agent_id = "test-agent-id"
    qwen_settings = {
      model = {
        name = "custom-model"
      }
      telemetry = {
        enabled = true
      }
    }
  }

  assert {
    condition     = local.settings.model.name == "custom-model"
    error_message = "custom settings object should be used as-is"
  }

  assert {
    condition     = local.settings.telemetry.enabled == true
    error_message = "custom settings object should preserve nested values"
  }
}

run "custom_settings_json_string" {
  command = plan

  variables {
    agent_id = "test-agent-id"
    qwen_settings = jsonencode({
      model = {
        name = "json-model"
      }
      telemetry = {
        enabled = true
      }
    })
  }

  assert {
    condition     = local.settings.model.name == "json-model"
    error_message = "custom settings JSON string should be decoded before use"
  }

  assert {
    condition     = local.settings.telemetry.enabled == true
    error_message = "custom settings JSON string should preserve nested values"
  }
}

run "invalid_settings_string" {
  command = plan

  variables {
    agent_id      = "test-agent-id"
    qwen_settings = "not-json"
  }

  expect_failures = [
    var.qwen_settings,
  ]
}

run "custom_approval_mode" {
  command = plan

  variables {
    agent_id           = "test-agent-id"
    qwen_approval_mode = "auto-edit"
  }

  assert {
    condition     = strcontains(local.agentapi_start_script, "--approval-mode auto-edit")
    error_message = "start script should use the configured approval mode"
  }
}
