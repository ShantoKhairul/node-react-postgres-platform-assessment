import client from "prom-client";

// Default Node.js process metrics (CPU, memory, event-loop lag, GC...).
client.collectDefaultMetrics();

const httpRequests = new client.Counter({
  name: "http_requests_total",
  help: "HTTP requests handled, by method, route and status code",
  labelNames: ["method", "route", "status"],
});

const httpDuration = new client.Histogram({
  name: "http_request_duration_seconds",
  help: "HTTP request latency in seconds",
  labelNames: ["method", "route"],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
});

// Records metrics + one structured JSON access-log line per request. The JSON
// lines are what makes logs filterable in Loki (`| json | status >= 500`).
export function observe(req, res, next) {
  if (req.path === "/metrics") return next();
  const start = process.hrtime.bigint();
  res.on("finish", () => {
    const seconds = Number(process.hrtime.bigint() - start) / 1e9;
    // Use the route PATTERN (not the raw URL) to keep label cardinality bounded.
    const route = req.route ? req.route.path : "unmatched";
    httpRequests.inc({ method: req.method, route, status: res.statusCode });
    httpDuration.observe({ method: req.method, route }, seconds);
    if (!route.startsWith("/api/health")) {
      console.log(
        JSON.stringify({
          level: res.statusCode >= 500 ? "error" : "info",
          msg: "request",
          method: req.method,
          path: req.originalUrl,
          status: res.statusCode,
          duration_ms: Math.round(seconds * 1000),
        })
      );
    }
  });
  next();
}

export async function metricsHandler(req, res) {
  res.set("Content-Type", client.register.contentType);
  res.end(await client.register.metrics());
}
