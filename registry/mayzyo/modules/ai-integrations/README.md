---
display_name: AI Integrations
description: Shared optional Exa, GitHub, and Context7 integrations for the mayzyo AI assistant modules.
icon: ../../../../.icons/coder-modules.svg
verified: false
tags: [ai, mcp, exa, github, context7, internal]
---

# AI Integrations

Defines the optional AI integrations shared by the mayzyo AI assistant modules: [Exa](https://exa.ai) search, [GitHub](https://github.com) MCP, and [Context7](https://context7.com) documentation MCP. An integration is enabled automatically when its credential is provided.

```tf
module "ai_integrations" {
  source  = "registry.coder.com/mayzyo/ai-integrations/coder"
  version = "0.1.0"

  agent_id         = coder_agent.main.id
  exa_api_key      = var.exa_api_key
  github_token     = var.github_token
  context7_api_key = var.context7_api_key
}
```

Pass only the credentials you want to enable; an empty or omitted credential disables that integration. Each enabled credential is exposed to the agent as an environment variable.

## Rendered formats

Consuming modules receive OpenCode V2 `mcp.servers` entries or Qwen Code `mcpServers` entries. Credentials use OpenCode's `{env:...}` substitution or Qwen Code's `$VAR`/`${VAR}` substitution, so no credentials are written to either config file.

> [!NOTE]
> This module is used internally by `mayzyo/opencode`, `mayzyo/qwen-code`, and `mayzyo/qwen-code-tasks`. When one of those modules is used inside the `mayzyo/ai-assistants` umbrella, the umbrella creates the environment variables once and passes `create_integration_env = false` to the wrapped assistant modules to avoid duplicates. The `mayzyo/antigravity-cli` module is intentionally excluded because Antigravity performs search server-side.
