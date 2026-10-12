terraform {
  required_version = ">= 1.9"

  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">= 2.13"
    }
  }
}

# Shared, optional AI integrations used by every mayzyo AI assistant module.
# An integration is enabled automatically when its credential is provided.
# Credentials are exposed to the agent as environment variables, and each
# consuming module renders the enabled integrations into its own config format.

variable "agent_id" {
  description = "The ID of a Coder agent. Used when create_env is true."
  type        = string
}

variable "create_env" {
  description = "Whether to expose the provided credentials as agent environment variables. Set false when an umbrella module already creates them."
  type        = bool
  default     = true
}

variable "exa_api_key" {
  description = "Exa API key. When set, the Exa search integration is enabled and exposed as EXA_API_KEY."
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_token" {
  description = "GitHub token. When set, the GitHub integration is enabled and exposed as GITHUB_PERSONAL_ACCESS_TOKEN."
  type        = string
  default     = ""
  sensitive   = true
}

variable "context7_api_key" {
  description = "Context7 API key. When set, the Context7 documentation integration is enabled and exposed as CONTEXT7_API_KEY."
  type        = string
  default     = ""
  sensitive   = true
}

resource "coder_env" "exa_api_key" {
  count    = var.create_env && var.exa_api_key != "" ? 1 : 0
  agent_id = var.agent_id
  name     = "EXA_API_KEY"
  value    = var.exa_api_key
}

resource "coder_env" "github_token" {
  count    = var.create_env && var.github_token != "" ? 1 : 0
  agent_id = var.agent_id
  name     = "GITHUB_PERSONAL_ACCESS_TOKEN"
  value    = var.github_token
}

resource "coder_env" "context7_api_key" {
  count    = var.create_env && var.context7_api_key != "" ? 1 : 0
  agent_id = var.agent_id
  name     = "CONTEXT7_API_KEY"
  value    = var.context7_api_key
}

locals {
  enabled = {
    exa      = nonsensitive(var.exa_api_key) != ""
    github   = nonsensitive(var.github_token) != ""
    context7 = nonsensitive(var.context7_api_key) != ""
  }

  urls = {
    exa      = "https://mcp.exa.ai/mcp"
    github   = "https://api.githubcopilot.com/mcp/"
    context7 = "https://mcp.context7.com/mcp"
  }

  # OpenCode V2 mcp.servers entries. Secrets are referenced with {env:...}, so
  # no credentials are written to the config file.
  opencode_servers = merge(
    local.enabled.exa ? {
      exa = {
        type    = "remote"
        url     = local.urls.exa
        oauth   = false
        headers = { "x-api-key" = "{env:EXA_API_KEY}" }
      }
    } : {},
    local.enabled.github ? {
      github = {
        type    = "remote"
        url     = local.urls.github
        oauth   = false
        headers = { Authorization = "Bearer {env:GITHUB_PERSONAL_ACCESS_TOKEN}" }
      }
    } : {},
    local.enabled.context7 ? {
      context7 = {
        type    = "remote"
        url     = local.urls.context7
        oauth   = false
        headers = { Authorization = "Bearer {env:CONTEXT7_API_KEY}" }
      }
    } : {},
  )

  # Qwen Code (Gemini-based) mcpServers entries. Qwen Code expands $VAR/${VAR}
  # in settings strings from the process environment, so secrets stay on disk
  # only as environment variable references.
  qwen_servers = merge(
    local.enabled.exa ? {
      exa = {
        httpUrl = local.urls.exa
        headers = { "x-api-key" = "$${EXA_API_KEY}" }
      }
    } : {},
    local.enabled.github ? {
      github = {
        httpUrl = local.urls.github
        headers = { Authorization = "Bearer $${GITHUB_PERSONAL_ACCESS_TOKEN}" }
      }
    } : {},
    local.enabled.context7 ? {
      context7 = {
        httpUrl = local.urls.context7
        headers = { Authorization = "Bearer $${CONTEXT7_API_KEY}" }
      }
    } : {},
  )
}

output "integrations" {
  description = "Names of the enabled integrations, in a stable order."
  value = compact([
    local.enabled.exa ? "exa" : "",
    local.enabled.github ? "github" : "",
    local.enabled.context7 ? "context7" : "",
  ])
}

output "enabled" {
  description = "Map of integration name to whether it is enabled by a provided credential."
  value       = local.enabled
}

output "opencode_mcp" {
  description = "Enabled integrations as OpenCode V2 mcp.servers entries. Secrets use {env:...} substitution."
  value       = local.opencode_servers
}

output "qwen_mcp" {
  description = "Enabled integrations as Qwen Code mcpServers entries. Secrets use $VAR substitution."
  value       = local.qwen_servers
}
