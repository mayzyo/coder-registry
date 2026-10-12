import { spawnSync } from "node:child_process";
import {
  cp,
  mkdir,
  mkdtemp,
  readFile,
  rm,
  symlink,
  writeFile,
} from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, relative, resolve } from "node:path";

export interface TestPlan {
  resource_changes: {
    address: string;
    type: string;
    change: { after: { name?: string; value?: string; script?: string } };
  }[];
}

function terraform(args: string[], cwd: string) {
  const result = spawnSync("terraform", args, {
    cwd,
    encoding: "utf8",
    maxBuffer: 32 * 1024 * 1024,
  });
  if (result.error || result.status !== 0) {
    throw new Error(
      `${result.error ?? ""}\n${result.stderr}\n${result.stdout}`,
    );
  }
  return result.stdout;
}

// Copy each dependency as a separate package so tests cannot rely on siblings
// from the repository checkout.
export async function packagedTestPlans(moduleDirectory: string) {
  terraform(["init", "-input=false", "-no-color"], moduleDirectory);
  const temporaryDirectory = await mkdtemp(join(tmpdir(), "registry-package-"));
  const packageDirectory = join(temporaryDirectory, "module");
  const copyPackage = (source: string, target: string) =>
    cp(source, target, {
      recursive: true,
      filter: (path) =>
        !relative(source, path).split(/[\\/]/).includes(".terraform"),
    });

  try {
    await copyPackage(moduleDirectory, packageDirectory);
    await mkdir(join(packageDirectory, ".terraform/modules"), {
      recursive: true,
    });
    const manifest = JSON.parse(
      await readFile(
        join(moduleDirectory, ".terraform/modules/modules.json"),
        "utf8",
      ).catch((error) => {
        if (error.code === "ENOENT")
          return '{"Modules":[{"Key":"","Dir":".","Source":""}]}';
        throw error;
      }),
    ) as {
      Modules: { Key: string; Dir: string; Source: string; Version?: string }[];
    };
    for (const dependency of manifest.Modules) {
      if (!dependency.Key) continue;
      const destination = `.terraform/modules/${dependency.Key}`;
      await copyPackage(
        resolve(moduleDirectory, dependency.Dir),
        join(packageDirectory, destination),
      );
      dependency.Dir = destination;
    }
    await writeFile(
      join(packageDirectory, ".terraform/modules/modules.json"),
      JSON.stringify(manifest),
    );
    await symlink(
      join(moduleDirectory, ".terraform/providers"),
      join(packageDirectory, ".terraform/providers"),
    );

    const run = (args: string[]) => terraform(args, packageDirectory);
    run([
      "init",
      "-backend=false",
      "-get=false",
      "-lockfile=readonly",
      "-no-color",
    ]);
    const plans: Record<string, TestPlan> = {};
    for (const line of run(["test", "-json", "-verbose"]).split("\n")) {
      if (!line) continue;
      const event = JSON.parse(line);
      if (event.type === "test_plan")
        plans[event["@testrun"]] = event.test_plan;
    }
    return plans;
  } finally {
    await rm(temporaryDirectory, { recursive: true, force: true });
  }
}

export function installedConfig(
  plan: TestPlan,
  address: string,
  argument: string,
) {
  const resource = plan.resource_changes.find(
    (resource) => resource.address === address,
  );
  const encodedScript = resource?.change.after.script?.match(
    /echo -n '([^']*)' \| base64 -d >/,
  )?.[1];
  if (!encodedScript) throw new Error(`Missing install script at ${address}`);
  const script = Buffer.from(encodedScript, "base64").toString();
  const encodedConfig = script.match(new RegExp(`${argument}='([^']*)'`))?.[1];
  if (!encodedConfig) throw new Error(`Missing ${argument} in ${address}`);
  return JSON.parse(Buffer.from(encodedConfig, "base64").toString());
}
