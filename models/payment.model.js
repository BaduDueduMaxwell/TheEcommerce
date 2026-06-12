const mongoose = require("mongoose");

const paymentSchema = new mongoose.Schema(
  {
    orderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Order",
      required: true,
    },
    amount: { type: Number, required: true },
    currency: { type: String, default: "GHS" },
    transactionId: { type: String, required: true },
    paymentMethod: { type: String, default: "Paystack" },
    paymentStatus: { type: String, enum: ["Pending", "Completed"], default: "Pending" },
  },
  { timestamps: true }
);

const Payment = mongoose.model("Payment", paymentSchema);

module.exports = Payment;
