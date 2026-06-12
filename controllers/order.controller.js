const Order = require("../models/order.model");
const User = require("../models/user.model");
const Product = require("../models/product.model");
const mongoose = require("mongoose");

const placeOrder = async (req, res) => {
  try {
    const userId = req.user.userId;

    // Validate userId
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res
        .status(400)
        .json({ message: `Invalid user ID format: ${userId}` });
    }

    // Find user by ID
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    const { items, shippingAddress, paymentMethod } = req.body;

    // Validate items
    if (!items || !items.length) {
      return res
        .status(400)
        .json({ message: "No items provided for the order" });
    }

    // Validate shipping address
    if (
      !shippingAddress ||
      !shippingAddress.street ||
      !shippingAddress.city ||
      !shippingAddress.postalCode ||
      !shippingAddress.country
    ) {
      return res.status(400).json({ message: "Invalid shipping address" });
    }

    // Validate payment method
    const validPaymentMethods = [
      "Paystack",
      "CreditCard",
      "PayPal",
      "BankTransfer",
    ];
    if (!validPaymentMethods.includes(paymentMethod)) {
      return res.status(400).json({ message: "Invalid payment method" });
    }

    if (
      items.some(
        (item) =>
          !mongoose.Types.ObjectId.isValid(item.productId) ||
          !Number.isInteger(item.quantity) ||
          item.quantity < 1
      )
    ) {
      return res.status(400).json({
        message: "Each item requires a valid productId and positive quantity",
      });
    }

    const productIds = items.map((item) => item.productId);
    const products = await Product.find({ _id: { $in: productIds } });
    const productsById = new Map(
      products.map((product) => [product._id.toString(), product])
    );

    if (products.length !== new Set(productIds).size) {
      return res.status(400).json({ message: "One or more products are invalid" });
    }

    const trustedItems = items.map((item) => {
      const product = productsById.get(item.productId.toString());
      if (item.quantity > product.stock) {
        const error = new Error(`Insufficient stock for ${product.name}`);
        error.statusCode = 409;
        throw error;
      }
      return {
        productId: product._id,
        quantity: item.quantity,
        price: product.price,
      };
    });

    const totalAmount = trustedItems.reduce(
      (total, item) => total + item.price * item.quantity,
      0
    );

    // Create new order
    const newOrder = new Order({
      userId,
      items: trustedItems,
      totalAmount,
      shippingAddress,
      paymentMethod,
      status: "Pending",
      paymentStatus: "Pending",
    });

    await newOrder.save();

    res
      .status(201)
      .json({ message: "Order placed successfully", order: newOrder });
  } catch (error) {
    console.error("Error in placeOrder:", error);
    res.status(error.statusCode || 500).json({
      message: error.statusCode
        ? error.message
        : "An error occurred while placing the order",
    });
  }
};

const getAllOrders = async (req, res) => {
  try {
    const orders = await Order.find({});
    res.status(200).json(orders);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getUserOrders = async (req, res) => {
  try {
    const userId = req.user?.userId || req.user?.id;

    // Validate userId
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res
        .status(400)
        .json({ message: `Invalid user ID format: ${userId}` });
    }

    const orders = await Order.find({
      userId: new mongoose.Types.ObjectId(userId),
    });

    res.status(200).json(orders);
  } catch (error) {
    console.error("Error fetching user orders:", error);
    res.status(500).json({ message: error.message });
  }
};

const updateOrderStatus = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { status } = req.body;

    const validStatuses = ["Pending", "Shipped", "Delivered", "Cancelled"];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ message: "Invalid status value" });
    }

    const updatedOrder = await Order.findByIdAndUpdate(
      orderId,
      { status },
      { new: true, runValidators: true }
    );

    if (!updatedOrder) {
      return res.status(404).json({ message: "Order not found" });
    }

    res.status(200).json({
      message: "Order status updated successfully",
      order: updatedOrder,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const deleteOrder = async (req, res) => {
  try {
    const { orderId } = req.params;

    // Find the order first
    const order = await Order.findById(orderId);

    if (!order) {
      return res.status(404).json({ message: "Order not found" });
    }

    // Authorization check
    if (
      req.user.role !== "admin" &&
      req.user.userId !== order.userId.toString()
    ) {
      return res
        .status(403)
        .json({ message: "You do not have permission to delete this order" });
    }

    // Delete the order
    await order.deleteOne();

    res.status(200).json({ message: "Order deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  placeOrder,
  getAllOrders,
  getUserOrders,
  updateOrderStatus,
  deleteOrder,
};
