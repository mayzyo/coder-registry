---
display_name: Qwen Code
description: Install and configure the Qwen Code CLI in your workspace.
icon: ../../../../.icons/qwen-code.svg
verified: false
tags: [agent, ai, qwen-code, cli]
---

# Qwen Code

Install and configure the [Qwen Code](https://github.com/QwenLM/qwen-code) CLI in your workspace. Starting Qwen Code is left to the caller, such as a terminal command, IDE launcher, or custom `coder_app`.

```tf
module "qwen-code" {
  source   = "registry.coder.com/mayzyo/qwen-code/coder"
  version  = "1.0.0"
  agent_id = coder_agent.main.id
  api_key  = var.dashscope_api_key
}
```

By default, the module writes `~/.qwen/settings.json` for Dashscope's OpenAI-compatible endpoint, explicitly sets `telemetry.enabled = false`, and exposes the API key through `DASHSCOPE_API_KEY`. The API key is passed through a sensitive Terraform variable into `coder_env`; only the environment variable name is written to Qwen Code settings. The installer uses Qwen's standalone archive when available and falls back to a user-owned npm install under `~/.local`.

> [!NOTE]
> Qwen Code can also be configured interactively with `qwen` and `/auth`. Use `model`, `base_url`, `api_key_env_var`, `api_key`, and `generation_config` when you want workspaces to come up preconfigured from template variables.

## Examples

### Standalone mode with a launcher app

```tf
locals {
  qwen_workdir = "/home/coder/project"
}

module "qwen-code" {
  source   = "registry.coder.com/mayzyo/qwen-code/coder"
  version  = "1.0.0"
  agent_id = coder_agent.main.id
  workdir  = local.qwen_workdir
  api_key  = var.dashscope_api_key
}

resource "coder_app" "qwen" {
  agent_id     = coder_agent.main.id
  slug         = "qwen"
  display_name = "Qwen Code"
  icon         = "/icon/qwen-code.svg"
  open_in      = "slim-window"
  command      = <<-EOT
    #!/bin/bash
    set -e
    cd ${local.qwen_workdir}
    qwen
  EOT
}
```

### Custom OpenAI-compatible endpoint

Configure Qwen Code for any OpenAI-compatible endpoint by passing the provider values through module inputs.

```tf
module "qwen-code" {
  source          = "registry.coder.com/mayzyo/qwen-code/coder"
  version         = "1.0.0"
  agent_id        = coder_agent.main.id
  model           = "qwen/qwen3-coder"
  base_url        = "https://openrouter.ai/api/v1"
  api_key_env_var = "OPENROUTER_API_KEY"
  api_key         = var.openrouter_api_key

  generation_config = {
    contextWindowSize = 262144
  }
}
```

Qwen Code requires an `envKey` for model providers. For local endpoints without authentication, pass a harmless placeholder value such as `ollama` or `not-needed` as `api_key`; it is still kept out of `settings.json`.

### Full settings override

For advanced provider, model, or security configuration, pass the full Qwen settings object. Keep secrets in environment variables, not inside the settings object.

```tf
module "qwen-code" {
  source   = "registry.coder.com/mayzyo/qwen-code/coder"
  version  = "1.0.0"
  agent_id = coder_agent.main.id
  api_key  = var.openrouter_api_key

  api_key_env_var = "OPENROUTER_API_KEY"
  settings = {
    modelProviders = {
      openai = [{
        id      = "qwen/qwen3-coder"
        name    = "Qwen3 Coder"
        envKey  = "OPENROUTER_API_KEY"
        baseUrl = "https://openrouter.ai/api/v1"
      }]
    }
    security = {
      auth = {
        selectedType = "openai"
      }
    }
    model = {
      name = "qwen/qwen3-coder"
    }
  }
}
```

### Installer customization

```tf
module "qwen-code" {
  source   = "registry.coder.com/mayzyo/qwen-code/coder"
  version  = "1.0.0"
  agent_id = coder_agent.main.id

  install_method    = "standalone"
  qwen_code_version = "0.0.11"
  install_mirror    = "aliyun"
  install_source    = "internal-template"
}
```

## Troubleshooting

The module uses `coder-utils`, so install logs and materialized scripts are under `~/.coder-modules/mayzyo/qwen-code/`.

```bash
cat ~/.coder-modules/mayzyo/qwen-code/logs/install.log
cat ~/.coder-modules/mayzyo/qwen-code/scripts/install.sh
```

## References

- [Qwen Code GitHub repository](https://github.com/QwenLM/qwen-code)
- [Qwen Code quickstart](https://qwenlm.github.io/qwen-code-docs/en/users/quickstart/)
