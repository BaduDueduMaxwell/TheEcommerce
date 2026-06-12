const express = require("express");
const router = express.Router();
const { createPayment, verifyPayment, handleWebhook } = require("../controllers/payment.controller");
const { authenticateToken } = require("../middlewares/auth.middleware");

// Payment routes
router.post("/", authenticateToken, createPayment); // Initialize payment
router.get("/verify/:reference", authenticateToken, verifyPayment); // Verify payment
router.post("/webhook", handleWebhook); // Webhook for Paystack

module.exports = router;
