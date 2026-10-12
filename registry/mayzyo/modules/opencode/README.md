---
display_name: OpenCode
description: Install and configure the OpenCode CLI in your workspace.
icon: ../../.images/opencode.svg
verified: false
tags: [agent, ai, opencode, cli]
---

# OpenCode

Install and configure the [OpenCode](https://opencode.ai) CLI (V2) in your workspace. Starting OpenCode is left to the caller, such as a terminal command, IDE launcher, or custom `coder_app`.

```tf
module "opencode" {
  source   = "registry.coder.com/mayzyo/opencode/coder"
  version  = "2.1.0"
  agent_id = coder_agent.main.id
  workdir  = "/home/coder/project"
}
```

OpenCode V2 is installed from the official [V2 standalone installer](https://opencode.ai/v2/install), which downloads a self-contained binary to `$HOME/.opencode/bin`. Node.js and npm are **not** required.

By default, the module writes a global native OpenCode V2 config to `~/.config/opencode/opencode.jsonc` for an OpenAI-compatible Open WebUI endpoint (`openwebui_base_url`). It selects the Qwen (`local`), GLM, and DeepSeek models with context limits, sets `openwebui/local` as the default model, maps the `build`, `plan`, `general`, `explore`, `title`, and `summary` agents, and enables automatic compaction. The config uses the native V2 shapes (`providers`/`settings`, `agents`, `websearch`, `mcp.servers`) and selects Exa as the built-in web search provider when an Exa API key is supplied. Without that key, OpenCode keeps its normal search provider selection.

> [!NOTE]
> Pass `opencode_config` to replace the generated config entirely. The built-in default is only used when `opencode_config` is empty.

## Upgrading from 1.x

Version 2.0.0 of this module requires OpenCode V2. Existing V1 binaries are upgraded before the module writes the native V2 config. Update any `opencode_version` pin to a 2.x version. If installation is disabled, provide a V2 binary on PATH; incompatible binaries cause the script to fail before changing the config.

OpenCode V2 changes the plugin and server APIs. Port custom plugins and API clients before upgrading; see the [V1 migration guide](https://opencode.ai/v2/docs/migrate-v1).

## Examples

### Open WebUI API key

Keep the API key out of the config file. When `openwebui_api_key` is set, the module exposes it to the agent as `OPENWEBUI_API_KEY` and the generated config reads it via OpenCode's `{env:OPENWEBUI_API_KEY}` substitution.

```tf
module "opencode" {
  source             = "registry.coder.com/mayzyo/opencode/coder"
  version            = "2.1.0"
  agent_id           = coder_agent.main.id
  workdir            = "/home/coder/project"
  openwebui_api_key  = var.openwebui_api_key
  openwebui_base_url = var.openwebui_base_url
}
```

### Exa search and MCP integrations

The module shares the optional [Exa](https://exa.ai), GitHub, and [Context7](https://context7.com) integrations with the other mayzyo AI assistant modules. Each integration is enabled automatically when its credential is set, and the credential is exposed to the agent as an environment variable.

`exa_api_key` also enables OpenCode's built-in Exa web search provider. The generated config references every credential through `{env:...}` substitution, so no secret is written to `opencode.jsonc`.

```tf
module "opencode" {
  source           = "registry.coder.com/mayzyo/opencode/coder"
  version          = "2.1.0"
  agent_id         = coder_agent.main.id
  workdir          = "/home/coder/project"
  exa_api_key      = var.exa_api_key
  github_token     = var.github_token
  context7_api_key = var.context7_api_key
}
```

### Custom config and launcher app

```tf
module "opencode" {
  source   = "registry.coder.com/mayzyo/opencode/coder"
  version  = "2.1.0"
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
  version          = "2.1.0"
  agent_id         = coder_agent.main.id
  opencode_version = "2.0.0"
}
```

## Troubleshooting

The module uses `coder-utils`, so install logs and materialized scripts are under `~/.coder-modules/mayzyo/opencode/`.

```bash
cat ~/.coder-modules/mayzyo/opencode/logs/install.log
cat ~/.coder-modules/mayzyo/opencode/scripts/install.sh
```

## References

- [OpenCode V2 documentation](https://opencode.ai/v2/docs)
- [OpenCode V2 JSON config](https://opencode.ai/v2/docs/config)
- [OpenCode V2 providers](https://opencode.ai/v2/docs/providers)
- [OpenCode V2 web search](https://opencode.ai/v2/docs/websearch)
- [OpenCode V2 MCP servers](https://opencode.ai/v2/docs/mcp-servers)
- [Migrate from OpenCode V1 to V2](https://opencode.ai/v2/docs/migrate-v1)
