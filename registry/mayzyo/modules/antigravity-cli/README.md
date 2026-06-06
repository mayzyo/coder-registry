---
display_name: Antigravity CLI
description: Install and configure Google's Antigravity CLI (agy) in your workspace.
icon: ../../.images/antigravity-cli.svg
verified: false
tags: [agent, ai, antigravity, cli]
---

# Antigravity CLI

Install and configure [Antigravity CLI](https://antigravity.google/docs/cli-overview), Google's terminal-first interface for Antigravity agents, in your workspace. Starting Antigravity CLI is left to the caller, such as a terminal command, IDE launcher, custom `coder_app`, or a future task wrapper.

```tf
module "antigravity-cli" {
  source   = "registry.coder.com/mayzyo/antigravity-cli/coder"
  version  = "0.1.1"
  agent_id = coder_agent.main.id
}
```

By default, the module uses the official macOS/Linux installer, prepares Antigravity CLI settings under `~/.gemini/antigravity-cli/`, and enables the documented terminal sandbox setting. Authentication is handled by `agy` through Google Sign-In or an existing secure keyring session.

> [!NOTE]
> Antigravity CLI can also be configured interactively with `/config`, `/settings`, `/permissions`, `/model`, and `/mcp`. Use `antigravity_settings` and `mcp` when you want workspaces to come up preconfigured from template variables.

## Examples

### Standalone mode with a launcher app

```tf
locals {
  antigravity_workdir = "/home/coder/project"
}

module "antigravity-cli" {
  source   = "registry.coder.com/mayzyo/antigravity-cli/coder"
  version  = "0.1.1"
  agent_id = coder_agent.main.id
  workdir  = local.antigravity_workdir
}

resource "coder_app" "antigravity_cli" {
  agent_id     = coder_agent.main.id
  slug         = "antigravity-cli"
  display_name = "Antigravity CLI"
  icon         = "https://raw.githubusercontent.com/mayzyo/coder-registry/main/registry/mayzyo/.images/antigravity-cli.svg"
  open_in      = "slim-window"
  command      = <<-EOT
    #!/bin/bash
    set -e
    cd ${local.antigravity_workdir}
    agy
  EOT
}
```

### MCP servers

Provide a JSON-encoded MCP configuration to write `~/.gemini/antigravity-cli/mcp_config.json`. Antigravity CLI also supports workspace-local MCP configuration in `.agents/mcp_config.json`.

```tf
module "antigravity-cli" {
  source   = "registry.coder.com/mayzyo/antigravity-cli/coder"
  version  = "0.1.1"
  agent_id = coder_agent.main.id

  mcp = jsonencode({
    mcpServers = {
      github = {
        serverUrl = "https://api.githubcopilot.com/mcp/"
        headers = {
          Authorization = "Bearer ${data.coder_external_auth.github.access_token}"
        }
      }
    }
  })
}

data "coder_external_auth" "github" {
  id = "github"
}
```

### Settings override

For advanced preferences, pass a settings object. The module always sets `enableTerminalSandbox` from `enable_terminal_sandbox` in the generated file.

```tf
module "antigravity-cli" {
  source   = "registry.coder.com/mayzyo/antigravity-cli/coder"
  version  = "0.1.1"
  agent_id = coder_agent.main.id

  enable_terminal_sandbox = true
  antigravity_settings = {
    permissions = {
      allow = ["command(git status)"]
      deny  = ["command(rm -rf)"]
    }
  }
}
```

## Troubleshooting

The module uses `coder-utils`, so install logs and materialized scripts are under `~/.coder-modules/mayzyo/antigravity-cli/`.

```bash
cat ~/.coder-modules/mayzyo/antigravity-cli/logs/install.log
cat ~/.coder-modules/mayzyo/antigravity-cli/scripts/install.sh
```

## References

- [Antigravity CLI installation](https://antigravity.google/docs/cli-install)
- [Antigravity CLI settings](https://antigravity.google/docs/cli-settings)
- [Antigravity CLI plugins and MCP](https://antigravity.google/docs/cli-plugins)
