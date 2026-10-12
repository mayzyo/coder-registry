---
display_name: AI Assistants Suite
description: Complete developer AI toolchain integrating Codex, Claude Code, Qwen Code, Antigravity CLI, and OpenCode
icon: ../../../../.icons/gemini.svg
verified: false
tags: [ai, assistant, coding, helper]
---

# AI Assistants Suite

A unified Coder module that provides an AI coding assistant suite (Codex, Claude Code, Qwen Code, Antigravity CLI, and OpenCode) with standardized configurations, model providers, and MCP servers. Automatically exposes user-facing `coder_parameter` toggles to enable each tool.

## Usage

```tf
module "ai_assistants" {
  source  = "registry.coder.com/mayzyo/ai-assistants/coder"
  version = "1.1.0"

  agent_id = coder_agent.main.id
  workdir  = local.workspace_dir

  anthropic_api_key  = var.anthropic_api_key
  anthropic_base_url = var.anthropic_base_url
  bailian_api_key    = var.bailian_api_key
  github_pat         = var.github_pat
  tavily_api_key     = var.tavily_api_key
  openwebui_api_key  = var.openwebui_api_key
}
```

Each assistant is opt-in through a `coder_parameter` toggle (`run_codex`, `run_claude_code`, `run_qwen_code`, `run_antigravity`, `run_opencode`), all defaulting to `false`, and exposes a slim-window `coder_app` launcher.

## OpenCode

OpenCode is installed from its official standalone installer (no Node.js/npm required) and configured for an OpenAI-compatible Open WebUI endpoint. When `openwebui_api_key` is set, it is exposed to the agent as `OPENWEBUI_API_KEY` and the config reads it via OpenCode's `{env:OPENWEBUI_API_KEY}` substitution, so the secret is never written to disk.