export interface AppConfig {
  environment: "development" | "staging";
  port: number;
  host: string;
  databaseUrl: string;
  demoAuthEnabled: boolean;
}

export function loadConfig(env: NodeJS.ProcessEnv = process.env): AppConfig {
  const environment = env.APP_ENV ?? "development";
  if (environment !== "development" && environment !== "staging")
    throw new Error("CONFIG_ENVIRONMENT_NOT_SUPPORTED");
  const port = Number(env.PORT ?? 3000);
  if (!Number.isInteger(port) || port < 1 || port > 65535)
    throw new Error("CONFIG_PORT_INVALID");
  if (!env.DATABASE_URL?.trim()) throw new Error("CONFIG_DATABASE_REQUIRED");
  if (env.DEMO_AUTH_ENABLED !== "true" && env.DEMO_AUTH_ENABLED !== "false")
    throw new Error("CONFIG_DEMO_AUTH_REQUIRED");
  return {
    environment,
    port,
    host: environment === "staging" ? "0.0.0.0" : "127.0.0.1",
    databaseUrl: env.DATABASE_URL.trim(),
    demoAuthEnabled: env.DEMO_AUTH_ENABLED === "true",
  };
}
