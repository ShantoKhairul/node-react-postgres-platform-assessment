// Dependency-free tests: they exercise routes that must work without
// Postgres/Redis (liveness, validation), so CI needs no service containers.
import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { app } from "../src/app.js";

let server;
let base;

before(async () => {
  server = app.listen(0);
  await new Promise((r) => server.once("listening", r));
  base = `http://127.0.0.1:${server.address().port}`;
});

after(() => server.close());

test("GET /api/health returns ok", async () => {
  const res = await fetch(`${base}/api/health`);
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), { status: "ok" });
});

test("GET /api/health/live does not depend on the database", async () => {
  const res = await fetch(`${base}/api/health/live`);
  assert.equal(res.status, 200);
});

test("POST /api/items without a name is rejected with 400", async () => {
  const res = await fetch(`${base}/api/items`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: "{}",
  });
  assert.equal(res.status, 400);
});
