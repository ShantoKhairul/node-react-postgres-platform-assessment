import { app } from "./app.js";
import { initSchema } from "./db.js";

const PORT = process.env.PORT || 4000;

// Listen immediately so liveness passes; readiness (/api/health/ready) keeps
// traffic away until the database is reachable.
app.listen(PORT, () => console.log(`backend listening on :${PORT}`));

// Retry schema setup instead of exiting: a database that is briefly down must
// not put the pod into a crash loop.
(async () => {
  for (let attempt = 1; ; attempt++) {
    try {
      await initSchema();
      console.log("database schema ready");
      return;
    } catch (err) {
      console.error(`schema init failed (attempt ${attempt}): ${err.message}; retrying in 3s`);
      await new Promise((r) => setTimeout(r, 3000));
    }
  }
})();
