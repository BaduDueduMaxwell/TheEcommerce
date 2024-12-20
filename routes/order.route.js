const express = require("express");
const router = express.Router();
const {
  placeOrder,
  getAllOrders,
  getUserOrders,
  updateOrderStatus,
  deleteOrder,
} = require("../controllers/order.controller");
const {
  authenticateToken,
  authorizeRole,
} = require("../middlewares/auth.middleware");

// user routes
router.get("/my-orders", authenticateToken, getUserOrders);
router.post("/place-order", authenticateToken, placeOrder);
router.delete("/:orderId", authenticateToken, deleteOrder);

// Admin routes
router.get("/", authenticateToken, authorizeRole("admin"), getAllOrders);
router.put(
  "/:orderId/status",
  authenticateToken,
  authorizeRole("admin"),
  updateOrderStatus
);

module.exports = router;
