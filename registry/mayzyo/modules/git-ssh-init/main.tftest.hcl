mock_provider "coder" {}

run "plan_with_defaults" {
  command = plan

  variables {
    agent_id  = "test-agent-id"
    home_user = "node"
  }

  assert {
    condition     = var.agent_id == "test-agent-id"
    error_message = "agent_id should match"
  }
}
