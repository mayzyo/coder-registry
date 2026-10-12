---
display_name: OpenCode
description: Install and configure the OpenCode CLI in your workspace.
icon: ../../.images/opencode.svg
verified: false
tags: [agent, ai, opencode, cli]
---

# OpenCode

Install and configure the [OpenCode](https://opencode.ai) CLI in your workspace. Starting OpenCode is left to the caller, such as a terminal command, IDE launcher, or custom `coder_app`.

```tf
module "opencode" {
  source   = "registry.coder.com/mayzyo/opencode/coder"
  version  = "1.0.0"
  agent_id = coder_agent.main.id
  workdir  = "/home/coder/project"
}
```

OpenCode is installed from the official [standalone installer](https://opencode.ai/install), which downloads a self-contained binary to `$HOME/.opencode/bin`. Node.js and npm are **not** required. Custom provider packages referenced with `"npm"` in the config (for example `@ai-sdk/openai-compatible`) are fetched by OpenCode itself at runtime.

By default, the module writes a global config to `~/.config/opencode/opencode.jsonc` for an OpenAI-compatible Open WebUI endpoint, selecting the Qwen, GLM, and Deepseek models and mapping them to the `build`, `plan`, and helper agents.

> [!NOTE]
> Pass `opencode_config` to replace the generated config entirely. The built-in default is only used when `opencode_config` is empty.

## Examples

### Open WebUI API key

Keep the API key out of the config file. When `openwebui_api_key` is set, the module exposes it to the agent as `OPENWEBUI_API_KEY` and the generated config reads it via OpenCode's `{env:OPENWEBUI_API_KEY}` substitution.

```tf
module "opencode" {
  source            = "registry.coder.com/mayzyo/opencode/coder"
  version           = "1.0.0"
  agent_id          = coder_agent.main.id
  workdir           = "/home/coder/project"
  openwebui_api_key = var.openwebui_api_key
}
```

### Custom config and launcher app

```tf
module "opencode" {
  source   = "registry.coder.com/mayzyo/opencode/coder"
  version  = "1.0.0"
  agent_id = coder_agent.main.id
  workdir  = "/home/coder/project"

  opencode_config = jsonencode({
    "$schema" = "https://opencode.ai/config.json"
    model     = "anthropic/claude-sonnet-4-5"
  })
}

resource "coder_app" "opencode" {
  agent_id     = coder_agent.main.id
  slug         = "opencode"
  display_name = "OpenCode"
  icon         = "https://raw.githubusercontent.com/mayzyo/coder-registry/main/registry/mayzyo/.images/opencode.svg"
  open_in      = "slim-window"
  command      = <<-EOT
    #!/bin/bash
    set -e
    export PATH="$HOME/.opencode/bin:$PATH"
    cd /home/coder/project
    opencode
  EOT
}
```

### Pin a version

```tf
module "opencode" {
  source           = "registry.coder.com/mayzyo/opencode/coder"
  version          = "1.0.0"
  agent_id         = coder_agent.main.id
  opencode_version = "1.0.180"
}
```

## Troubleshooting

The module uses `coder-utils`, so install logs and materialized scripts are under `~/.coder-modules/mayzyo/opencode/`.

```bash
cat ~/.coder-modules/mayzyo/opencode/logs/install.log
cat ~/.coder-modules/mayzyo/opencode/scripts/install.sh
```

## References

- [OpenCode documentation](https://opencode.ai/docs)
- [OpenCode JSON config](https://opencode.ai/docs/config/)
- [OpenCode providers](https://opencode.ai/docs/providers/)