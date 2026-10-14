import { app } from "./app.js";
import { initSchema } from "./db.js";

const PORT = process.env.PORT || 4000;

initSchema()
  .then(() => {
    app.listen(PORT, () => console.log(`backend listening on :${PORT}`));
  })
  .catch((err) => {
    console.error("failed to initialize schema:", err);
    process.exit(1);
  });
