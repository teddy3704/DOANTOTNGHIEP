import { execFileSync } from "node:child_process";

export type GitObjectReader = (args: readonly string[]) => Buffer;

export function createGitObjectReader(root: string): GitObjectReader {
  return (args) => {
    try {
      return execFileSync("git", [...args], {
        cwd: root,
        stdio: ["ignore", "pipe", "pipe"],
        maxBuffer: 32 * 1024 * 1024,
      });
    } catch {
      // Git errors can contain paths, arguments or captured blob contents.
      throw new Error("INDEX_SCAN_READ_FAILED");
    }
  };
}

// Inspect the complete prospective commit, not the working-tree copy of files.
// Return counts only; no blob contents, paths or secret values leave this helper.
export function scanGitIndex(
  needles: readonly Buffer[],
  readGit: GitObjectReader,
) {
  let entries: string[];
  try {
    entries = readGit(["ls-files", "--stage", "-z"])
      .toString("utf8")
      .split("\0")
      .filter(Boolean);
  } catch {
    throw new Error("INDEX_SCAN_READ_FAILED");
  }
  const blobIds = new Set<string>();
  let privateConfigFiles = 0;
  for (const entry of entries) {
    const parsed =
      /^(100644|100755|120000) ([a-f0-9]{40}|[a-f0-9]{64}) 0\t([\s\S]+)$/.exec(
        entry,
      );
    // Fail closed on conflicts, submodules and unknown index record formats.
    if (!parsed) throw new Error("INDEX_SCAN_UNSUPPORTED_ENTRY");
    const [, , objectId, path] = parsed;
    if (!objectId || !path) throw new Error("INDEX_SCAN_UNSUPPORTED_ENTRY");
    blobIds.add(objectId);
    const filename = path.split("/").at(-1) ?? "";
    if (
      (filename === ".env" || filename.startsWith(".env.")) &&
      filename !== ".env.example"
    ) {
      privateConfigFiles++;
    }
  }
  let secretValueMatches = 0;
  for (const objectId of blobIds) {
    let content: Buffer;
    try {
      content = readGit(["cat-file", "blob", objectId]);
    } catch {
      throw new Error("INDEX_SCAN_READ_FAILED");
    }
    if (needles.some((needle) => content.includes(needle)))
      secretValueMatches++;
  }
  return {
    indexedFiles: entries.length,
    scannedBlobs: blobIds.size,
    secretValueMatches,
    privateConfigFiles,
  };
}
