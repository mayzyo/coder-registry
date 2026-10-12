import { expect, test } from "bun:test";
import { spawnSync } from "node:child_process";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

const cases = [
  {
    name: "upgrades V1 before writing V2 config",
    existing: "1.0.180",
    requested: "latest",
    downloaded: "opencode v2.0.27",
    installs: 1,
    succeeds: true,
  },
  {
    name: "reuses an installed V2 binary",
    existing: "opencode v2.0.27",
    requested: "latest",
    downloaded: "",
    installs: 0,
    succeeds: true,
  },
  {
    name: "normalizes prefixed pinned versions",
    existing: "opencode v2.0.27",
    requested: "v2.0.27",
    downloaded: "",
    installs: 0,
    succeeds: true,
  },
  {
    name: "installs the requested V2 version",
    existing: "opencode v2.0.26",
    requested: "2.0.27",
    downloaded: "opencode v2.0.27",
    installs: 1,
    succeeds: true,
  },
  {
    name: "rejects V1 when installation is disabled",
    existing: "1.0.180",
    requested: "latest",
    downloaded: "",
    installs: 0,
    succeeds: false,
    install: false,
  },
  {
    name: "accepts V2 when installation is disabled",
    existing: "opencode v2.0.27",
    requested: "latest",
    downloaded: "",
    installs: 0,
    succeeds: true,
    install: false,
  },
  {
    name: "rejects an installer that leaves V1 installed",
    existing: "1.0.180",
    requested: "latest",
    downloaded: "1.0.180",
    installs: 1,
    succeeds: false,
  },
  {
    name: "rejects an installer returning the wrong pin",
    existing: "opencode v2.0.26",
    requested: "2.0.27",
    downloaded: "opencode v2.0.26",
    installs: 1,
    succeeds: false,
  },
  {
    name: "preserves config when the installer fails",
    existing: "1.0.180",
    requested: "latest",
    downloaded: "",
    installs: 1,
    succeeds: false,
  },
];

test.each(cases)(
  "$name",
  async (scenario) => {
    const directory = await mkdtemp(join(tmpdir(), "opencode-install-"));
    try {
      const run = (args: string[]) => {
        const result = spawnSync("terraform", args, {
          cwd: directory,
          encoding: "utf8",
        });
        if (result.error || result.status !== 0)
          throw new Error(
            `${result.error ?? ""}\n${result.stdout}\n${result.stderr}`,
          );
        return result.stdout;
      };
      const argumentsToRender = {
        ARG_INSTALL_OPENCODE: String(scenario.install ?? true),
        ARG_OPENCODE_VERSION: scenario.requested,
        ARG_WORKDIR: "",
        ARG_OPENCODE_CONFIG: Buffer.from(
          '{"providers":{},"agents":{},"mcp":{"servers":{}}}',
        ).toString("base64"),
      };
      await writeFile(
        join(directory, "main.tf"),
        `output "script" {
      value = templatefile(${JSON.stringify(join(import.meta.dir, "scripts/install.sh.tftpl"))}, {
        ${Object.entries(argumentsToRender)
          .map(([name, value]) => `${name} = ${JSON.stringify(value)}`)
          .join("\n")}
      })
    }`,
      );
      run(["init", "-backend=false", "-no-color"]);
      run(["apply", "-auto-approve", "-no-color"]);
      // Redirect only the rendered script's home paths; keep the test process's
      // actual HOME untouched, including Terraform's own configuration.
      const script = run(["output", "-raw", "script"]).replaceAll(
        "$HOME",
        directory,
      );
      const scriptPath = join(directory, "install.sh");
      await writeFile(scriptPath, script);

      const installDirectory = join(directory, ".opencode/bin");
      const mockDirectory = join(directory, "mock-bin");
      const configDirectory = join(directory, ".config/opencode");
      await Promise.all(
        [installDirectory, mockDirectory, configDirectory].map((path) =>
          mkdir(path, { recursive: true }),
        ),
      );
      const binary = join(installDirectory, "opencode");
      await writeFile(
        binary,
        `#!/bin/bash\nprintf '%s\\n' '${scenario.existing}'\n`,
        { mode: 0o755 },
      );
      const configPath = join(configDirectory, "opencode.jsonc");
      await writeFile(configPath, "existing config");
      const callsPath = join(directory, "installer-calls");
      await writeFile(callsPath, "");
      await writeFile(
        join(mockDirectory, "curl"),
        `#!/bin/bash
      echo called >> '${callsPath}'
      ${
        scenario.downloaded
          ? `cat <<'INSTALLER'
        printf '%s\\n' '#!/bin/bash' "printf '%s\\\\n' '${scenario.downloaded}'" > '${binary}'
        chmod +x '${binary}'
INSTALLER`
          : "exit 1"
      }
    `,
        { mode: 0o755 },
      );

      const result = spawnSync("bash", [scriptPath], {
        encoding: "utf8",
        env: { ...process.env, PATH: `${mockDirectory}:/usr/bin:/bin` },
      });
      expect(result.status === 0, `${result.stdout}\n${result.stderr}`).toBe(
        scenario.succeeds,
      );
      expect(
        (await readFile(callsPath, "utf8")).trim().split("\n").filter(Boolean),
      ).toHaveLength(scenario.installs);
      const config = await readFile(configPath, "utf8");
      if (scenario.succeeds)
        expect(JSON.parse(config)).toEqual({
          providers: {},
          agents: {},
          mcp: { servers: {} },
        });
      else expect(config).toBe("existing config");
    } finally {
      await rm(directory, { recursive: true, force: true });
    }
  },
  30_000,
);
