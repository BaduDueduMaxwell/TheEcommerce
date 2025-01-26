const express = require("express");
const router = express.Router();
const { createPayment, verifyPayment, handleWebhook } = require("../controllers/payment.controller");

// Payment routes
router.post("/", createPayment); // Initialize payment
router.get("/verify/:reference", verifyPayment); // Verify payment
router.post("/webhook", handleWebhook); // Webhook for Paystack

module.exports = router;
