run "defaults" {
  command = plan

  variables {
    agent_id = "test-agent-id"
  }

  assert {
    condition     = local.module_directory == "$HOME/.coder-modules/mayzyo/antigravity-cli"
    error_message = "module directory should follow the registry module data layout."
  }

  assert {
    condition     = var.install_antigravity == true
    error_message = "install_antigravity should default to true."
  }

  assert {
    condition     = var.configure_settings == true
    error_message = "configure_settings should default to true."
  }

  assert {
    condition     = jsondecode(local.settings_json).enableTerminalSandbox == true
    error_message = "generated settings should enable terminal sandbox by default."
  }

  assert {
    condition     = var.antigravity_binary_path == "$HOME/.local/bin"
    error_message = "antigravity_binary_path should default to the official installer path."
  }
}

run "custom_workdir" {
  command = plan

  variables {
    agent_id = "test-agent-id"
    workdir  = "/home/coder/projects/test-project/"
  }

  assert {
    condition     = local.workdir == "/home/coder/projects/test-project"
    error_message = "workdir should be trimmed and stored correctly."
  }
}

run "custom_binary_path_requires_manual_install" {
  command = plan

  variables {
    agent_id                = "test-agent-id"
    install_antigravity     = false
    antigravity_binary_path = "/custom/bin"
  }

  assert {
    condition     = output.binary_path == "/custom/bin/agy"
    error_message = "binary_path should use the custom binary path."
  }
}

run "settings_override" {
  command = plan

  variables {
    agent_id = "test-agent-id"
    antigravity_settings = {
      permissions = {
        allow = ["command(git status)"]
      }
    }
  }

  assert {
    condition     = jsondecode(local.settings_json).permissions.allow[0] == "command(git status)"
    error_message = "custom settings should be merged into generated settings."
  }

  assert {
    condition     = jsondecode(local.settings_json).enableTerminalSandbox == true
    error_message = "enableTerminalSandbox should be controlled by enable_terminal_sandbox."
  }
}

run "disable_terminal_sandbox" {
  command = plan

  variables {
    agent_id                = "test-agent-id"
    enable_terminal_sandbox = false
  }

  assert {
    condition     = jsondecode(local.settings_json).enableTerminalSandbox == false
    error_message = "generated settings should disable terminal sandbox when requested."
  }
}

run "disable_settings" {
  command = plan

  variables {
    agent_id           = "test-agent-id"
    configure_settings = false
  }

  assert {
    condition     = local.settings_json == ""
    error_message = "settings_json should be empty when configure_settings is false."
  }
}

run "mcp_config_rendering" {
  command = plan

  variables {
    agent_id = "test-agent-id"
    mcp = jsonencode({
      mcpServers = {
        github = {
          serverUrl = "https://api.githubcopilot.com/mcp/"
        }
      }
    })
  }

  assert {
    condition     = strcontains(local.install_script, "mcp_config.json")
    error_message = "install script should write the documented global MCP config file."
  }
}
