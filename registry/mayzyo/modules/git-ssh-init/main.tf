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

variable "home_user" {
  description = "The username inside the container whose home directory is used (e.g. node, vscode)."
  type        = string
  default     = "vscode"
}

variable "default_git_host" {
  description = "Default SSH host used when shorthand repository names are provided (e.g. micha/signal-bus becomes git@<default_git_host>:micha/signal-bus)."
  type        = string
  default     = "gitea.time-emoji-services"
}

data "coder_parameter" "git_repo" {
  name         = "git_repo"
  display_name = "Git Repository"
  icon         = "/emojis/1f4e6.png"
  type         = "string"
  mutable      = false
  description  = "The project url of a git repository cloning address (e.g. micha/signal-bus). Defaults to gitea. Provide a full cloning address for other git providers (git@github.com:mayzyo/signal-bus)"
  default      = ""
}

locals {
  repo_name = data.coder_parameter.git_repo.value == "" ? "" : trimsuffix(
    element(split("/", data.coder_parameter.git_repo.value), length(split("/", data.coder_parameter.git_repo.value)) - 1),
    ".git",
  )
  workdir = local.repo_name == "" ? "/home/${var.home_user}" : "/home/${var.home_user}/${local.repo_name}"
}

resource "coder_script" "git_ssh_init" {
  agent_id     = var.agent_id
  display_name = "Git & SSH Init"
  icon         = "/icon/git.svg"
  run_on_start = true

  script = <<-EOF
    #!/bin/sh
    set -e

    SSH_DIR="$HOME/.ssh"
    SSH_CONFIG="$SSH_DIR/config"

    mkdir -p -m 700 "$SSH_DIR"

    if grep -q "StrictHostKeyChecking accept-new" "$SSH_CONFIG" 2>/dev/null; then
      echo "SSH StrictHostKeyChecking rule already exists. Skipping."
    else
      echo "Adding global StrictHostKeyChecking rule to SSH config..."
      echo "" >> "$SSH_CONFIG"
      echo "# Automatically accept new host keys for any domain" >> "$SSH_CONFIG"
      echo "Host *" >> "$SSH_CONFIG"
      echo "    StrictHostKeyChecking accept-new" >> "$SSH_CONFIG"
      chmod 600 "$SSH_CONFIG"
      echo "SSH config updated successfully."
    fi

    repo_input="${data.coder_parameter.git_repo.value}"
    if [ ! -z "$repo_input" ]; then
      repo_name=$(basename "$repo_input" .git)
      case "$repo_input" in
        *@*:* | *://*)
          clone_url="$repo_input"
          ;;
        *)
          clone_url="git@${var.default_git_host}:$repo_input"
          ;;
      esac

      if [ -d "$repo_name/.git" ]; then
        echo "Folder '$repo_name' already exists. Skipping clone."
      else
        echo "Cloning repository $clone_url..."
        git clone --progress "$clone_url"
      fi
    fi
  EOF
}

output "workdir" {
  description = "The resolved workspace working directory path (pointing to the cloned repository if specified, or the user's home directory)."
  value       = local.workdir
}

output "repo_name" {
  description = "The name of the cloned repository directory, or empty string if no repository was specified."
  value       = local.repo_name
}
