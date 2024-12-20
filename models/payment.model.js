const mongoose = require("mongoose");

const PaymentSchema = mongoose.Schema({
  orderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Order",
    required: true,
  },
  paymentStatus: {
    type: String,
    default: "Pending",
  },
  transactionId: {
    type: String,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

const Payment = mongoose.model("Payment", PaymentSchema);

module.exports = Payment;
