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
  default     = "https://raw.githubusercontent.com/mayzyo/coder-registry/main/registry/mayzyo/.images/antigravity-cli.svg"
}

variable "workdir" {
  description = "Optional project directory to create before users start Antigravity CLI."
  type        = string
  default     = null
}

variable "pre_install_script" {
  description = "Custom script to run before installing Antigravity CLI."
  type        = string
  default     = null
}

variable "post_install_script" {
  description = "Custom script to run after installing and configuring Antigravity CLI."
  type        = string
  default     = null
}

variable "install_antigravity" {
  description = "Whether to install Antigravity CLI."
  type        = bool
  default     = true
}

variable "antigravity_binary_path" {
  description = "Directory containing agy when install_antigravity is false. The official installer writes agy to $HOME/.local/bin."
  type        = string
  default     = "$HOME/.local/bin"

  validation {
    condition     = var.antigravity_binary_path == "$HOME/.local/bin" || !var.install_antigravity
    error_message = "Custom antigravity_binary_path can only be used when install_antigravity is false. The official installer installs to $HOME/.local/bin."
  }
}

variable "configure_settings" {
  description = "Whether to write ~/.gemini/antigravity-cli/settings.json."
  type        = bool
  default     = true
}

variable "enable_terminal_sandbox" {
  description = "Whether to enable Antigravity CLI terminal sandboxing in generated settings."
  type        = bool
  default     = true
}

variable "antigravity_settings" {
  description = "Complete Antigravity CLI settings object to merge into ~/.gemini/antigravity-cli/settings.json."
  type        = any
  default     = null
}

variable "mcp" {
  description = "JSON-encoded MCP server configuration written to ~/.gemini/antigravity-cli/mcp_config.json."
  type        = string
  default     = ""
}

locals {
  module_directory = "$HOME/.coder-modules/mayzyo/antigravity-cli"
  workdir          = var.workdir != null ? trimsuffix(var.workdir, "/") : ""

  generated_settings = merge(
    var.antigravity_settings != null ? var.antigravity_settings : {},
    {
      enableTerminalSandbox = var.enable_terminal_sandbox
    },
  )

  settings_json = var.configure_settings ? jsonencode(local.generated_settings) : ""

  install_script = templatefile("${path.module}/scripts/install.sh.tftpl", {
    ARG_INSTALL_ANTIGRAVITY     = tostring(var.install_antigravity)
    ARG_ANTIGRAVITY_BINARY_PATH = base64encode(var.antigravity_binary_path)
    ARG_WORKDIR                 = base64encode(local.workdir)
    ARG_SETTINGS_JSON           = local.settings_json != "" ? base64encode(local.settings_json) : ""
    ARG_MCP                     = var.mcp != "" ? base64encode(var.mcp) : ""
  })
}

module "coder_utils" {
  source  = "registry.coder.com/coder/coder-utils/coder"
  version = "0.0.1"

  agent_id            = var.agent_id
  module_directory    = local.module_directory
  display_name_prefix = "Antigravity CLI"
  icon                = var.icon
  pre_install_script  = var.pre_install_script
  install_script      = local.install_script
  post_install_script = var.post_install_script
}

output "scripts" {
  description = "Ordered list of coder exp sync names produced by this module, in run order."
  value       = module.coder_utils.scripts
}

output "binary_path" {
  description = "Full path to the agy binary."
  value       = "${var.antigravity_binary_path}/agy"
}
