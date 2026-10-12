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
  description = "Working directory for AI coding assistants and apps."
  type        = string
  default     = null
}

variable "anthropic_api_key" {
  description = "Anthropic API key for Claude Code."
  type        = string
  default     = "xxxx-xxxxx-xxxx"
  sensitive   = true
}

variable "anthropic_base_url" {
  description = "Base URL for Anthropic proxy or endpoint."
  type        = string
  default     = "http://192.168.133.51:7821"
}

variable "bailian_api_key" {
  description = "Alibaba BaiLian Provider key used for Qwen models."
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_pat" {
  description = "GitHub Personal Access Token used for the GitHub MCP integration."
  type        = string
  default     = ""
  sensitive   = true
}

variable "exa_api_key" {
  description = "Exa API key used for the Exa search integration."
  type        = string
  default     = ""
  sensitive   = true
}

variable "context7_api_key" {
  description = "Context7 API key used for the Context7 documentation MCP integration."
  type        = string
  default     = ""
  sensitive   = true
}

variable "openwebui_api_key" {
  description = "Optional API key for the Open WebUI endpoint used by OpenCode."
  type        = string
  default     = ""
  sensitive   = true
}

variable "openwebui_base_url" {
  description = "Open WebUI OpenAI-compatible base URL used for the local Qwen model."
  type        = string
  default     = "http://open-webui.time-emoji-services/api"
}

# --- Coder Parameters for AI Assistants ---
data "coder_parameter" "run_codex" {
  name         = "run_codex"
  display_name = "Run Codex CLI"
  icon         = "/icon/openai.svg"
  type         = "bool"
  mutable      = true
  description  = "Pre-install and run Codex CLI?"
  default      = false
}

data "coder_parameter" "run_claude_code" {
  name         = "run_claude_code"
  display_name = "Run Claude Code"
  icon         = "/icon/claude.svg"
  type         = "bool"
  mutable      = true
  description  = "Pre-install and run Claude Code?"
  default      = false
}

data "coder_parameter" "run_qwen_code" {
  name         = "run_qwen_code"
  display_name = "Run Qwen Code"
  icon         = "https://raw.githubusercontent.com/mayzyo/coder-registry/main/registry/mayzyo/.images/qwen-code.svg"
  type         = "bool"
  mutable      = true
  description  = "Pre-install and run Qwen Code?"
  default      = false
}

data "coder_parameter" "run_antigravity" {
  name         = "run_antigravity"
  display_name = "Run Antigravity CLI"
  icon         = "https://raw.githubusercontent.com/mayzyo/coder-registry/main/registry/mayzyo/.images/antigravity-cli.svg"
  type         = "bool"
  mutable      = true
  description  = "Pre-install and run Antigravity CLI?"
  default      = false
}

data "coder_parameter" "run_opencode" {
  name         = "run_opencode"
  display_name = "Run OpenCode"
  icon         = "https://raw.githubusercontent.com/mayzyo/coder-registry/main/registry/mayzyo/.images/opencode.svg"
  type         = "bool"
  mutable      = true
  description  = "Pre-install and run OpenCode?"
  default      = false
}

data "coder_workspace" "me" {}

locals {
  workdir_cmd = var.workdir != null && var.workdir != "" ? "cd \"${var.workdir}\"\n" : ""
}

# Create the shared integration environment variables once for the whole
# workspace. The wrapped assistant modules render their own config entries and
# skip env creation so the variables are not duplicated.
module "ai_integrations" {
  source  = "registry.coder.com/mayzyo/ai-integrations/coder"
  version = "0.1.0"

  agent_id         = var.agent_id
  exa_api_key      = var.exa_api_key
  github_token     = var.github_pat
  context7_api_key = var.context7_api_key
}

# --- Codex CLI ---
module "codex" {
  count    = data.coder_parameter.run_codex.value ? data.coder_workspace.me.start_count : 0
  source   = "registry.coder.com/coder-labs/codex/coder"
  version  = "5.3.2"
  agent_id = var.agent_id
  workdir  = var.workdir
}

resource "coder_app" "codex" {
  count        = data.coder_parameter.run_codex.value ? data.coder_workspace.me.start_count : 0
  agent_id     = var.agent_id
  slug         = "codex"
  display_name = "Codex"
  icon         = "/icon/openai.svg"
  open_in      = "slim-window"
  command      = <<-EOT
    #!/bin/bash
    set -e
    ${local.workdir_cmd}codex
  EOT
}

# --- Claude Code ---
module "claude_code" {
  count             = data.coder_parameter.run_claude_code.value ? data.coder_workspace.me.start_count : 0
  source            = "registry.coder.com/coder/claude-code/coder"
  version           = "5.4.1"
  agent_id          = var.agent_id
  workdir           = var.workdir
  anthropic_api_key = var.anthropic_api_key
}

resource "coder_env" "anthropic_base_url" {
  count    = data.coder_parameter.run_claude_code.value && var.anthropic_base_url != "" ? 1 : 0
  agent_id = var.agent_id
  name     = "ANTHROPIC_BASE_URL"
  value    = var.anthropic_base_url
}

resource "coder_app" "claude" {
  count        = data.coder_parameter.run_claude_code.value ? data.coder_workspace.me.start_count : 0
  agent_id     = var.agent_id
  slug         = "claude"
  display_name = "Claude Code"
  icon         = "/icon/claude.svg"
  open_in      = "slim-window"
  command      = <<-EOT
    #!/bin/bash
    set -e
    ${local.workdir_cmd}claude
  EOT
}

# --- Qwen Code ---
module "qwen_code" {
  count    = data.coder_parameter.run_qwen_code.value ? data.coder_workspace.me.start_count : 0
  source   = "registry.coder.com/mayzyo/qwen-code/coder"
  version  = "1.1.0"
  agent_id = var.agent_id
  workdir  = var.workdir

  qwen_settings = {
    "$version" = 4
    telemetry = {
      enabled = false
    }
    privacy = {
      usageStatisticsEnabled = false
    }
    env = {
      OPENWEBUI_API_KEY = var.openwebui_api_key
      BAILIAN_API_KEY   = var.bailian_api_key
    }
    modelProviders = {
      openai = [
        {
          id      = "local"
          name    = "Qwen 3.8 Flash Next"
          baseUrl = var.openwebui_base_url
          envKey  = "OPENWEBUI_API_KEY"
        },
        {
          id      = "qwen3.7-max"
          name    = "Qwen 3.7 Max"
          baseUrl = "https://dashscope.aliyuncs.com/compatible-mode/v1"
          envKey  = "BAILIAN_API_KEY"
        },
        {
          id      = "qwen3.7-plus"
          name    = "Qwen 3.7 Plus"
          baseUrl = "https://dashscope.aliyuncs.com/compatible-mode/v1"
          envKey  = "BAILIAN_API_KEY"
        },
        {
          id      = "kimi-k2.6"
          name    = "Kimi K2.6"
          baseUrl = "https://dashscope.aliyuncs.com/compatible-mode/v1"
          envKey  = "BAILIAN_API_KEY"
        },
        {
          id      = "MiniMax-M2.5"
          name    = "MiniMax M2.5"
          baseUrl = "https://dashscope.aliyuncs.com/compatible-mode/v1"
          envKey  = "BAILIAN_API_KEY"
        },
        {
          id      = "deepseek-v4-pro"
          name    = "Deepseek v4 Pro"
          baseUrl = "https://dashscope.aliyuncs.com/compatible-mode/v1"
          envKey  = "BAILIAN_API_KEY"
        }
      ]
    }
    security = {
      auth = {
        selectedType = "openai"
      }
    }
    model = {
      name = "local"
    }
    permissions = {
      allow = [
        "Edit",
        "Write",
        "Agent",
        "Bash(which *)",
        "Bash(find *)",
        "Bash(rm *)",
        "Bash(sed *)",
        "Bash(grep *)",
        "Bash(/test *)",
        "Bash(cat *)",
        "Bash(mkdir *)",
      ]
    }
  }

  # The Exa, GitHub, and Context7 MCP servers are merged into these settings by
  # the qwen-code module from the credentials below.
  exa_api_key            = var.exa_api_key
  github_token           = var.github_pat
  context7_api_key       = var.context7_api_key
  create_integration_env = false
}

resource "coder_app" "qwen_code" {
  count        = data.coder_parameter.run_qwen_code.value ? data.coder_workspace.me.start_count : 0
  agent_id     = var.agent_id
  slug         = "qwen"
  display_name = "Qwen Code"
  icon         = "https://raw.githubusercontent.com/mayzyo/coder-registry/main/registry/mayzyo/.images/qwen-code.svg"
  open_in      = "slim-window"
  command      = <<-EOT
    #!/bin/bash
    set -e
    ${local.workdir_cmd}qwen
  EOT
}

# --- Antigravity CLI ---
module "antigravity" {
  count    = data.coder_parameter.run_antigravity.value ? data.coder_workspace.me.start_count : 0
  source   = "registry.coder.com/mayzyo/antigravity-cli/coder"
  version  = "0.1.2"
  agent_id = var.agent_id
  workdir  = var.workdir
}

resource "coder_app" "antigravity" {
  count        = data.coder_parameter.run_antigravity.value ? data.coder_workspace.me.start_count : 0
  agent_id     = var.agent_id
  slug         = "antigravity"
  display_name = "Antigravity CLI"
  icon         = "https://raw.githubusercontent.com/mayzyo/coder-registry/main/registry/mayzyo/.images/antigravity-cli.svg"
  open_in      = "slim-window"
  command      = <<-EOT
    #!/bin/bash
    set -e
    ${local.workdir_cmd}agy
  EOT
}

# --- OpenCode ---
module "opencode" {
  count              = data.coder_parameter.run_opencode.value ? data.coder_workspace.me.start_count : 0
  source             = "registry.coder.com/mayzyo/opencode/coder"
  version            = "2.1.0"
  agent_id           = var.agent_id
  workdir            = var.workdir
  openwebui_api_key  = var.openwebui_api_key
  openwebui_base_url = var.openwebui_base_url

  exa_api_key            = var.exa_api_key
  github_token           = var.github_pat
  context7_api_key       = var.context7_api_key
  create_integration_env = false
}

resource "coder_app" "opencode" {
  count        = data.coder_parameter.run_opencode.value ? data.coder_workspace.me.start_count : 0
  agent_id     = var.agent_id
  slug         = "opencode"
  display_name = "OpenCode"
  icon         = "https://raw.githubusercontent.com/mayzyo/coder-registry/main/registry/mayzyo/.images/opencode.svg"
  open_in      = "slim-window"
  command      = <<-EOT
    #!/bin/bash
    set -e
    export PATH="$HOME/.opencode/bin:$PATH"
    ${local.workdir_cmd}opencode
  EOT
}
