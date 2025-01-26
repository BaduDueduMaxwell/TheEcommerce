const Cart = require("../models/cart.model");
const Product = require("../models/product.model");

// Function to calculate the total price of products in the cart
const calculateTotalPrice = async (items) => {
  let total = 0;
  for (const item of items) {
    const product = await Product.findById(item.productId);
    if (product) {
      total += product.price * item.quantity;
    }
  }
  return total;
};

const getUserCart = async (req, res) => {
  try {
    const { userId } = req.params;

    const cart = await Cart.findOne({ userId });

    if (!cart) {
      return res.status(404).json({ message: "Cart not found" });
    }

    const totalPrice = await calculateTotalPrice(cart.items);

    res.status(200).json({ ...cart.toObject(), totalPrice });
  } catch (error) {
    console.error("Error fetching the cart:", error.message);
    res.status(500).json({ message: "Internal server error" });
  }
};

const addUserCart = async (req, res) => {
  try {
    const { userId, items } = req.body;

    if (!userId || !items || items.length === 0) {
      return res
        .status(400)
        .json({ message: "User ID and items are required" });
    }

    // Validate each item in the array
    for (const item of items) {
      if (!item.productId || !item.quantity) {
        return res.status(400).json({
          message: "Each item must have a productId and quantity",
        });
      }
    }

    const totalPrice = await calculateTotalPrice(items);

    const cart = await Cart.create({ userId, items, totalPrice });
    res.status(200).json(cart);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const updateUserCart = async (req, res) => {
  try {
    const { userId } = req.params;
    const { items } = req.body;

    if (!items || items.length === 0) {
      return res
        .status(400)
        .json({ message: "Items are required to update the cart" });
    }

    const totalPrice = await calculateTotalPrice(items);

    const cart = await Cart.findOneAndUpdate(
      { userId },
      { items, totalPrice },
      {
        new: true,
        runValidators: true,
      }
    );

    if (!cart) {
      return res.status(404).json({ message: "Cart not found" });
    }

    res.status(200).json(cart);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const deleteProductsFromCart = async (req, res) => {
  try {
    const { userId } = req.params;

    // Find the cart by userId and clear the items array
    const cart = await Cart.findOneAndUpdate(
      { userId },
      { $set: { items: [], totalPrice: 0 } }, // Clear the items and set totalPrice to 0
      { new: true }
    );

    if (!cart) {
      return res.status(404).json({ message: "Cart not found" });
    }

    res.status(200).json({
      message: "All products deleted from cart successfully",
      cart,
    });
  } catch (error) {
    console.error("Error deleting products from cart:", error.message);
    res.status(500).json({ message: "Internal server error" });
  }
};

const deleteProductFromCart = async (req, res) => {
  try {
    const { userId, productId } = req.params;
    console.log(userId, productId);

    if (!productId) {
      return res.status(400).json({ message: "Product ID is required" });
    }

    // Find the cart by userId and remove the product from items array
    const cart = await Cart.findOneAndUpdate(
      { userId },
      { $pull: { items: { productId } } },
      { new: true }
    );

    // Check if the cart exists
    if (!cart) {
      return res.status(404).json({ message: "Cart not found for this user" });
    }

    if (cart.items.length === 0) {
      await cart.deleteOne();
      return res
        .status(404)
        .json({ message: "Cart is empty and has been removed" });
    }

    // Recalculate the total price and update
    const totalPrice = await calculateTotalPrice(cart.items);

    cart.totalPrice = totalPrice;

    await cart.save();

    res.status(200).json({
      message: "Product deleted successfully from cart",
      cart,
    });
  } catch (error) {
    console.error("Error deleting product from cart:", error.message);
    res.status(500).json({ message: "Internal server error" });
  }
};

module.exports = {
  addUserCart,
  updateUserCart,
  getUserCart,
  deleteProductsFromCart,
  deleteProductFromCart,
};
