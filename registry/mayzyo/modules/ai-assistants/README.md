---
display_name: AI Assistants Suite
description: Complete developer AI toolchain integrating Codex, Claude Code, Qwen Code, Antigravity CLI, and OpenCode
icon: ../../../../.icons/gemini.svg
verified: false
tags: [ai, assistant, coding, helper]
---

# AI Assistants Suite

A unified Coder module that provides an AI coding assistant suite (Codex, Claude Code, Qwen Code, Antigravity CLI, and OpenCode) with standardized configurations, model providers, and MCP servers. It automatically exposes user-facing `coder_parameter` toggles to enable each tool.

```tf
module "ai_assistants" {
  source  = "registry.coder.com/mayzyo/ai-assistants/coder"
  version = "2.0.0"

  agent_id = coder_agent.main.id
  workdir  = local.workspace_dir

  anthropic_api_key  = var.anthropic_api_key
  anthropic_base_url = var.anthropic_base_url
  bailian_api_key    = var.bailian_api_key
  github_pat         = var.github_pat
  exa_api_key        = var.exa_api_key
  context7_api_key   = var.context7_api_key
  openwebui_api_key  = var.openwebui_api_key
}
```

Each assistant is opt-in through a `coder_parameter` toggle (`run_codex`, `run_claude_code`, `run_qwen_code`, `run_antigravity`, `run_opencode`), all defaulting to `false`, and exposes a slim-window `coder_app` launcher.

## Shared integrations (Exa, GitHub, Context7)

The suite defines the optional Exa search, GitHub, and [Context7](https://context7.com) documentation MCP servers once through the internal `mayzyo/ai-integrations` module. Each integration is enabled automatically when its credential is set, and the credential is exposed to the agent as an environment variable exactly once for the whole workspace.

Enabled integrations are wired into the assistants that support MCP servers:

- **Qwen Code** receives them as `mcpServers` entries in `settings.json`, referencing each credential with Qwen Code's `${VAR}` substitution.
- **OpenCode** receives them as OpenCode V2 `mcp.servers` entries referencing each credential with `{env:...}` substitution, and `exa_api_key` also enables OpenCode's built-in Exa web search provider.

Antigravity CLI is intentionally excluded because it performs search server-side. Codex and Claude Code are left unmodified by this suite.

> [!NOTE]
> The suite previously wired Tavily into Qwen Code through `tavily_api_key`. That variable has been replaced by `exa_api_key`; update your template variables when upgrading.

## OpenCode

OpenCode is installed from its official standalone V2 installer (no Node.js/npm required) and configured for an OpenAI-compatible Open WebUI endpoint. When `openwebui_api_key` is set, it is exposed to the agent as `OPENWEBUI_API_KEY` and the config reads it via OpenCode's `{env:OPENWEBUI_API_KEY}` substitution, so the secret is never written to disk.

## References

- [Exa](https://exa.ai)
- [Context7](https://context7.com)
- [OpenCode V2 documentation](https://opencode.ai/v2/docs)
