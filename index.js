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

// Load environment variables
require("dotenv").config();

// routes
app.use("/api/products", productRoute);
app.use("/api/users", userRoute);
app.use("/api/cart", cartRoute);
app.use("/api/orders", orderRoute);
app.use("api/payment", paymentRoute);

mongoose
  .connect(
    "mongodb://duedumaxwell63:meLWpeHd83MilMYK@backenddb-shard-00-00.pasoy.mongodb.net:27017,backenddb-shard-00-01.pasoy.mongodb.net:27017,backenddb-shard-00-02.pasoy.mongodb.net:27017/?ssl=true&replicaSet=atlas-5hbovb-shard-0&authSource=admin&retryWrites=true&w=majority&appName=BackendDB"
  )
  .then(() => {
    console.log("Connected to the database");
    app.listen(3000, () => {
      console.log("Server is running on port 3000");
    });
  })
  .catch(() => {
    console.error("Connection failed");
  });
