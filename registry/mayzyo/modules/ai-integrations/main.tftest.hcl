mock_provider "coder" {}

run "defaults" {
  command = plan

  variables {
    agent_id = "test-agent-id"
  }

  assert {
    condition     = length(output.integrations) == 0
    error_message = "no integrations should be enabled without credentials"
  }

  assert {
    condition     = length(output.opencode_mcp) == 0
    error_message = "opencode mcp servers should be empty without credentials"
  }

  assert {
    condition     = length(output.qwen_mcp) == 0
    error_message = "qwen mcp servers should be empty without credentials"
  }

  assert {
    condition     = length(resource.coder_env.exa_api_key) == 0
    error_message = "exa env var should be omitted without a credential"
  }

  assert {
    condition     = length(resource.coder_env.github_token) == 0
    error_message = "github env var should be omitted without a credential"
  }

  assert {
    condition     = length(resource.coder_env.context7_api_key) == 0
    error_message = "context7 env var should be omitted without a credential"
  }
}

run "exa_enabled" {
  command = plan

  variables {
    agent_id    = "test-agent-id"
    exa_api_key = "test-exa-key"
  }

  assert {
    condition     = output.enabled.exa == true && output.enabled.github == false && output.enabled.context7 == false
    error_message = "only exa should be enabled when only exa_api_key is set"
  }

  assert {
    condition     = output.opencode_mcp.exa.url == "https://mcp.exa.ai/mcp"
    error_message = "opencode exa server should target the hosted Exa MCP endpoint"
  }

  assert {
    condition     = output.opencode_mcp.exa.headers["x-api-key"] == "{env:EXA_API_KEY}"
    error_message = "opencode exa server should reference the env var instead of the secret"
  }

  assert {
    condition     = output.qwen_mcp.exa.headers["x-api-key"] == "$${EXA_API_KEY}"
    error_message = "qwen exa server should reference the env var instead of the secret"
  }

  assert {
    condition     = !strcontains(jsonencode(output.opencode_mcp), "test-exa-key")
    error_message = "opencode config should not contain the exa secret"
  }

  assert {
    condition     = resource.coder_env.exa_api_key[0].name == "EXA_API_KEY"
    error_message = "exa credential should be exposed as EXA_API_KEY"
  }
}

run "all_enabled" {
  command = plan

  variables {
    agent_id         = "test-agent-id"
    exa_api_key      = "test-exa-key"
    github_token     = "test-github-token"
    context7_api_key = "test-context7-key"
  }

  assert {
    condition     = output.enabled.exa == true && output.enabled.github == true && output.enabled.context7 == true
    error_message = "all integrations should be enabled when all credentials are set"
  }

  assert {
    condition     = output.opencode_mcp.github.headers.Authorization == "Bearer {env:GITHUB_PERSONAL_ACCESS_TOKEN}"
    error_message = "opencode github server should reference the env var"
  }

  assert {
    condition     = output.opencode_mcp.context7.headers.Authorization == "Bearer {env:CONTEXT7_API_KEY}"
    error_message = "opencode context7 server should reference the env var"
  }

  assert {
    condition     = output.opencode_mcp.context7.url == "https://mcp.context7.com/mcp"
    error_message = "opencode context7 server should target the Context7 endpoint"
  }

  assert {
    condition     = resource.coder_env.github_token[0].name == "GITHUB_PERSONAL_ACCESS_TOKEN"
    error_message = "github credential should be exposed as GITHUB_PERSONAL_ACCESS_TOKEN"
  }

  assert {
    condition     = resource.coder_env.context7_api_key[0].name == "CONTEXT7_API_KEY"
    error_message = "context7 credential should be exposed as CONTEXT7_API_KEY"
  }

  assert {
    condition     = contains(output.integrations, "exa") && contains(output.integrations, "github") && contains(output.integrations, "context7")
    error_message = "integrations output should list every enabled integration"
  }
}

run "create_env_disabled" {
  command = plan

  variables {
    agent_id    = "test-agent-id"
    exa_api_key = "test-exa-key"
    create_env  = false
  }

  assert {
    condition     = length(resource.coder_env.exa_api_key) == 0
    error_message = "env vars should not be created when create_env is false"
  }

  assert {
    condition     = output.enabled.exa == true
    error_message = "integration should still render when create_env is false"
  }
}