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
  description = "The icon to use for the install script."
  type        = string
  default     = "/icon/qwen-code.svg"
}

variable "workdir" {
  description = "Optional project directory to create before users start Qwen Code."
  type        = string
  default     = null
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
  default     = "https://qwen-code-assets.oss-cn-hangzhou.aliyuncs.com/installation/install-qwen.sh"

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

  settings_json = var.configure_settings ? (var.qwen_settings != null ? jsonencode(var.qwen_settings) : jsonencode(local.generated_settings)) : ""

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

output "scripts" {
  description = "Ordered list of coder exp sync names produced by this module, in run order."
  value       = module.coder_utils.scripts
}
