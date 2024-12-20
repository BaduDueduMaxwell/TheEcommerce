const Order = require("../models/order.model");
const Cart = require("../models/cart.model");

const placeOrder = async (req, res) => {
  try {
    const userId = req.user.id;
    const { items, shippingAddress } = req.body;

    // Validate items and calculate total amount
    const totalAmount = items.reduce(
      (acc, item) => acc + item.price * item.quantity,
      0
    );

    // Create the order
    const newOrder = await Order.create({
      userId,
      items,
      totalAmount,
      shippingAddress,
      status: "Pending",
    });

    // Remove items from cart
    await Cart.findOneAndUpdate(
      { userId },
      { $pull: { items: { $in: items.map((item) => item.productId) } } }
    );

    res
      .status(201)
      .json({ message: "Order placed successfully", order: newOrder });
  } catch (error) {
    res.status(500).json({ message: error.message });
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
    const userId = req.user.id;
    const orders = await Order.find({ userId });

    if (!orders.length) {
      return res.status(404).json({ message: "No orders found for this user" });
    }

    res.status(200).json(orders);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const updateOrderStatus = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { status } = req.body;

    const validStatuses = ["Pending", "Shipped", "Delivered"];
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
