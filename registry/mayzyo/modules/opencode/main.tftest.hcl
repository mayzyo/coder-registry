mock_provider "coder" {}

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
    condition     = jsondecode(local.opencode_config_json).providers.openwebui.settings.baseURL == "http://open-webui.time-emoji-services/api"
    error_message = "generated config should target the default Open WebUI base URL"
  }

  assert {
    condition     = jsondecode(local.opencode_config_json).providers.openwebui.package == "@opencode/ai/providers/openai-compatible"
    error_message = "generated config should use the native V2 OpenAI-compatible provider package"
  }

  assert {
    condition     = jsondecode(local.opencode_config_json).providers.openwebui.name == "Open WebUI"
    error_message = "generated config should name the Open WebUI provider"
  }

  assert {
    condition     = jsondecode(local.opencode_config_json).agents.title.model == "openwebui/local"
    error_message = "generated config should map the title agent to the default small model"
  }

  assert {
    condition     = jsondecode(local.opencode_config_json).agents.build.model == "openwebui/deepseek-v4.1-flash"
    error_message = "generated config should map the build agent to the default model"
  }

  assert {
    condition     = jsondecode(local.opencode_config_json).agents.general.steps == 25
    error_message = "generated config should preserve agent step limits"
  }

  assert {
    condition     = !contains(keys(jsondecode(local.opencode_config_json)), "websearch")
    error_message = "generated config should leave search provider selection to OpenCode without an Exa credential"
  }

  assert {
    condition     = !strcontains(local.opencode_config_json, "small_model")
    error_message = "generated config should not use the deprecated V1 small_model field"
  }

  assert {
    condition     = !contains(keys(jsondecode(local.opencode_config_json)), "provider")
    error_message = "generated config should not use the deprecated V1 provider map"
  }

  assert {
    condition     = length(jsondecode(local.opencode_config_json).mcp.servers) == 0
    error_message = "generated config should have no mcp servers when no integration credentials are provided"
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
    condition     = strcontains(local.install_script, "https://opencode.ai/v2/install")
    error_message = "install script should use the OpenCode V2 installer"
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
    condition     = jsondecode(local.opencode_config_json).providers.openwebui.settings.apiKey == "{env:OPENWEBUI_API_KEY}"
    error_message = "generated config should reference the API key through env substitution"
  }

  assert {
    condition     = !strcontains(local.opencode_config_json, "test-openwebui-key")
    error_message = "generated config should not contain the API key secret"
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
    condition     = jsondecode(local.opencode_config_json).websearch.provider == "exa"
    error_message = "an Exa credential should select the Exa web search provider"
  }

  assert {
    condition     = jsondecode(local.opencode_config_json).mcp.servers.exa.url == "https://mcp.exa.ai/mcp"
    error_message = "enabled exa integration should add the Exa MCP server"
  }

  assert {
    condition     = jsondecode(local.opencode_config_json).mcp.servers.exa.headers["x-api-key"] == "{env:EXA_API_KEY}"
    error_message = "exa MCP server should reference EXA_API_KEY instead of the secret"
  }

  assert {
    condition     = jsondecode(local.opencode_config_json).mcp.servers.github.headers.Authorization == "Bearer {env:GITHUB_PERSONAL_ACCESS_TOKEN}"
    error_message = "github MCP server should reference GITHUB_PERSONAL_ACCESS_TOKEN"
  }

  assert {
    condition     = jsondecode(local.opencode_config_json).mcp.servers.context7.url == "https://mcp.context7.com/mcp"
    error_message = "enabled context7 integration should add the Context7 MCP server"
  }

  assert {
    condition     = !strcontains(local.opencode_config_json, "test-exa-key") && !strcontains(local.opencode_config_json, "test-github-token") && !strcontains(local.opencode_config_json, "test-context7-key")
    error_message = "generated config should not contain any integration secrets"
  }

  assert {
    condition     = module.ai_integrations.enabled.exa && module.ai_integrations.enabled.github && module.ai_integrations.enabled.context7
    error_message = "the shared integrations module should receive every provided credential"
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

run "reject_v1_version" {
  command = plan

  variables {
    agent_id         = "test-agent-id"
    opencode_version = "1.0.180"
  }

  expect_failures = [var.opencode_version]
}

run "pinned_v2_version" {
  command = plan

  variables {
    agent_id         = "test-agent-id"
    opencode_version = "v2.0.27"
  }

  assert {
    condition     = strcontains(local.install_script, "ARG_OPENCODE_VERSION='v2.0.27'")
    error_message = "a pinned V2 version should be passed to the installer"
  }
}
