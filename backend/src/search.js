const SEARCH_URL = process.env.SEARCH_URL || "http://localhost:9200";
const INDEX = "items";

async function call(path, init = {}) {
  const res = await fetch(`${SEARCH_URL}${path}`, {
    signal: AbortSignal.timeout(3000),
    ...init,
  });
  if (!res.ok) throw new Error(`search ${path} returned ${res.status}`);
  return res.json();
}

// Health probe used by /api/health/search (the minimum the task asks for).
export function searchHealth() {
  return call("/_cluster/health");
}

// Used by the queue worker: index/refresh one document. Idempotent by id, so a
// retried job just overwrites the same document.
export function indexItem(item) {
  return call(`/${INDEX}/_doc/${item.id}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ name: item.name, created_at: item.created_at }),
  });
}

export async function searchItems(q) {
  const body = { size: 20, query: { match: { name: { query: q, fuzziness: "AUTO" } } } };
  const res = await fetch(`${SEARCH_URL}/${INDEX}/_search`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(3000),
  });
  if (res.status === 404) return []; // index not created yet = nothing indexed
  if (!res.ok) throw new Error(`search returned ${res.status}`);
  const data = await res.json();
  return data.hits.hits.map((h) => ({ id: Number(h._id), ...h._source }));
}
