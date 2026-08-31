mock_provider "coder" {}

run "plan_with_defaults" {
  command = plan

  variables {
    agent_id = "test-agent-id"
    workdir  = "/home/node/project"
  }

  assert {
    condition     = var.agent_id == "test-agent-id"
    error_message = "agent_id should match"
  }

  assert {
    condition     = var.run_codex == false
    error_message = "run_codex should default to false"
  }
}
