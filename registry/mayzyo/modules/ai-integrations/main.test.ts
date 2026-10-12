import { expect, test } from "bun:test";
import { join } from "node:path";
import { installedConfig, packagedTestPlans } from "./test-util";

const credentials = {
  EXA_API_KEY: "test-exa-key",
  GITHUB_PERSONAL_ACCESS_TOKEN: "test-github-token",
  CONTEXT7_API_KEY: "test-context7-key",
};

test.each([
  "ai-integrations",
  "opencode",
  "qwen-code",
  "qwen-code-tasks",
  "ai-assistants",
])(
  "%s initializes and passes tests as an isolated registry package",
  async (moduleName) => {
    const plans = await packagedTestPlans(
      join(import.meta.dir, "..", moduleName),
    );
    expect(Object.keys(plans).length).toBeGreaterThan(0);

    if (moduleName === "ai-assistants") {
      const plan = plans.plan_with_integrations;
      const environments = plan.resource_changes.filter(
        (resource) => resource.type === "coder_env",
      );
      expect(environments).toHaveLength(3);
      for (const [name, value] of Object.entries(credentials)) {
        const matches = environments.filter(
          (resource) => resource.change.after.name === name,
        );
        expect(matches).toHaveLength(1);
        expect(matches[0].address).toStartWith("module.ai_integrations.");
        expect(matches[0].change.after.value).toBe(value);
      }

      const qwen = installedConfig(
        plan,
        "module.qwen_code[0].module.coder_utils.coder_script.install_script",
        "ARG_SETTINGS_JSON",
      );
      const opencode = installedConfig(
        plan,
        "module.opencode[0].module.coder_utils.coder_script.install_script",
        "ARG_OPENCODE_CONFIG",
      );
      expect(Object.keys(qwen.mcpServers).sort()).toEqual([
        "context7",
        "exa",
        "github",
      ]);
      expect(Object.keys(opencode.mcp.servers).sort()).toEqual([
        "context7",
        "exa",
        "github",
      ]);
      expect(qwen.mcpServers.github.headers.Authorization).toBe(
        "Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}",
      );
      expect(opencode.mcp.servers.github.headers.Authorization).toBe(
        "Bearer {env:GITHUB_PERSONAL_ACCESS_TOKEN}",
      );
    }

    if (moduleName === "qwen-code-tasks") {
      for (const runName of ["integrations", "external_integration_env"]) {
        const plan = plans[runName];
        const environments = plan.resource_changes.filter(
          (resource) =>
            resource.type === "coder_env" &&
            Object.hasOwn(credentials, resource.change.after.name ?? ""),
        );
        expect(environments).toHaveLength(runName === "integrations" ? 3 : 0);
        for (const [name, value] of Object.entries(credentials)) {
          if (runName === "integrations") {
            expect(
              environments.find(
                (resource) => resource.change.after.name === name,
              )?.change.after.value,
            ).toBe(value);
          }
        }
        const config = installedConfig(
          plan,
          "module.qwen_code.module.coder_utils.coder_script.install_script",
          "ARG_SETTINGS_JSON",
        );
        expect(Object.keys(config.mcpServers).sort()).toEqual([
          "context7",
          "exa",
          "github",
        ]);
        expect(config.mcpServers.github.headers.Authorization).toBe(
          "Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}",
        );
        expect(config.mcpServers.exa.headers["x-api-key"]).toBe(
          "${EXA_API_KEY}",
        );
        expect(config.mcpServers.context7.headers.Authorization).toBe(
          "Bearer ${CONTEXT7_API_KEY}",
        );
      }
    }
  },
  60_000,
);
