import { Worker } from "bullmq";
import IORedis from "ioredis";
import { indexItem } from "./search.js";

const connection = new IORedis(process.env.REDIS_URL || "redis://localhost:6379", {
  maxRetriesPerRequest: null,
});

// Consumes "item-events" jobs enqueued by the API on every write.
// Indexes each new item into the search engine (more work could hang off
// the same queue: notifications, cache invalidation, ...).
const worker = new Worker(
  "item-events",
  async (job) => {
    console.log(`processing ${job.name}`, job.data);
    // Async side effect of a write: make the new item searchable. A failure
    // throws, and BullMQ retries it (default: once; raise `attempts` for prod).
    await indexItem(job.data);
  },
  { connection }
);

worker.on("completed", (job) => console.log(`job ${job.id} completed`));
worker.on("failed", (job, err) => console.error(`job ${job?.id} failed:`, err.message));

console.log("worker started, waiting for jobs on 'item-events'");
