run "defaults" {
  command = plan

  variables {
    agent_id = "test-agent-id"
  }

  assert {
    condition     = local.settings.mcpServers.coder.command == "coder"
    error_message = "settings should configure the Coder MCP server"
  }

  assert {
    condition     = contains(local.settings.mcpServers.coder.args, "--allowed-tools") && contains(local.settings.mcpServers.coder.args, "coder_report_task")
    error_message = "Coder MCP should expose coder_report_task for timeline reporting"
  }

  assert {
    condition     = local.settings.mcpServers.coder.env.CODER_MCP_APP_STATUS_SLUG == "qwen-code"
    error_message = "Coder MCP should target the default app slug"
  }

  assert {
    condition     = local.settings.mcpServers.coder.env.CODER_MCP_ALLOWED_TOOLS == "coder_report_task"
    error_message = "Coder MCP env should restrict allowed tools to coder_report_task"
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
    condition     = strcontains(local.agentapi_start_script, "--system-prompt") && strcontains(local.agentapi_start_script, "--prompt")
    error_message = "start script should support Qwen Code headless task mode"
  }

  assert {
    condition     = strcontains(var.task_system_prompt, "coder_report_task")
    error_message = "default system prompt should instruct Qwen to report timeline updates"
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
