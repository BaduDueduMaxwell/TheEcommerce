const express = require("express");
const router = express.Router();

const {
  addPayment,
  getAllPayment,
  getSpecificOrderPayment,
} = require("../controllers/payment.controller");
const {
  authenticateToken,
  authorizeRole,
} = require("../middlewares/auth.middleware");

// Protected Routes
router.post("/", authenticateToken, addPayment);
router.get("/", authenticateToken, authorizeRole("admin"), getAllPayment);
router.get(
  "/:id",
  authenticateToken,
  authorizeRole("admin", "user"),
  getSpecificOrderPayment
);

module.exports = router;
