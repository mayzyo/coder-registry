mock_provider "coder" {}

run "plan_with_defaults" {
  command = plan

  variables {
    agent_id = "test-agent-id"
    workdir  = "/home/node/project"
  }

  override_data {
    target = data.coder_workspace.me
    values = {
      start_count = 1
    }
  }

  override_data {
    target = data.coder_parameter.run_codex
    values = {
      value = false
    }
  }

  override_data {
    target = data.coder_parameter.run_claude_code
    values = {
      value = false
    }
  }

  override_data {
    target = data.coder_parameter.run_qwen_code
    values = {
      value = false
    }
  }

  override_data {
    target = data.coder_parameter.run_antigravity
    values = {
      value = false
    }
  }

  override_data {
    target = data.coder_parameter.run_opencode
    values = {
      value = false
    }
  }

  assert {
    condition     = var.agent_id == "test-agent-id"
    error_message = "agent_id should match"
  }

  assert {
    condition     = length(module.opencode) == 0
    error_message = "opencode module should be disabled by default"
  }

  assert {
    condition     = length(resource.coder_app.opencode) == 0
    error_message = "opencode app should be disabled by default"
  }
}

run "plan_with_opencode" {
  command = plan

  variables {
    agent_id = "test-agent-id"
    workdir  = "/home/node/project"
  }

  override_data {
    target = data.coder_workspace.me
    values = {
      start_count = 1
    }
  }

  override_data {
    target = data.coder_parameter.run_codex
    values = {
      value = false
    }
  }

  override_data {
    target = data.coder_parameter.run_claude_code
    values = {
      value = false
    }
  }

  override_data {
    target = data.coder_parameter.run_qwen_code
    values = {
      value = false
    }
  }

  override_data {
    target = data.coder_parameter.run_antigravity
    values = {
      value = false
    }
  }

  override_data {
    target = data.coder_parameter.run_opencode
    values = {
      value = true
    }
  }

  assert {
    condition     = length(module.opencode) == 1
    error_message = "opencode module should be enabled when run_opencode is true"
  }

  assert {
    condition     = length(resource.coder_app.opencode) == 1
    error_message = "opencode app should be enabled when run_opencode is true"
  }

  assert {
    condition     = resource.coder_app.opencode[0].slug == "opencode"
    error_message = "opencode app should use the opencode slug"
  }
}

run "plan_with_integrations" {
  command = plan

  variables {
    agent_id         = "test-agent-id"
    workdir          = "/home/node/project"
    exa_api_key      = "test-exa-key"
    github_pat       = "test-github-token"
    context7_api_key = "test-context7-key"
  }

  override_data {
    target = data.coder_workspace.me
    values = {
      start_count = 1
    }
  }

  override_data {
    target = data.coder_parameter.run_codex
    values = {
      value = false
    }
  }

  override_data {
    target = data.coder_parameter.run_claude_code
    values = {
      value = false
    }
  }

  override_data {
    target = data.coder_parameter.run_qwen_code
    values = {
      value = true
    }
  }

  override_data {
    target = data.coder_parameter.run_antigravity
    values = {
      value = false
    }
  }

  override_data {
    target = data.coder_parameter.run_opencode
    values = {
      value = true
    }
  }

  assert {
    condition     = length(module.ai_integrations.integrations) == 3
    error_message = "the umbrella should enable all three shared integrations when credentials are set"
  }

  assert {
    condition     = length(module.qwen_code) == 1 && length(module.opencode) == 1
    error_message = "both MCP clients should be enabled to exercise shared integrations"
  }

  assert {
    condition     = contains(module.ai_integrations.integrations, "exa") && contains(module.ai_integrations.integrations, "github") && contains(module.ai_integrations.integrations, "context7")
    error_message = "the umbrella should enable exa, github, and context7"
  }
}
