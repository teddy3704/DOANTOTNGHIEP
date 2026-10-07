import assert from "node:assert/strict";
import test from "node:test";
import { loadConfig } from "../src/config.ts";

// Configuration fixtures only. Never load a real .env in unit tests.
const fixture = () => ({
  APP_ENV: "development",
  PORT: "3000",
  DATABASE_URL: "postgresql://localhost/development_test",
  DEMO_AUTH_ENABLED: "true",
});

test("configuration: development binds only to the local interface", () => {
  const config = loadConfig(fixture());
  assert.equal(config.environment, "development");
  assert.equal(config.port, 3000);
  assert.equal(config.host, "127.0.0.1");
  assert.equal(config.demoAuthEnabled, true);
});

test("configuration: explicitly enabled staging and disabled identity are supported", () => {
  const config = loadConfig({
    ...fixture(),
    APP_ENV: "staging",
    PORT: "8080",
    DEMO_AUTH_ENABLED: "false",
  });
  assert.equal(config.host, "0.0.0.0");
  assert.equal(config.port, 8080);
  assert.equal(config.demoAuthEnabled, false);
});

test("SEC10: production and unsupported environments cannot load demo configuration", () => {
  for (const environment of ["production", "prod", "test", "", "DEVELOPMENT"]) {
    assert.throws(
      () => loadConfig({ ...fixture(), APP_ENV: environment }),
      /^Error: CONFIG_ENVIRONMENT_NOT_SUPPORTED$/,
    );
  }
});

test("configuration: port must be a valid nonzero TCP integer", () => {
  for (const port of [
    "0",
    "-1",
    "65536",
    "3000.5",
    "invalid",
    "",
    " 3000 ",
    "3e3",
    "0xbb8",
  ]) {
    assert.throws(
      () => loadConfig({ ...fixture(), PORT: port }),
      /^Error: CONFIG_PORT_INVALID$/,
    );
  }
});

test("configuration: identity enablement must be explicit and exactly boolean text", () => {
  for (const value of ["TRUE", "1", "yes", ""]) {
    assert.throws(
      () => loadConfig({ ...fixture(), DEMO_AUTH_ENABLED: value }),
      /^Error: CONFIG_DEMO_AUTH_REQUIRED$/,
    );
  }
  const env: NodeJS.ProcessEnv = fixture();
  delete env.DEMO_AUTH_ENABLED;
  assert.throws(() => loadConfig(env), /^Error: CONFIG_DEMO_AUTH_REQUIRED$/);
});

test("configuration: missing connection settings fail without displaying environment values", () => {
  for (const value of ["", "   "]) {
    assert.throws(
      () => loadConfig({ ...fixture(), DATABASE_URL: value }),
      /^Error: CONFIG_DATABASE_REQUIRED$/,
    );
  }
  const env: NodeJS.ProcessEnv = fixture();
  delete env.DATABASE_URL;
  assert.throws(() => loadConfig(env), /^Error: CONFIG_DATABASE_REQUIRED$/);
});

test("configuration: errors never reflect unrelated sensitive-looking input", () => {
  const marker = "synthetic-private-test-marker";
  let safe = false;
  try {
    loadConfig({ ...fixture(), APP_ENV: "production", DATABASE_URL: marker });
  } catch (error) {
    safe =
      error instanceof Error &&
      !error.message.includes(marker) &&
      error.message === "CONFIG_ENVIRONMENT_NOT_SUPPORTED";
  }
  assert.equal(safe, true);
});
