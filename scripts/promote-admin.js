require("dotenv").config();

const mongoose = require("mongoose");
const User = require("../models/user.model");

const promoteAdmin = async () => {
  if (process.env.NODE_ENV === "production") {
    throw new Error("Admin promotion is disabled in production");
  }
  if (!process.env.MONGODB_URI) {
    throw new Error("MONGODB_URI is required");
  }

  const email = process.argv[2]?.trim().toLowerCase();
  if (!email) {
    throw new Error(
      "Provide the existing user's email: npm run promote-admin -- user@example.com"
    );
  }

  await mongoose.connect(process.env.MONGODB_URI);
  const user = await User.findOneAndUpdate(
    { email },
    { role: "admin" },
    { new: true }
  );

  if (!user) {
    throw new Error("User not found. Create the account in the app first.");
  }

  console.log(`${email} is now an admin. Sign in again to refresh the JWT.`);
};

promoteAdmin()
  .catch((error) => {
    console.error("Admin promotion failed:", error.message);
    process.exitCode = 1;
  })
  .finally(async () => {
    await mongoose.disconnect();
  });
