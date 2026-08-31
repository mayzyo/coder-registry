mock_provider "coder" {}
mock_provider "kubernetes" {}

run "plan_with_defaults" {
  command = plan

  variables {
    agent_id          = "test-agent-id"
    agent_token       = "test-token"
    agent_init_script = "echo hello"
    container_image   = "mcr.microsoft.com/devcontainers/typescript-node:24"
    home_user         = "node"
  }

  assert {
    condition     = var.agent_id == "test-agent-id"
    error_message = "agent_id should match"
  }

  assert {
    condition     = var.container_image == "mcr.microsoft.com/devcontainers/typescript-node:24"
    error_message = "container_image should match"
  }
}
