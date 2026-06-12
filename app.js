const express = require("express");

const productRoute = require("./routes/product.route");
const userRoute = require("./routes/user.route");
const cartRoute = require("./routes/cart.route");
const orderRoute = require("./routes/order.route");
const paymentRoute = require("./routes/payment.route");
const eventRoute = require("./routes/event.route");

const app = express();

app.use(
  express.json({
    verify: (req, _res, buffer) => {
      req.rawBody = buffer;
    },
  })
);

app.get("/health", (_req, res) => {
  res.status(200).json({ status: "ok" });
});

app.use("/api/products", productRoute);
app.use("/api/users", userRoute);
app.use("/api/cart", cartRoute);
app.use("/api/orders", orderRoute);
app.use("/api/payment", paymentRoute);
app.use("/api/events", eventRoute);

app.use((_req, res) => {
  res.status(404).json({ message: "Route not found" });
});

module.exports = app;
