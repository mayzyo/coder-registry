# antigravity-cli module

New module created at `registry/mayzyo/modules/antigravity-cli/` for installing and configuring Google's Antigravity CLI (agy).

## Key Implementation Details

**Installation Method:**
- Uses official installer: `curl -fsSL https://antigravity.google/cli/install.sh | bash`
- Binary location: `~/.local/bin/agy`
- No Node.js/npm dependencies (unlike gemini-cli which uses npm)

**Configuration Files:**
- Settings: `~/.gemini/antigravity-cli/settings.json`
- Keybindings: `~/.gemini/antigravity-cli/keybindings.json`

**Module Variables:**
- `antigravity_api_key` - API key for authentication
- `enable_yolo_mode` - Auto-approve all tool calls
- `enable_sandbox` - Secure execution containment (default: true)
- `antigravity_model` - Default model selection
- `antigravity_settings_json` - Custom settings.json content
- `mcp` - MCP server configurations
- `antigravity_system_prompt` - System prompt for GEMINI.md
- `task_prompt` - Automated task execution prompt
- `folder` - Working directory
- `install_antigravity`, `antigravity_version`, `disable_autoupdater` - Version control
- `pre_install_script`, `post_install_script` - Custom scripts
- `antigravity_binary_path` - Custom binary path (when install disabled)

**Architecture:**
- Uses `coder-utils` module for script orchestration
- Follows same pattern as `coder/modules/claude-code`
- Install and start scripts as `.tftpl` templates
- Module directory: `$HOME/.coder-modules/mayzyo/antigravity-cli`
