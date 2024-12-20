const mongoose = require("mongoose");

const CartSchema = mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    items: [
      {
        productId: {
          type: mongoose.Schema.Types.ObjectId,
          ref: "Product",
          required: true,
        },
        quantity: {
          type: Number,
          required: true,
        },
      },
    ],
    totalPrice: {
      type: Number,
      required: true,
    },
    status: {
      type: String,
      default: "Pending",
      enum: ["Pending", "Shipping", "Delivered", "Cancelled"],
    },
  },
  { timestamps: true }
);

const Cart = mongoose.model("Cart", CartSchema);

module.exports = Cart;
