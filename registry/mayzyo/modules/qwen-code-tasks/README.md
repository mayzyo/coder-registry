---
display_name: Qwen Code Tasks
description: Wrap Qwen Code with AgentAPI, Coder Tasks, and Coder MCP reporting.
icon: ../../.images/qwen-code.svg
verified: false
tags: [agent, ai, tasks, qwen-code]
---

# Qwen Code Tasks

Install and configure Qwen Code through the `mayzyo/qwen-code` module, then run it behind AgentAPI so it can be used from Coder Tasks. The wrapper adds Coder MCP settings, starts Qwen Code in headless mode when a task prompt is provided, and exposes `task_app_id` for `coder_ai_task`.

```tf
data "coder_task" "me" {}

module "qwen_code_tasks" {
  count   = data.coder_workspace.me.start_count
  source  = "registry.coder.com/mayzyo/qwen-code-tasks/coder"
  version = "1.0.1"

  agent_id    = coder_agent.main.id
  workdir     = "/home/coder/project"
  task_prompt = data.coder_task.me.prompt

  qwen_model           = "qwen-3-next-coder"
  qwen_base_url        = "http://host.docker.internal:11434/v1"
  qwen_api_key_env_var = "QWEN_API_KEY"
  qwen_api_key         = var.qwen_api_key
}

resource "coder_ai_task" "qwen" {
  count  = data.coder_workspace.me.start_count
  app_id = module.qwen_code_tasks[count.index].task_app_id
}
```

By default, the module configures Coder MCP in Qwen Code settings, pre-allows Qwen to call `mcp__coder__coder_report_task` and `Agent(general-purpose)`, disables Qwen telemetry and usage statistics in generated settings, and enables AgentAPI state persistence.

> [!NOTE]
> This module is a task/runtime wrapper. Use `mayzyo/qwen-code` directly when you only need the Qwen Code CLI installed and configured.
> When consumed from Git, this wrapper uses the sibling `../qwen-code` module from the same checked-out repository, so both modules come from the same branch or tag.
