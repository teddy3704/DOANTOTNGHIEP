import type { FastifyServerOptions } from "fastify";

// A status-only policy is stronger than a list of secret names: request, response
// and exception serializers cannot leak a new header/query/driver field later.
export function safeLoggerOptions(
  logger: FastifyServerOptions["logger"],
): NonNullable<FastifyServerOptions["logger"]> {
  if (logger === false) return false;
  const options = typeof logger === "object" ? logger : {};
  return {
    ...options,
    base: { service: "dlu-lms-support-api" },
    redact: {
      paths: [
        "req.headers",
        "req.url",
        "req.body",
        "request.headers",
        "request.body",
        "authorization",
        "cookie",
        "password",
        "token",
        "DATABASE_URL",
      ],
      remove: true,
    },
    serializers: {
      req: () => ({}),
      res: () => ({}),
      err: () => ({
        type: "SanitizedError",
        message: "Internal details omitted",
        stack: "",
      }),
    },
  };
}
