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

variable "icon" {
  description = "The icon to use for the install script. Use a built-in Coder /icon path or a full URL."
  type        = string
  default     = "https://raw.githubusercontent.com/mayzyo/coder-registry/main/registry/mayzyo/.images/qwen-code.svg"
}

variable "workdir" {
  description = "Optional project directory to create before users start Qwen Code."
  type        = string
  default     = null
}

variable "create_app" {
  description = "Whether to create a healthchecked AgentAPI web app for Qwen Code."
  type        = bool
  default     = true
}

variable "app_slug" {
  description = "Slug for the Qwen Code web app."
  type        = string
  default     = "qwen-code"

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.app_slug))
    error_message = "app_slug must contain lowercase letters, numbers, and single hyphens between words."
  }
}

variable "order" {
  description = "Display order for the Qwen Code web app."
  type        = number
  default     = null
}

variable "group" {
  description = "Workspace app group for Qwen Code."
  type        = string
  default     = null
}

variable "install_agentapi" {
  description = "Whether to install AgentAPI for the Qwen Code web app."
  type        = bool
  default     = true
}

variable "agentapi_version" {
  description = "AgentAPI version used by the Qwen Code web app."
  type        = string
  default     = "v0.12.2"
}

variable "agentapi_port" {
  description = "Port used by the Qwen Code AgentAPI web app."
  type        = number
  default     = 3285
}

variable "agentapi_subdomain" {
  description = "Whether the Qwen Code AgentAPI web app uses a subdomain."
  type        = bool
  default     = true
}

variable "enable_state_persistence" {
  description = "Whether AgentAPI should save and restore Qwen Code chat state across workspace restarts."
  type        = bool
  default     = true
}

variable "state_file_path" {
  description = "Optional AgentAPI state file path. Defaults to the Qwen Code AgentAPI module directory."
  type        = string
  default     = ""
}

variable "pid_file_path" {
  description = "Optional AgentAPI PID file path. Defaults to the Qwen Code AgentAPI module directory."
  type        = string
  default     = ""
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

variable "install_qwen_code" {
  description = "Whether to install Qwen Code."
  type        = bool
  default     = true
}

variable "qwen_code_version" {
  description = "The Qwen Code version to install. Use latest or a semver string. For npm installs this is used as the package version."
  type        = string
  default     = "latest"

  validation {
    condition     = var.qwen_code_version == "latest" || can(regex("^v?[0-9]+\\.[0-9]+\\.[0-9]+([.-][A-Za-z0-9]+)*$", var.qwen_code_version))
    error_message = "qwen_code_version must be latest or a semver string."
  }
}

variable "install_method" {
  description = "Install method: detect tries Qwen's standalone archive first and falls back to npm; standalone only uses the official archive; npm installs the npm package."
  type        = string
  default     = "detect"

  validation {
    condition     = contains(["detect", "standalone", "npm"], var.install_method)
    error_message = "install_method must be detect, standalone, or npm."
  }
}

variable "install_source" {
  description = "Source label recorded in ~/.qwen/source.json."
  type        = string
  default     = "coder-registry"

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]+$", var.install_source))
    error_message = "install_source may only contain letters, numbers, dot, underscore, or dash."
  }
}

variable "install_mirror" {
  description = "Standalone archive mirror to use with the official installer."
  type        = string
  default     = "github"

  validation {
    condition     = contains(["github", "aliyun"], var.install_mirror)
    error_message = "install_mirror must be github or aliyun."
  }
}

variable "install_base_url" {
  description = "Optional HTTPS base URL for standalone archive downloads."
  type        = string
  default     = ""

  validation {
    condition     = var.install_base_url == "" || startswith(var.install_base_url, "https://")
    error_message = "install_base_url must be empty or start with https://."
  }
}

variable "installer_url" {
  description = "HTTPS URL for Qwen Code's official installer script."
  type        = string
  default     = "https://raw.githubusercontent.com/QwenLM/qwen-code/main/scripts/installation/install-qwen-with-source.sh"

  validation {
    condition     = startswith(var.installer_url, "https://")
    error_message = "installer_url must start with https://."
  }
}

variable "npm_registry" {
  description = "npm registry used when installing via npm."
  type        = string
  default     = "https://registry.npmjs.org"

  validation {
    condition     = startswith(var.npm_registry, "https://")
    error_message = "npm_registry must start with https://."
  }
}

variable "install_root" {
  description = "User-owned root where Qwen Code standalone files and npm global packages are installed."
  type        = string
  default     = "$HOME/.local"
}

variable "qwen_binary_path" {
  description = "Directory containing qwen when install_qwen_code is false."
  type        = string
  default     = "$HOME/.local/bin"
}

variable "configure_settings" {
  description = "Whether to write ~/.qwen/settings.json."
  type        = bool
  default     = true
}

variable "qwen_settings" {
  description = "Complete Qwen Code settings object to write to ~/.qwen/settings.json. Prefer qwen_api_key for secrets instead of embedding them here."
  type        = any
  default     = null
}

variable "qwen_auth_type" {
  description = "Default Qwen Code auth protocol used when generating settings."
  type        = string
  default     = "openai"

  validation {
    condition     = contains(["openai", "anthropic", "gemini"], var.qwen_auth_type)
    error_message = "qwen_auth_type must be openai, anthropic, or gemini."
  }
}

variable "qwen_model" {
  description = "Default model name used when generating settings."
  type        = string
  default     = "qwen3.6-plus"
}

variable "qwen_model_display_name" {
  description = "Human-readable model name used when generating settings. Defaults to qwen_model."
  type        = string
  default     = ""
}

variable "qwen_base_url" {
  description = "Provider base URL used when generating settings. Leave empty for providers that do not need one."
  type        = string
  default     = "https://dashscope.aliyuncs.com/compatible-mode/v1"
}

variable "qwen_provider_description" {
  description = "Provider description used when generating settings."
  type        = string
  default     = "Qwen via Dashscope"
}

variable "qwen_api_key" {
  description = "API key exposed to Qwen Code through qwen_api_key_env_var."
  type        = string
  default     = ""
  sensitive   = true
}

variable "qwen_api_key_env_var" {
  description = "Environment variable name Qwen Code should read for the API key. For local providers without auth, set qwen_api_key to a harmless placeholder such as ollama."
  type        = string
  default     = "DASHSCOPE_API_KEY"

  validation {
    condition     = can(regex("^[A-Za-z_][A-Za-z0-9_]*$", var.qwen_api_key_env_var))
    error_message = "qwen_api_key_env_var must be a valid environment variable name."
  }
}

variable "qwen_generation_config" {
  description = "Optional generationConfig object included in the generated provider entry."
  type        = any
  default     = null
}

variable "enable_coder_mcp" {
  description = "Whether to configure Coder's MCP server for task status and timeline reporting."
  type        = bool
  default     = true
}

variable "task_prompt" {
  description = "Optional task prompt to run Qwen Code in headless mode through AgentAPI."
  type        = string
  default     = ""
}

variable "task_system_prompt" {
  description = "System instruction prepended to task_prompt so Qwen Code reports task status to Coder."
  type        = string
  default     = "Every step of the way, report tasks to Coder with proper descriptions and statuses."
}

variable "enable_telemetry" {
  description = "Whether to enable Qwen Code telemetry in generated settings."
  type        = bool
  default     = false
}

variable "enable_usage_statistics" {
  description = "Whether to enable Qwen Code usage statistics in generated settings."
  type        = bool
  default     = false
}

resource "coder_env" "qwen_api_key" {
  count    = var.qwen_api_key != "" && var.qwen_api_key_env_var != "" ? 1 : 0
  agent_id = var.agent_id
  name     = var.qwen_api_key_env_var
  value    = var.qwen_api_key
}

locals {
  module_directory = "$HOME/.coder-modules/mayzyo/qwen-code"
  workdir          = var.workdir != null ? trimsuffix(var.workdir, "/") : ""

  generated_provider = merge(
    {
      id   = var.qwen_model
      name = var.qwen_model_display_name != "" ? var.qwen_model_display_name : var.qwen_model
    },
    var.qwen_base_url != "" ? { baseUrl = var.qwen_base_url } : {},
    var.qwen_provider_description != "" ? { description = var.qwen_provider_description } : {},
    { envKey = var.qwen_api_key_env_var },
    var.qwen_generation_config != null ? { generationConfig = var.qwen_generation_config } : {},
  )

  generated_settings = {
    modelProviders = {
      (var.qwen_auth_type) = [local.generated_provider]
    }
    security = {
      auth = {
        selectedType = var.qwen_auth_type
      }
    }
    model = {
      name = var.qwen_model
    }
    telemetry = {
      enabled = var.enable_telemetry
    }
    privacy = {
      usageStatisticsEnabled = var.enable_usage_statistics
    }
  }

  coder_mcp_server = {
    command = "coder"
    args    = ["exp", "mcp", "server"]
    env = {
      CODER_MCP_APP_STATUS_SLUG  = var.app_slug
      CODER_MCP_AI_AGENTAPI_URL  = "http://localhost:${var.agentapi_port}"
    }
  }

  base_settings = var.qwen_settings != null ? var.qwen_settings : local.generated_settings
  settings_with_coder_mcp = var.enable_coder_mcp ? merge(
    local.base_settings,
    {
      mcpServers = merge(
        try(local.base_settings.mcpServers, {}),
        { coder = local.coder_mcp_server },
      )
    },
  ) : local.base_settings

  settings_json = var.configure_settings ? jsonencode(local.settings_with_coder_mcp) : ""

  agentapi_install_script = <<-EOT
    #!/bin/bash
    set -o errexit
    set -o pipefail

    trap 'coder exp sync complete mayzyo-qwen-code-agentapi' EXIT
    coder exp sync want mayzyo-qwen-code-agentapi ${join(" ", module.coder_utils.scripts)}
    coder exp sync start mayzyo-qwen-code-agentapi
  EOT

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

    export PATH="${var.install_root}/bin:${var.qwen_binary_path}:$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"

    if ! command -v qwen > /dev/null 2>&1; then
      echo "Error: qwen is not installed or not on PATH."
      exit 1
    fi

    printf "Qwen Code version: %s\n" "$(qwen --version 2> /dev/null || echo unknown)"
    if [ -n "$TASK_PROMPT" ]; then
      PROMPT="$TASK_SYSTEM_PROMPT Your task at hand: $TASK_PROMPT"
      agentapi server --port "$AGENTAPI_PORT" --term-width 67 --term-height 1190 -- qwen --prompt "$PROMPT"
    else
      agentapi server --port "$AGENTAPI_PORT" --term-width 67 --term-height 1190 -- qwen
    fi
  EOT

  install_script = templatefile("${path.module}/scripts/install.sh.tftpl", {
    ARG_INSTALL_QWEN_CODE  = tostring(var.install_qwen_code)
    ARG_INSTALL_METHOD     = var.install_method
    ARG_QWEN_CODE_VERSION  = var.qwen_code_version
    ARG_INSTALL_SOURCE     = var.install_source
    ARG_INSTALL_MIRROR     = var.install_mirror
    ARG_INSTALL_BASE_URL   = base64encode(var.install_base_url)
    ARG_INSTALLER_URL      = base64encode(var.installer_url)
    ARG_NPM_REGISTRY       = base64encode(var.npm_registry)
    ARG_INSTALL_ROOT       = base64encode(var.install_root)
    ARG_QWEN_BINARY_PATH   = base64encode(var.qwen_binary_path)
    ARG_WORKDIR            = base64encode(local.workdir)
    ARG_SETTINGS_JSON      = local.settings_json != "" ? base64encode(local.settings_json) : ""
    ARG_CONFIGURE_SETTINGS = tostring(var.configure_settings)
  })
}

module "coder_utils" {
  source  = "registry.coder.com/coder/coder-utils/coder"
  version = "0.0.1"

  agent_id            = var.agent_id
  module_directory    = local.module_directory
  display_name_prefix = "Qwen Code"
  icon                = var.icon
  pre_install_script  = var.pre_install_script
  install_script      = local.install_script
  post_install_script = var.post_install_script
}

module "agentapi" {
  count   = var.create_app ? 1 : 0
  source  = "registry.coder.com/coder/agentapi/coder"
  version = "2.4.0"

  agent_id                 = var.agent_id
  folder                   = local.workdir != "" ? local.workdir : "$HOME"
  web_app_slug             = var.app_slug
  web_app_order            = var.order
  web_app_group            = var.group
  web_app_icon             = var.icon
  web_app_display_name     = "Qwen Code"
  cli_app_slug             = "${var.app_slug}-cli"
  cli_app_display_name     = "Qwen Code CLI"
  module_dir_name          = ".coder-modules/mayzyo/qwen-code/agentapi"
  install_agentapi         = var.install_agentapi
  agentapi_version         = var.agentapi_version
  agentapi_port            = var.agentapi_port
  agentapi_subdomain       = var.agentapi_subdomain
  enable_state_persistence = var.enable_state_persistence
  state_file_path          = var.state_file_path
  pid_file_path            = var.pid_file_path
  install_script           = local.agentapi_install_script
  start_script             = local.agentapi_start_script
}

output "scripts" {
  description = "Ordered list of coder exp sync names produced by this module, in run order."
  value       = module.coder_utils.scripts
}

output "app_id" {
  description = "ID of the Qwen Code AgentAPI web app, or an empty string when create_app is false."
  value       = var.create_app ? module.agentapi[0].task_app_id : ""
}
