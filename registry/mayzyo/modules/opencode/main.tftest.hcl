run "defaults" {
  command = plan

  variables {
    agent_id = "test-agent-id"
  }

  assert {
    condition     = local.module_directory == "$HOME/.coder-modules/mayzyo/opencode"
    error_message = "module directory should follow the registry module data layout"
  }

  assert {
    condition     = jsondecode(local.opencode_config_json).provider.openwebui.options.baseURL == "http://openwebui.time-emoji-services/api"
    error_message = "generated config should target the default Open WebUI base URL"
  }

  assert {
    condition     = jsondecode(local.opencode_config_json).provider.openwebui.npm == "@ai-sdk/openai-compatible"
    error_message = "generated config should use the OpenAI-compatible provider package"
  }

  assert {
    condition     = jsondecode(local.opencode_config_json).small_model == "openwebui/local"
    error_message = "generated config should select the default small model"
  }

  assert {
    condition     = jsondecode(local.opencode_config_json).agent.build.model == "openwebui/deepseek-v4.1-flash"
    error_message = "generated config should map the build agent to the default model"
  }

  assert {
    condition     = jsondecode(local.opencode_config_json).agent.general.steps == 25
    error_message = "generated config should preserve agent step limits"
  }

  assert {
    condition     = length(resource.coder_env.openwebui_api_key) == 0
    error_message = "api key env var should be omitted when openwebui_api_key is empty"
  }

  assert {
    condition     = !strcontains(local.opencode_config_json, "apiKey")
    error_message = "generated config should not include an apiKey option when no key is set"
  }

  assert {
    condition     = strcontains(local.install_script, "ARG_INSTALL_OPENCODE='true'")
    error_message = "install script should install OpenCode by default"
  }

  assert {
    condition     = strcontains(local.install_script, "https://opencode.ai/install")
    error_message = "install script should use the standalone OpenCode installer (no npm required)"
  }
}

run "openwebui_api_key" {
  command = plan

  variables {
    agent_id          = "test-agent-id"
    openwebui_api_key = "test-openwebui-key"
  }

  assert {
    condition     = resource.coder_env.openwebui_api_key[0].name == "OPENWEBUI_API_KEY"
    error_message = "api key should be exposed through OPENWEBUI_API_KEY"
  }

  assert {
    condition     = jsondecode(local.opencode_config_json).provider.openwebui.options.apiKey == "{env:OPENWEBUI_API_KEY}"
    error_message = "generated config should reference the API key through env substitution"
  }

  assert {
    condition     = !strcontains(local.opencode_config_json, "test-openwebui-key")
    error_message = "generated config should not contain the API key secret"
  }
}

run "custom_config" {
  command = plan

  variables {
    agent_id = "test-agent-id"
    opencode_config = jsonencode({
      "$schema" = "https://opencode.ai/config.json"
      model     = "anthropic/claude-sonnet-4-5"
    })
  }

  assert {
    condition     = jsondecode(local.opencode_config_json).model == "anthropic/claude-sonnet-4-5"
    error_message = "custom config should be used as-is"
  }

  assert {
    condition     = !strcontains(local.opencode_config_json, "openwebui")
    error_message = "custom config should not be merged with the default Open WebUI config"
  }
}

run "install_disabled" {
  command = plan

  variables {
    agent_id         = "test-agent-id"
    install_opencode = false
  }

  assert {
    condition     = strcontains(local.install_script, "ARG_INSTALL_OPENCODE='false'")
    error_message = "install script should skip installing OpenCode when requested"
  }
}

run "invalid_version" {
  command = plan

  variables {
    agent_id         = "test-agent-id"
    opencode_version = "not-a-version"
  }

  expect_failures = [
    var.opencode_version,
  ]
}