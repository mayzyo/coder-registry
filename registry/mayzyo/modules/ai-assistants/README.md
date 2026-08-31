---
display_name: AI Assistants Suite
description: Complete developer AI toolchain integrating Codex, Claude Code, Qwen Code, and Antigravity CLI
icon: ../../../../.icons/gemini.svg
verified: false
tags: [ai, assistant, coding, helper]
---

# AI Assistants Suite

A unified Coder module that provides an AI coding assistant suite (Codex, Claude Code, Qwen Code, and Antigravity CLI) with standardized configurations, model providers, and MCP servers. Automatically exposes user-facing `coder_parameter` toggles to enable each tool.

## Usage

```tf
module "ai_assistants" {
  source  = "registry.coder.com/mayzyo/ai-assistants/coder"
  version = "1.0.0"

  agent_id = coder_agent.main.id
  workdir  = local.workspace_dir

  anthropic_api_key  = var.anthropic_api_key
  anthropic_base_url = var.anthropic_base_url
  bailian_api_key    = var.bailian_api_key
  github_pat         = var.github_pat
  tavily_api_key     = var.tavily_api_key
}
```
