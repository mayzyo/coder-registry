---
display_name: Git & SSH Init
description: Automatically configure SSH strict host key checking and clone a git repository into the workspace
icon: ../../../../.icons/git.svg
verified: false
tags: [git, ssh, helper]
---

# Git & SSH Init

Configures SSH key checking (`StrictHostKeyChecking accept-new`) and clones a repository provided via the workspace `git_repo` parameter upon startup.

## Usage

```tf
module "git_init" {
  source    = "registry.coder.com/mayzyo/git-ssh-init/coder"
  version   = "1.0.0"
  agent_id  = coder_agent.main.id
  home_user = "node"
}
```
