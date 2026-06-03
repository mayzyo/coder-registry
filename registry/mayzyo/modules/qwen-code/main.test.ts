import { describe, expect, it } from "bun:test";
import {
  findResourceInstance,
  runTerraformApply,
  runTerraformInit,
} from "~test";

describe("qwen-code", async () => {
  await runTerraformInit(import.meta.dir);

  it("applies with defaults", async () => {
    const state = await runTerraformApply(import.meta.dir, {
      agent_id: "test-agent-id",
    });

    expect(state.outputs.scripts).toBeDefined();
  });

  it("creates an API key environment variable when configured", async () => {
    const state = await runTerraformApply(import.meta.dir, {
      agent_id: "test-agent-id",
      api_key: "test-key",
    });

    const env = findResourceInstance(state, "coder_env", "api_key");
    expect(env.name).toBe("DASHSCOPE_API_KEY");
  });
});
