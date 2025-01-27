// Load environment variables
require("dotenv").config();

const express = require("express");
const mongoose = require("mongoose");

const productRoute = require("./routes/product.route.js");
const userRoute = require("./routes/user.route.js");
const cartRoute = require("./routes/cart.route.js");
const orderRoute = require("./routes/order.route.js");
const paymentRoute = require("./routes/payment.route.js");

const app = express();

// middleware
app.use(express.json());

// routes
app.use("/api/products", productRoute);
app.use("/api/users", userRoute);
app.use("/api/cart", cartRoute);
app.use("/api/orders", orderRoute);
app.use("/api/payment", paymentRoute);

mongoose
  .connect(process.env.MONGODB_URI)
  .then(() => {
    console.log("Connected to the database");
    app.listen(3000, () => {
      console.log("Server is running on port 3000");
    });
  })
  .catch(() => {
    console.error("Connection failed");
  });
