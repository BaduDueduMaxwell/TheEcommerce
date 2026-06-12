require("dotenv").config();

const mongoose = require("mongoose");
const app = require("./app");

const port = Number(process.env.PORT || 3000);

const startServer = async () => {
  if (!process.env.MONGODB_URI) {
    throw new Error("MONGODB_URI is required");
  }

  await mongoose.connect(process.env.MONGODB_URI);
  console.log("Connected to the database");

  app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
  });
};

startServer().catch((error) => {
  console.error("Server startup failed:", error.message);
  process.exitCode = 1;
});
