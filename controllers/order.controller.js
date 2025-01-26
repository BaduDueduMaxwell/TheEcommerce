const Order = require("../models/order.model");
const Cart = require("../models/cart.model");
const User = require("../models/user.model");
const mongoose = require("mongoose");

const placeOrder = async (req, res) => {
  try {
    console.log("Request received at /place-order");
    const userId = req.user.userId;

    // Validate userId
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      console.log("Invalid user ID format");
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
    const validPaymentMethods = ["CreditCard", "PayPal", "BankTransfer"];
    if (!validPaymentMethods.includes(paymentMethod)) {
      // Add items to the cart if the payment method is invalid
      console.log("Invalid payment method, adding items to cart");
      let userCart = await Cart.findOne({ userId });
      if (!userCart) {
        userCart = new Cart({ userId, items });
      } else {
        // Merge items into the existing cart
        items.forEach((item) => {
          const existingItemIndex = userCart.items.findIndex(
            (cartItem) => cartItem.productId.toString() === item.productId
          );
          if (existingItemIndex !== -1) {
            // Update quantity if item already exists in the cart
            userCart.items[existingItemIndex].quantity += item.quantity;
          } else {
            // Add new item to the cart
            userCart.items.push(item);
          }
        });
      }
      await userCart.save();
      return res
        .status(200)
        .json({ message: "Items added to cart due to invalid payment method" });
    }

    // Calculate total amount
    const totalAmount = items.reduce(
      (total, item) => total + item.price * item.quantity,
      0
    );

    // Create new order
    const newOrder = new Order({
      userId,
      items,
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
    res
      .status(500)
      .json({ message: "An error occurred while placing the order" });
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

    console.log("Fetching orders for user ID:", userId);

    const orders = await Order.find({
      userId: new mongoose.Types.ObjectId(userId),
    });

    if (!orders.length) {
      return res.status(404).json({ message: "No orders found for this user" });
    }

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
    if (req.user.role !== "admin" && req.user.id !== order.userId.toString()) {
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
