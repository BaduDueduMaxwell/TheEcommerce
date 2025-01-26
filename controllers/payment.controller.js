const axios = require("axios");
const crypto = require("crypto");
const Payment = require("../models/payment.model");

const PAYSTACK_SECRET_KEY = process.env.PAYSTACK_SECRET_KEY;

// Initialize a payment
const createPayment = async (req, res) => {
  try {
    const { orderId, amount, email, currency = "NGN" } = req.body;

    if (!orderId || !amount || !email) {
      return res.status(400).json({
        success: false,
        message: "orderId, amount, and email are required",
      });
    }

    const response = await axios.post(
      "https://api.paystack.co/transaction/initialize",
      {
        email,
        amount: amount * 100, // Convert amount to kobo
        currency,
      },
      {
        headers: { Authorization: `Bearer ${PAYSTACK_SECRET_KEY}` },
      }
    );

    const { data } = response.data;

    const payment = await Payment.create({
      orderId,
      amount,
      currency,
      transactionId: data.reference,
      paymentMethod: "Paystack",
      paymentStatus: "Pending",
    });

    res.status(201).json({
      success: true,
      message: "Payment initialized. Complete payment using the authorization URL.",
      paymentUrl: data.authorization_url,
      reference: data.reference,
      payment,
    });
  } catch (error) {
    console.error("Error initializing payment:", error.message);
    res.status(500).json({
      success: false,
      message: "Failed to initialize payment",
      error: error.message,
    });
  }
};

// Verify a payment
const verifyPayment = async (req, res) => {
  try {
    const { reference } = req.params;

    if (!reference) {
      return res.status(400).json({ success: false, message: "Reference is required" });
    }

    const response = await axios.get(
      `https://api.paystack.co/transaction/verify/${reference}`,
      {
        headers: { Authorization: `Bearer ${PAYSTACK_SECRET_KEY}` },
      }
    );

    const { data } = response.data;

    if (data.status !== "success") {
      return res.status(400).json({ success: false, message: "Verification failed" });
    }

    const payment = await Payment.findOneAndUpdate(
      { transactionId: reference },
      { paymentStatus: "Completed" },
      { new: true }
    );

    if (!payment) {
      return res.status(404).json({ success: false, message: "Payment record not found" });
    }

    res.status(200).json({ success: true, message: "Payment verified", payment });
  } catch (error) {
    console.error("Error verifying payment:", error.message);
    res.status(500).json({ success: false, message: "Verification failed", error: error.message });
  }
};

// Handle webhooks
const handleWebhook = async (req, res) => {
  try {
    const signature = req.headers["x-paystack-signature"];
    const payload = JSON.stringify(req.body);

    const hash = crypto.createHmac("sha512", PAYSTACK_SECRET_KEY).update(payload).digest("hex");

    if (hash !== signature) {
      return res.status(400).json({ success: false, message: "Invalid signature" });
    }

    const { event, data } = req.body;

    if (event === "charge.success") {
      await Payment.findOneAndUpdate(
        { transactionId: data.reference },
        { paymentStatus: "Completed" }
      );
    }

    res.sendStatus(200);
  } catch (error) {
    console.error("Webhook error:", error.message);
    res.status(500).json({ success: false, message: "Webhook processing failed" });
  }
};

module.exports = {
  createPayment,
  verifyPayment,
  handleWebhook,
};
