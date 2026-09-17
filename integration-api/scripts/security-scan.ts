import { readFile } from "node:fs/promises";
import { execFileSync } from "node:child_process";
import { parseEnv } from "node:util";
import { resolve } from "node:path";
import { createGitObjectReader, scanGitIndex } from "./git-index-scan.ts";

// Only boolean/count output. Never echo secret values, matches, lines or files.
try {
  const root = resolve("..");
  const env = parseEnv(await readFile(".env", "utf8"));
  const secret = env.DATABASE_URL;
  if (!secret) throw new Error("MISSING_LOCAL_CONFIGURATION");
  const parsed = new URL(secret);
  const password = decodeURIComponent(parsed.password);
  if (password.length < 8) throw new Error("CREDENTIAL_SCAN_INPUT_INVALID");
  const needles = [secret, password, parsed.password].map((value) =>
    Buffer.from(value),
  );
  const readGit = createGitObjectReader(root);
  const names = readGit([
    "ls-files",
    "-z",
    "--cached",
    "--others",
    "--exclude-standard",
  ])
    .toString("utf8")
    .split("\0")
    .filter(Boolean);
  let matches = 0;
  for (const name of new Set(names)) {
    const content = await readFile(resolve(root, name));
    if (needles.some((value) => content.includes(value))) matches++;
  }
  const index = scanGitIndex(needles, readGit);
  const collection = await readFile(
    "postman/DLU_LMS_Student_Support.postman_collection.json",
    "utf8",
  );
  const environment = await readFile(
    "postman/DLU_LMS_Development.postman_environment.json",
    "utf8",
  );
  const envKeys = (
    JSON.parse(environment) as { values: { key: string }[] }
  ).values
    .map((v) => v.key)
    .sort();
  const postmanSafe =
    JSON.stringify(envKeys) ===
      JSON.stringify(["base_url", "demo_student_code"]) &&
    !/DATABASE_URL|postgres(?:ql)?:\/\//i.test(collection + environment);
  const ignored =
    execFileSync("git", ["check-ignore", "integration-api/.env"], {
      cwd: root,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
    }).trim() === "integration-api/.env";
  const stagedFileCount = readGit(["diff", "--cached", "--name-only", "-z"])
    .toString("utf8")
    .split("\0")
    .filter(Boolean).length;
  const safe =
    matches === 0 &&
    index.secretValueMatches === 0 &&
    index.privateConfigFiles === 0 &&
    postmanSafe &&
    ignored;
  console.log(
    JSON.stringify(
      {
        SECRET_SCAN: safe ? "PASS" : "FAIL",
        scannedFiles: new Set(names).size,
        secretValueMatches: matches,
        indexedFiles: index.indexedFiles,
        scannedIndexBlobs: index.scannedBlobs,
        indexedSecretValueMatches: index.secretValueMatches,
        indexedPrivateConfigFiles: index.privateConfigFiles,
        postmanSafe,
        localSecretIgnored: ignored,
        stagedFileCount,
      },
      null,
      2,
    ),
  );
  if (!safe) process.exitCode = 1;
} catch {
  console.log("SECRET_SCAN=FAIL");
  process.exitCode = 1;
}
