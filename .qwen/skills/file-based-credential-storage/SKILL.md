---
name: file-based-credential-storage
description: Configure CLI tools to use file-based credential storage instead of OS keychain or OAuth-only
source: auto-skill
extracted_at: '2026-06-05'
---

# File-Based Credential Storage for CLI Tools

When configuring CLI tools (like Codex CLI) that support multiple authentication methods, use file-based credential storage instead of OS keychain or OAuth-only approaches. This is especially important for headless/SSH environments.

## Pattern

**Instead of hardcoding OAuth-only or keychain-based auth:**
```toml
preferred_auth_method = "oauth"
cli_auth_credentials_store = "keychain"  # Fails in headless environments
```

**Use file-based storage with auto-detection:**
```toml
cli_auth_credentials_store = "file"
mcp_oauth_credentials_store_mode = "file"
# Omit preferred_auth_method - let the tool auto-detect
```

## Implementation Steps

1. **Omit `preferred_auth_method` from default config** - Let the CLI tool auto-detect which method to use based on available credentials

2. **Seed credential files when variables are provided:**
   - If API key is provided → create `~/.codex/auth.json` with the key
   - If no API key → user runs `codex login` for OAuth

3. **Secure credential files:**
   ```bash
   chmod 600 "$${auth_path}"
   ```

4. **Use file-based storage for both CLI auth and MCP OAuth:**
   - CLI auth: `~/.codex/auth.json`
   - MCP OAuth: `~/.codex/mcp_oauth_credentials.json`

## Terraform Module Example

```tf
variable "openai_api_key" {
  type        = string
  description = "OpenAI API key for Codex CLI."
  sensitive   = true
  default     = ""
}

# In install script template:
function add_auth_json() {
  if [ "$${ARG_ENABLE_AI_GATEWAY}" = "true" ] || [ -z "$${ARG_OPENAI_API_KEY}" ]; then
    return
  fi

  local auth_path="$HOME/.codex/auth.json"
  mkdir -p "$(dirname "$${auth_path}")"

  cat << EOF > "$${auth_path}"
{
  "auth_mode": "apikey",
  "OPENAI_API_KEY": "$${ARG_OPENAI_API_KEY}"
}
EOF
  chmod 600 "$${auth_path}"
}
```

## Benefits

- **Headless-friendly**: Works in SSH/container environments without OS keychain
- **Flexible**: Supports both API key (seeded) and OAuth (user-run `codex login`)
- **Transparent**: Credentials stored in known file locations for troubleshooting
- **Secure**: Proper file permissions on credential files

## When to Apply

- Configuring CLI tools in workspace modules
- Supporting both API key and OAuth authentication
- Targeting headless/SSH/container environments
- Avoiding OS-specific keychain dependencies
