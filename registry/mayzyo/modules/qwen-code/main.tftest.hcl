run "defaults" {
  command = plan

  variables {
    agent_id = "test-agent-id"
  }

  assert {
    condition     = local.module_directory == "$HOME/.coder-modules/mayzyo/qwen-code"
    error_message = "module directory should follow the registry module data layout"
  }

  assert {
    condition     = jsondecode(local.settings_json).model.name == "qwen3.6-plus"
    error_message = "generated settings should select the default Qwen model"
  }

  assert {
    condition     = jsondecode(local.settings_json).security.auth.selectedType == "openai"
    error_message = "generated settings should select the configured auth type"
  }

  assert {
    condition     = jsondecode(local.settings_json).modelProviders.openai[0].baseUrl == "https://dashscope.aliyuncs.com/compatible-mode/v1"
    error_message = "generated settings should include the default Dashscope base URL"
  }

  assert {
    condition     = jsondecode(local.settings_json).telemetry.enabled == false
    error_message = "generated settings should explicitly disable Qwen Code telemetry by default"
  }

  assert {
    condition     = jsondecode(local.settings_json).privacy.usageStatisticsEnabled == false
    error_message = "generated settings should explicitly disable Qwen Code usage statistics by default"
  }

  assert {
    condition     = var.installer_url == "https://raw.githubusercontent.com/QwenLM/qwen-code/main/scripts/installation/install-qwen-with-source.sh"
    error_message = "installer_url should default to the installer that supports --method"
  }

  assert {
    condition     = length(resource.coder_env.qwen_api_key) == 0
    error_message = "api key env var should be omitted when qwen_api_key is empty"
  }
}

run "qwen_api_key_env" {
  command = plan

  variables {
    agent_id     = "test-agent-id"
    qwen_api_key = "test-key"
  }

  assert {
    condition     = resource.coder_env.qwen_api_key[0].name == "DASHSCOPE_API_KEY"
    error_message = "api key should use the default Dashscope env var"
  }

  assert {
    condition     = jsondecode(local.settings_json).modelProviders.openai[0].envKey == "DASHSCOPE_API_KEY"
    error_message = "generated settings should point at the API key env var"
  }

  assert {
    condition     = !strcontains(local.settings_json, "test-key")
    error_message = "generated settings should not contain the API key secret"
  }
}

run "custom_provider_variables" {
  command = plan

  variables {
    agent_id                  = "test-agent-id"
    qwen_model                = "qwen/qwen3-coder"
    qwen_model_display_name   = "Qwen3 Coder"
    qwen_base_url             = "https://openrouter.ai/api/v1"
    qwen_api_key_env_var      = "OPENROUTER_API_KEY"
    qwen_api_key              = "test-openrouter-key"
    qwen_provider_description = "Qwen through OpenRouter"
    qwen_generation_config = {
      contextWindowSize = 262144
    }
  }

  assert {
    condition     = jsondecode(local.settings_json).model.name == "qwen/qwen3-coder"
    error_message = "generated settings should select the user-provided model"
  }

  assert {
    condition     = jsondecode(local.settings_json).modelProviders.openai[0].baseUrl == "https://openrouter.ai/api/v1"
    error_message = "generated settings should use the user-provided base URL"
  }

  assert {
    condition     = jsondecode(local.settings_json).modelProviders.openai[0].envKey == "OPENROUTER_API_KEY"
    error_message = "generated settings should include the user-provided envKey"
  }

  assert {
    condition     = resource.coder_env.qwen_api_key[0].name == "OPENROUTER_API_KEY"
    error_message = "API key should be exposed through the configured env var"
  }

  assert {
    condition     = !strcontains(local.settings_json, "test-openrouter-key")
    error_message = "generated settings should not contain the user-provided API key secret"
  }
}

run "invalid_qwen_api_key_env_var" {
  command = plan

  variables {
    agent_id             = "test-agent-id"
    qwen_api_key_env_var = ""
  }

  expect_failures = [
    var.qwen_api_key_env_var,
  ]
}

run "custom_settings" {
  command = plan

  variables {
    agent_id = "test-agent-id"
    qwen_settings = {
      model = {
        name = "custom-model"
      }
    }
  }

  assert {
    condition     = jsondecode(local.settings_json).model.name == "custom-model"
    error_message = "custom settings should be used as-is"
  }
}

run "integrations" {
  command = plan

  variables {
    agent_id         = "test-agent-id"
    exa_api_key      = "test-exa-key"
    github_token     = "test-github-token"
    context7_api_key = "test-context7-key"
  }

  assert {
    condition     = jsondecode(local.settings_json).mcpServers.exa.httpUrl == "https://mcp.exa.ai/mcp"
    error_message = "enabled exa integration should add the Exa MCP server"
  }

  assert {
    condition     = jsondecode(local.settings_json).mcpServers.exa.headers["x-api-key"] == "$${EXA_API_KEY}"
    error_message = "exa MCP server should reference EXA_API_KEY instead of the secret"
  }

  assert {
    condition     = jsondecode(local.settings_json).mcpServers.github.headers.Authorization == "Bearer $${GITHUB_PERSONAL_ACCESS_TOKEN}"
    error_message = "github MCP server should reference GITHUB_PERSONAL_ACCESS_TOKEN"
  }

  assert {
    condition     = jsondecode(local.settings_json).mcpServers.context7.httpUrl == "https://mcp.context7.com/mcp"
    error_message = "enabled context7 integration should add the Context7 MCP server"
  }

  assert {
    condition     = !strcontains(local.settings_json, "test-exa-key") && !strcontains(local.settings_json, "test-github-token") && !strcontains(local.settings_json, "test-context7-key")
    error_message = "generated settings should not contain any integration secrets"
  }

  assert {
    condition     = module.ai_integrations.enabled.exa && module.ai_integrations.enabled.github && module.ai_integrations.enabled.context7
    error_message = "the shared integrations module should receive every provided credential"
  }
}

run "integrations_merge_custom_settings" {
  command = plan

  variables {
    agent_id    = "test-agent-id"
    exa_api_key = "test-exa-key"
    qwen_settings = {
      mcpServers = {
        custom = {
          httpUrl = "https://example.com/mcp"
        }
        exa = {
          httpUrl = "https://override.example.com/mcp"
        }
      }
    }
  }

  assert {
    condition     = jsondecode(local.settings_json).mcpServers.custom.httpUrl == "https://example.com/mcp"
    error_message = "user-provided mcpServers entries should be preserved"
  }

  assert {
    condition     = jsondecode(local.settings_json).mcpServers.exa.httpUrl == "https://override.example.com/mcp"
    error_message = "user-provided mcpServers should take precedence over generated integrations"
  }
}

run "enable_telemetry" {
  command = plan

  variables {
    agent_id         = "test-agent-id"
    enable_telemetry = true
  }

  assert {
    condition     = jsondecode(local.settings_json).telemetry.enabled == true
    error_message = "generated settings should enable telemetry when requested"
  }
}

run "enable_usage_statistics" {
  command = plan

  variables {
    agent_id                = "test-agent-id"
    enable_usage_statistics = true
  }

  assert {
    condition     = jsondecode(local.settings_json).privacy.usageStatisticsEnabled == true
    error_message = "generated settings should enable usage statistics when requested"
  }
}

run "invalid_method" {
  command = plan

  variables {
    agent_id       = "test-agent-id"
    install_method = "curl"
  }

  expect_failures = [
    var.install_method,
  ]
}
