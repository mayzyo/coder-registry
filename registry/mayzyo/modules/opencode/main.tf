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
  default     = "https://raw.githubusercontent.com/mayzyo/coder-registry/main/registry/mayzyo/.images/opencode.svg"
}

variable "workdir" {
  description = "Optional project directory to create before users start OpenCode."
  type        = string
  default     = null
}

variable "pre_install_script" {
  description = "Custom script to run before installing OpenCode."
  type        = string
  default     = null
}

variable "post_install_script" {
  description = "Custom script to run after installing and configuring OpenCode."
  type        = string
  default     = null
}

variable "install_opencode" {
  description = "Whether to install OpenCode."
  type        = bool
  default     = true
}

variable "opencode_version" {
  description = "The OpenCode version to install. Use latest or a semver string."
  type        = string
  default     = "latest"

  validation {
    condition     = var.opencode_version == "latest" || can(regex("^v?[0-9]+\\.[0-9]+\\.[0-9]+([.-][A-Za-z0-9]+)*$", var.opencode_version))
    error_message = "opencode_version must be latest or a semver string."
  }
}

variable "opencode_config" {
  description = "Complete OpenCode JSON/JSONC config to write to ~/.config/opencode/opencode.jsonc. When empty, a default Open WebUI provider config is generated."
  type        = string
  default     = ""
}

variable "openwebui_api_key" {
  description = "Optional API key for the Open WebUI endpoint. When set, it is injected into the default config as options.apiKey using {env:OPENWEBUI_API_KEY} and exposed to the agent through OPENWEBUI_API_KEY."
  type        = string
  default     = ""
  sensitive   = true
}

resource "coder_env" "openwebui_api_key" {
  count    = var.openwebui_api_key != "" ? 1 : 0
  agent_id = var.agent_id
  name     = "OPENWEBUI_API_KEY"
  value    = var.openwebui_api_key
}

locals {
  module_directory = "$HOME/.coder-modules/mayzyo/opencode"
  workdir          = var.workdir != null ? trimsuffix(var.workdir, "/") : ""

  openwebui_base_url = "http://openwebui.time-emoji-services/api"

  openwebui_options = var.openwebui_api_key != "" ? {
    baseURL = local.openwebui_base_url
    apiKey  = "{env:OPENWEBUI_API_KEY}"
    } : {
    baseURL = local.openwebui_base_url
  }

  default_opencode_config = {
    "$schema" = "https://opencode.ai/config.json"
    provider = {
      openwebui = {
        npm     = "@ai-sdk/openai-compatible"
        name    = "Open WebUI"
        options = local.openwebui_options
        models = {
          "local"               = { name = "Qwen 3.8 Flash" }
          "glm-5.3"             = { name = "GLM 5.3" }
          "deepseek-v4.1-flash" = { name = "Deepseek V4.1 Flash" }
        }
      }
    }
    small_model = "openwebui/local"
    agent = {
      build      = { model = "openwebui/deepseek-v4.1-flash" }
      plan       = { model = "openwebui/glm-5.3" }
      general    = { model = "openwebui/deepseek-v4.1-flash", steps = 25 }
      explore    = { model = "openwebui/local" }
      scout      = { model = "openwebui/local" }
      compaction = { model = "openwebui/local" }
      title      = { model = "openwebui/local" }
      summary    = { model = "openwebui/local" }
    }
  }

  opencode_config_json = var.opencode_config != "" ? var.opencode_config : jsonencode(local.default_opencode_config)

  install_script = templatefile("${path.module}/scripts/install.sh.tftpl", {
    ARG_INSTALL_OPENCODE = tostring(var.install_opencode)
    ARG_OPENCODE_VERSION = var.opencode_version
    ARG_WORKDIR          = base64encode(local.workdir)
    ARG_OPENCODE_CONFIG  = base64encode(local.opencode_config_json)
  })
}

module "coder_utils" {
  source  = "registry.coder.com/coder/coder-utils/coder"
  version = "0.0.1"

  agent_id            = var.agent_id
  module_directory    = local.module_directory
  display_name_prefix = "OpenCode"
  icon                = var.icon
  pre_install_script  = var.pre_install_script
  install_script      = local.install_script
  post_install_script = var.post_install_script
}

output "scripts" {
  description = "Ordered list of coder exp sync names produced by this module, in run order."
  value       = module.coder_utils.scripts
}