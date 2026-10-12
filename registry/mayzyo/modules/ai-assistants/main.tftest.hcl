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