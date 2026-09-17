import assert from "node:assert/strict";
import test from "node:test";
import { scanGitIndex } from "../scripts/git-index-scan.ts";

// Synthetic markers only; these tests never read local environment settings.
const objectId = "a".repeat(40);
const marker = Buffer.from("synthetic-index-only-marker");

test("secret gate inspects the indexed blob even when the working copy is clean", () => {
  const observedCalls: string[][] = [];
  const result = scanGitIndex([marker], (args) => {
    observedCalls.push([...args]);
    if (args[0] === "ls-files") {
      return Buffer.from(`100644 ${objectId} 0\tintegration-api/staged.txt\0`);
    }
    assert.deepEqual(args, ["cat-file", "blob", objectId]);
    return marker;
  });
  assert.equal(result.secretValueMatches, 1);
  assert.equal(result.scannedBlobs, 1);
  assert.equal(observedCalls.length, 2);
  assert.equal(JSON.stringify(result).includes(marker.toString()), false);
});

test("secret gate scans each indexed object once and rejects private env paths", () => {
  let blobReads = 0;
  const result = scanGitIndex([marker], (args) => {
    if (args[0] === "ls-files") {
      return Buffer.from(
        [".env", "integration-api/.env.staging", "integration-api/.env.example"]
          .map((path) => `100644 ${objectId} 0\t${path}\0`)
          .join(""),
      );
    }
    blobReads++;
    return Buffer.from("safe fixture");
  });
  assert.equal(result.indexedFiles, 3);
  assert.equal(result.privateConfigFiles, 2);
  assert.equal(result.secretValueMatches, 0);
  assert.equal(blobReads, 1);
});

test("secret gate fails closed for conflicting or unsupported index entries", () => {
  for (const entry of [
    `100644 ${objectId} 2\tconflicted.txt\0`,
    `160000 ${objectId} 0\tsubmodule\0`,
    "invalid index record\0",
  ]) {
    assert.throws(
      () => scanGitIndex([marker], () => Buffer.from(entry)),
      /^Error: INDEX_SCAN_UNSUPPORTED_ENTRY$/,
    );
  }
});

test("secret gate sanitizes Git index and blob read failures", () => {
  for (const failAt of ["ls-files", "cat-file"]) {
    assert.throws(
      () =>
        scanGitIndex([marker], (args) => {
          if (args[0] === failAt) throw new Error(marker.toString());
          return Buffer.from(`100644 ${objectId} 0\tsafe.txt\0`);
        }),
      /^Error: INDEX_SCAN_READ_FAILED$/,
    );
  }
});

test("secret gate handles NUL-separated filenames and an empty index", () => {
  const empty = scanGitIndex([marker], () => Buffer.alloc(0));
  assert.deepEqual(empty, {
    indexedFiles: 0,
    scannedBlobs: 0,
    secretValueMatches: 0,
    privateConfigFiles: 0,
  });
  const result = scanGitIndex([marker], (args) =>
    Buffer.from(
      args[0] === "ls-files"
        ? `100644 ${objectId} 0\tpath with\nnewline.txt\0`
        : "safe fixture",
    ),
  );
  assert.equal(result.indexedFiles, 1);
  assert.equal(result.secretValueMatches, 0);
});
