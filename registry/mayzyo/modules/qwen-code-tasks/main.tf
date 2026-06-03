terraform {
  required_version = ">= 1.9"

  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">= 2.13"
    }
  }
}

variable "agent_id" {
  description = "The ID of a Coder agent."
  type        = string
}

variable "workdir" {
  description = "Project directory where Qwen Code runs."
  type        = string
  default     = "/home/coder/project"
}

variable "icon" {
  description = "The icon to use for the Qwen Code task app."
  type        = string
  default     = "https://raw.githubusercontent.com/mayzyo/coder-registry/main/registry/mayzyo/.images/qwen-code.svg"
}

variable "order" {
  description = "Display order for the Qwen Code task app."
  type        = number
  default     = null
}

variable "group" {
  description = "Workspace app group for Qwen Code."
  type        = string
  default     = null
}

variable "app_slug" {
  description = "Slug for the Qwen Code task app."
  type        = string
  default     = "qwen-code"

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.app_slug))
    error_message = "app_slug must contain lowercase letters, numbers, and single hyphens between words."
  }
}

variable "qwen_api_key" {
  description = "API key exposed to Qwen Code through qwen_api_key_env_var. Use a placeholder for endpoints that do not require one."
  type        = string
  default     = "not-needed"
  sensitive   = true
}

variable "qwen_api_key_env_var" {
  description = "Environment variable name Qwen Code should read for the API key."
  type        = string
  default     = "QWEN_API_KEY"

  validation {
    condition     = can(regex("^[A-Za-z_][A-Za-z0-9_]*$", var.qwen_api_key_env_var))
    error_message = "qwen_api_key_env_var must be a valid environment variable name."
  }
}

variable "qwen_model" {
  description = "Qwen model name used by the generated OpenAI-compatible provider."
  type        = string
  default     = "qwen-3-next-coder"
}

variable "qwen_base_url" {
  description = "OpenAI-compatible provider base URL."
  type        = string
  default     = "http://host.docker.internal:11434/v1"
}

variable "qwen_settings" {
  description = "Optional complete Qwen Code settings object. Coder MCP is merged in by default."
  type        = any
  default     = null
}

variable "enable_coder_mcp" {
  description = "Whether to configure Coder's MCP server for task status and timeline reporting."
  type        = bool
  default     = true
}

variable "task_prompt" {
  description = "Task prompt passed to Qwen Code headless mode."
  type        = string
  default     = ""
}

variable "task_system_prompt" {
  description = "System instruction passed to Qwen Code headless mode."
  type        = string
  default     = "You are Qwen Code running inside a Coder workspace. Every step of the way, report task progress to Coder with clear descriptions and statuses. Inspect the repository first, make the smallest safe plan, preserve existing conventions, verify changes, and finish with a concise summary of changed files and checks run."
}

variable "install_qwen_code" {
  description = "Whether to install Qwen Code through the qwen-code module."
  type        = bool
  default     = true
}

variable "qwen_code_version" {
  description = "The Qwen Code version to install."
  type        = string
  default     = "latest"
}

variable "install_agentapi" {
  description = "Whether to install AgentAPI for web UI and task automation."
  type        = bool
  default     = true
}

variable "agentapi_version" {
  description = "The AgentAPI version to install."
  type        = string
  default     = "v0.12.2"
}

variable "agentapi_port" {
  description = "Port used by AgentAPI."
  type        = number
  default     = 3285
}

variable "agentapi_subdomain" {
  description = "Whether the AgentAPI web app uses a subdomain."
  type        = bool
  default     = true
}

variable "enable_state_persistence" {
  description = "Whether AgentAPI should save and restore Qwen Code chat state across workspace restarts."
  type        = bool
  default     = true
}

variable "pre_install_script" {
  description = "Custom script to run before installing Qwen Code."
  type        = string
  default     = null
}

variable "post_install_script" {
  description = "Custom script to run after installing and configuring Qwen Code."
  type        = string
  default     = null
}

locals {
  qwen_settings = {
    modelProviders = {
      openai = [{
        id      = var.qwen_model
        name    = var.qwen_model
        baseUrl = var.qwen_base_url
        envKey  = var.qwen_api_key_env_var
      }]
    }
    security = {
      auth = {
        selectedType = "openai"
      }
    }
    model = {
      name = var.qwen_model
    }
    telemetry = {
      enabled = false
    }
    privacy = {
      usageStatisticsEnabled = false
    }
  }

  coder_mcp_server = {
    command = "coder"
    args    = ["exp", "mcp", "server"]
    env = {
      CODER_MCP_APP_STATUS_SLUG = var.app_slug
      CODER_MCP_AI_AGENTAPI_URL = "http://localhost:${var.agentapi_port}"
    }
  }

  base_settings = var.qwen_settings != null ? var.qwen_settings : local.qwen_settings
  settings = var.enable_coder_mcp ? merge(
    local.base_settings,
    {
      mcpServers = merge(
        try(local.base_settings.mcpServers, {}),
        { coder = local.coder_mcp_server },
      )
    },
  ) : local.base_settings

  agentapi_start_script = <<-EOT
    #!/bin/bash
    set -o errexit
    set -o pipefail

    AGENTAPI_PORT="$${2:-${var.agentapi_port}}"
    TASK_PROMPT=$(echo -n '${base64encode(var.task_prompt)}' | base64 -d)
    TASK_SYSTEM_PROMPT=$(echo -n '${base64encode(var.task_system_prompt)}' | base64 -d)

    if [ -f "$HOME/.bashrc" ]; then
      source "$HOME/.bashrc"
    fi

    if [ -s "$HOME/.nvm/nvm.sh" ]; then
      source "$HOME/.nvm/nvm.sh"
    fi

    if command -v npm > /dev/null 2>&1; then
      npm_prefix=$(npm config get prefix 2> /dev/null || true)
      if [ -n "$npm_prefix" ]; then
        export PATH="$npm_prefix/bin:$PATH"
      fi
    fi

    export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"

    if ! command -v qwen > /dev/null 2>&1; then
      echo "Error: qwen is not installed or not on PATH."
      exit 1
    fi

    printf "Qwen Code version: %s\n" "$(qwen --version 2> /dev/null || echo unknown)"
    if [ -n "$TASK_PROMPT" ]; then
      agentapi server --port "$AGENTAPI_PORT" --term-width 67 --term-height 1190 -- qwen --system-prompt "$TASK_SYSTEM_PROMPT" --prompt "$TASK_PROMPT"
    else
      agentapi server --port "$AGENTAPI_PORT" --term-width 67 --term-height 1190 -- qwen
    fi
  EOT
}

module "qwen_code" {
  source = "../qwen-code"

  agent_id             = var.agent_id
  icon                 = var.icon
  workdir              = var.workdir
  pre_install_script   = var.pre_install_script
  post_install_script  = var.post_install_script
  install_qwen_code    = var.install_qwen_code
  qwen_code_version    = var.qwen_code_version
  qwen_api_key         = var.qwen_api_key
  qwen_api_key_env_var = var.qwen_api_key_env_var
  qwen_settings        = local.settings
}

module "agentapi" {
  source  = "registry.coder.com/coder/agentapi/coder"
  version = "2.4.0"

  agent_id                 = var.agent_id
  folder                   = var.workdir
  web_app_slug             = var.app_slug
  web_app_order            = var.order
  web_app_group            = var.group
  web_app_icon             = var.icon
  web_app_display_name     = "Qwen Code"
  cli_app_slug             = "${var.app_slug}-cli"
  cli_app_display_name     = "Qwen Code CLI"
  module_dir_name          = ".coder-modules/mayzyo/qwen-code-tasks"
  install_agentapi         = var.install_agentapi
  agentapi_version         = var.agentapi_version
  agentapi_port            = var.agentapi_port
  agentapi_subdomain       = var.agentapi_subdomain
  enable_state_persistence = var.enable_state_persistence
  install_script           = <<-EOT
    #!/bin/bash
    set -o errexit
    set -o pipefail

    trap 'coder exp sync complete mayzyo-qwen-code-agentapi' EXIT
    coder exp sync want mayzyo-qwen-code-agentapi ${join(" ", module.qwen_code.scripts)}
    coder exp sync start mayzyo-qwen-code-agentapi
  EOT
  start_script             = local.agentapi_start_script
}

output "task_app_id" {
  description = "ID of the AgentAPI web app for coder_ai_task."
  value       = module.agentapi.task_app_id
}

output "scripts" {
  description = "Ordered list of coder exp sync names produced by the wrapped qwen-code module."
  value       = module.qwen_code.scripts
}
