---
display_name: Kubernetes Workspace
description: Provision Kubernetes workspace pods and persistent home volumes with custom compute and architecture settings
icon: ../../../../.icons/kubernetes.svg
verified: false
tags: [kubernetes, workspace, container]
---

# Kubernetes Workspace

Provisions an isolated Kubernetes workspace pod and persistent home volume (`PersistentVolumeClaim`) for Coder workspaces. Automatically exposes user-facing `coder_parameter` controls for CPU cores, RAM sizing, target architecture (x86/arm64), persistent disk size, and sidecar disk attachment.

## Usage

```tf
module "kubernetes_workspace" {
  source  = "registry.coder.com/mayzyo/kubernetes-workspace/coder"
  version = "1.0.0"

  agent_id          = coder_agent.main.id
  agent_token       = coder_agent.main.token
  agent_init_script = coder_agent.main.init_script
  container_image   = "mcr.microsoft.com/devcontainers/typescript-node:24"
  container_name    = "nodejs"
  home_user         = "node"
}

resource "coder_agent" "main" {
  os   = "linux"
  arch = module.kubernetes_workspace.arch
}
```
